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
        HStack(spacing: 16) {
            // Time + label
            VStack(alignment: .leading, spacing: 4) {
                Text(alarm.timeString)
                    .font(GhibliTheme.Typography.timeDisplay(38))
                    .foregroundColor(isToggled ? Color.ghibliDeepForest : Color.ghibleBarkBrown.opacity(0.45))

                Text(alarm.label)
                    .font(GhibliTheme.Typography.body(13))
                    .foregroundColor(isToggled ? Color.ghibleBarkBrown : Color.ghibleBarkBrown.opacity(0.4))

                if !alarm.repeatString.isEmpty {
                    Text(alarm.repeatString)
                        .font(GhibliTheme.Typography.caption(11))
                        .foregroundColor(isToggled ? Color.ghibliWarmEarth.opacity(0.8) : Color.ghibleBarkBrown.opacity(0.3))
                }
            }

            Spacer()

            // Leaf toggle
            Toggle("", isOn: $isToggled)
                .labelsHidden()
                .toggleStyle(GhibliToggleStyle())
                .onChange(of: isToggled) { _ in
                    alarmManager.toggleAlarm(alarm)
                }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(cardBackground)
        .ghibliShadow(isToggled ? GhibliTheme.Shadow.warm : GhibliTheme.Shadow.soft)
    }

    @ViewBuilder
    private var cardBackground: some View {
        if isToggled {
            RoundedRectangle(cornerRadius: GhibliTheme.Radius.lg, style: .continuous)
                .fill(Color.ghibliParchment)
                .overlay(
                    RoundedRectangle(cornerRadius: GhibliTheme.Radius.lg, style: .continuous)
                        .stroke(Color.ghibliForestGreen.opacity(0.4), lineWidth: 1.5)
                )
        } else {
            RoundedRectangle(cornerRadius: GhibliTheme.Radius.lg, style: .continuous)
                .fill(Color.ghibliParchment.opacity(0.55))
                .overlay(
                    RoundedRectangle(cornerRadius: GhibliTheme.Radius.lg, style: .continuous)
                        .stroke(Color.ghibleBarkBrown.opacity(0.15), lineWidth: 1)
                )
        }
    }
}

#Preview {
    AlarmCard(alarm: Alarm(
        time: Date(),
        repeatDays: [.monday, .tuesday, .wednesday, .thursday, .friday],
        label: "起床啦！"
    ))
    .padding()
    .background(Color.ghibliSoftSky.opacity(0.3))
    .environmentObject(AlarmManager())
}
