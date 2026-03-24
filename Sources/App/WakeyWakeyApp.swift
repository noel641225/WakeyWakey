import SwiftUI

@main
struct WakeyWakeyApp: App {
    @StateObject private var alarmManager = AlarmManager()
    @StateObject private var settingsManager = SettingsManager()

    init() {
        GhibliNavigationStyle.applyGlobalAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(alarmManager)
                .environmentObject(settingsManager)
                .tint(Color.ghibliForestGreen)
        }
    }
}
