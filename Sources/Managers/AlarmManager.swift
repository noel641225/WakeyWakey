import Foundation
import Combine
import UserNotifications

// MARK: - Alarm Manager
class AlarmManager: ObservableObject {
    @Published var alarms: [Alarm] = []
    @Published var isAlarmTriggering = false
    @Published var currentTriggeringAlarm: Alarm?
    
    private let userDefaults = UserDefaults.standard
    private let alarmsKey = "savedAlarms"
    
    init() {
        loadAlarms()
        requestNotificationPermission()
    }
    
    // MARK: - Permission
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
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
        content.body = alarm.label
        content.sound = .default
        content.badge = 1
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: alarm.time)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: alarm.id.uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Schedule error: \(error)")
            }
        }
    }
    
    // MARK: - Trigger Alarm
    func triggerAlarm(_ alarm: Alarm) {
        currentTriggeringAlarm = alarm
        isAlarmTriggering = true
    }
    
    func dismissAlarm() {
        isAlarmTriggering = false
        currentTriggeringAlarm = nil
    }
    
    func snoozeAlarm() {
        // 延長鬧鐘 5 分鐘
        guard var alarm = currentTriggeringAlarm else { return }
        
        alarm.time = Date().addingTimeInterval(60 * 5)
        updateAlarm(alarm)
        
        isAlarmTriggering = false
        currentTriggeringAlarm = nil
    }
}
