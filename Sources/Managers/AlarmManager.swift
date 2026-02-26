import Foundation
import Combine
import UserNotifications
import UIKit

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
        setupNotificationDelegate()
    }
    
    // MARK: - Permission
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge, .criticalAlert]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
            if granted {
                print("Notification permission granted")
            }
        }
    }
    
    // MARK: - Setup Delegate
    private func setupNotificationDelegate() {
        UNUserNotificationCenter.current().delegate = self
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                                willPresent notification: UNNotification, 
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // App 在前台時也要顯示通知
        completionHandler([.banner, .sound, .badge])
        
        // 觸發鬧鐘
        let alarmId = notification.request.identifier
        if let alarm = alarms.first(where: { $0.id.uuidString == alarmId }) {
            DispatchQueue.main.async {
                self.triggerAlarm(alarm)
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                                didReceive response: UNNotificationResponse, 
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let alarmId = response.notification.request.identifier
        if let alarm = alarms.first(where: { $0.id.uuidString == alarmId }) {
            DispatchQueue.main.async {
                self.triggerAlarm(alarm)
            }
        }
        completionHandler()
    }
    
    // MARK: - CRUD Operations
    func addAlarm(_ alarm: Alarm) {
        alarms.append(alarm)
        saveAlarms()
        scheduleNotification(for: alarm)
    }
    
    func updateAlarm(_ alarm: Alarm) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index] = alarm
            saveAlarms()
            
            // 重新安排通知
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [alarm.id.uuidString])
            if alarm.isEnabled {
                scheduleNotification(for: alarm)
            }
        }
    }
    
    func deleteAlarm(_ alarm: Alarm) {
        alarms.removeAll { $0.id == alarm.id }
        saveAlarms()
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [alarm.id.uuidString])
    }
    
    func toggleAlarm(_ alarm: Alarm) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index].isEnabled.toggle()
            saveAlarms()
            
            if alarms[index].isEnabled {
                scheduleNotification(for: alarms[index])
            } else {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [alarm.id.uuidString])
            }
        }
    }
    
    // MARK: - Storage
    private func saveAlarms() {
        if let encoded = try? JSONEncoder().encode(alarms) {
            userDefaults.set(encoded, forKey: alarmsKey)
        }
    }
    
    private func loadAlarms() {
        if let data = userDefaults.data(forKey: alarmsKey),
           let decoded = try? JSONDecoder().decode([Alarm].self, from: data) {
            alarms = decoded
        }
    }
    
    // MARK: - Notification
    private func scheduleNotification(for alarm: Alarm) {
        let content = UNMutableNotificationContent()
        content.title = "Wakey Wakey! ⏰"
        content.body = alarm.label.isEmpty ? "起床時間到囉！" : alarm.label
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "ALARM_CATEGORY"
        
        let calendar = Calendar.current
        var components = calendar.dateComponents([.hour, .minute], from: alarm.time)
        components.second = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: alarm.id.uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Schedule error: \(error.localizedDescription)")
            } else {
                print("Alarm scheduled for \(components.hour ?? 0):\(components.minute ?? 0)")
            }
        }
        
        // 註冊通知類別
        registerNotificationCategories()
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
        
        let alarmCategory = UNNotificationCategory(
            identifier: "ALARM_CATEGORY",
            actions: [snoozeAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([alarmCategory])
    }
    
    // MARK: - Trigger Alarm
    func triggerAlarm(_ alarm: Alarm) {
        currentTriggeringAlarm = alarm
        isAlarmTriggering = true
        
        // 震動
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        
        // 播放聲音（如果需要）
        // 可以添加自定義聲音
    }
    
    func dismissAlarm() {
        isAlarmTriggering = false
        currentTriggeringAlarm = nil
        
        // 清除 badge
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
    
    func snoozeAlarm() {
        guard var alarm = currentTriggeringAlarm else { return }
        
        // 延長 5 分鐘
        alarm.time = Date().addingTimeInterval(60 * 5)
        updateAlarm(alarm)
        
        isAlarmTriggering = false
        currentTriggeringAlarm = nil
    }
    
    // MARK: - Debug
    func printScheduledNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("=== Pending Notifications ===")
            for request in requests {
                print("ID: \(request.identifier), Trigger: \(request.trigger?.description ?? "N/A")")
            }
            print("=============================")
        }
    }
}
