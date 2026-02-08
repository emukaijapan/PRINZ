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
    
    #if DEBUG
    // MARK: - OpenAI API連携（開発用）

    /// OpenAI APIを使用して返信を生成
    /// ⚠️ 開発用：本番では FirebaseService 経由を使用
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
    #endif

    // MARK: - モック生成（フォールバック用）
    
    /// モックAI: コンテキストに応じた返信案を生成
    func generateReplies(for extractedText: String, context: Context) -> [Reply] {
        return [
            generateReply(for: extractedText, context: context, type: .safe),
            generateReply(for: extractedText, context: context, type: .chill),
            generateReply(for: extractedText, context: context, type: .witty)
        ]
    }
    
    /// タイプ別に返信を3バリエーション生成
    func generateReplies(for extractedText: String, context: Context, type: ReplyType) -> [Reply] {
        return getMockVariations(context: context, type: type).map { text in
            Reply(text: text, type: type, context: context)
        }
    }
    
    /// 単一の返信を生成
    private func generateReply(for extractedText: String, context: Context, type: ReplyType) -> Reply {
        let text = getMockReply(context: context, type: type)
        return Reply(text: text, type: type, context: context)
    }
    
    /// 同一カテゴリ3バリエーションのモック返信テキスト
    private func getMockVariations(context: Context, type: ReplyType) -> [String] {
        switch (context, type) {
        case (.matchStart, .safe):
            return ["よろしくね！趣味とか教えて😊", "はじめまして！共通点ありそう✨", "プロフ見て気になってた！"]
        case (.matchStart, .chill):
            return ["いいねありがとう！何系の人？笑", "タイプかも！会ってみたいな", "写真の雰囲気いい感じ😏"]
        case (.matchStart, .witty):
            return ["運命感じちゃったかも🔮", "マッチした記念に乾杯しよ🥂", "これは運命のいいね？笑"]
        case (.dateProposal, .safe):
            return ["いいね！どこ行く？", "楽しみ！場所決めよう😊", "ぜひ！いつが都合いい？"]
        case (.dateProposal, .chill):
            return ["待ってた！週末空いてるよ😊", "やっと会えるね！ドキドキ", "二人で行きたい店あるんだ"]
        case (.dateProposal, .witty):
            return ["やっと誘ってくれたね笑", "デートプラン任せて👑", "OK！でも場所は秘密ね🤫"]
        case (.dailyChat, .safe):
            return ["そうなんだ！いいね👍", "わかる！それ気になるよね", "へぇ〜もっと聞きたい！"]
        case (.dailyChat, .chill):
            return ["わかるー！最近どう？", "それめっちゃ共感する笑", "今度一緒にやろうよ！"]
        case (.dailyChat, .witty):
            return ["え、それ気になる笑", "天才かよ笑", "その発想はなかった🤣"]
        case (.afterDate, .safe):
            return ["楽しかった！また行こう！", "今日ありがとう！帰れた？", "また会いたいな😊"]
        case (.afterDate, .chill):
            return ["おつー、今度は飲みね🍻", "次はもっと長く一緒にいたい", "帰りたくなかったなぁ"]
        case (.afterDate, .witty):
            return ["逆にいつ空いてるの？笑", "余韻がすごい🫠", "もう次の予定決めちゃう？"]
        case (.checkInterest, .safe):
            return ["また連絡するね！", "最近忙しかった？", "元気にしてる？😊"]
        case (.checkInterest, .chill):
            return ["もっと話したいな", "そろそろ会いたくない？", "ずっと気になってたんだよね"]
        case (.checkInterest, .witty):
            return ["次いつ会える？", "既読つくの待ってた笑", "忘れてないよね？👀"]
        case (.followUp, .safe):
            return ["最近どう？元気してる？", "久しぶり！変わりない？", "ふと思い出して連絡した😊"]
        case (.followUp, .chill):
            return ["久しぶり！会いたいね", "元気？そろそろ飲もうよ", "ずっと連絡しようと思ってた"]
        case (.followUp, .witty):
            return ["生きてる？笑", "急に現れた人です👋", "忘れた頃にやってくるタイプ笑"]
        }
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
