//
//  UsageManager.swift
//  PRINZ
//
//  利用回数制限を管理（無料ユーザー: 5回/24時間）
//

import Foundation
import Combine

/// 利用回数制限を管理するシングルトン
class UsageManager: ObservableObject {
    static let shared = UsageManager()

    /// 無料ユーザーの1日あたりの利用上限
    private let dailyFreeLimit = 5

    /// UserDefaults のキー
    private let usageCountKey = "usageCount"
    private let lastResetDateKey = "lastResetDate"
    private let hasUsedTrialKey = "hasUsedFreeTrial"

    /// App Group の UserDefaults
    private let defaults = UserDefaults(suiteName: "group.com.mgolworks.prinz")

    /// 残り利用回数
    @Published private(set) var remainingCount: Int = 5

    /// トライアル使用済みフラグ
    @Published private(set) var hasUsedTrial: Bool = false

    private init() {
        checkAndResetIfNeeded()
        loadState()
    }

    // MARK: - Public Methods

    /// 利用可能かチェック（プレミアムユーザーは常にtrue）
    func canUse() -> Bool {
        // プレミアムユーザーは無制限
        if SubscriptionManager.shared.isProUserThreadSafe {
            return true
        }

        // 24時間経過チェック
        checkAndResetIfNeeded()

        return remainingCount > 0
    }

    /// 利用回数を消費（成功時にtrue）
    func consumeUsage() -> Bool {
        // プレミアムユーザーは消費しない
        if SubscriptionManager.shared.isProUserThreadSafe {
            return true
        }

        // 24時間経過チェック
        checkAndResetIfNeeded()

        guard remainingCount > 0 else {
            return false
        }

        let currentCount = defaults?.integer(forKey: usageCountKey) ?? 0
        defaults?.set(currentCount + 1, forKey: usageCountKey)

        remainingCount = max(0, dailyFreeLimit - (currentCount + 1))
        print("📊 UsageManager: Used 1, remaining: \(remainingCount)")

        return true
    }

    /// 残り回数を取得
    func getRemainingCount() -> Int {
        if SubscriptionManager.shared.isProUserThreadSafe {
            return 999  // 無制限
        }

        checkAndResetIfNeeded()
        return remainingCount
    }

    /// トライアル使用済みかチェック
    func hasAlreadyUsedTrial() -> Bool {
        return defaults?.bool(forKey: hasUsedTrialKey) ?? false
    }

    /// トライアル使用済みとしてマーク
    func markTrialAsUsed() {
        defaults?.set(true, forKey: hasUsedTrialKey)
        hasUsedTrial = true
        print("📊 UsageManager: Trial marked as used")
    }

    /// 状態をリロード（外部からの更新時）
    func reload() {
        checkAndResetIfNeeded()
        loadState()
    }

    // MARK: - Private Methods

    private func loadState() {
        let currentCount = defaults?.integer(forKey: usageCountKey) ?? 0
        remainingCount = max(0, dailyFreeLimit - currentCount)
        hasUsedTrial = defaults?.bool(forKey: hasUsedTrialKey) ?? false
    }

    /// 24時間経過していたらカウントをリセット
    private func checkAndResetIfNeeded() {
        guard let lastResetDate = defaults?.object(forKey: lastResetDateKey) as? Date else {
            // 初回起動: 現在時刻を記録
            defaults?.set(Date(), forKey: lastResetDateKey)
            defaults?.set(0, forKey: usageCountKey)
            remainingCount = dailyFreeLimit
            return
        }

        let now = Date()
        let hoursSinceReset = now.timeIntervalSince(lastResetDate) / 3600

        if hoursSinceReset >= 24 {
            // 24時間以上経過: リセット
            defaults?.set(now, forKey: lastResetDateKey)
            defaults?.set(0, forKey: usageCountKey)
            remainingCount = dailyFreeLimit
            print("📊 UsageManager: 24h passed, count reset to \(dailyFreeLimit)")
        }
    }

    /// 次のリセットまでの残り時間（時間）
    func hoursUntilReset() -> Int {
        guard let lastResetDate = defaults?.object(forKey: lastResetDateKey) as? Date else {
            return 24
        }

        let now = Date()
        let hoursSinceReset = now.timeIntervalSince(lastResetDate) / 3600
        let hoursRemaining = max(0, 24 - hoursSinceReset)

        return Int(ceil(hoursRemaining))
    }

    /// 次のリセットまでの残り時間を文字列で取得
    func timeUntilResetString() -> String {
        guard let lastResetDate = defaults?.object(forKey: lastResetDateKey) as? Date else {
            return "24時間後"
        }

        // リセット予定時刻を計算
        let resetDate = lastResetDate.addingTimeInterval(24 * 60 * 60)
        let now = Date()

        if resetDate <= now {
            return "まもなく"
        }

        // 日付フォーマッター
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")

        let calendar = Calendar.current
        if calendar.isDateInToday(resetDate) {
            // 今日中にリセット
            formatter.dateFormat = "H:mm"
            return "今日 \(formatter.string(from: resetDate)) に解禁"
        } else if calendar.isDateInTomorrow(resetDate) {
            // 明日リセット
            formatter.dateFormat = "H:mm"
            return "明日 \(formatter.string(from: resetDate)) に解禁"
        } else {
            // それ以降
            formatter.dateFormat = "M/d H:mm"
            return "\(formatter.string(from: resetDate)) に解禁"
        }
    }
}
