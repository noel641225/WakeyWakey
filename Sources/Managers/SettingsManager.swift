import Foundation
import Combine

// MARK: - Settings Manager
class SettingsManager: ObservableObject {
    @Published var settings: AppSettings {
        didSet {
            saveSettings()
        }
    }
    
    private let userDefaults = UserDefaults.standard
    private let settingsKey = "appSettings"
    
    init() {
        if let data = userDefaults.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = AppSettings()
        }
    }
    
    // MARK: - Save/Load
    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            userDefaults.set(encoded, forKey: settingsKey)
        }
    }
    
    // MARK: - Quick Access
    var defaultSnoozeTaps: Int {
        get { settings.defaultSnoozeTaps }
        set { settings.defaultSnoozeTaps = newValue }
    }
    
    var defaultDismissTaps: Int {
        get { settings.defaultDismissTaps }
        set { settings.defaultDismissTaps = newValue }
    }
    
    var defaultMoveSpeed: Double {
        get { settings.defaultMoveSpeed }
        set { settings.defaultMoveSpeed = newValue }
    }
    
    var snoozeDuration: Int {
        get { settings.snoozeDuration }
        set { settings.snoozeDuration = newValue }
    }
    
    var aiProvider: AIProviderType {
        get { settings.aiProvider }
        set { settings.aiProvider = newValue }
    }
    
    var userAPIKey: String? {
        get { settings.userAPIKey }
        set { settings.userAPIKey = newValue }
    }
    
    var freeQuotaRemaining: Int {
        get { settings.freeQuotaRemaining }
        set { settings.freeQuotaRemaining = newValue }
    }
    
    // MARK: - AI Quota
    func useAIQuota() -> Bool {
        if settings.freeQuotaRemaining > 0 {
            settings.freeQuotaRemaining -= 1
            return true
        }
        return false
    }
    
    func resetQuota() {
        settings.freeQuotaRemaining = 5
    }
}
