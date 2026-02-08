# PRINZ

既読のまま、終わらせない。

LINEやマッチングアプリのスクリーンショットからAI返信案を生成するiOSアプリ。

---

## 概要

PRINZは、Share ExtensionとVision Frameworkを使ったOCRベースの返信案生成アプリ。
スクリーンショットを共有するだけで、3つのトーン（安牌・ちょい攻め・変化球）で返信案を提示する。

---

## 機能一覧

| 機能 | 説明 |
|------|------|
| チャット返信生成 | LINEトーク画面のスクショからAI返信案を3パターン生成 |
| プロフィール挨拶生成 | マッチングアプリのプロフィール画面から初回メッセージを生成 |
| テキスト入力 | スクショ不要、テキスト直接入力で返信生成 |
| Share Extension | 写真アプリやLINEから直接共有して処理 |
| トーン選択 | 安牌 / ちょい攻め / 変化球 の3カテゴリ |
| 長さ選択 | 短文（30文字以内）/ 長文（50〜80文字） |
| フォーカス指定 | 「触れてほしい話題」をユーザーが指定可能 |
| コピー&履歴 | タップでコピー、最大30件の履歴保存 |
| サブスクリプション | 無料5回/日、プレミアム100回/日（RevenueCat） |
| オンボーディング | 初回起動時6ステップのチュートリアル+設定 |

---

## 技術スタック

| カテゴリ | 技術 |
|---------|------|
| 言語 | Swift 5.9+ |
| UI | SwiftUI (iOS 17+) |
| OCR | Vision Framework (ja-JP, en-US) |
| AI | OpenAI GPT-4o-mini (Firebase Functions経由) |
| Backend | Firebase Cloud Functions (Node.js 20, asia-northeast1) |
| DB | Firestore (利用回数・プレミアムステータス管理) |
| 課金 | RevenueCat |
| プロセス間共有 | App Groups (`group.com.prinz.app`) |

---

## アーキテクチャ

```
[iOS App / Share Extension]
    │
    ├─ Vision Framework (オンデバイスOCR)
    │     ├─ ChatParser (トーク画面解析、座標ベース左右判定)
    │     └─ ProfileParser (プロフィール情報抽出)
    │
    ├─ FirebaseService (API Client)
    │     └─ httpsCallable("generateReply")
    │
    └─ App Group (UserDefaults + JSON + 画像共有)

[Firebase Cloud Functions]
    │
    ├─ generateReply (onCall)
    │     ├─ 認証チェック (Firebase Auth)
    │     ├─ Rate Limiting (Firestore)
    │     ├─ プロンプト生成 (パーソナルタイプ/性別/年代に応じた動的構築)
    │     └─ OpenAI GPT-4o-mini → JSON形式で3パターン返信
    │
    └─ handleRevenueCatWebhook (onRequest)
          └─ Firestore users/{userId}.isPremium 更新
```

---

## ディレクトリ構成

