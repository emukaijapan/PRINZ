//
//  Context.swift
//  PRINZ
//
//  Created on 2026-01-11.
//

import Foundation

enum Context: String, Codable, CaseIterable {
    case matchStart = "マッチ直後"
    case dateProposal = "デート打診"
    case fight = "喧嘩"
    case checkInterest = "脈あり確認"
    
    var displayName: String {
        return self.rawValue
    }
    
    var emoji: String {
        switch self {
        case .matchStart: return "✨"
        case .dateProposal: return "📅"
        case .fight: return "💢"
        case .checkInterest: return "💭"
        }
    }
}
