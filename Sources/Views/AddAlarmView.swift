import SwiftUI
import PhotosUI

// MARK: - Add Alarm View
struct AddAlarmView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var alarmManager: AlarmManager
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var ringtoneManager: RingtoneManager

    @State private var alarmTime = Date()
    @State private var alarmLabel = "起床啦！"
    @State private var selectedRepeatDays: Set<Weekday> = []
    @State private var selectedImageType: AlarmImageType = .defaultBunny
    @State private var snoozeTaps: Int = 1
    @State private var dismissTaps: Int = 3
    @State private var moveSpeed: Double = 0.5
    @State private var selectedRingtone: RingtoneSelection = .default
    @State private var showRingtonePicker = false
    var body: some View {
        NavigationView {
            ZStack {
                // Warm parchment background
                Color.ghibliCream.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        timeSection
                        repeatSection
                        labelSection
                        imageSection

                        // 鈴聲選擇
                        ringtoneSection

                        // 進階設定
                        advancedSection
                    }
                    .padding(18)
                }
            }
            .navigationTitle("新增鬧鐘")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                        .font(GhibliTheme.Typography.body(16))
                        .foregroundColor(Color.ghibleBarkBrown.opacity(0.7))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("儲存") { saveAlarm() }
                        .font(GhibliTheme.Typography.heading(16))
                        .foregroundColor(Color.ghibliForestGreen)
                }
            }
            .ghibliNavigation()
        }
    }

    // MARK: - Time Section
    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("⏰ 鬧鐘時間")

            DatePicker("", selection: $alarmTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .tint(Color.ghibliForestGreen)
                .frame(maxWidth: .infinity)
        }
        .ghibliCard()
    }

    // MARK: - Repeat Section
    private var repeatSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("🔄 重複")

            HStack(spacing: 6) {
                ForEach(Weekday.allCases) { day in
                    let isSelected = selectedRepeatDays.contains(day)
                    Button(action: {
                        if isSelected { selectedRepeatDays.remove(day) }
                        else { selectedRepeatDays.insert(day) }
                    }) {
                        Text(day.shortName)
                            .font(GhibliTheme.Typography.body(13))
                            .foregroundColor(isSelected ? .white : Color.ghibleBarkBrown.opacity(0.7))
                            .frame(width: 38, height: 38)
                            .background(
                                Circle().fill(isSelected ? Color.ghibliForestGreen : Color.ghibliWarmEarth.opacity(0.12))
                            )
                            .overlay(
                                Circle().stroke(isSelected ? Color.ghibliForestGreen : Color.ghibliWarmEarth.opacity(0.25), lineWidth: 1)
                            )
                    }
                }
            }

            if !selectedRepeatDays.isEmpty {
                Button("取消全選") { selectedRepeatDays.removeAll() }
                    .font(GhibliTheme.Typography.caption(13))
                    .foregroundColor(Color.ghibleBarkBrown.opacity(0.6))
            }
        }
        .ghibliCard()
    }

    // MARK: - Label Section
    private var labelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("🏷️ 標籤")

            TextField("起床啦！", text: $alarmLabel)
                .font(GhibliTheme.Typography.body(16))
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: GhibliTheme.Radius.md)
                        .fill(Color.ghibliCream)
                        .overlay(
                            RoundedRectangle(cornerRadius: GhibliTheme.Radius.md)
                                .stroke(Color.ghibliWarmEarth.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .ghibliCard()
    }

    // MARK: - Image Section
    private var imageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("🖼️ 鬧鐘圖案")

            ForEach(AlarmImageType.allCases) { type in
                let isSelected = selectedImageType == type
                Button(action: { selectedImageType = type }) {
                    HStack {
                        Text(type.displayName)
                            .font(GhibliTheme.Typography.body(15))
                            .foregroundColor(isSelected ? Color.ghibliDeepForest : Color.ghibleBarkBrown.opacity(0.7))
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color.ghibliForestGreen)
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: GhibliTheme.Radius.md)
                            .fill(isSelected ? Color.ghibliForestGreen.opacity(0.1) : Color.ghibliCream)
                            .overlay(
                                RoundedRectangle(cornerRadius: GhibliTheme.Radius.md)
                                    .stroke(isSelected ? Color.ghibliForestGreen.opacity(0.5) : Color.ghibliWarmEarth.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
            }
        }
        .ghibliCard()
    }

    // MARK: - Ringtone Section
    private var ringtoneSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("🎵 鈴聲")

            Button(action: { showRingtonePicker = true }) {
                HStack {
                    Image(systemName: "music.note")
                        .foregroundColor(Color.ghibliForestGreen)
                    Text(selectedRingtone.displayName)
                        .font(GhibliTheme.Typography.body(15))
                        .foregroundColor(Color.ghibliDeepForest)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color.ghibleBarkBrown.opacity(0.6))
                        .font(.system(size: 14))
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: GhibliTheme.Radius.md)
                        .fill(Color.ghibliCream)
                        .overlay(
                            RoundedRectangle(cornerRadius: GhibliTheme.Radius.md)
                                .stroke(Color.ghibliWarmEarth.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
        .ghibliCard()
        .sheet(isPresented: $showRingtonePicker) {
            RingtonePickerView(selectedRingtone: $selectedRingtone)
                .environmentObject(ringtoneManager)
        }
    }

    // MARK: - Advanced Section
    private var advancedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("⚙️ 進階設定")

            HStack {
                Text("延長所需點擊")
                    .font(GhibliTheme.Typography.body(15))
                    .foregroundColor(Color.ghibliDeepForest)
                Spacer()
                Stepper("\(snoozeTaps) 次", value: $snoozeTaps, in: 1...10)
                    .tint(Color.ghibliForestGreen)
            }

            Divider().background(Color.ghibliWarmEarth.opacity(0.2))

            HStack {
                Text("取消所需點擊")
                    .font(GhibliTheme.Typography.body(15))
                    .foregroundColor(Color.ghibliDeepForest)
                Spacer()
                Stepper("\(dismissTaps) 次", value: $dismissTaps, in: 1...10)
                    .tint(Color.ghibliForestGreen)
            }

            Divider().background(Color.ghibliWarmEarth.opacity(0.2))

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("圖案移動速度")
                        .font(GhibliTheme.Typography.body(15))
                        .foregroundColor(Color.ghibliDeepForest)
                    Spacer()
                    Text(String(format: "%.0f%%", moveSpeed * 100))
                        .font(GhibliTheme.Typography.body(14))
                        .foregroundColor(Color.ghibliWarmEarth)
                }
                Slider(value: $moveSpeed, in: 0.1...1.0)
                    .tint(Color.ghibliForestGreen)
            }
        }
        .ghibliCard()
    }

    // MARK: - Section Header Helper
    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(GhibliTheme.Typography.heading(16))
            .foregroundColor(Color.ghibliDeepForest)
    }

    // MARK: - Save
    private func saveAlarm() {
        let alarm = Alarm(
            time: alarmTime,
            isEnabled: true,
            repeatDays: Array(selectedRepeatDays),
            label: alarmLabel,
            imageType: selectedImageType,
            snoozeCount: snoozeTaps,
            dismissCount: dismissTaps,
            moveSpeed: moveSpeed,
            selectedRingtone: selectedRingtone
        )
        alarmManager.addAlarm(alarm)
        dismiss()
    }
}

#Preview {
    AddAlarmView()
        .environmentObject(AlarmManager())
        .environmentObject(SettingsManager())
        .environmentObject(RingtoneManager())
}
