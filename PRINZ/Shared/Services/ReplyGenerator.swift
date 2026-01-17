//
//  ReplyGenerator.swift
//  PRINZ
//
//  Created on 2026-01-11.
//

import Foundation

class ReplyGenerator {
    static let shared = ReplyGenerator()
    
    private init() {}
    
    // MARK: - OpenAI API連携
    
    /// OpenAI APIを使用して返信を生成
    func generateRepliesWithAI(
        message: String,
        context: Context,
        personalType: PersonalType,
        gender: UserGender,
        ageGroup: UserAgeGroup
    ) async throws -> [Reply] {
        
        let relationship = context.displayName
        
        let aiReplies = try await OpenAIService.shared.generateReplies(
            message: message,
            personalType: personalType,
            gender: gender,
            ageGroup: ageGroup,
            relationship: relationship
        )
        
        // AIGeneratedReplyをReplyに変換
        return aiReplies.compactMap { aiReply in
            guard let replyType = ReplyType.from(apiType: aiReply.type) else {
                return nil
            }
            return Reply(
                text: aiReply.text,
                type: replyType,
                context: context,
                reasoning: aiReply.reasoning
            )
        }
    }
    
    // MARK: - モック生成（フォールバック用）
    
    /// モックAI: コンテキストに応じた返信案を生成
    func generateReplies(for extractedText: String, context: Context) -> [Reply] {
        return [
            generateReply(for: extractedText, context: context, type: .safe),
            generateReply(for: extractedText, context: context, type: .chill),
            generateReply(for: extractedText, context: context, type: .witty)
        ]
    }
    
    /// タイプ別に返信を生成
    func generateReplies(for extractedText: String, context: Context, type: ReplyType) -> [Reply] {
        return [generateReply(for: extractedText, context: context, type: type)]
    }
    
    /// 単一の返信を生成
    private func generateReply(for extractedText: String, context: Context, type: ReplyType) -> Reply {
        let text = getMockReply(context: context, type: type)
        return Reply(text: text, type: type, context: context)
    }
    
    /// モック返信テキストを取得
    private func getMockReply(context: Context, type: ReplyType) -> String {
        switch context {
        case .matchStart:
            switch type {
            case .safe: return "よろしくね！趣味とか教えて😊"
            case .chill: return "いいねありがとう！何系の人？笑"
            case .witty: return "運命感じちゃったかも🔮"
            }
            
        case .dateProposal:
            switch type {
            case .safe: return "いいね！どこ行く？"
            case .chill: return "待ってた！週末空いてるよ😊"
            case .witty: return "やっと誘ってくれたね笑"
            }
            
        case .checkInterest:
            switch type {
            case .safe: return "また連絡するね！"
            case .chill: return "もっと話したいな"
            case .witty: return "次いつ会える？"
            }
            
        case .dailyChat:
            switch type {
            case .safe: return "そうなんだ！いいね👍"
            case .chill: return "わかるー！最近どう？"
            case .witty: return "え、それ気になる笑"
            }
            
        case .afterDate:
            switch type {
            case .safe: return "楽しかった！また行こう！"
            case .chill: return "おつー、今度は飲みね🍻"
            case .witty: return "逆にいつ空いてるの？笑"
            }
            
        case .followUp:
            switch type {
            case .safe: return "最近どう？元気してる？"
            case .chill: return "久しぶり！会いたいね"
            case .witty: return "生きてる？笑"
            }
        }
    }
}

// MARK: - ReplyType Extension

extension ReplyType {
    /// APIのタイプ文字列からReplyTypeを取得
    static func from(apiType: String) -> ReplyType? {
        switch apiType.lowercased() {
        case "safe": return .safe
        case "aggressive": return .chill
        case "unique": return .witty
        default: return nil
        }
    }
}
