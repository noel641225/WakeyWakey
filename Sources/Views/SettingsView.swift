import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var alarmManager: AlarmManager
    @Environment(\.colorScheme) var colorScheme
    @State private var showingResetAlert = false
    @StateObject private var headerAnimator = SpriteAnimator(fps: 3)

    var body: some View {
        ZStack {
            // Warm cozy indoor background
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color.ghibliDarkBackground, Color.ghibliDarkCard.opacity(0.8), Color.ghibliDarkBackground]
                    : [Color.ghibliCream, Color.ghibliParchment.opacity(0.8), Color.ghibliSoftSky.opacity(0.25)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    headerView

                    // 鬧鐘設置
                    settingsSection(title: "🔔 鬧鐘設置") {
                        VStack(spacing: 16) {
                            settingsRow {
                                Text("延長分鐘數")
                                    .font(GhibliTheme.Typography.body(16))
                                    .foregroundColor(Color.ghibliDeepForest)
                                Spacer()
                                Stepper("\(settingsManager.snoozeDuration) 分鐘",
                                        value: $settingsManager.settings.snoozeDuration,
                                        in: 1...30)
                                .tint(Color.ghibliForestGreen)
                            }
                            ghibliDivider
                            settingsRow {
                                Text("取消需要點擊次數")
                                    .font(GhibliTheme.Typography.body(16))
                                    .foregroundColor(Color.ghibliDeepForest)
                                Spacer()
                                Stepper("\(settingsManager.settings.defaultDismissTaps) 次",
                                        value: $settingsManager.settings.defaultDismissTaps,
                                        in: 1...10)
                                .tint(Color.ghibliForestGreen)
                            }
                        }
                    }

                    // 通知設置
                    settingsSection(title: "🔊 通知設置") {
                        VStack(spacing: 16) {
                            settingsRow {
                                Text("音量")
                                    .font(GhibliTheme.Typography.body(16))
                                    .foregroundColor(Color.ghibliDeepForest)
                                Spacer()
                                Slider(value: $settingsManager.settings.soundVolume, in: 0...1)
                                    .frame(width: 140)
                                    .tint(Color.ghibliForestGreen)
                                Text("\(Int(settingsManager.settings.soundVolume * 100))%")
                                    .font(GhibliTheme.Typography.body(14))
                                    .foregroundColor(Color.ghibliWarmEarth)
                                    .frame(width: 38)
                            }
                            ghibliDivider
                            Toggle(isOn: $settingsManager.settings.vibrationEnabled) {
                                Text("震動")
                                    .font(GhibliTheme.Typography.body(16))
                                    .foregroundColor(Color.ghibliDeepForest)
                            }
                            .toggleStyle(GhibliToggleStyle())
                        }
                    }

                    // AI 設置
                    settingsSection(title: "✨ AI 設置") {
                        VStack(spacing: 16) {
                            settingsRow {
                                Text("AI 供應商")
                                    .font(GhibliTheme.Typography.body(16))
                                    .foregroundColor(Color.ghibliDeepForest)
                                Spacer()
                                Picker("", selection: $settingsManager.settings.aiProvider) {
                                    ForEach(AIProviderType.allCases) { provider in
                                        Text(provider.displayName).tag(provider)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(Color.ghibliForestGreen)
                            }

                            if settingsManager.settings.aiProvider == .userCustom {
                                ghibliDivider
                                SecureField("輸入 API Key",
                                           text: Binding(
                                               get: { settingsManager.settings.userAPIKey ?? "" },
                                               set: { settingsManager.settings.userAPIKey = $0 }
                                           ))
                                .font(GhibliTheme.Typography.body(15))
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: GhibliTheme.Radius.md)
                                        .fill(colorScheme == .dark ? Color.ghibliDarkBackground : Color.ghibliCream)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: GhibliTheme.Radius.md)
                                                .stroke(Color.ghibliWarmEarth.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }

                            ghibliDivider
                            settingsRow {
                                Text("剩餘免費次數")
                                    .font(GhibliTheme.Typography.body(16))
                                    .foregroundColor(Color.ghibliDeepForest)
                                Spacer()
                                Text("\(settingsManager.settings.freeQuotaRemaining) 次")
                                    .font(GhibliTheme.Typography.heading(16))
                                    .foregroundColor(Color.ghibliForestGreen)
                            }
                        }
                    }

                    // 數據管理
                    settingsSection(title: "🗂️ 數據管理") {
                        VStack(spacing: 16) {
                            Button(action: { showingResetAlert = true }) {
                                HStack {
                                    Text("重置所有設置")
                                        .font(GhibliTheme.Typography.body(16))
                                        .foregroundColor(Color.ghibliWarmEarth)
                                    Spacer()
                                    Image(systemName: "arrow.counterclockwise")
                                        .foregroundColor(Color.ghibliWarmEarth)
                                }
                            }
                            ghibliDivider
                            Button(action: {
                                for alarm in alarmManager.alarms {
                                    alarmManager.deleteAlarm(alarm)
                                }
                            }) {
                                HStack {
                                    Text("刪除所有鬧鐘")
                                        .font(GhibliTheme.Typography.body(16))
                                        .foregroundColor(Color(hex: "B03030"))
                                    Spacer()
                                    Image(systemName: "trash")
                                        .foregroundColor(Color(hex: "B03030"))
                                }
                            }
                        }
                    }

                    // 關於
                    settingsSection(title: "🌿 關於") {
                        settingsRow {
                            Text("版本")
                                .font(GhibliTheme.Typography.body(16))
                                .foregroundColor(Color.ghibliDeepForest)
                            Spacer()
                            Text("1.0.0")
                                .font(GhibliTheme.Typography.body(14))
                                .foregroundColor(Color.ghibleBarkBrown.opacity(0.7))
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 100)
            }
        }
        .alert("重置設置", isPresented: $showingResetAlert) {
            Button("取消", role: .cancel) {}
            Button("確認", role: .destructive) {
                settingsManager.settings = AppSettings()
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
                    .font(GhibliTheme.Typography.title(26))
                    .foregroundColor(colorScheme == .dark ? Color.ghibliDarkText : Color.ghibliDeepForest)
                Text("個人化你的小屋")
                    .font(GhibliTheme.Typography.body(13))
                    .foregroundColor(colorScheme == .dark ? Color.ghibliDarkText.opacity(0.7) : Color.ghibleBarkBrown.opacity(0.75))
            }
            Spacer()
            AnimatedCharacterView(animator: headerAnimator, size: 56)
                .onAppear { headerAnimator.startAnimation(state: .idle) }
        }
        .padding(.horizontal, 6)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Settings Section
    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(GhibliTheme.Typography.heading(16))
                .foregroundColor(Color.ghibliDeepForest)
                .padding(.leading, 4)

            VStack(spacing: 0) { content() }
                .ghibliCard(padding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
                            cornerRadius: GhibliTheme.Radius.md)
        }
    }

    @ViewBuilder
    private func settingsRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack { content() }
    }

    private var ghibliDivider: some View {
        Divider()
            .background(Color.ghibliWarmEarth.opacity(0.15))
    }
}

#Preview {
    SettingsView()
        .environmentObject(AlarmManager())
        .environmentObject(SettingsManager())
}
