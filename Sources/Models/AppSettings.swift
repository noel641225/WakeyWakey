import Foundation

// MARK: - App Settings
struct AppSettings: Codable, Equatable {
    var defaultSnoozeTaps: Int      // 預設延長點擊次數
    var defaultDismissTaps: Int     // 預設取消點擊次數
    var defaultMoveSpeed: Double    // 預設移動速度
    var snoozeDuration: Int         // 延長分鐘數
    var soundVolume: Double         // 音量
    var vibrationEnabled: Bool     // 震動
    var aiProvider: AIProviderType // AI 供應商
    var userAPIKey: String?         // 使用者的 API Key
    var freeQuotaRemaining: Int     // 剩餘免費次數
    
    init(
        defaultSnoozeTaps: Int = 1,
        defaultDismissTaps: Int = 3,
        defaultMoveSpeed: Double = 0.5,
        snoozeDuration: Int = 5,
        soundVolume: Double = 0.8,
        vibrationEnabled: Bool = true,
        aiProvider: AIProviderType = .miniMax,
        userAPIKey: String? = nil,
        freeQuotaRemaining: Int = 5
    ) {
        self.defaultSnoozeTaps = defaultSnoozeTaps
        self.defaultDismissTaps = defaultDismissTaps
        self.defaultMoveSpeed = defaultMoveSpeed
        self.snoozeDuration = snoozeDuration
        self.soundVolume = soundVolume
        self.vibrationEnabled = vibrationEnabled
        self.aiProvider = aiProvider
        self.userAPIKey = userAPIKey
        self.freeQuotaRemaining = freeQuotaRemaining
    }
}

// MARK: - AI Provider Type
enum AIProviderType: String, Codable, CaseIterable, Identifiable {
    case miniMax = "minimax"
    case openAI = "openai"
    case stability = "stability"
    case userCustom = "userCustom"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .miniMax: return "MiniMax (預設)"
        case .openAI: return "OpenAI DALL-E"
        case .stability: return "Stability AI"
        case .userCustom: return "自訂 API"
        }
    }
}