```
20_PRINZ/
├── PRINZ/
│   ├── PRINZApp.swift               # エントリポイント (Firebase/RevenueCat初期化)
│   ├── ContentView.swift            # タブビュー (ホーム/テキスト入力/履歴/設定)
│   │
│   ├── Views/
│   │   ├── HomeView.swift           # メイン画面 (写真選択→OCR→トーン選択→結果)
│   │   ├── ReplyResultView.swift    # AI返信表示 (タイピングアニメーション/カスタマイズ)
│   │   ├── ReplyCustomizeView.swift # トーンタグ再選択UI
│   │   ├── ManualInputView.swift    # テキスト入力モード
│   │   ├── HistoryView.swift        # 履歴一覧
│   │   ├── SettingsView.swift       # ユーザー設定
│   │   ├── OnboardingView.swift     # 初回チュートリアル (6ステップ)
│   │   └── PaywallView.swift        # 課金UI (RevenueCat)
│   │
│   ├── Shared/
│   │   ├── Models/
│   │   │   ├── Context.swift        # 会話状況 (マッチ直後/デート打診/脈あり確認/日常/デート後/フォロー)
│   │   │   ├── PersonalType.swift   # 性格10種 (知的/熱血/優しい/おもしろ/クール/誠実/アクティブ/シャイ/ミステリアス/ナチュラル)
│   │   │   ├── Reply.swift          # 返信データ + ReplyType (safe/chill/witty)
│   │   │   ├── ToneTag.swift        # トーンタグEnum
│   │   │   └── UserAttributes.swift # UserGender / UserAgeGroup
│   │   └── Services/
│   │       ├── FirebaseService.swift      # Cloud Functions APIクライアント
│   │       ├── OCRService.swift           # Vision Framework OCR (バックグラウンド処理)
│   │       ├── ChatParser.swift           # チャット画面OCRテキスト解析 (座標ベース)
│   │       ├── ProfileParser.swift        # プロフィール情報抽出 (名前/年齢/趣味/自己紹介)
│   │       ├── DataManager.swift          # ローカル履歴管理 (JSON, シリアルキュー)
│   │       ├── SharedImageManager.swift   # App Group画像共有
│   │       ├── SubscriptionManager.swift  # RevenueCat課金管理
│   │       ├── ReplyGenerator.swift       # モック返信生成 (フォールバック)
│   │       ├── OpenAIService.swift        # OpenAI直接呼び出し (開発用)
│   │       └── PromptFactory.swift        # プロンプト生成
│   │
│   ├── DesignSystem/
│   │   ├── Color+Extensions.swift   # カラーパレット (ネオンパープル/シアン/グラス)
│   │   ├── GlassCard.swift          # ガラスモーフィズムカード
│   │   ├── NeonButtonStyle.swift    # ネオンボタン
│   │   ├── SkeletonLoaderView.swift # ローディングUI
│   │   └── TypingTextView.swift     # タイピングアニメーション
│   │
│   ├── PRINZ.entitlements           # App Groups
│   └── GoogleService-Info.plist     # Firebase設定
│
├── ShareExtension/
│   ├── ShareViewController.swift    # Share Extension本体 (Firebase初期化/OCR/AI生成)
│   └── Views/
│       ├── ContextSelectionView.swift   # 状況選択UI
│       ├── ReplyOptionsView.swift       # 返信表示UI
│       └── ScanningAnimationView.swift  # 解析中アニメーション
│
├── firebase/
│   ├── functions/
│   │   ├── index.js                 # Cloud Functions (generateReply / handleRevenueCatWebhook)
│   │   └── package.json             # Node.js 20, firebase-functions 5, openai 4
│   ├── firestore.rules
│   └── firebase.json
│
└── docs/                            # 開発ドキュメント
```

---

## データフロー

### チャット返信生成

```
写真選択 → OCRService.recognizeTextWithCoordinates()
         → ChatParser.parseWithCoordinates()
             ├── 座標ベースで左(相手)/右(自分)を分離
             ├── 相手の名前を抽出
             └── 直近の自分の発言を抽出
         → FirebaseService.generateReplies()
             └── Cloud Functions → OpenAI GPT-4o-mini
         → ReplyResultView (3パターン表示 + タイピングアニメーション)
         → タップでコピー + 履歴保存
```

### プロフィール挨拶生成

```
写真選択 → OCRService.recognizeText()
         → ProfileParser.parse()
             └── 年齢/居住地/趣味/自己紹介を抽出
         → FirebaseService.generateReplies(mode: "profileGreeting")
         → ReplyResultView
```

---

## 環境変数・シークレット

| キー | 管理場所 | 用途 |
|------|---------|------|
| `OPENAI_API_KEY` | Firebase Secret | Cloud Functionsで使用 |
| `REVENUECAT_API_KEY` | Xcode Build Settings → Info.plist | RevenueCat SDK初期化 |

---

## セットアップ

### 1. Firebase

```bash
cd firebase/functions
npm install

# ローカル実行
firebase emulators:start

# デプロイ
firebase deploy --only functions
```

