import Foundation

// MARK: - Alarm Model
struct Alarm: Identifiable, Codable, Equatable {
    var id: UUID
    var time: Date
    var isEnabled: Bool
    var repeatDays: [Weekday]
    var label: String
    var imageType: AlarmImageType
    var customImageData: Data?
    var snoozeCount: Int       // 延長次數
    var dismissCount: Int      // 取消所需次數
    var moveSpeed: Double      // 移動速度 0.1~1.0
    
    init(
        id: UUID = UUID(),
        time: Date = Date(),
        isEnabled: Bool = true,
        repeatDays: [Weekday] = [],
        label: String = "起床啦！",
        imageType: AlarmImageType = .defaultBunny,
        customImageData: Data? = nil,
        snoozeCount: Int = 1,
        dismissCount: Int = 3,
        moveSpeed: Double = 0.5
    ) {
        self.id = id
        self.time = time
        self.isEnabled = isEnabled
        self.repeatDays = repeatDays
        self.label = label
        self.imageType = imageType
        self.customImageData = customImageData
        self.snoozeCount = snoozeCount
        self.dismissCount = dismissCount
        self.moveSpeed = moveSpeed
    }
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }
    
    var repeatString: String {
        if repeatDays.isEmpty {
            return "只響一次"
        } else if repeatDays.count == 7 {
            return "每天"
        } else {
            return repeatDays.map { $0.shortName }.joined(separator: " ")
        }
    }
}

// MARK: - Weekday
enum Weekday: Int, Codable, CaseIterable, Identifiable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    
    var id: Int { rawValue }
    
    var name: String {
        switch self {
        case .sunday: return "週日"
        case .monday: return "週一"
        case .tuesday: return "週二"
        case .wednesday: return "週三"
        case .thursday: return "週四"
        case .friday: return "週五"
        case .saturday: return "週六"
        }
    }
    
    var shortName: String {
        switch self {
        case .sunday: return "日"
        case .monday: return "一"
        case .tuesday: return "二"
        case .wednesday: return "三"
        case .thursday: return "四"
        case .friday: return "五"
        case .saturday: return "六"
        }
    }
}

// MARK: - Alarm Image Type
enum AlarmImageType: String, Codable, CaseIterable, Identifiable {
    case defaultBunny = "defaultBunny"
    case defaultLobster = "defaultLobster"
    case customPhoto = "customPhoto"
    case aiGenerated = "aiGenerated"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .defaultBunny: return "🐰 預設兔子"
        case .defaultLobster: return "🦞 預設龍蝦"
        case .customPhoto: return "📷 自己照片"
        case .aiGenerated: return "✨ AI 生成"
        }
    }
}
