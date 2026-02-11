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
        case .intellectual: return "博識で論理的\nスマートな会話を展開"
        case .passionate: return "情熱的でストレート\n相手を引っ張るタイプ"
        case .gentle: return "優しく包容力がある\n安心感を与える言葉選び"
        case .funny: return "ユーモアセンス抜群\n相手を笑わせることが得意"
        case .cool: return "余裕があり落ち着いた印象\n短文で核心を突く"
        case .sincere: return "嘘をつかない誠実さ\n真剣に向き合う姿勢"
        case .active: return "フットワーク軽くノリ良し\n明るくテンポ良い会話"
        case .shy: return "少し奥手で謙虚\n丁寧さが可愛げに見える"
        case .mysterious: return "意味深で興味を惹く\n詩的な表現が特徴"
        case .natural: return "飾らない等身大\n友達のような距離感"
        }
    }
}
