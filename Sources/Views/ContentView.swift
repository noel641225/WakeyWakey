import SwiftUI

struct ContentView: View {
    @EnvironmentObject var alarmManager: AlarmManager
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var showingAddAlarm = false
    @State private var selectedTab = 0  // 0 = 鬧鐘, 1 = 設定
    
    var body: some View {
        ZStack {
            // 根據選擇的標籤顯示不同內容
            switch selectedTab {
            case 0:
                alarmPageView
            case 1:
                SettingsView()
            default:
                alarmPageView
            }
            
            // 底部導航（始終顯示）
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
    }
    
    // MARK: - Alarm Page View
    private var alarmPageView: some View {
        ZStack {
            // 可愛的背景 gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "FFB6C1"), // 淺粉色
                    Color(hex: "E6E6FA"), // 薰衣草紫
                    Color(hex: "B0E0E6")  // 粉末藍
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 標題區
                headerView
                
                // 鬧鐘列表
                alarmListView
                
                Spacer()
                    .frame(height: 80)
            }
        }
    }
    
    // MARK: - Header View
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
            
            // 龍蝦 mascot
            LobsterView()
                .frame(width: 60, height: 60)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 20)
    }
    
    // MARK: - Alarm List
    private var alarmListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if alarmManager.alarms.isEmpty {
                    emptyStateView
                } else {
                    ForEach(alarmManager.alarms) { alarm in
                        AlarmCard(alarm: alarm)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            // 兔子 mascot
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
    }
    
    // MARK: - Bottom Navigation
    private var bottomNavigation: some View {
        HStack(spacing: 40) {
            // 首頁按鈕
            navButton(icon: "clock.fill", label: "鬧鐘", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            
            // 新增按鈕 (突出) - 只在鬧鐘頁顯示
            Button(action: {
                showingAddAlarm = true
            }) {
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
            
            // 設定按鈕
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
    
    // MARK: - Nav Button
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
