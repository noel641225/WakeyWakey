import Foundation
import UserNotifications
import UIKit
import AudioToolbox
import AVFoundation


// MARK: - Alarm Manager
class AlarmManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var alarms: [Alarm] = []
    @Published var isAlarmTriggering = false
    @Published var currentTriggeringAlarm: Alarm?
    @Published var pendingExpiredAlarms: [Alarm] = []

    private let userDefaults = UserDefaults.standard
    private let alarmsKey = "savedAlarms"

    // Audio player for in-app alarm sound
    private var alarmAudioPlayer: AVAudioPlayer?
    private var alarmAudioEngine: AVAudioEngine?
    private var alarmToneNode: AVAudioPlayerNode?

    // In-app alarm check timer (fires every second when app is open)
    private var checkTimer: Timer?
    // Tracks alarms already fired in a given hour:minute to prevent double-trigger
    private var firedAlarmKeys: Set<String> = []

    override init() {
        super.init()
        loadAlarms()
        requestNotificationPermission()
        UNUserNotificationCenter.current().delegate = self
        registerNotificationCategories()
        checkForExpiredAlarms()
        startAlarmCheckTimer()
    }

    // MARK: - Permission
    private func requestNotificationPermission() {
        // NOTE: Do NOT request .criticalAlert here — it requires a special Apple entitlement
        // and causes the ENTIRE permission request to fail if the app doesn't have it.
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            if let error { print("Notification permission error: \(error)") }
            if !granted { print("Notification permission denied by user") }
        }
    }

    // MARK: - In-App Alarm Timer

    private func startAlarmCheckTimer() {
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkAlarms()
        }
        RunLoop.main.add(timer, forMode: .common)
        checkTimer = timer
    }

    private func checkAlarms() {
        guard !isAlarmTriggering else { return }
        let now = Date()
        let calendar = Calendar.current
        let nowComponents = calendar.dateComponents([.hour, .minute, .weekday], from: now)
        guard let hour = nowComponents.hour, let minute = nowComponents.minute else { return }

        for alarm in alarms where alarm.isEnabled {
            let alarmComponents = calendar.dateComponents([.hour, .minute], from: alarm.time)
            guard alarmComponents.hour == hour, alarmComponents.minute == minute else { continue }

            // Deduplicate: don't fire the same alarm twice in the same minute
            let key = "\(alarm.id)_\(hour)_\(minute)"
            guard !firedAlarmKeys.contains(key) else { continue }

            // For repeating alarms, verify today is a selected day
            if !alarm.repeatDays.isEmpty {
                guard let weekday = nowComponents.weekday,
                      alarm.repeatDays.contains(where: { $0.rawValue == weekday }) else { continue }
            }

            firedAlarmKeys.insert(key)
            triggerAlarm(alarm)
            break // show one alarm at a time
        }
    }

    // MARK: - Expired Alarm Detection
    // Detects one-time alarms whose notification already fired while the app was closed.

    private func checkForExpiredAlarms() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { [weak self] requests in
            guard let self else { return }
            let pendingIds = Set(requests.map { $0.identifier })
            DispatchQueue.main.async {
                // One-time alarms that are still enabled but have no pending notification
                // likely fired while the app was closed (notification was consumed).
                let expired = self.alarms.filter { alarm in
                    alarm.isEnabled &&
                    alarm.repeatDays.isEmpty &&
                    !pendingIds.contains(alarm.id.uuidString)
                }
                self.pendingExpiredAlarms = expired
            }
        }
    }

    func handleExpiredAlarm(_ alarm: Alarm, shouldTrigger: Bool) {
        pendingExpiredAlarms.removeAll { $0.id == alarm.id }
        if shouldTrigger {
            triggerAlarm(alarm)
        } else {
            if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
                alarms[index].isEnabled = false
                saveAlarms()
            }
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
        guard let alarm = alarm(for: response.notification.request.identifier) else {
            completionHandler()
            return
        }
        DispatchQueue.main.async {
            switch response.actionIdentifier {
            case "SNOOZE_ACTION":
                self.snoozeAlarm(alarm: alarm, duration: 5)
            case "DISMISS_ACTION":
                // Disable one-time alarm when dismissed from notification
                if alarm.repeatDays.isEmpty,
                   let index = self.alarms.firstIndex(where: { $0.id == alarm.id }) {
                    self.alarms[index].isEnabled = false
                    self.saveAlarms()
                }
            default:
                // User tapped the notification body — show AlarmFiringView
                self.triggerAlarm(alarm)
            }
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
        if alarm.selectedRingtone.type == .custom,
           let fileName = alarm.selectedRingtone.customFileName {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: fileName))
        } else {
            content.sound = .default
        }
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
        guard !isAlarmTriggering else { return }
        currentTriggeringAlarm = alarm
        isAlarmTriggering = true

        // Disable one-time alarms after firing so they don't re-trigger tomorrow
        if alarm.repeatDays.isEmpty,
           let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index].isEnabled = false
            saveAlarms()
        }

        // Remove from expired list if it's there
        pendingExpiredAlarms.removeAll { $0.id == alarm.id }

        // Vibrate
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))

        // Play ringtone
        startRingtonePlayback(for: alarm.selectedRingtone)
    }

    func dismissAlarm() {
        stopRingtonePlayback()
        isAlarmTriggering = false
        currentTriggeringAlarm = nil
        UNUserNotificationCenter.current().setBadgeCount(0, withCompletionHandler: nil)
    }

    /// Schedules a one-time snooze notification without corrupting the stored alarm time.
    func snoozeAlarm(alarm: Alarm, duration: Int) {
        stopRingtonePlayback()
        isAlarmTriggering = false
        currentTriggeringAlarm = nil

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
            for r in requests {
                print("ID: \(r.identifier), Trigger: \(r.trigger?.description ?? "N/A")")
            }
            print("=============================")
        }
    }
}
