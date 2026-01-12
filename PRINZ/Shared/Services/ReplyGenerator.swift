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
    
    /// モックAI: コンテキストに応じた返信案を生成
    /// - Parameters:
    ///   - extractedText: OCRで抽出されたテキスト
    ///   - context: 会話のコンテキスト
    /// - Returns: 3つの返信案（安牌、ちょい攻め、変化球）
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
            
        case .fight:
            switch type {
            case .safe: return "ごめん、言い過ぎた"
            case .chill: return "ちょっと冷静になろう"
            case .witty: return "そっちこそどうなの？"
            }
        }
    }
}