### 2. Xcode

1. `PRINZ.xcodeproj` を開く
2. SPMで以下を追加:
   - `firebase-ios-sdk`
   - `purchases-ios` (RevenueCat)
3. 両ターゲット (PRINZ, ShareExtension) で App Groups を有効化: `group.com.prinz.app`
4. Build Settings > User-Defined に `REVENUECAT_API_KEY` を設定
5. Info.plist に `<key>REVENUECAT_API_KEY</key><string>$(REVENUECAT_API_KEY)</string>` を追加
6. `GoogleService-Info.plist` を両ターゲットに含める

### 3. RevenueCat

1. RevenueCat Dashboardでプロジェクト作成
2. Entitlement `premium` を作成
3. App Store Connect で商品IDを登録
4. Webhook URLをCloud Functions のエンドポイントに設定

---

## Free vs Premium

| | Free | Premium |
|---|---|---|
| 1日の利用回数 | 5回 | 100回 |
| チャット返信 | 可 | 可 |
| あいさつ作成 | 可 | 可 |
| トーン選択 | 可 | 可 |

### 価格設定
- 週額: 480円 (ローンチ: 240円)
- 年額: 9,800円 (ローンチ: 4,900円)
- トライアル: 3日間無料

---

## セキュリティ

- **OCRはオンデバイス処理** — 画像はサーバーに送信しない
- **Cloud Functions経由のAI呼び出し** — OpenAI APIキーはクライアントに露出しない
- **Firebase認証必須** (DEV_MODE=false)
- **Rate Limiting** — Firestoreで利用回数を管理
- **デバッグログ** — `#if DEBUG` でリリースビルドでは出力・永続化しない
- **APIキー管理** — Info.plist (Build Settings経由)、ハードコードなし

---

## デザイン

- **テーマ**: ゲーミングPC x 魔法の鏡
- **背景**: Magic Gradient (深紫→ローズピンク)
- **アクセント**: ネオンパープル (#D000FF) / ネオンシアン (#00FFFF)
- **エフェクト**: ガラスモーフィズム (UltraThinMaterial + グラデーション)
- **アニメーション**: タイピングテキスト、BOX順次出現、スケルトンローダー

---

## 状態管理

| データ | 保存先 | スコープ |
|--------|-------|---------|
| ユーザー設定 (性別/年齢/パーソナルタイプ) | UserDefaults (AppGroup) | Main + ShareExt |
| オンボーディング完了フラグ | UserDefaults (AppGroup) | Main + ShareExt |
| 返信履歴 (最大30件) | JSON (AppGroup Container) | Main + ShareExt |
| サブスク状態 | RevenueCat → メモリ | Main App |
| デバッグログ (DEBUGのみ) | UserDefaults (AppGroup) | ShareExt |

---

## Cloud Functions API

### generateReply (onCall)

**リクエスト:**
```json
{
  "message": "相手のメッセージ",
  "personalType": "ナチュラル系",
  "gender": "男性",
  "ageGroup": "20代後半",
  "relationship": "マッチ直後",
  "partnerName": "相手の名前 (optional)",
  "userMessage": "ユーザーの意図 (optional)",
  "replyLength": "short | long",
  "selectedTone": "safe | aggressive | unique (optional)",
  "mode": "chatReply | profileGreeting",
  "profileInfo": { ... }
}
```

**レスポンス:**
```json
{
  "success": true,
  "replies": [
    { "type": "safe", "text": "返信テキスト", "reasoning": "解説" },
    { "type": "aggressive", "text": "...", "reasoning": "..." },
    { "type": "unique", "text": "...", "reasoning": "..." }
  ],
  "remainingToday": 4
}
```

### handleRevenueCatWebhook (onRequest)

RevenueCatからのイベント (INITIAL_PURCHASE, RENEWAL, CANCELLATION, EXPIRATION等) を受信し、Firestore `users/{userId}.isPremium` を更新。
