//
//  Context.swift
//  PRINZ
//
//  Created on 2026-01-11.
//

import Foundation

/// 会話の状況タグ（日本向け）
enum Context: String, Codable, CaseIterable {
    case matchStart = "マッチ直後"
    case dateProposal = "デート打診"
    case checkInterest = "脈あり確認"
    case dailyChat = "日常会話"
    case afterDate = "デート後"
    case followUp = "フォロー"
    
    var displayName: String {
        return self.rawValue
    }
    
    var emoji: String {
        switch self {
        case .matchStart: return "✨"
        case .dateProposal: return "📅"
        case .checkInterest: return "💭"
        case .dailyChat: return "💬"
        case .afterDate: return "🌙"
        case .followUp: return "📲"
        }
    }
}

