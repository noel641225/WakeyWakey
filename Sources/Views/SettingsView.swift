import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var alarmManager: AlarmManager
    @State private var showingResetAlert = false
    
    var body: some View {
        ZStack {
            // 背景 gradient
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
            
            ScrollView {
                VStack(spacing: 20) {
                    // 標題
                    headerView
                    
                    // 鬧鐘設置
                    settingsSection(title: "鬧鐘設置") {
                        VStack(spacing: 16) {
                            // 延長分鐘數
                            HStack {
                                Text("延長分鐘數")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                Spacer()
                                Stepper("\(settingsManager.snoozeDuration) 分鐘", 
                                        value: $settingsManager.settings.snoozeDuration, 
                                        in: 1...30)
                                    .labelsHidden()
                            }
                            
                            Divider().background(Color.white.opacity(0.3))
                            
                            // 取消需要點擊次數
                            HStack {
                                Text("取消需要點擊次數")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                Spacer()
                                Stepper("\(settingsManager.settings.defaultDismissTaps) 次", 
                                        value: $settingsManager.settings.defaultDismissTaps, 
                                        in: 1...10)
                                    .labelsHidden()
                            }
                        }
                    }
                    
                    // 通知設置
                    settingsSection(title: "通知設置") {
                        VStack(spacing: 16) {
                            // 音量
                            HStack {
                                Text("音量")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                Spacer()
                                Slider(value: $settingsManager.settings.soundVolume, 
                                       in: 0...1)
                                    .frame(width: 150)
                                Text("\(Int(settingsManager.settings.soundVolume * 100))%")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.8))
                                    .frame(width: 40)
                            }
                            
                            Divider().background(Color.white.opacity(0.3))
                            
                            // 震動
                            Toggle(isOn: $settingsManager.settings.vibrationEnabled) {
                                Text("震動")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            .tint(Color(hex: "FF6B6B"))
                        }
                    }
                    
                    // AI 設置
                    settingsSection(title: "AI 設置") {
                        VStack(spacing: 16) {
                            // AI 供應商
                            HStack {
                                Text("AI 供應商")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                Spacer()
                                Picker("", selection: $settingsManager.settings.aiProvider) {
                                    ForEach(AIProviderType.allCases) { provider in
                                        Text(provider.displayName).tag(provider)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(Color(hex: "FF6B6B"))
                            }
                            
                            // API Key (如果需要)
                            if settingsManager.settings.aiProvider == .userCustom {
                                Divider().background(Color.white.opacity(0.3))
                                
                                SecureField("輸入 API Key", 
                                           text: Binding(
                                               get: { settingsManager.settings.userAPIKey ?? "" },
                                               set: { settingsManager.settings.userAPIKey = $0 }
                                           ))
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            Divider().background(Color.white.opacity(0.3))
                            
                            // 剩餘免費次數
                            HStack {
                                Text("剩餘免費次數")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(settingsManager.settings.freeQuotaRemaining) 次")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Color(hex: "FF6B6B"))
                            }
                        }
                    }
                    
                    // 數據管理
                    settingsSection(title: "數據管理") {
                        VStack(spacing: 16) {
                            Button(action: {
                                showingResetAlert = true
                            }) {
                                HStack {
                                    Text("重置所有設置")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "arrow.counterclockwise")
                                        .foregroundColor(.white)
                                }
                            }
                            
                            Divider().background(Color.white.opacity(0.3))
                            
                            Button(action: {
                                // 刪除所有鬧鐘
                                for alarm in alarmManager.alarms {
                                    alarmManager.deleteAlarm(alarm)
                                }
                            }) {
                                HStack {
                                    Text("刪除所有鬧鐘")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "trash")
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                    
                    // 關於
                    settingsSection(title: "關於") {
                        VStack(spacing: 12) {
                            HStack {
                                Text("版本")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                Spacer()
                                Text("1.0.0")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
        }
        .alert("重置設置", isPresented: $showingResetAlert) {
            Button("取消", role: .cancel) {}
            Button("確認", role: .destructive) {
                settingsManager.settings = AppSettings()
                settingsManager.saveSettings()
            }
        } message: {
            Text("確定要重置所有設置嗎？")
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("設定")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Customize your experience!")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            Spacer()
            
            // 兔子 mascot
            BunnyView(isAnimating: false)
                .frame(width: 60, height: 60)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 20)
    }
    
    // MARK: - Settings Section
    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            VStack(spacing: 0) {
                content()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
        }
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
        .environmentObject(AlarmManager())
        .environmentObject(SettingsManager())
}
