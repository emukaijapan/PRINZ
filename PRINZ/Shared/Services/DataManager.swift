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
    
    private init() {}
    
    // MARK: - App Group Container
    
    private var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
    }
    
    private var historyFileURL: URL? {
        containerURL?.appendingPathComponent(historyFileName)
    }
    
    // MARK: - Save Reply
    
    /// 返信案を履歴に保存
    func saveReply(_ reply: Reply) {
        var history = loadHistory()
        history.insert(reply, at: 0) // 新しいものを先頭に
        
        // 最大100件まで保存
        if history.count > 100 {
            history = Array(history.prefix(100))
        }
        
        saveHistory(history)
    }
    
    /// 複数の返信案を保存
    func saveReplies(_ replies: [Reply]) {
        var history = loadHistory()
        history.insert(contentsOf: replies, at: 0)
        
        if history.count > 100 {
            history = Array(history.prefix(100))
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
            print("✅ Saved \(history.count) replies to history")
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
