//
//  ToneTag.swift
//  PRINZ
//
//  Created on 2026-01-12.
//

import Foundation

/// トーンタグ - 返信のトーンを指定（日本向け）
enum ToneTag: String, CaseIterable, Codable {
    case safe = "安牌"
    case chill = "ちょい攻め"
    case witty = "変化球"
    
    var displayName: String {
        return self.rawValue
    }
    
    var emoji: String {
        switch self {
        case .safe: return "🛡️"
        case .chill: return "🔥"
        case .witty: return "⚡"
        }
    }
    
    var description: String {
        switch self {
        case .safe: return "無難で安全な返信"
        case .chill: return "ちょっと攻めた返信"
        case .witty: return "意外性のある返信"
        }
    }
}
