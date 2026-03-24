import SwiftUI
import AudioToolbox

// MARK: - Alarm Firing View
// Fullscreen overlay shown when an alarm triggers.
// The mascot moves around the screen; user must tap it `dismissCount` times to dismiss.
struct AlarmFiringView: View {
    @EnvironmentObject var alarmManager: AlarmManager
    @EnvironmentObject var settingsManager: SettingsManager
    let alarm: Alarm

    // Chase-and-tap state
    @State private var tapCount: Int = 0
    @State private var characterPosition: CGPoint = CGPoint(x: 180, y: 350)
    @State private var characterScale: CGFloat = 1.0
    @State private var bounceAnimation = false
    @State private var moveTimer: Timer?
    @State private var vibrateTimer: Timer?
    @State private var showDismissed = false
    @State private var snoozeUsed: Int = 0
    @State private var screenSize: CGSize = .zero
    @State private var isReady = false

    @StateObject private var animator = SpriteAnimator(fps: 6)

    private var dismissTapsRequired: Int { alarm.dismissCount }
    private var canSnooze: Bool { snoozeUsed < alarm.snoozeCount }

    // Movement interval: fast at moveSpeed 1.0 (0.3s), slow at 0.1 (3.0s)
    private var moveInterval: TimeInterval {
        3.3 - 3.0 * alarm.moveSpeed
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                SunriseBackgroundView()

                // Alarm info overlay at top
                VStack(spacing: 0) {
                    alarmInfoPanel
                    Spacer()
                    if canSnooze {
                        snoozeButton
                            .padding(.bottom, 48)
                    }
                }

                // Animated character (chase to tap)
                if isReady {
                    characterView
                        .position(characterPosition)
                        .animation(.spring(response: 0.6, dampingFraction: 0.65), value: characterPosition)
                }

                // Tap progress indicator
                tapProgressView
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.82)

                if showDismissed {
                    dismissedOverlay
                }
            }
            .onAppear {
                screenSize = geo.size
                characterPosition = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                isReady = true
                animator.startAnimation(state: .moving)

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    startMoving(in: geo.size)
                }
                startVibrating()
            }
            .onDisappear {
                moveTimer?.invalidate()
                moveTimer = nil
                vibrateTimer?.invalidate()
                vibrateTimer = nil
                animator.stopAnimation()
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Alarm Info Panel
    private var alarmInfoPanel: some View {
        VStack(spacing: 8) {
            Text(alarm.timeString)
                .font(GhibliTheme.Typography.timeDisplay(72))
                .foregroundColor(.white)
                .shadow(color: Color.ghibliDeepForest.opacity(0.4), radius: 4, x: 0, y: 2)

            Text(alarm.label.isEmpty ? "起床時間到了！" : alarm.label)
                .font(GhibliTheme.Typography.heading(20))
                .foregroundColor(Color.ghibliCream)
                .shadow(color: Color.ghibliDeepForest.opacity(0.3), radius: 2, x: 0, y: 1)

            Text("抓住小精靈來關掉鬧鐘！")
                .font(GhibliTheme.Typography.body(14))
                .foregroundColor(Color.ghibliCream.opacity(0.85))
        }
        .padding(.top, 80)
        .padding(.horizontal, 24)
    }

    // MARK: - Character View
    private var characterView: some View {
        AnimatedCharacterView(animator: animator, size: 90) {
            handleCharacterTap()
        }
        .scaleEffect(characterScale)
        .animation(.spring(response: 0.2, dampingFraction: 0.4), value: characterScale)
    }

    // MARK: - Tap Progress
    private var tapProgressView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                ForEach(0..<dismissTapsRequired, id: \.self) { i in
                    Circle()
                        .fill(i < tapCount ? Color.ghibliMeadowGold : Color.white.opacity(0.35))
                        .frame(width: 14, height: 14)
                        .overlay(
                            Circle().stroke(Color.white.opacity(0.6), lineWidth: 1)
                        )
                        .scaleEffect(i < tapCount ? 1.2 : 1.0)
                        .animation(.spring(response: 0.2, dampingFraction: 0.5), value: tapCount)
                }
            }
            Text("點擊 \(dismissTapsRequired - tapCount) 次關閉")
                .font(GhibliTheme.Typography.caption(13))
                .foregroundColor(Color.white.opacity(0.8))
        }
    }

    // MARK: - Snooze Button
    private var snoozeButton: some View {
        Button(action: handleSnooze) {
            Label("延長 \(settingsManager.snoozeDuration) 分鐘", systemImage: "moon.zzz.fill")
                .font(GhibliTheme.Typography.body(15))
        }
        .ghibliButton(.secondary)
    }

    // MARK: - Dismissed Overlay
    private var dismissedOverlay: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 16) {
                Text("🌿")
                    .font(.system(size: 64))
                Text("好眠結束！")
                    .font(GhibliTheme.Typography.title(28))
                    .foregroundColor(.white)
                Text("今天也要元氣滿滿哦！")
                    .font(GhibliTheme.Typography.body(16))
                    .foregroundColor(Color.ghibliCream)
            }
        }
        .transition(.opacity.combined(with: .scale))
    }

    // MARK: - Tap Handling
    private func handleCharacterTap() {
        animator.transition(to: .tapped)
        withAnimation(.spring(response: 0.15, dampingFraction: 0.4)) {
            characterScale = 0.8
        }
        // Haptic feedback
        AudioServicesPlaySystemSound(1519) // Peek haptic

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                characterScale = 1.0
            }
            animator.transition(to: .moving)
        }

        // Jump away on tap
        moveMascot(in: screenSize)

        tapCount += 1
        if tapCount >= dismissTapsRequired {
            dismissAlarm()
        }
    }

    private func handleSnooze() {
        snoozeUsed += 1
        alarmManager.snoozeAlarm(alarm: alarm, duration: settingsManager.snoozeDuration)
    }

    // MARK: - Dismiss
    private func dismissAlarm() {
        moveTimer?.invalidate()
        vibrateTimer?.invalidate()
        animator.transition(to: .dismissed)
        withAnimation(.easeInOut(duration: 0.4)) {
            showDismissed = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alarmManager.dismissAlarm()
        }
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
        let topPad: CGFloat = 240    // avoid top info area
        let bottomPad: CGFloat = 130 // avoid snooze button

        let minX = pad
        let maxX = max(minX + 1, size.width - pad)
        let minY = topPad
        let maxY = max(minY + 1, size.height - bottomPad)

        characterPosition = CGPoint(
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
    AlarmFiringView(alarm: Alarm(
        time: Date(),
        isEnabled: true,
        repeatDays: [],
        label: "起床啦！",
        dismissCount: 3
    ))
    .environmentObject(AlarmManager())
    .environmentObject(SettingsManager())
}
