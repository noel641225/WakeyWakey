import SwiftUI

@main
struct WakeyWakeyApp: App {
    @StateObject private var alarmManager = AlarmManager()
    @StateObject private var settingsManager = SettingsManager()
    @StateObject private var ringtoneManager = RingtoneManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(alarmManager)
                .environmentObject(settingsManager)
                .environmentObject(ringtoneManager)
        }
    }
}
