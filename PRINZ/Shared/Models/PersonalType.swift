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
        case .intellectual: return "博識で論理的。知的な語彙を使い、スマートな会話を展開する。"
        case .passionate: return "情熱的でエネルギーに溢れている。ストレートな表現を好み、相手を引っ張る。"
        case .gentle: return "とにかく優しく、包容力がある。相手を肯定し、安心感を与える言葉を選ぶ。"
        case .funny: return "ユーモアセンス抜群。ボケやツッコミを交え、相手を笑わせることを最優先する。"
        case .cool: return "感情を表に出しすぎず、余裕がある。短文で核心を突く、ミステリアスな色気を持つ。"
        case .sincere: return "嘘をつかない誠実さ。丁寧な言葉遣いで、真剣に向き合う姿勢を見せる。"
        case .active: return "フットワークが軽く、ノリが良い。絵文字も適度に使い、明るくテンポ良い会話をする。"
        case .shy: return "少し奥手で謙虚。丁寧すぎるくらい丁寧だが、そこが可愛げに見えるように。"
        case .mysterious: return "生活感を見せない。詩的な表現や、意味深な言葉で相手の興味を惹く。"
        case .natural: return "飾らない等身大。親しみやすく、友達のような距離感でリラックスして話す。"
        }
    }
}
