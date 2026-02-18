# PRINZ リリース計測・マーケティング設計書（文章版） v1.0

作成日: 2026年2月17日

## 1. 目的

本設計書は、PRINZのリリース後に「ユーザー数の変化」「継続利用」「課金転換」を継続的に可視化し、マーケティング施策を改善するための計測基盤と運用方針を定義する。  
Firebaseを主軸に、iOSアプリ内行動、Firestore利用実績、RevenueCat課金状態を統合して意思決定に使える状態を作る。

## 2. 適用範囲

対象はiOSアプリ本体、Share Extension、Firebase Cloud Functions、Firestore、RevenueCat Webhook、LP（`firebase/public/index.html`）とする。  
対象外は広告媒体ごとの高度なアトリビューション最適化、機械学習によるLTV予測とする。

## 3. 現状前提

現状で取得できるデータは、Cloud Functionsの利用回数記録（`usage`）と課金状態（`users.isPremium`）が中心である。  
無料上限は1日5回、Premiumは無制限（実装上は999999回）である。  
匿名認証UIDが全体の共通ユーザーIDとして利用可能である。  
現状はFirebase Analyticsイベントが未実装のため、初回起動やオンボード離脱などの詳細なファネルは未計測である。

## 4. KPI定義

- 新規ユーザー数: `first_open` の日次ユニークUID
- DAU/WAU/MAU: 当日/当週/当月に主要イベントを実行したユニークUID
- 活性化率: `onboarding_complete / first_open`
- 初回価値到達率: `reply_generated / first_open`
- 継続率: D1/D7/D30で再訪した割合
- Paywall到達率: `paywall_view / reply_generated`
- トライアル開始率: `trial_start / paywall_view`
- 課金転換率: `purchase_success / trial_start`
- 収益効率: ARPPU、課金ユーザー比率
- プロダクト利用密度: `reply_generated` 回数 / DAU

## 5. イベント設計（Firebase Analytics）

- `first_open`: 初回起動時に送信
- `app_open`: フォアグラウンド復帰時に送信
- `onboarding_start`: オンボード開始時に送信
- `onboarding_complete`: オンボード完了時に送信
- `reply_generate_request`: 返信生成要求時に送信
- `reply_generated`: 返信生成成功時に送信
- `reply_generate_error`: 返信生成失敗時に送信
- `reply_copied`: 返信コピー時に送信
- `paywall_view`: ペイウォール表示時に送信
- `trial_start`: トライアル開始時に送信
- `purchase_success`: 購入成功時に送信
- `purchase_restore`: 購入復元成功時に送信

共通パラメータは `user_id`, `is_premium`, `mode(chatReply/profileGreeting)`, `input_source(screenshot/text/share_extension)`, `tone(safe/aggressive/unique)`, `reply_length(short/long)`, `remaining_today`, `plan(weekly/yearly)`, `error_code` とする。  
送信禁止データは、OCR全文テキスト、個人名、連絡先、会話の生文とする。

## 6. データ基盤構成

Firebase AnalyticsをBigQueryへエクスポートし、日次集計テーブルを作成する。  
Firestore `usage` は実利用量の一次ソース、RevenueCat Webhookによる `users.isPremium` は課金状態の一次ソースとする。  
集計は日次バッチで行い、Looker Studioで閲覧可能にする。

## 7. ダッシュボード仕様

- グロース画面: 新規、DAU/WAU/MAU、D1/D7/D30
- ファネル画面: `first_open → onboarding_complete → reply_generated → paywall_view → trial_start → purchase_success`
- 収益画面: 課金ユーザー数、プラン比率、解約イベント、ARPPU
- 利用品質画面: エラー率、OCR失敗率、タイムアウト率、生成成功率

更新頻度は日次、週次レビューを固定実施する。

## 8. マーケティング戦略（LP準拠）

訴求軸は3つに固定する。

- 「既読のまま、終わらせない。」
- 「スクショ共有→トーン選択→コピーの3ステップ」
- 「画像は送らないプライバシー設計」

運用方針は以下とする。

- 0-30日: 課題訴求型クリエイティブを毎日投稿し、初回価値到達率を最大化する
- 31-60日: App Storeスクショと説明文のABテストでCVR改善を行う
- 61-90日: Paywall文言とプラン提示順のABテストで課金転換を最適化する

週次の意思決定基準を定める。

- 活性化率が60%未満ならオンボード短縮を優先
- `reply_generated`率が50%未満なら導線改善を優先
- `paywall_view→trial_start`が8%未満なら価値訴求を再設計
- `trial_start→purchase_success`が35%未満なら価格訴求と比較表示を再設計

## 9. リリース前の整合性修正必須項目

- [x] LPのApp Storeボタンリンク未設定を修正する → `https://apps.apple.com/app/id6740875498` に設定済み
- [x] 週額価格の表記ゆれ（330円/480円）を統一する → 330円に統一済み
- [x] Premium特典の表記ゆれ（無制限/100回）を統一する → 無制限に統一済み（Firebase: 999999回）
- [x] 利用回数リセット仕様を「毎日0時（JST）」に統一済み（クライアント・サーバー両方）

## 10. 実装スケジュール

