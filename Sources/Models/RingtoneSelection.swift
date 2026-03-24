import Foundation

// MARK: - Ringtone Type
enum RingtoneType: String, Codable, Equatable {
    case preset
    case custom
}

// MARK: - Preset Ringtone
enum PresetRingtone: String, Codable, CaseIterable, Identifiable, Equatable {
    case classic  = "Classic"
    case digital  = "Digital"
    case gentle   = "Gentle"
    case bells    = "Bells"
    case marimba  = "Marimba"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .classic:  return "🔔 經典"
        case .digital:  return "📱 數位"
        case .gentle:   return "🌸 輕柔"
        case .bells:    return "🎵 鈴聲"
        case .marimba:  return "🎶 木琴"
        }
    }

    var frequency: Double {
        switch self {
        case .classic:  return 440.0
        case .digital:  return 880.0
        case .gentle:   return 330.0
        case .bells:    return 660.0
        case .marimba:  return 523.25
        }
    }

    var harmonics: [Double] {
        switch self {
        case .classic:  return [1.0, 0.5, 0.25]
        case .digital:  return [1.0, 0.0,  0.0]
        case .gentle:   return [1.0, 0.3,  0.1]
        case .bells:    return [1.0, 0.6,  0.3, 0.15]
        case .marimba:  return [1.0, 0.4,  0.2, 0.05]
        }
    }

    var onDuration: Double {
        switch self {
        case .classic:  return 0.5
        case .digital:  return 0.15
        case .gentle:   return 1.0
        case .bells:    return 0.35
        case .marimba:  return 0.25
        }
    }

    var offDuration: Double {
        switch self {
        case .classic:  return 0.3
        case .digital:  return 0.08
        case .gentle:   return 0.5
        case .bells:    return 0.15
        case .marimba:  return 0.2
        }
    }
}

// MARK: - Ringtone Selection
struct RingtoneSelection: Codable, Equatable {
    var type: RingtoneType
    var presetName: String
    var customFileName: String?
    var customDisplayName: String?

    static let `default` = RingtoneSelection(
        type: .preset,
        presetName: PresetRingtone.classic.rawValue
    )

    var displayName: String {
        if type == .custom, let name = customDisplayName {
            return "🎵 \(name)"
        }
        return PresetRingtone(rawValue: presetName)?.displayName ?? "🔔 經典"
    }

    var preset: PresetRingtone? {
        guard type == .preset else { return nil }
        return PresetRingtone(rawValue: presetName)
    }
}
