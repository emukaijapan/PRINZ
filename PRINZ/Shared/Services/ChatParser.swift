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
    
    /// 相手からのメッセージのみを結合したテキスト
    var partnerMessagesText: String {
        messages
            .filter { $0.isFromPartner }
            .map { $0.text }
            .joined(separator: "\n")
    }
}

/// 個別のチャットメッセージ
struct ChatMessage {
    let text: String
    let isFromPartner: Bool       // 相手からのメッセージか
    let timestamp: String?        // 日時（あれば）
    let normalizedX: CGFloat?     // X座標（0=左端, 1=右端）
}

/// LINEやマッチングアプリのスクリーンショットからチャット情報を抽出
class ChatParser {
    static let shared = ChatParser()
    
    private init() {}
    
    /// OCRテキストを解析してチャット情報を抽出
    func parse(_ ocrText: String) -> ParsedChat {
        let lines = ocrText
            .split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        var partnerName: String?
        var messages: [ChatMessage] = []
        
        for (index, line) in lines.enumerated() {
            // 1行目は相手の名前の可能性が高い
            if index == 0 && !isTimestamp(line) && !isSystemMessage(line) {
                partnerName = extractName(from: line)
                continue
            }
            
            // 日時パターンを検出してスキップ
            if isTimestamp(line) {
                continue
            }
            
            // システムメッセージをスキップ
            if isSystemMessage(line) {
                continue
            }
            
            // 空白行をスキップ
            if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                continue
            }
            
            // メッセージとして追加
            // 右寄せ（自分のメッセージ）は全角スペースで始まることが多い
            let isFromPartner = !line.hasPrefix("　") && !line.hasPrefix("  ")
            
            messages.append(ChatMessage(
                text: line,
                isFromPartner: isFromPartner,
                timestamp: nil,
                normalizedX: nil
            ))
        }
        
        return ParsedChat(
            partnerName: partnerName,
            messages: messages,
            rawText: ocrText
        )
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
        ]
        
        return patterns.contains { line.range(of: $0, options: .regularExpression) != nil }
    }
    
    /// システムメッセージかどうかを判定
    private func isSystemMessage(_ line: String) -> Bool {
        let keywords = [
            "既読",
            "送信取消",
            "メッセージを削除",
            "未読",
            "通話",
            "ビデオ通話",
            "スタンプ",
            "写真",
            "動画",
        ]
        
        // キーワードのみの行はシステムメッセージ
        return keywords.contains { keyword in
            line == keyword || line.contains(keyword) && line.count < 10
        }
    }
    
    // MARK: - 座標ベースの話者分離
    
    /// OCR座標情報を使用してチャットを解析（左側=相手、右側=自分）
    /// - Parameter items: OCRService.OCRTextItemの配列
    /// - Returns: ParsedChat
    func parseWithCoordinates(_ items: [OCRService.OCRTextItem]) -> ParsedChat {
        var partnerName: String?
        var messages: [ChatMessage] = []
        
        // 一番上の左側テキストを名前として採用
        if let firstItem = items.first(where: { $0.isFromPartner && !isTimestamp($0.text) && !isSystemMessage($0.text) }) {
            // 1行目かつ左側なら名前の可能性
            if items.first?.text == firstItem.text {
                partnerName = extractName(from: firstItem.text)
            }
        }
        
        for item in items {
            // 日時パターンをスキップ
            if isTimestamp(item.text) { continue }
            
            // システムメッセージをスキップ
            if isSystemMessage(item.text) { continue }
            
            // 座標で左右判定（中心線0.5を基準）
            let isFromPartner = item.isFromPartner
            
            messages.append(ChatMessage(
                text: item.text,
                isFromPartner: isFromPartner,
                timestamp: nil,
                normalizedX: item.normalizedX
            ))
        }
        
        // 元のOCRテキストを再構築
        let rawText = items.map { $0.text }.joined(separator: "\n")
        
        return ParsedChat(
            partnerName: partnerName,
            messages: messages,
            rawText: rawText
        )
    }
}