- Day1-2: Analyticsイベント実装
- Day3: BigQuery連携と集計SQL作成
- Day4: ダッシュボード作成
- Day5: QAと計測検証、本番反映

## 11. 受け入れ基準

- 主要イベントが本番で欠損なく取得できる
- 日次でDAU、初回価値到達率、課金ファネルが確認できる
- LP/サポート/アップグレードページの価格・回数・文言が実装と一致している
- 週次レビューで施策判断ができる運用資料が整備されている

---

## 12. Swift実装ガイド

### 12.1 Analyticsヘルパー（推奨構造）

```swift
// Analytics/AnalyticsManager.swift

import FirebaseAnalytics

enum AnalyticsEvent {
    case appOpen(isFirstLaunch: Bool)
    case onboardingComplete(stepCount: Int)
    case replyGenerated(toneType: String, charCount: Int, responseTimeMs: Int)
    case replyCopied(toneType: String)
    case limitReached(isPremium: Bool, currentCount: Int)
    case paywallView(triggerPoint: String)
    case trialStart(productId: String)
    case purchaseSuccess(productId: String, price: Double, currency: String)

    var name: String {
        switch self {
        case .appOpen: return "app_open"
        case .onboardingComplete: return "onboarding_complete"
        case .replyGenerated: return "reply_generated"
        case .replyCopied: return "reply_copied"
        case .limitReached: return "limit_reached"
        case .paywallView: return "paywall_view"
        case .trialStart: return "trial_start"
        case .purchaseSuccess: return "purchase_success"
        }
    }

    var parameters: [String: Any] {
        switch self {
        case .appOpen(let isFirstLaunch):
            return ["is_first_launch": isFirstLaunch]
        case .onboardingComplete(let stepCount):
            return ["step_count": stepCount]
        case .replyGenerated(let toneType, let charCount, let responseTimeMs):
            return ["tone_type": toneType, "char_count": charCount, "response_time_ms": responseTimeMs]
        case .replyCopied(let toneType):
            return ["tone_type": toneType]
        case .limitReached(let isPremium, let currentCount):
            return ["is_premium": isPremium, "current_count": currentCount]
        case .paywallView(let triggerPoint):
            return ["trigger_point": triggerPoint]
        case .trialStart(let productId):
            return ["product_id": productId]
        case .purchaseSuccess(let productId, let price, let currency):
            return ["product_id": productId, "price": price, "currency": currency]
        }
    }
}

final class AnalyticsManager {
    static let shared = AnalyticsManager()
    private init() {}

    func log(_ event: AnalyticsEvent) {
        Analytics.logEvent(event.name, parameters: event.parameters)
    }
}
```

### 12.2 実装箇所マッピング

| イベント | 実装ファイル | 実装タイミング |
|---------|-------------|---------------|
| `app_open` | `PRINZApp.swift` | `onAppear` または `scenePhase` 変更時 |
| `onboarding_complete` | `OnboardingView.swift` | 最終ステップ完了時 |
| `reply_generated` | `ReplyGenerator.swift` | API レスポンス受信後 |
| `reply_copied` | `ReplyResultView.swift` | コピーボタンタップ時 |
| `limit_reached` | `UsageManager.swift` | 上限チェック時 |
| `paywall_view` | `PaywallView.swift` | `onAppear` |
| `purchase_success` | `SubscriptionManager.swift` | 購入完了コールバック |

---

## 13. BigQueryクエリ例

### DAU 計算
```sql
SELECT
  event_date,
  COUNT(DISTINCT user_pseudo_id) AS dau
FROM `project.analytics_XXXXXX.events_*`
WHERE event_name = 'app_open'
  AND _TABLE_SUFFIX BETWEEN '20260201' AND '20260228'
GROUP BY event_date
ORDER BY event_date
```

### トーン別利用率
```sql
SELECT
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'tone_type') AS tone_type,
  COUNT(*) AS count
FROM `project.analytics_XXXXXX.events_*`
WHERE event_name = 'reply_copied'
GROUP BY tone_type
```

### 課金ファネル（Paywall → Purchase）
```sql
WITH funnel AS (
  SELECT
    user_pseudo_id,
    MAX(IF(event_name = 'paywall_view', 1, 0)) AS viewed_paywall,
    MAX(IF(event_name = 'trial_start', 1, 0)) AS started_trial,
    MAX(IF(event_name = 'purchase_success', 1, 0)) AS purchased
  FROM `project.analytics_XXXXXX.events_*`
  GROUP BY user_pseudo_id
)
SELECT
  COUNT(*) AS total_users,
  SUM(viewed_paywall) AS paywall_views,
  SUM(started_trial) AS trial_starts,
  SUM(purchased) AS purchases,
  ROUND(SUM(purchased) / NULLIF(SUM(viewed_paywall), 0) * 100, 2) AS paywall_to_purchase_cvr
FROM funnel
WHERE viewed_paywall = 1
```

---

## 更新履歴

| 日付 | 内容 |
|------|------|
| 2026-02-17 | 初版作成 |
| 2026-02-17 | 整合性修正完了（価格330円統一、Premium無制限化、App Storeリンク設定）、Swift実装ガイド・BigQueryクエリ例を追加 |
