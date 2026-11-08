//
//  StressLevel.swift
//  Shared/Models
//

import Foundation

public enum StressLevel: Int, Codable, CaseIterable, Comparable {
    case happy = 0
    case calm = 1
    case tense = 2
    case stressed = 3
    case explode = 4

    public static func < (lhs: StressLevel, rhs: StressLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public var defaultEmoji: String {
        switch self {
        case .happy:    return "😄"
        case .calm:     return "🙂"
        case .tense:    return "😐"
        case .stressed: return "😰"
        case .explode:  return "🤯"
        }
    }

    public var label: String {
        switch self {
        case .happy:    return "开心"
        case .calm:     return "平静"
        case .tense:    return "紧张"
        case .stressed: return "压力"
        case .explode:  return "爆炸"
        }
    }

    public var colorHex: String {
        switch self {
        case .happy:    return "#4CD964"
        case .calm:     return "#5AC8FA"
        case .tense:    return "#FFCC00"
        case .stressed: return "#FF9500"
        case .explode:  return "#FF3B30"
        }
    }

    public static func from(score: Double) -> StressLevel {
        switch score {
        case ..<20:    return .happy
        case 20..<40:  return .calm
        case 40..<60:  return .tense
        case 60..<80:  return .stressed
        default:       return .explode
        }
    }
}

public struct StressSnapshot: Identifiable, Codable, Equatable {
    public var id: UUID = UUID()
    public var timestamp: Date
    public var score: Double
    public var hrvSDNN: Double
    public var baseline: Double
    public var level: StressLevel { StressLevel.from(score: score) }

    public init(timestamp: Date, score: Double, hrvSDNN: Double, baseline: Double) {
        self.timestamp = timestamp
        self.score = score
        self.hrvSDNN = hrvSDNN
        self.baseline = baseline
    }
}
