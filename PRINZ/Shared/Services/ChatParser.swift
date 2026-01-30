//
//  ChatParser.swift
//  PRINZ
//
//  Created on 2026-01-27.
//

import Foundation

/// OCRで抽出したチャットテキストを解析した結果
struct ParsedChat {
    let partnerName: String?      // 相手の名前
    let messages: [ChatMessage]   // 会話メッセージ配列
    let rawText: String           // 元のOCRテキスト
    let lastUserMessage: String?  // 自分の直近の発言（右下）
    
    /// 相手からのメッセージのみを結合したテキスト（重複除去済み）
    var partnerMessagesText: String {
        // 重複除去
        var seen = Set<String>()
        return messages
            .filter { $0.isFromPartner }
            .map { $0.text }
            .filter { text in
                let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if seen.contains(normalized) { return false }
                seen.insert(normalized)
                return true
            }
            .joined(separator: "\n")
    }
}

/// 個別のチャットメッセージ
struct ChatMessage {
    let text: String
    let isFromPartner: Bool       // 相手からのメッセージか
    let timestamp: String?        // 日時（あれば）
    let normalizedX: CGFloat?     // X座標（0=左端, 1=右端）
    let normalizedY: CGFloat?     // Y座標（0=下端, 1=上端）
}

/// LINEやマッチングアプリのスクリーンショットからチャット情報を抽出
class ChatParser {
    static let shared = ChatParser()
    
    private init() {}
    
    // MARK: - ブラックリスト
    
    /// UI要素やシステムメッセージのブラックリスト
    private let blacklistKeywords = [
        "既読",
        "今日",
        "昨日",
        "メッセージを入力",
        "Aa",
        "送信取消",
        "メッセージを削除",
        "未読",
        "通話",
        "ビデオ通話",
        "スタンプ",
        "写真",
        "動画",
        "トーク",
        "メニュー",
        "友だち",
        "ホーム",
        "ニュース",
        "ウォレット",
        // キーボード由来のノイズ
        "ABC",
        "abc",
        "あいう",
        "Aへ",
        "Aに",
        "絵文字",
        "マイク",
        "カメラ",
        "返信",
        "edit",
        "コピー",
        "転送",
        "削除",
        "もっと見る",
    ]
    
    /// 1文字記号のブラックリスト
    private let symbolBlacklist: Set<Character> = ["<", ">", "＜", "＞", "←", "→", "↑", "↓", "○", "×", "◎", "△", "▽", "●", "■", "◆", "♪", "♡", "☆", "★"]
    
    // MARK: - Y座標フィルタ閾値
    
    /// 有効なY座標範囲（UI要素除外用、下部20%をカット）
    private let validYRange: ClosedRange<CGFloat> = 0.15...0.80
    
    /// 自分のメッセージ判定用X座標閾値
    private let selfMessageXThreshold: CGFloat = 0.7
    
    /// OCRテキストを解析してチャット情報を抽出
    func parse(_ ocrText: String) -> ParsedChat {
        let lines = ocrText
            .split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        var partnerName: String?
        var messages: [ChatMessage] = []
        
        for (index, line) in lines.enumerated() {
            // ブラックリストチェック
            if shouldExclude(line) { continue }
            
            // 1行目は相手の名前の可能性が高い
            if index == 0 && !isTimestamp(line) {
                partnerName = extractName(from: line)
                continue
            }
            
            // 日時パターンを検出してスキップ
            if isTimestamp(line) { continue }
            
            // メッセージとして追加
            let isFromPartner = !line.hasPrefix("　") && !line.hasPrefix("  ")
            
            messages.append(ChatMessage(
                text: line,
                isFromPartner: isFromPartner,
                timestamp: nil,
                normalizedX: nil,
                normalizedY: nil
            ))
        }
        
        return ParsedChat(
            partnerName: partnerName,
            messages: messages,
            rawText: ocrText,
            lastUserMessage: nil
        )
    }
    
    // MARK: - 座標ベースの話者分離（強化版）
    
