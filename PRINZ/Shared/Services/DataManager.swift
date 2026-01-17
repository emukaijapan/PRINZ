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
    
    /// 返信案を履歴に保存
    func saveReply(_ reply: Reply) {
        var history = loadHistory()
        history.insert(reply, at: 0) // 新しいものを先頭に
        
        // 最大件数まで保存（30件）
        if history.count > maxHistoryCount {
            history = Array(history.prefix(maxHistoryCount))
        }
        
        saveHistory(history)
    }
    
    /// 複数の返信案を保存
    func saveReplies(_ replies: [Reply]) {
        var history = loadHistory()
        history.insert(contentsOf: replies, at: 0)
        
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
        guard let fileURL = historyFileURL else {
            print("❌ App Group container not found")
            return
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(history)
            try data.write(to: fileURL)
            print("✅ Saved \(history.count) replies to history (max: \(maxHistoryCount))")
        } catch {
            print("❌ Failed to save history: \(error)")
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
