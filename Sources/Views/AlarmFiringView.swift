import SwiftUI

// MARK: - Alarm Firing View
struct AlarmFiringView: View {
    @EnvironmentObject var alarmManager: AlarmManager
    let alarm: Alarm

    // Chase-and-tap state
    @State private var tapCount: Int = 0
    @State private var characterPosition: CGPoint = CGPoint(x: 180, y: 350)
    @State private var characterScale: CGFloat = 1.0
    @State private var bounceAnimation = false
    @State private var moveTimer: Timer?
    @State private var showDismissed = false

    @StateObject private var animator = SpriteAnimator(fps: 6)

    private var dismissTapsRequired: Int { alarm.dismissCount }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                SunriseBackgroundView()

                // Alarm info overlay at top
                VStack(spacing: 0) {
                    alarmInfoPanel
                    Spacer()
                    snoozeButton
                        .padding(.bottom, 48)
                }

                // Animated character (chase to tap)
                characterView
                    .position(characterPosition)
                    .animation(.spring(response: 0.6, dampingFraction: 0.65), value: characterPosition)

                // Tap progress indicator
                tapProgressView
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.82)

                if showDismissed {
                    dismissedOverlay
                }
            }
            .onAppear {
                spawnCharacter(in: geo.size)
                startMoving(in: geo.size)
                animator.startAnimation(state: .moving)
            }
            .onDisappear {
                moveTimer?.invalidate()
                moveTimer = nil
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
        Button(action: { alarmManager.snoozeAlarm() }) {
            Label("延長 5 分鐘", systemImage: "moon.zzz.fill")
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                characterScale = 1.0
            }
            animator.transition(to: .moving)
        }

        tapCount += 1
        if tapCount >= dismissTapsRequired {
            dismissAlarm()
        }
    }

    // MARK: - Dismiss
    private func dismissAlarm() {
        moveTimer?.invalidate()
        animator.transition(to: .dismissed)
        withAnimation(.easeInOut(duration: 0.4)) {
            showDismissed = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alarmManager.dismissAlarm()
        }
    }

    // MARK: - Movement
    private func spawnCharacter(in size: CGSize) {
        characterPosition = CGPoint(x: size.width / 2, y: size.height * 0.52)
    }

    private func startMoving(in size: CGSize) {
        let speed = max(0.6, alarm.moveSpeed)
        let interval = 2.2 / speed
        moveTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            Task { @MainActor in
                moveCharacter(in: size)
            }
        }
        RunLoop.main.add(moveTimer!, forMode: .common)
    }

    private func moveCharacter(in size: CGSize) {
        let padding: CGFloat = 60
        let newX = CGFloat.random(in: padding...(size.width - padding))
        let newY = CGFloat.random(in: size.height * 0.38...(size.height * 0.72))
        characterPosition = CGPoint(x: newX, y: newY)
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
