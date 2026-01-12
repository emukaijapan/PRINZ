//
//  PersonalType.swift
//  PRINZ
//
//  Created on 2026-01-12.
//

import Foundation

/// パーソナルタイプ（性格タイプ10種類）
enum PersonalType: String, Codable, CaseIterable {
    case intellectual = "知的系"
    case passionate = "熱血系"
    case gentle = "優しい系"
    case funny = "おもしろ系"
    case cool = "クール系"
    case sincere = "誠実系"
    case active = "アクティブ系"
    case shy = "シャイ系"
    case mysterious = "ミステリアス系"
    case natural = "ナチュラル系"
    
    var displayName: String {
        return self.rawValue
    }
    
    var emoji: String {
        switch self {
        case .intellectual: return "🤓"
        case .passionate: return "🔥"
        case .gentle: return "🕊️"
        case .funny: return "🤣"
        case .cool: return "😎"
        case .sincere: return "💯"
        case .active: return "⚡"
        case .shy: return "😊"
        case .mysterious: return "🌙"
        case .natural: return "🌿"
        }
    }
    
    var description: String {
        switch self {
        case .intellectual: return "博識で知的な会話が得意"
        case .passionate: return "情熱的で真剣な姿勢"
        case .gentle: return "優しく相手を包み込む"
        case .funny: return "ユーモアで相手を笑わせる"
        case .cool: return "クールで余裕のある対応"
        case .sincere: return "誠実で真っ直ぐな態度"
        case .active: return "アクティブでノリが良い"
        case .shy: return "控えめで奥ゆかしい"
        case .mysterious: return "ミステリアスで惹きつける"
        case .natural: return "自然体でありのまま"
        }
    }
}
