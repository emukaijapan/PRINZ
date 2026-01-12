//
//  Reply.swift
//  PRINZ
//
//  Created on 2026-01-11.
//

import Foundation

struct Reply: Identifiable, Codable {
    let id: UUID
    let text: String
    let type: ReplyType
    let context: Context
    let timestamp: Date
    
    init(id: UUID = UUID(), text: String, type: ReplyType, context: Context, timestamp: Date = Date()) {
        self.id = id
        self.text = text
        self.type = type
        self.context = context
        self.timestamp = timestamp
    }
}

enum ReplyType: String, Codable, CaseIterable {
    case safe = "安牌"
    case chill = "ちょい攻め"
    case witty = "変化球"
    
    var displayName: String {
        return self.rawValue
    }
    
    var color: String {
        switch self {
        case .safe: return "neonCyan"
        case .chill: return "neonPurple"
        case .witty: return "neonPurple"
        }
    }
}
