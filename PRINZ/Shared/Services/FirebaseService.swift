//
//  FirebaseService.swift
//  PRINZ
//
//  Created on 2026-01-13.
//

import Foundation
import FirebaseFunctions
import FirebaseAuth

/// Firebase Functions経由でAI返信を生成するサービス
class FirebaseService {
    static let shared = FirebaseService()
    
    private lazy var functions = Functions.functions(region: "asia-northeast1")
    
    private init() {}
    
    // MARK: - AI返信生成
    
    /// Firebase Functions経由でAI返信を生成
    /// - Parameters:
    ///   - message: 相手のメッセージ
    ///   - personalType: パーソナルタイプ
    ///   - gender: 性別
    ///   - ageGroup: 年代
    ///   - relationship: 関係性
    ///   - userMessage: ユーザーの意図（オプション）
    ///   - isShortMode: 短文モード（デフォルト: true）
    /// - Returns: 生成された返信配列と残り回数
    func generateReplies(
        message: String,
        personalType: PersonalType,
        gender: UserGender,
        ageGroup: UserAgeGroup,
        relationship: String? = nil,
        partnerName: String? = nil,
        userMessage: String? = nil,
        isShortMode: Bool = true,
        selectedTone: ReplyType? = nil,
        mode: String = "chatReply",
        profileInfo: [String: Any]? = nil
    ) async throws -> (replies: [Reply], remainingToday: Int) {

        var data: [String: Any] = [
            "message": message,
            "personalType": personalType.rawValue,
            "gender": gender.rawValue,
            "ageGroup": ageGroup.rawValue,
            "relationship": relationship ?? "マッチング中",
            "replyLength": isShortMode ? "short" : "long",
            "mode": mode
        ]

        // オプションパラメータを追加
        if let userMessage = userMessage {
            data["userMessage"] = userMessage
        }
        if let selectedTone = selectedTone {
            let toneString: String
            switch selectedTone {
            case .safe: toneString = "safe"
            case .chill: toneString = "aggressive"
            case .witty: toneString = "unique"
            }
            data["selectedTone"] = toneString
        }
        if let partnerName = partnerName {
            data["partnerName"] = partnerName
        }
        if let profileInfo = profileInfo {
            data["profileInfo"] = profileInfo
        }

        do {
            // 認証を確実に完了させてからFunctions呼び出し
            try await AuthManager.shared.ensureAuthenticated()

            // タイムアウト付きでFunctions呼び出し（Share Extension対応）
            let callable = functions.httpsCallable("generateReply")
            callable.timeoutInterval = 25  // 25秒でタイムアウト（Share Extensionの制限対策）

            let result = try await callable.call(data)
            
            guard let response = result.data as? [String: Any],
                  let success = response["success"] as? Bool,
                  success,
                  let repliesData = response["replies"] as? [[String: Any]],
                  let remainingToday = response["remainingToday"] as? Int else {
                throw FirebaseError.invalidResponse
            }
            
            // レスポンスをReplyオブジェクトに変換
            let replies = repliesData.compactMap { dict -> Reply? in
                guard let type = dict["type"] as? String,
                      let text = dict["text"] as? String,
                      let reasoning = dict["reasoning"] as? String,
                      let replyType = ReplyType.from(apiType: type) else {
                    return nil
                }
                
                return Reply(
                    text: text,
                    type: replyType,
                    context: Context.from(relationship: relationship ?? "マッチング中"),
                    reasoning: reasoning
                )
            }
            
            return (replies, remainingToday)
            
        } catch let error as NSError {
            // Firebase Functions エラーハンドリング
            if error.domain == FunctionsErrorDomain {
                let code = FunctionsErrorCode(rawValue: error.code)
                switch code {
                case .unauthenticated:
                    throw FirebaseError.unauthenticated
                case .resourceExhausted:
                    throw FirebaseError.rateLimitExceeded
                case .invalidArgument:
                    throw FirebaseError.invalidArgument(error.localizedDescription)
                default:
                    throw FirebaseError.unknown(error.localizedDescription)
                }
            }
            throw FirebaseError.unknown(error.localizedDescription)
        }
    }
}

// MARK: - Firebase Error

enum FirebaseError: Error, LocalizedError, Equatable {
    case unauthenticated
    case rateLimitExceeded
    case invalidArgument(String)
    case invalidResponse
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .unauthenticated:
            return "ログインが必要です"
        case .rateLimitExceeded:
            return "本日の利用上限に達しました"
        case .invalidArgument(let message):
            return "入力エラー: \(message)"
        case .invalidResponse:
            return "サーバーからの応答が不正です"
        case .unknown(let message):
            return "エラー: \(message)"
        }
    }
}

// MARK: - Context Extension

extension Context {
    /// 関係性文字列からContextを推定
    static func from(relationship: String) -> Context {
        if relationship.contains("マッチ") {
            return .matchStart
        } else if relationship.contains("デート") {
            if relationship.contains("後") {
                return .afterDate
            }
            return .dateProposal
        } else if relationship.contains("日常") {
            return .dailyChat
        } else if relationship.contains("フォロー") || relationship.contains("久しぶり") {
            return .followUp
        } else {
            return .checkInterest
        }
    }
}
