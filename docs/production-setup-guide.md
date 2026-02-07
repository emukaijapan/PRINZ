# PRINZ 商用化セットアップガイド

> Apple Developer登録完了後の手順書

## 前提条件

- [x] Apple Developer Program 登録完了
- [x] お問い合わせ: Googleフォーム（メールアドレス非公開）
- [ ] 本番用Firebaseプロジェクト確認

---

## Phase 1: App Store Connect 設定

### 1.1 アプリ登録

1. [App Store Connect](https://appstoreconnect.apple.com/) にログイン
2. 「マイApp」→「+」→「新規App」
3. 以下を入力:
   - **プラットフォーム**: iOS
   - **名前**: PRINZ
   - **プライマリ言語**: 日本語
   - **バンドルID**: `com.mgolworks.prinz`（Xcodeと一致させる）
   - **SKU**: `prinz-ios-001`

### 1.2 アプリ情報設定

| 項目 | 値 |
|------|-----|
| サブタイトル | 既読のまま、終わらせない。 |
| カテゴリ | ライフスタイル（プライマリ）/ ソーシャルネットワーキング（セカンダリ） |
| 年齢制限 | 17+ |
| プライバシーポリシーURL | `https://prinz-1f0bf.web.app/privacy-policy.html` |
| サポートURL | `https://prinz-1f0bf.web.app/support.html` |
| マーケティングURL | `https://prinz-1f0bf.web.app/` |

---

## Phase 2: App内課金（IAP）商品登録

### 2.1 商品作成

App Store Connect → 「マイApp」→ 「PRINZ」→ 「App内課金」→ 「管理」

#### 週額プラン
| 項目 | 値 |
|------|-----|
| 参照名 | Premium Weekly |
| 製品ID | `com.mgolworks.prinz.premium.weekly` |
| タイプ | 自動更新サブスクリプション |
| サブスクリプショングループ | Premium |
| 価格 | ¥480/週（ローンチ価格: ¥240） |
| 無料トライアル | 3日間 |

#### 年額プラン
| 項目 | 値 |
|------|-----|
| 参照名 | Premium Yearly |
| 製品ID | `com.mgolworks.prinz.premium.yearly` |
| タイプ | 自動更新サブスクリプション |
| サブスクリプショングループ | Premium |
| 価格 | ¥9,800/年（ローンチ価格: ¥4,900） |
| 無料トライアル | 3日間 |

### 2.2 ローカライズ（日本語）

各商品に以下を設定:
- **表示名**: Premium（週額）/ Premium（年額）
- **説明**: 1日100回まで返信生成、全機能アンロック

### 2.3 審査用情報

- **スクリーンショット**: 課金画面のスクショを添付
- **審査メモ**: 「サブスクリプションでAI返信生成回数が増加します」

---

## Phase 3: RevenueCat 設定

### 3.1 アカウント作成

1. [RevenueCat](https://www.revenuecat.com/) にアクセス
2. **商用メールアドレス**でアカウント作成
3. プロジェクト作成: `PRINZ`

### 3.2 App Store Connect 連携

1. RevenueCat Dashboard → 「Apps」→ 「+ New」
2. プラットフォーム: **App Store**
3. **App Bundle ID**: `com.mgolworks.prinz`
4. **App Store Connect API Key** を作成して設定:
   - App Store Connect → 「ユーザとアクセス」→ 「キー」→ 「App Store Connect API」
   - 「+」→ 名前: `RevenueCat`、アクセス: Admin
   - キーをダウンロード（.p8）
   - Issuer ID、Key ID、.p8ファイルをRevenueCatに入力

### 3.3 Public API Key 取得

1. RevenueCat → Project Settings → API Keys
2. **Public app-specific API key** をコピー
3. Xcodeの `Info.plist` に設定:
   ```xml
   <key>REVENUECAT_API_KEY</key>
   <string>appl_XXXXXXXXXXXXXXXXX</string>
   ```

### 3.4 Entitlement 作成

1. RevenueCat → Entitlements → 「+ New」
2. **Identifier**: `premium`
3. 商品を紐付け:
   - `com.mgolworks.prinz.premium.weekly`
   - `com.mgolworks.prinz.premium.yearly`

### 3.5 Webhook 設定（Firebase連携）

1. RevenueCat → Integrations → Webhooks
2. URL: `https://asia-northeast1-prinz-1f0bf.cloudfunctions.net/revenueCatWebhook`
3. Authorization Header: `Bearer YOUR_SECRET_KEY`（Firebaseで設定したキー）

---

## Phase 4: Xcode プロジェクト設定

### 4.1 Bundle ID 確認

- **Target → General → Bundle Identifier**: `com.mgolworks.prinz`
- App Store Connectと一致させる

### 4.2 Signing & Capabilities

1. **Team**: 新しいApple Developer アカウントを選択
2. **Signing Certificate**: 自動管理をON
3. Capabilities追加:
   - **In-App Purchase**
   - **Sign in with Apple**

### 4.3 RevenueCat SDK確認

SPM（Swift Package Manager）:
```
https://github.com/RevenueCat/purchases-ios.git
```

### 4.4 Info.plist 更新

```xml
<key>REVENUECAT_API_KEY</key>
<string>appl_YOUR_ACTUAL_KEY</string>
```

---

## Phase 5: Firebase 設定確認

### 5.1 GoogleService-Info.plist

- 既存の `prinz-1f0bf` プロジェクトを継続使用
- 変更不要（メールアドレスとは独立）

### 5.2 Firebase Hosting デプロイ

```bash
cd ~/20_PRINZ/firebase
firebase deploy --only hosting
```

確認URL:
- https://prinz-1f0bf.web.app/
- https://prinz-1f0bf.web.app/privacy-policy.html
- https://prinz-1f0bf.web.app/support.html
- https://prinz-1f0bf.web.app/terms.html

---

## Phase 6: テスト

### 6.1 Sandbox テスター作成

1. App Store Connect → 「ユーザとアクセス」→ 「Sandbox」→ 「テスター」
2. **新しいテスター追加**（実在しないメールでOK）
3. iPhoneの「設定」→「App Store」→「Sandboxアカウント」にログイン

### 6.2 課金テスト

1. Xcodeから実機にインストール
2. Sandboxアカウントでサインイン
3. 課金フローをテスト（実際の請求はなし）

---

## Phase 7: 審査提出

### 7.1 アーカイブ & アップロード

```
Xcode → Product → Archive → Distribute App → App Store Connect
```

### 7.2 審査提出前チェックリスト

- [ ] スクリーンショット 6枚（6.7インチ用）
- [ ] アプリアイコン設定
- [ ] プライバシーポリシーURL設定
- [ ] サポートURL設定
- [ ] App内課金商品が「送信準備完了」
- [ ] 年齢制限 17+
- [ ] 審査メモ記入

### 7.3 審査メモ例

```
PRINZはLINEやマッチングアプリのチャット返信をAIが提案するアプリです。

【テスト方法】
1. アプリを起動し、Apple IDでサインイン
2. ホーム画面でスクショをアップロード
3. トーンを選択してAI返信を生成

【課金について】
- Free: 5回/日
- Premium: 100回/日（週480円 or 年9,800円）
- 3日間無料トライアルあり
```

---

## クイックリファレンス

### 重要なID

| 項目 | 値 |
|------|-----|
| Bundle ID | `com.mgolworks.prinz` |
| App Group | `group.com.mgolworks.prinz` |
| Firebase Project | `prinz-1f0bf` |
| Weekly Product ID | `com.mgolworks.prinz.premium.weekly` |
| Yearly Product ID | `com.mgolworks.prinz.premium.yearly` |
| Entitlement ID | `premium` |

### 重要なURL

| 項目 | URL |
|------|-----|
| App Store Connect | https://appstoreconnect.apple.com/ |
| RevenueCat | https://app.revenuecat.com/ |
| Firebase Console | https://console.firebase.google.com/project/prinz-1f0bf |
| LP | https://prinz-1f0bf.web.app/ |
| プライバシーポリシー | https://prinz-1f0bf.web.app/privacy-policy.html |
| サポート | https://prinz-1f0bf.web.app/support.html |

---

## トラブルシューティング

### RevenueCat「商品が見つからない」

1. App Store Connectで商品ステータスが「送信準備完了」か確認
2. Bundle IDが一致しているか確認
3. Sandboxテスターでサインインしているか確認

### 課金が反映されない

1. RevenueCat Dashboardで購入イベントを確認
2. Entitlementに商品が紐付いているか確認
3. `SubscriptionManager.swift` の API Key が正しいか確認

---

*最終更新: 2026年2月6日*
