//
//  OpenAIService.swift
//  PRINZ
//
//  Created on 2026-01-13.
//

import Foundation

/// OpenAI APIレスポンスの構造体
struct OpenAIResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let role: String
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}

/// AI生成レスポンスの構造体
struct AIGeneratedReply: Codable {
    let type: String      // "safe", "aggressive", "unique"
    let text: String
    let reasoning: String
}

struct AIGeneratedReplies: Codable {
    let replies: [AIGeneratedReply]
}

/// OpenAI API連携サービス
class OpenAIService {
    static let shared = OpenAIService()
    
    private let apiURL = "https://api.openai.com/v1/chat/completions"
    private let model = "gpt-4o-mini"  // コスト効率の良いモデル
    
    private init() {}
    
    /// APIキーを取得（環境変数またはUserDefaultsから）
    private var apiKey: String? {
        // まずUserDefaultsをチェック
        if let key = UserDefaults.standard.string(forKey: "openai_api_key"), !key.isEmpty {
            return key
        }
        // 環境変数をチェック（開発用）
        return ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
    }
    
    /// APIキーを設定
    func setAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "openai_api_key")
    }
    
    /// APIキーが設定されているかチェック
    var hasAPIKey: Bool {
        return apiKey != nil
    }
    
    /// AI返信を生成
    /// - Parameters:
    ///   - message: 相手のメッセージ
    ///   - personalType: パーソナルタイプ
    ///   - gender: 性別
    ///   - ageGroup: 年代
    ///   - relationship: 関係性
    /// - Returns: 生成された返信配列
    func generateReplies(
        message: String,
        personalType: PersonalType,
        gender: UserGender,
        ageGroup: UserAgeGroup,
        relationship: String
    ) async throws -> [AIGeneratedReply] {
        
        guard let apiKey = apiKey else {
            throw OpenAIError.noAPIKey
        }
        
        // プロンプト作成
        let messages = PromptFactory.createMessages(
            targetMessage: message,
            personalType: personalType,
            gender: gender,
            ageGroup: ageGroup,
            relationship: relationship
        )
        
        // リクエストボディ
        let requestBody: [String: Any] = [
            "model": model,
            "messages": messages,
            "temperature": 0.8,
            "max_tokens": 1000,
            "response_format": ["type": "json_object"]
        ]
        
        // リクエスト作成
        var request = URLRequest(url: URL(string: apiURL)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // API呼び出し
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw OpenAIError.apiError(statusCode: httpResponse.statusCode)
        }
        
        // レスポンス解析
        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        
        guard let content = openAIResponse.choices.first?.message.content else {
            throw OpenAIError.noContent
        }
        
        // JSON解析
        guard let jsonData = content.data(using: .utf8) else {
            throw OpenAIError.invalidJSON
        }
        
        let replies = try JSONDecoder().decode(AIGeneratedReplies.self, from: jsonData)
        return replies.replies
    }
}

/// OpenAI APIエラー
enum OpenAIError: Error, LocalizedError {
    case noAPIKey
    case invalidResponse
    case apiError(statusCode: Int)
    case noContent
    case invalidJSON
    
    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "APIキーが設定されていません"
        case .invalidResponse:
            return "無効なレスポンス"
        case .apiError(let statusCode):
            return "APIエラー: \(statusCode)"
        case .noContent:
            return "コンテンツがありません"
        case .invalidJSON:
            return "JSONの解析に失敗しました"
        }
    }
}
