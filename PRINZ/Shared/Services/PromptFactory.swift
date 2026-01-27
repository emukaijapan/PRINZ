//
//  PromptFactory.swift
//  PRINZ
//
//  Created on 2026-01-13.
//

import Foundation

struct PromptFactory {
    
    /// OpenAI APIに送信するメッセージ配列（System + User）を作成する
    /// - Parameters:
    ///   - targetMessage: 相手から送られてきたメッセージ
    ///   - personalType: ユーザーが設定した自分の性格タイプ
    ///   - gender: ユーザーの性別
    ///   - ageGroup: ユーザーの年代
    ///   - relationship: 相手との関係性（例: "マッチングアプリで出会った", "付き合って3ヶ月"）
    /// - Returns: APIリクエスト用のメッセージ配列
    static func createMessages(
        targetMessage: String,
        personalType: PersonalType,
        gender: UserGender,
        ageGroup: UserAgeGroup,
        relationship: String
    ) -> [[String: String]] {
        
        // 1. システムプロンプト（AIの役割・人格・ルールの定義）
        let systemContent = """
        あなたは恋愛戦略のプロフェッショナルであり、優秀なゴーストライターです。
        以下の「ユーザー属性」と「性格設定」を持つ人物になりきって、相手の心を動かす返信を考えてください。
        
        【ユーザー属性】
        - 性別: \(gender.rawValue)
        - 年代: \(ageGroup.rawValue)
        
        【性格設定: \(personalType.rawValue)】
        \(personalType.description)
        
        【重要事項】
        - ユーザーの「年代」と「性別」に完全に同調した言葉遣いをすること。
        - 若いユーザーなら若者言葉や自然な崩し方を、年配のユーザーなら落ち着いた表現を選ぶこと。
        - 違和感のある「おじさん/おばさん構文」や、逆に年齢にそぐわない無理な若作りは避けること。
        - 文脈に合わせて、絵文字や記号を適切に使用すること。
        
        【出力ルール】
        - 以下の3つのカテゴリ（安牌、ちょい攻め、変化球）の返信案を作成すること。
        - 長さは「短文（1〜3文程度）」とし、LINEやチャットとして自然なテンポにすること。
        - 必ず以下のJSON形式のみを出力すること。前置きや挨拶は一切不要。
        
        【カテゴリ定義】
        1. safe (安牌): 無難で失敗しない。相手に共感し、会話を維持する。
        2. aggressive (ちょい攻め): 好意を匂わせる。デートに誘う。距離を一歩縮める。
        3. unique (変化球): 相手の予想を裏切る。笑いを取る。鋭い視点やツッコミ。
        
        【JSONフォーマット】
        {
            "replies": [
                {
                    "type": "safe",
                    "text": "（性格と属性を反映した安牌な返信テキスト）",
                    "reasoning": "（なぜこの返信が良いのかの簡潔な解説）"
                },
                {
                    "type": "aggressive",
                    "text": "（性格と属性を反映した攻めた返信テキスト）",
                    "reasoning": "（解説）"
                },
                {
                    "type": "unique",
                    "text": "（性格と属性を反映した変化球な返信テキスト）",
                    "reasoning": "（解説）"
                }
            ]
        }
        """
        
        // 2. ユーザープロンプト（相手のメッセージ情報と文脈）
        let userContent = """
        相手のメッセージ: "\(targetMessage)"
        現在の関係性: \(relationship)
        
        このメッセージに対して、指定されたJSONフォーマットで3パターンの返信を作成してください。
        """
        
        // 3. 配列として結合して返す
        return [
            ["role": "system", "content": systemContent],
            ["role": "user", "content": userContent]
        ]
    }
}
