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
                // 背景
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "FFB6C1"), Color(hex: "E6E6FA")]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 時間選擇
                        timeSection
                        
                        // 重複設定
                        repeatSection
                        
                        // 標籤
                        labelSection
                        
                        // 圖片選擇
                        imageSection

                        // 鈴聲選擇
                        ringtoneSection

                        // 進階設定
                        advancedSection
                    }
                    .padding(20)
                }
            }
            .navigationTitle("新增鬧鐘")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("儲存") {
                        saveAlarm()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "FF6B6B"))
                }
            }
        }
    }
    
    // MARK: - Time Section
    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("⏰ 鬧鐘時間")
                .font(.headline)
                .foregroundColor(.white)
            
            DatePicker("", selection: $alarmTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .colorInvert()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Repeat Section
    private var repeatSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🔄 重複")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 8) {
                ForEach(Weekday.allCases) { day in
                    Button(action: {
                        if selectedRepeatDays.contains(day) {
                            selectedRepeatDays.remove(day)
                        } else {
                            selectedRepeatDays.insert(day)
                        }
                    }) {
                        Text(day.shortName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(selectedRepeatDays.contains(day) ? .white : .gray)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(selectedRepeatDays.contains(day) ? 
                                        Color(hex: "FF6B6B") : Color(.systemGray5))
                            )
                    }
                }
            }
            
            if !selectedRepeatDays.isEmpty {
                Button("取消全選") {
                    selectedRepeatDays.removeAll()
                }
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Label Section
    private var labelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🏷️ 標籤")
                .font(.headline)
                .foregroundColor(.white)
            
            TextField("起床啦！", text: $alarmLabel)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Image Section
    private var imageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🖼️ 鬧鐘圖案")
                .font(.headline)
                .foregroundColor(.white)
            
            ForEach(AlarmImageType.allCases) { type in
                Button(action: {
                    selectedImageType = type
                }) {
                    HStack {
                        Text(type.displayName)
                            .foregroundColor(selectedImageType == type ? .white : .gray)
                        
                        Spacer()
                        
                        if selectedImageType == type {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedImageType == type ? 
                                Color(hex: "FF6B6B") : Color(.systemGray5))
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Ringtone Section
    private var ringtoneSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🎵 鈴聲")
                .font(.headline)
                .foregroundColor(.white)

            Button(action: { showRingtonePicker = true }) {
                HStack {
                    Image(systemName: "music.note")
                        .foregroundColor(Color(hex: "FF6B6B"))
                    Text(selectedRingtone.displayName)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
        .sheet(isPresented: $showRingtonePicker) {
            RingtonePickerView(selectedRingtone: $selectedRingtone)
                .environmentObject(ringtoneManager)
        }
    }

    // MARK: - Advanced Section
    private var advancedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("⚙️ 進階設定")
                .font(.headline)
                .foregroundColor(.white)
            
            // 延長次數
            HStack {
                Text("延長所需點擊")
                    .foregroundColor(.white)
                Spacer()
                Stepper("\(snoozeTaps) 次", value: $snoozeTaps, in: 1...10)
                    .colorInvert()
            }
            
            // 取消次數
            HStack {
                Text("取消所需點擊")
                    .foregroundColor(.white)
                Spacer()
                Stepper("\(dismissTaps) 次", value: $dismissTaps, in: 1...10)
                    .colorInvert()
            }
            
            // 移動速度
            VStack(alignment: .leading) {
                HStack {
                    Text("圖案移動速度")
                        .foregroundColor(.white)
                    Spacer()
                    Text(String(format: "%.0f%%", moveSpeed * 100))
                        .foregroundColor(.white)
                }
                Slider(value: $moveSpeed, in: 0.1...1.0)
                    .tint(Color(hex: "FF6B6B"))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
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

// MARK: - Preview
#Preview {
    AddAlarmView()
        .environmentObject(AlarmManager())
        .environmentObject(SettingsManager())
        .environmentObject(RingtoneManager())
}
