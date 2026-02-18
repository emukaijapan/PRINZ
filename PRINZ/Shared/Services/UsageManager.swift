//
//  UsageManager.swift
//  PRINZ
//
//  利用回数制限を管理（無料ユーザー: 5回/日、毎日0時JSTリセット）
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

        // 日付変更チェック（JST 0時）
        checkAndResetIfNeeded()

        return remainingCount > 0
    }

    /// 利用回数を消費（成功時にtrue）
    func consumeUsage() -> Bool {
        // プレミアムユーザーは消費しない
        if SubscriptionManager.shared.isProUserThreadSafe {
            return true
        }

        // 日付変更チェック（JST 0時）
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

    /// JST 0時を跨いでいたらカウントをリセット
    private func checkAndResetIfNeeded() {
        // JST (UTC+9) のカレンダー
        var jstCalendar = Calendar(identifier: .gregorian)
        jstCalendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!

        let now = Date()
        let todayJST = jstCalendar.startOfDay(for: now)

        guard let lastResetDate = defaults?.object(forKey: lastResetDateKey) as? Date else {
            // 初回起動: 今日の0時を記録
            defaults?.set(todayJST, forKey: lastResetDateKey)
            defaults?.set(0, forKey: usageCountKey)
            remainingCount = dailyFreeLimit
            return
        }

        let lastResetDayJST = jstCalendar.startOfDay(for: lastResetDate)

        if todayJST > lastResetDayJST {
            // 日付が変わった（JST 0時を跨いだ）: リセット
            defaults?.set(todayJST, forKey: lastResetDateKey)
            defaults?.set(0, forKey: usageCountKey)
            remainingCount = dailyFreeLimit
            print("📊 UsageManager: New day (JST), count reset to \(dailyFreeLimit)")
        }
    }

    /// 次のリセットまでの残り時間（時間）- JST 0時までの時間
    func hoursUntilReset() -> Int {
        var jstCalendar = Calendar(identifier: .gregorian)
        jstCalendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!

        let now = Date()
        let todayJST = jstCalendar.startOfDay(for: now)
        let tomorrowJST = jstCalendar.date(byAdding: .day, value: 1, to: todayJST)!

        let secondsUntilReset = tomorrowJST.timeIntervalSince(now)
        let hoursRemaining = secondsUntilReset / 3600

        return Int(ceil(hoursRemaining))
    }

    /// 次のリセットまでの残り時間を文字列で取得
    func timeUntilResetString() -> String {
        let hours = hoursUntilReset()

        if hours <= 0 {
            return "まもなく"
        } else if hours == 1 {
            return "あと1時間"
        } else if hours < 24 {
            return "あと\(hours)時間"
        } else {
            return "明日 0:00 に解禁"
        }
    }
}
