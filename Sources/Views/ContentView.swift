import SwiftUI

struct ContentView: View {
    @EnvironmentObject var alarmManager: AlarmManager
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var showingAddAlarm = false
    @State private var selectedTab = 0  // 0 = 鬧鐘, 1 = 設定

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
        .fullScreenCover(
            isPresented: Binding(
                get: { alarmManager.isAlarmTriggering },
                set: { _ in alarmManager.dismissAlarm() }
            )
        ) {
            if let alarm = alarmManager.currentTriggeringAlarm {
                AlarmFiringView(alarm: alarm)
                    .environmentObject(alarmManager)
                    .environmentObject(settingsManager)
            } else {
                Color.clear.onAppear { alarmManager.dismissAlarm() }
            }
        }
    }

    // MARK: - Alarm Page View

    private var alarmPageView: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "FFB6C1"),
                    Color(hex: "E6E6FA"),
                    Color(hex: "B0E0E6")
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

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
                Text("Wakey Wakey! ✨")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("一起床就要元氣滿滿！")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }

            Spacer()

            LobsterView()
                .frame(width: 60, height: 60)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 20)
    }

    // MARK: - Alarm List (List for swipe-to-delete)

    private var alarmListView: some View {
        List {
            if alarmManager.alarms.isEmpty {
                emptyStateView
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
            } else {
                ForEach(alarmManager.alarms) { alarm in
                    AlarmCard(alarm: alarm)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                alarmManager.deleteAlarm(alarm)
                            } label: {
                                Label("刪除", systemImage: "trash")
                            }
                        }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .padding(.bottom, 20)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            BunnyView(isAnimating: true)
                .frame(width: 120, height: 120)

            Text("還沒有鬧鐘！")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("點擊下方 + 按鈕\n新增第一個鬧鐘吧～")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 60)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Bottom Navigation

    private var bottomNavigation: some View {
        HStack(spacing: 40) {
            navButton(icon: "clock.fill", label: "鬧鐘", isSelected: selectedTab == 0) {
                selectedTab = 0
            }

            Button(action: { showingAddAlarm = true }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                        .shadow(color: Color(hex: "FF6B6B").opacity(0.4), radius: 8, x: 0, y: 4)

                    Image(systemName: "plus")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .opacity(selectedTab == 0 ? 1 : 0.5)
            .disabled(selectedTab != 0)

            navButton(icon: "gearshape.fill", label: "設定", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
        )
        .padding(.horizontal, 20)
    }

    private func navButton(icon: String, label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(isSelected ? Color(hex: "FF6B6B") : .gray)

                Text(label)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? Color(hex: "FF6B6B") : .gray)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .environmentObject(AlarmManager())
        .environmentObject(SettingsManager())
}
