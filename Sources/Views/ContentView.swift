import SwiftUI

struct ContentView: View {
    @EnvironmentObject var alarmManager: AlarmManager
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var showingAddAlarm = false
    @State private var selectedTab = 0  // 0 = 鬧鐘, 1 = 設定
    @StateObject private var headerAnimator = SpriteAnimator(fps: 4)
    @StateObject private var emptyStateAnimator = SpriteAnimator(fps: 3)

    var body: some View {
        ZStack {
            switch selectedTab {
            case 0:
                alarmPageView
            case 1:
                SettingsView()
            default:
                alarmPageView
            }

            VStack {
                Spacer()
                bottomNavigation
            }
        }
        .sheet(isPresented: $showingAddAlarm) {
            AddAlarmView()
                .environmentObject(alarmManager)
                .environmentObject(settingsManager)
        }
        .fullScreenCover(isPresented: Binding(
            get: { alarmManager.isAlarmTriggering && alarmManager.currentTriggeringAlarm != nil },
            set: { if !$0 { alarmManager.dismissAlarm() } }
        )) {
            if let alarm = alarmManager.currentTriggeringAlarm {
                AlarmFiringView(alarm: alarm)
                    .environmentObject(alarmManager)
                    .environmentObject(settingsManager)
            }
        }
    }

    // MARK: - Alarm Page
    private var alarmPageView: some View {
        ZStack {
            MeadowBackgroundView()

            VStack(spacing: 0) {
                headerView
                alarmListView
                Spacer().frame(height: 80)
            }
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Wakey Wakey")
                    .font(GhibliTheme.Typography.title(26))
                    .foregroundColor(Color.ghibliDeepForest)

                Text("一起床就要元氣滿滿！")
                    .font(GhibliTheme.Typography.body(13))
                    .foregroundColor(Color.ghibleBarkBrown.opacity(0.9))
            }

            Spacer()

            // Totoro-style mascot
            AnimatedCharacterView(animator: headerAnimator, size: 58)
                .onAppear { headerAnimator.startAnimation(state: .idle) }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 16)
        .background(Color.ghibliCream.opacity(0.85))
    }

    // MARK: - Alarm List
    private var alarmListView: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                if alarmManager.alarms.isEmpty {
                    emptyStateView
                } else {
                    ForEach(alarmManager.alarms) { alarm in
                        AlarmCard(alarm: alarm)
                            .transition(.asymmetric(insertion: .scale.combined(with: .opacity),
                                                    removal: .opacity))
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 100)
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 18) {
            AnimatedCharacterView(animator: emptyStateAnimator, size: 110)
                .onAppear { emptyStateAnimator.startAnimation(state: .idle) }

            Text("還沒有鬧鐘")
                .font(GhibliTheme.Typography.heading(20))
                .foregroundColor(Color.ghibliDeepForest)

            Text("點擊下方 + 按鈕\n新增第一個鬧鐘吧～")
                .font(GhibliTheme.Typography.body(15))
                .foregroundColor(Color.ghibleBarkBrown.opacity(0.75))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 50)
    }

    // MARK: - Bottom Navigation
    private var bottomNavigation: some View {
        HStack(spacing: 40) {
            navButton(icon: "clock.fill", label: "鬧鐘", isSelected: selectedTab == 0) {
                selectedTab = 0
            }

            // Add alarm button
            Button(action: { showingAddAlarm = true }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.ghibliForestGreen, Color.ghibliDeepForest],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                        .shadow(color: Color.ghibliForestGreen.opacity(0.45), radius: 10, x: 0, y: 4)

                    Image(systemName: "plus")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .opacity(selectedTab == 0 ? 1 : 0.4)
            .disabled(selectedTab != 0)

            navButton(icon: "gearshape.fill", label: "設定", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.ghibliCream.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(Color.ghibliWarmEarth.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.ghibleBarkBrown.opacity(0.12), radius: 12, x: 0, y: -4)
        )
        .padding(.horizontal, 20)
    }

    private func navButton(icon: String, label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(isSelected ? Color.ghibliForestGreen : Color.ghibleBarkBrown.opacity(0.5))

                Text(label)
                    .font(GhibliTheme.Typography.caption(11))
                    .foregroundColor(isSelected ? Color.ghibliForestGreen : Color.ghibleBarkBrown.opacity(0.5))
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AlarmManager())
        .environmentObject(SettingsManager())
}
