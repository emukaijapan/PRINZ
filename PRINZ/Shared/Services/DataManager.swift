//
//  DataManager.swift
//  PRINZ
//
//  Created on 2026-01-11.
//

import Foundation

class DataManager {
  static let shared = DataManager()

  private let historyFileName = "reply_history.json"
  private let maxHistoryCount = 30
  private let saveQueue = DispatchQueue(label: "com.prinz.datamanager.save")

  /// 起動時に1回だけ解決してキャッシュ
  private let cachedHistoryFileURL: URL?

  private init() {
    let url = FileManager.default
      .containerURL(forSecurityApplicationGroupIdentifier: "group.com.prinz.app")
    self.cachedHistoryFileURL = url?.appendingPathComponent(historyFileName)

    if url == nil {
      print("❌ DataManager: App Group container not found")
    }
  }

  // MARK: - Save Reply

  /// 返信案を履歴に保存（重複排除・直列化）
  func saveReply(_ reply: Reply) {
    saveQueue.async {
      var history = self.loadHistory()

      if !history.contains(where: { $0.id == reply.id }) {
        history.insert(reply, at: 0)
      }

      if history.count > self.maxHistoryCount {
        history = Array(history.prefix(self.maxHistoryCount))
      }

      self.writeHistory(history)
    }
  }

  /// 複数の返信案を保存（重複排除・直列化）
  func saveReplies(_ replies: [Reply]) {
    saveQueue.async {
      var history = self.loadHistory()
      let existingIds = Set(history.map { $0.id })
      let newReplies = replies.filter { !existingIds.contains($0.id) }

      if !newReplies.isEmpty {
        history.insert(contentsOf: newReplies, at: 0)
      }

      if history.count > self.maxHistoryCount {
        history = Array(history.prefix(self.maxHistoryCount))
      }

      self.writeHistory(history)
    }
  }

  // MARK: - Load History

  /// 同期読み込み（既存の呼び出し元との互換性維持）
  func loadHistory() -> [Reply] {
    guard let fileURL = cachedHistoryFileURL,
          FileManager.default.fileExists(atPath: fileURL.path) else {
      return []
    }

    do {
      let data = try Data(contentsOf: fileURL)
      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601
      return try decoder.decode([Reply].self, from: data)
    } catch {
      print("❌ DataManager: Load failed - \(error.localizedDescription)")
      return []
    }
  }

  /// 非同期読み込み
  func loadHistoryAsync() async -> [Reply] {
    await Task.detached(priority: .utility) {
      self.loadHistory()
    }.value
  }

  // MARK: - Private Write

  private func writeHistory(_ history: [Reply]) {
    guard let fileURL = cachedHistoryFileURL else { return }

    do {
      let encoder = JSONEncoder()
      encoder.dateEncodingStrategy = .iso8601
      let data = try encoder.encode(history)
      try data.write(to: fileURL, options: .atomic)
    } catch {
      print("❌ DataManager: Save failed - \(error.localizedDescription)")
    }
  }

  // MARK: - Clear History

  func clearHistory() {
    guard let fileURL = cachedHistoryFileURL else { return }
    try? FileManager.default.removeItem(at: fileURL)
  }
}
