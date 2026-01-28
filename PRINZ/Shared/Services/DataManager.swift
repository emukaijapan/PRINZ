//
//  DataManager.swift
//  PRINZ
//
//  Created on 2026-01-11.
//

import Foundation

class DataManager {
    static let shared = DataManager()
    
    private let appGroupIdentifier = "group.com.prinz.app"
    private let historyFileName = "reply_history.json"
    
    /// 履歴の最大件数（容量節約のため）
    private let maxHistoryCount = 30
    
    private init() {}
    
    // MARK: - App Group Container
    
    private var containerURL: URL? {
        let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
        if url == nil {
            print("❌ DataManager: App Group container not found for: \(appGroupIdentifier)")
        } else {
            print("✅ DataManager: App Group container: \(url!.path)")
        }
        return url
    }
    
    private var historyFileURL: URL? {
        guard let container = containerURL else { return nil }
        let url = container.appendingPathComponent(historyFileName)
        print("📁 DataManager: History file path: \(url.path)")
        return url
    }
    
    // MARK: - Save Reply
    
    /// 返信案を履歴に保存（重複排除）
    func saveReply(_ reply: Reply) {
        var history = loadHistory()
        
        // 重複排除: 同じIDが既に存在しない場合のみ追加
        if !history.contains(where: { $0.id == reply.id }) {
            history.insert(reply, at: 0)
        }
        
        // 最大件数まで保存（30件）
        if history.count > maxHistoryCount {
            history = Array(history.prefix(maxHistoryCount))
        }
        
        saveHistory(history)
    }
    
    /// 複数の返信案を保存（重複排除）
    func saveReplies(_ replies: [Reply]) {
        var history = loadHistory()
        
        // 既存IDのセットを作成
        let existingIds = Set(history.map { $0.id })
        
        // 重複しないものだけフィルタリング
        let newReplies = replies.filter { !existingIds.contains($0.id) }
        
        if !newReplies.isEmpty {
            history.insert(contentsOf: newReplies, at: 0)
            print("📝 DataManager: Added \(newReplies.count) new replies (filtered \(replies.count - newReplies.count) duplicates)")
        }
        
        if history.count > maxHistoryCount {
            history = Array(history.prefix(maxHistoryCount))
        }
        
        saveHistory(history)
    }
    
    // MARK: - Load History
    
    /// 履歴を読み込み
    func loadHistory() -> [Reply] {
        guard let fileURL = historyFileURL,
              FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let history = try decoder.decode([Reply].self, from: data)
            return history
        } catch {
            print("❌ Failed to load history: \(error)")
            return []
        }
    }
    
    // MARK: - Private Save
    
    private func saveHistory(_ history: [Reply]) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        print("📝 [\(timestamp)] DataManager.saveHistory: Starting save of \(history.count) replies")
        
        guard let fileURL = historyFileURL else {
            print("❌ [\(timestamp)] DataManager.saveHistory: App Group container not found")
            return
        }
        
        print("📁 [\(timestamp)] DataManager.saveHistory: Target file: \(fileURL.path)")
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            
            print("🔄 [\(timestamp)] DataManager.saveHistory: Encoding data...")
            let data = try encoder.encode(history)
            
            print("💾 [\(timestamp)] DataManager.saveHistory: Writing \(data.count) bytes to file...")
            try data.write(to: fileURL)
            
            print("✅ [\(timestamp)] DataManager.saveHistory: SUCCESS - Saved \(history.count) replies")
            
            // 書き込み確認
            if FileManager.default.fileExists(atPath: fileURL.path) {
                let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path)
                let size = attrs?[.size] as? Int ?? 0
                print("✅ [\(timestamp)] DataManager.saveHistory: File verified - Size: \(size) bytes")
            }
        } catch {
            print("❌ [\(timestamp)] DataManager.saveHistory: FAILED - \(error.localizedDescription)")
        }
    }
    
    // MARK: - Clear History
    
    /// 履歴をクリア
    func clearHistory() {
        guard let fileURL = historyFileURL else { return }
        try? FileManager.default.removeItem(at: fileURL)
        print("🗑️ History cleared")
    }
}
