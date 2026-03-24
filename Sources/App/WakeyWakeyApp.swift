import SwiftUI

@main
struct WakeyWakeyApp: App {
    @StateObject private var alarmManager = AlarmManager()
    @StateObject private var settingsManager = SettingsManager()
    @StateObject private var ringtoneManager = RingtoneManager()

    init() {
        GhibliNavigationStyle.applyGlobalAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(alarmManager)
                .environmentObject(settingsManager)
                .environmentObject(ringtoneManager)
                .tint(Color.ghibliForestGreen)
        }
    }
}
