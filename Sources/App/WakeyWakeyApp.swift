import SwiftUI

@main
struct WakeyWakeyApp: App {
    @StateObject private var alarmManager = AlarmManager()
    @StateObject private var settingsManager = SettingsManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(alarmManager)
                .environmentObject(settingsManager)
        }
    }
}