    /// OCR座標情報を使用してチャットを解析（ノイズ除去強化版）
    /// - Parameter items: OCRService.OCRTextItemの配列
    /// - Returns: ParsedChat
    func parseWithCoordinates(_ items: [OCRService.OCRTextItem]) -> ParsedChat {
        var partnerName: String?
        var messages: [ChatMessage] = []
        var lastUserMessage: String?
        var lowestUserY: CGFloat = 1.0  // 最も下のY座標（小さい値=下）
        
        // 1. 垂直クロップ：Y座標が0.15〜0.85の範囲外は除外
        let verticallyFiltered = items.filter { validYRange.contains($0.normalizedY) }
        
        print("📊 ChatParser: \(items.count) items -> \(verticallyFiltered.count) after vertical crop")
        
        // 2. 一番上の左側テキストを名前として採用
        if let firstItem = verticallyFiltered.first(where: { 
            $0.isFromPartner && !isTimestamp($0.text) && !shouldExclude($0.text) 
        }) {
            if verticallyFiltered.first?.text == firstItem.text {
                partnerName = extractName(from: firstItem.text)
            }
        }
        
        for item in verticallyFiltered {
            // キーワードブラックリストチェック
            if shouldExclude(item.text) {
                print("  🚫 Excluded: \(item.text.prefix(20))...")
                continue
            }
            
            // 日時パターンをスキップ
            if isTimestamp(item.text) { continue }
            
            // 座標で左右判定（中心線0.5を基準）
            let isFromPartner = item.isFromPartner
            
            // 3. 自分の直近発言の抽出（右側 x>0.7 かつ 最も下のもの）
            if item.normalizedX > selfMessageXThreshold {
                if item.normalizedY < lowestUserY {
                    lowestUserY = item.normalizedY
                    lastUserMessage = item.text
                }
            }
            
            messages.append(ChatMessage(
                text: item.text,
                isFromPartner: isFromPartner,
                timestamp: nil,
                normalizedX: item.normalizedX,
                normalizedY: item.normalizedY
            ))
        }
        
        // 4. パース結果の浄化：重複除去
        let cleanedMessages = removeDuplicates(from: messages)
        
        // 元のOCRテキストを再構築
        let rawText = verticallyFiltered.map { $0.text }.joined(separator: "\n")
        
        print("📊 ChatParser Result:")
        print("  Partner Name: \(partnerName ?? "なし")")
        print("  Messages: \(cleanedMessages.count) (Partner: \(cleanedMessages.filter { $0.isFromPartner }.count))")
        print("  Last User Message: \(lastUserMessage ?? "なし")")
        
        return ParsedChat(
            partnerName: partnerName,
            messages: cleanedMessages,
            rawText: rawText,
            lastUserMessage: lastUserMessage
        )
    }
    
    // MARK: - Private Methods
    
    /// ブラックリストに該当するか判定
    private func shouldExclude(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 空文字列は除外
        if trimmed.isEmpty { return true }
        
        // 1文字の記号は除外
        if trimmed.count == 1 && symbolBlacklist.contains(trimmed.first!) {
            return true
        }
        
        // 2文字以下の記号のみは除外
        if trimmed.count <= 2 && trimmed.allSatisfy({ symbolBlacklist.contains($0) || $0.isWhitespace }) {
            return true
        }
        
        // キーワードブラックリストチェック
        for keyword in blacklistKeywords {
            // 完全一致
            if trimmed == keyword { return true }
            // キーワードのみで構成される短い文字列
            if trimmed.contains(keyword) && trimmed.count < keyword.count + 5 {
                return true
            }
        }
        
        return false
    }
    
    /// 名前を抽出（「さん」「くん」などの敬称を除去）
    private func extractName(from line: String) -> String {
        var name = line
        let suffixes = ["さん", "くん", "ちゃん", "様", "氏"]
        
        for suffix in suffixes {
            if name.hasSuffix(suffix) {
                name = String(name.dropLast(suffix.count))
                break
            }
        }
        
        return name.trimmingCharacters(in: .whitespaces)
    }
    
    /// 日時パターンかどうかを判定
    private func isTimestamp(_ line: String) -> Bool {
        let patterns = [
            "^\\d{1,2}:\\d{2}$",                    // 20:30
            "^既読\\s*\\d{1,2}:\\d{2}$",            // 既読 20:30
            "^\\d{1,2}/\\d{1,2}\\s*\\d{1,2}:\\d{2}$", // 12/25 20:30
            "^\\d{1,2}/\\d{1,2}$",                  // 12/25
            "^午前\\d{1,2}:\\d{2}$",                // 午前10:30
            "^午後\\d{1,2}:\\d{2}$",                // 午後8:30
            "^\\d{1,2}:\\d{2}\\s*(AM|PM)$",         // 10:30 AM
        ]
        
        return patterns.contains { line.range(of: $0, options: .regularExpression) != nil }
    }
    
    /// 重複メッセージを除去
    private func removeDuplicates(from messages: [ChatMessage]) -> [ChatMessage] {
        var seen = Set<String>()
        return messages.filter { message in
            let normalized = message.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if seen.contains(normalized) { return false }
            seen.insert(normalized)
            return true
        }
    }
}
