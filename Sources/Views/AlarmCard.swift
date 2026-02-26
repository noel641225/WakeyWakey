import SwiftUI

// MARK: - Alarm Card View
struct AlarmCard: View {
    let alarm: Alarm
    @EnvironmentObject var alarmManager: AlarmManager
    @State private var isToggled: Bool
    
    init(alarm: Alarm) {
        self.alarm = alarm
        self._isToggled = State(initialValue: alarm.isEnabled)
    }
    
    var body: some View {
        HStack {
            // 鬧鐘時間
            VStack(alignment: .leading, spacing: 4) {
                Text(alarm.timeString)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(isToggled ? .white : .gray)
                
                Text(alarm.label)
                    .font(.system(size: 14))
                    .foregroundColor(isToggled ? .white.opacity(0.9) : .gray.opacity(0.8))
                
                Text(alarm.repeatString)
                    .font(.system(size: 12))
                    .foregroundColor(isToggled ? .white.opacity(0.7) : .gray.opacity(0.6))
            }
            
            Spacer()
            
            // 切換開關
            Toggle("", isOn: $isToggled)
                .labelsHidden()
                .tint(Color(hex: "FF6B6B"))
                .onChange(of: isToggled) { newValue in
                    alarmManager.toggleAlarm(alarm)
                }
        }
        .padding(20)
        .background(cardBackground)
        .shadow(color: isToggled ? Color(hex: "FF6B6B").opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
    }
    
    @ViewBuilder
    private var cardBackground: some View {
        if isToggled {
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        } else {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGray6))
        }
    }
}

// MARK: - Preview
#Preview {
    AlarmCard(alarm: Alarm(time: Date(), repeatDays: [.monday, .tuesday, .wednesday, .thursday, .friday], label: "起床啦！"))
        .padding()
        .environmentObject(AlarmManager())
}
