import Foundation
import Combine
import UserNotifications
import UIKit
import AudioToolbox
import AVFoundation

// MARK: - Alarm Manager
class AlarmManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var alarms: [Alarm] = []
    @Published var isAlarmTriggering = false
    @Published var currentTriggeringAlarm: Alarm?

    private let userDefaults = UserDefaults.standard
    private let alarmsKey = "savedAlarms"

    // Audio player for in-app alarm sound
    private var alarmAudioPlayer: AVAudioPlayer?
    private var alarmAudioEngine: AVAudioEngine?
    private var alarmToneNode: AVAudioPlayerNode?
    
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
        // Use custom sound file if available, otherwise default
        if alarm.selectedRingtone.type == .custom,
           let fileName = alarm.selectedRingtone.customFileName {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: fileName))
        } else {
            content.sound = .default
        }
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

        // Vibrate
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))

        // Play ringtone
        startRingtonePlayback(for: alarm.selectedRingtone)
    }

    func dismissAlarm() {
        stopRingtonePlayback()
        isAlarmTriggering = false
        currentTriggeringAlarm = nil

        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }

    func snoozeAlarm() {
        stopRingtonePlayback()
        guard var alarm = currentTriggeringAlarm else { return }

        alarm.time = Date().addingTimeInterval(60 * 5)
        updateAlarm(alarm)

        isAlarmTriggering = false
        currentTriggeringAlarm = nil
    }

    // MARK: - Ringtone Playback
    private func startRingtonePlayback(for selection: RingtoneSelection) {
        stopRingtonePlayback()
        setupAlarmAudioSession()

        if selection.type == .custom, let fileName = selection.customFileName {
            let fileURL = RingtoneManager.soundsDirectory.appendingPathComponent(fileName)
            do {
                let player = try AVAudioPlayer(contentsOf: fileURL)
                player.numberOfLoops = -1
                player.play()
                alarmAudioPlayer = player
            } catch {
                playPresetTone(selection.preset ?? .classic)
            }
        } else {
            playPresetTone(selection.preset ?? .classic)
        }
    }

    private func playPresetTone(_ preset: PresetRingtone) {
        let sampleRate: Double = 44100
        let onFrames  = AVAudioFrameCount(sampleRate * preset.onDuration)
        let offFrames = AVAudioFrameCount(sampleRate * preset.offDuration)
        let total     = onFrames + offFrames

        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: total),
              let channelData = buffer.floatChannelData?[0] else { return }

        buffer.frameLength = total
        let freq      = preset.frequency
        let harmonics = preset.harmonics

        for i in 0..<Int(onFrames) {
            let t       = Double(i) / sampleRate
            let attack  = min(1.0, Double(i)           / (sampleRate * 0.015))
            let release = min(1.0, Double(Int(onFrames) - i) / (sampleRate * 0.015))
            let env     = min(attack, release) * 0.5
            var sample  = 0.0
            for (hi, amplitude) in harmonics.enumerated() {
                sample += amplitude * sin(2.0 * Double.pi * freq * Double(hi + 1) * t)
            }
            channelData[i] = Float(sample * env / Double(harmonics.count))
        }
        for i in 0..<Int(offFrames) { channelData[Int(onFrames) + i] = 0 }

        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)

        do {
            try engine.start()
            player.scheduleBuffer(buffer, at: nil, options: [.loops], completionHandler: nil)
            player.play()
            alarmAudioEngine = engine
            alarmToneNode    = player
        } catch {
            print("Alarm tone error: \(error)")
        }
    }

    private func stopRingtonePlayback() {
        alarmAudioPlayer?.stop()
        alarmToneNode?.stop()
        alarmAudioEngine?.stop()
        alarmAudioPlayer = nil
        alarmToneNode    = nil
        alarmAudioEngine = nil
    }

    private func setupAlarmAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(
            .playback, mode: .default, options: [])
        try? AVAudioSession.sharedInstance().setActive(true)
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
