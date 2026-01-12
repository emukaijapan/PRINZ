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
    
    /// モックAI: コンテキストに応じた3つの返信案を生成
    /// - Parameters:
    ///   - extractedText: OCRで抽出されたテキスト
    ///   - context: 会話のコンテキスト
    /// - Returns: 3つの返信案（安牌、ちょい攻め、変化球）
    func generateReplies(for extractedText: String, context: Context) -> [Reply] {
        // 実際のLLM APIを使用する場合はここで通信
        // PoCではモックデータを返す
        
        let mockReplies: [Reply]
        
        switch context {
        case .matchStart:
            mockReplies = [
                Reply(text: "楽しかった！また行こう！", type: .safe, context: context),
                Reply(text: "おつー、今度は飲みね🍻", type: .chill, context: context),
                Reply(text: "逆にいつ空いてるの？笑", type: .witty, context: context)
            ]
            
        case .dateProposal:
            mockReplies = [
                Reply(text: "いいね！どこ行く？", type: .safe, context: context),
                Reply(text: "待ってた！週末空いてるよ😊", type: .chill, context: context),
                Reply(text: "やっと誘ってくれたね笑", type: .witty, context: context)
            ]
            
        case .fight:
            mockReplies = [
                Reply(text: "ごめん、言い過ぎた", type: .safe, context: context),
                Reply(text: "ちょっと冷静になろう", type: .chill, context: context),
                Reply(text: "そっちこそどうなの？", type: .witty, context: context)
            ]
            
        case .checkInterest:
            mockReplies = [
                Reply(text: "また連絡するね！", type: .safe, context: context),
                Reply(text: "もっと話したいな", type: .chill, context: context),
                Reply(text: "次いつ会える？", type: .witty, context: context)
            ]
        }
        
        return mockReplies
    }
}
