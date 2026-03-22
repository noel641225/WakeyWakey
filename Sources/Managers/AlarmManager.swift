import Foundation
import UserNotifications
import UIKit
import AudioToolbox

// MARK: - Alarm Manager
class AlarmManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var alarms: [Alarm] = []
    @Published var isAlarmTriggering = false
    @Published var currentTriggeringAlarm: Alarm?

    private let userDefaults = UserDefaults.standard
    private let alarmsKey = "savedAlarms"

    override init() {
        super.init()
        loadAlarms()
        requestNotificationPermission()
        UNUserNotificationCenter.current().delegate = self
        registerNotificationCategories()
    }

    // MARK: - Permission
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge, .criticalAlert]
        ) { _, error in
            if let error { print("Notification permission error: \(error)") }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
        if let alarm = alarm(for: notification.request.identifier) {
            DispatchQueue.main.async { self.triggerAlarm(alarm) }
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if let alarm = alarm(for: response.notification.request.identifier) {
            DispatchQueue.main.async { self.triggerAlarm(alarm) }
        }
        completionHandler()
    }

    /// Extracts the matching Alarm from a notification identifier.
    /// Handles formats: "uuid", "uuid_weekday", "uuid_snooze"
    private func alarm(for notificationId: String) -> Alarm? {
        let uuidString = notificationId.components(separatedBy: "_").first ?? notificationId
        guard let id = UUID(uuidString: uuidString) else { return nil }
        return alarms.first(where: { $0.id == id })
    }

    // MARK: - CRUD

    func addAlarm(_ alarm: Alarm) {
        alarms.append(alarm)
        saveAlarms()
        if alarm.isEnabled { scheduleNotifications(for: alarm) }
    }

    func updateAlarm(_ alarm: Alarm) {
        guard let index = alarms.firstIndex(where: { $0.id == alarm.id }) else { return }
        cancelAllNotifications(for: alarms[index])
        alarms[index] = alarm
        saveAlarms()
        if alarm.isEnabled { scheduleNotifications(for: alarm) }
    }

    func deleteAlarm(_ alarm: Alarm) {
        cancelAllNotifications(for: alarm)
        alarms.removeAll { $0.id == alarm.id }
        saveAlarms()
    }

    func toggleAlarm(_ alarm: Alarm) {
        guard let index = alarms.firstIndex(where: { $0.id == alarm.id }) else { return }
        alarms[index].isEnabled.toggle()
        saveAlarms()
        if alarms[index].isEnabled {
            scheduleNotifications(for: alarms[index])
        } else {
            cancelAllNotifications(for: alarm)
        }
    }

    // MARK: - Storage

    private func saveAlarms() {
        if let encoded = try? JSONEncoder().encode(alarms) {
            userDefaults.set(encoded, forKey: alarmsKey)
        }
    }

    private func loadAlarms() {
        guard let data = userDefaults.data(forKey: alarmsKey),
              let decoded = try? JSONDecoder().decode([Alarm].self, from: data) else { return }
        alarms = decoded
    }

    // MARK: - Notification Scheduling

    private func scheduleNotifications(for alarm: Alarm) {
        let content = UNMutableNotificationContent()
        content.title = "Wakey Wakey! ⏰"
        content.body = alarm.label.isEmpty ? "起床時間到囉！" : alarm.label
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "ALARM_CATEGORY"

        let calendar = Calendar.current
        var baseComponents = calendar.dateComponents([.hour, .minute], from: alarm.time)
        baseComponents.second = 0

        if alarm.repeatDays.isEmpty {
            // One-time alarm at next occurrence of this hour:minute
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: baseComponents,
                repeats: false
            )
            let request = UNNotificationRequest(
                identifier: alarm.id.uuidString,
                content: content,
                trigger: trigger
            )
            UNUserNotificationCenter.current().add(request) { error in
                if let error { print("Schedule error: \(error)") }
            }
        } else {
            // Weekly repeating notification for each selected weekday
            for weekday in alarm.repeatDays {
                var components = baseComponents
                components.weekday = weekday.rawValue
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let id = "\(alarm.id.uuidString)_\(weekday.rawValue)"
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request) { error in
                    if let error { print("Schedule error weekday \(weekday.rawValue): \(error)") }
                }
            }
        }
    }

    /// Cancels all pending notifications for an alarm (one-time, all weekdays, and snooze).
    private func cancelAllNotifications(for alarm: Alarm) {
        var ids = [alarm.id.uuidString, "\(alarm.id.uuidString)_snooze"]
        ids += (1...7).map { "\(alarm.id.uuidString)_\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    private func registerNotificationCategories() {
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "延長 5 分鐘",
            options: []
        )
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_ACTION",
            title: "關閉",
            options: [.destructive]
        )
        let category = UNNotificationCategory(
            identifier: "ALARM_CATEGORY",
            actions: [snoozeAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    // MARK: - Trigger / Dismiss / Snooze

    func triggerAlarm(_ alarm: Alarm) {
        currentTriggeringAlarm = alarm
        isAlarmTriggering = true
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
    }

    func dismissAlarm() {
        isAlarmTriggering = false
        currentTriggeringAlarm = nil
        UNUserNotificationCenter.current().setBadgeCount(0, withCompletionHandler: nil)
    }

    /// Schedules a one-time snooze notification without corrupting the stored alarm time.
    func snoozeAlarm(alarm: Alarm, duration: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Wakey Wakey! ⏰"
        content.body = alarm.label.isEmpty ? "起床時間到囉！" : alarm.label
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "ALARM_CATEGORY"

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(duration * 60),
            repeats: false
        )
        let snoozeId = "\(alarm.id.uuidString)_snooze"
        let request = UNNotificationRequest(identifier: snoozeId, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("Snooze schedule error: \(error)") }
        }
        dismissAlarm()
    }

    // MARK: - Debug

    func printScheduledNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("=== Pending Notifications ===")
            for r in requests {
                print("ID: \(r.identifier), Trigger: \(r.trigger?.description ?? "N/A")")
            }
            print("=============================")
        }
    }
}
