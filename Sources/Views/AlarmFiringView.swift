import SwiftUI
import AudioToolbox

// MARK: - Alarm Firing View
// Fullscreen overlay shown when an alarm triggers.
// The mascot moves around the screen; user must tap it `dismissCount` times to dismiss.
struct AlarmFiringView: View {
    let alarm: Alarm
    @EnvironmentObject var alarmManager: AlarmManager
    @EnvironmentObject var settingsManager: SettingsManager

    // Mascot movement
    @State private var mascotPosition: CGPoint = .zero
    @State private var screenSize: CGSize = .zero
    @State private var isReady = false
    @State private var moveTimer: Timer?
    @State private var vibrateTimer: Timer?

    // Game state
    @State private var tapCount: Int = 0
    @State private var snoozeUsed: Int = 0
    @State private var showTapFeedback = false
    @State private var tapFeedbackScale: CGFloat = 1.0

    // Movement interval: fast at moveSpeed 1.0 (0.3s), slow at 0.1 (3.0s)
    private var moveInterval: TimeInterval {
        3.3 - 3.0 * alarm.moveSpeed
    }

    private var remainingTaps: Int { max(0, alarm.dismissCount - tapCount) }
    private var canSnooze: Bool { snoozeUsed < alarm.snoozeCount }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Full-bleed background
                LinearGradient(
                    colors: [
                        Color(hex: "FF6B6B"),
                        Color(hex: "FF8E53"),
                        Color(hex: "FFB6C1")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Static layout: time / label / counter at top, snooze at bottom
                VStack(spacing: 12) {
                    Spacer().frame(height: 50)

                    Text(alarm.timeString)
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    if !alarm.label.isEmpty {
                        Text(alarm.label)
                            .font(.system(size: 22, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                    }

                    // Tap counter badge
                    tapCounterBadge

                    Spacer()

                    // Snooze button — shown while snoozes remain
                    if canSnooze {
                        snoozeButton
                    }

                    Spacer().frame(height: 44)
                }
                .padding(.horizontal, 24)

                // Moving mascot button
                if isReady {
                    Button(action: handleTap) {
                        mascotView
                            .frame(width: 100, height: 100)
                            .scaleEffect(tapFeedbackScale)
                            .animation(
                                .spring(response: 0.2, dampingFraction: 0.4),
                                value: tapFeedbackScale
                            )
                    }
                    .buttonStyle(.plain)
                    .position(mascotPosition)
                    .animation(
                        .spring(response: 0.7, dampingFraction: 0.65),
                        value: mascotPosition
                    )
                }
            }
            .onAppear {
                screenSize = geometry.size
                // Start at center, then begin moving after a short delay so user
                // can see where it is before it starts running away
                mascotPosition = CGPoint(x: geometry.size.width / 2,
                                         y: geometry.size.height / 2)
                isReady = true

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    startMoving(in: geometry.size)
                }
                startVibrating()
            }
            .onDisappear {
                moveTimer?.invalidate()
                vibrateTimer?.invalidate()
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Sub-views

    private var tapCounterBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "hand.tap.fill")
                .foregroundColor(.white)
            Text(remainingTaps == 0 ? "關閉中…" : "還需點擊 \(remainingTaps) 次")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Capsule().fill(Color.white.opacity(0.25)))
    }

    private var snoozeButton: some View {
        Button(action: handleSnooze) {
            HStack(spacing: 8) {
                Image(systemName: "zzz")
                Text("延長 \(settingsManager.snoozeDuration) 分鐘")
                    .fontWeight(.semibold)
            }
            .font(.system(size: 18))
            .foregroundColor(Color(hex: "FF6B6B"))
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(Capsule().fill(Color.white))
            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
        }
    }

    @ViewBuilder
    private var mascotView: some View {
        switch alarm.imageType {
        case .defaultLobster:
            LobsterView()
        default:
            BunnyView(isAnimating: true)
        }
    }

    // MARK: - Game Logic

    private func handleTap() {
        tapCount += 1

        // Bounce animation
        tapFeedbackScale = 1.35
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            tapFeedbackScale = 1.0
        }

        // Haptic feedback
        AudioServicesPlaySystemSound(1519) // Peek haptic

        // Jump away immediately on tap
        moveMascot(in: screenSize)

        if tapCount >= alarm.dismissCount {
            alarmManager.dismissAlarm()
        }
    }

    private func handleSnooze() {
        snoozeUsed += 1
        alarmManager.snoozeAlarm(alarm: alarm, duration: settingsManager.snoozeDuration)
    }

    // MARK: - Movement

    private func startMoving(in size: CGSize) {
        moveMascot(in: size) // first jump

        let timer = Timer.scheduledTimer(withTimeInterval: moveInterval, repeats: true) { _ in
            moveMascot(in: size)
        }
        RunLoop.main.add(timer, forMode: .common)
        moveTimer = timer
    }

    private func moveMascot(in size: CGSize) {
        let pad: CGFloat = 70
        let topPad: CGFloat = 240   // avoid top info area
        let bottomPad: CGFloat = 130 // avoid snooze button

        let minX = pad
        let maxX = max(minX + 1, size.width - pad)
        let minY = topPad
        let maxY = max(minY + 1, size.height - bottomPad)

        mascotPosition = CGPoint(
            x: CGFloat.random(in: minX...maxX),
            y: CGFloat.random(in: minY...maxY)
        )
    }

    // MARK: - Vibration Loop

    private func startVibrating() {
        let timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
        RunLoop.main.add(timer, forMode: .common)
        vibrateTimer = timer
    }
}

// MARK: - Preview
#Preview {
    AlarmFiringView(alarm: Alarm(label: "起床啦！", imageType: .defaultBunny, snoozeCount: 2, dismissCount: 5, moveSpeed: 0.5))
        .environmentObject(AlarmManager())
        .environmentObject(SettingsManager())
}
