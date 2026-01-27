# PRINZ AI回答品質改善セッション

**日付**: 2026-01-27  
**ステータス**: 実装完了、Mac側でのXcode設定が残っている

---

## 🎯 セッション目標

PRINZアプリのAI回答品質を改善し、UI/UXを向上させる。

---

## ✅ 完了した実装（WSL側）

### 1. ChatParser.swift 追加 ⭐
- **パス**: `PRINZ/Shared/Services/ChatParser.swift`
- **機能**:
  - OCRテキストから相手の名前を自動抽出
  - 日時情報（`20:30`, `既読 20:30`など）を除去
  - システムメッセージ（`既読`, `送信取消`など）をスキップ
  - 相手/自分のメッセージを識別

### 2. FirebaseService.swift 更新
- **パラメータ追加**:
  - `partnerName: String?` - 相手の名前
  - `userMessage: String?` - ユーザーの意図
  - `isShortMode: Bool` - 短文/長文モード（デフォルト: true）

### 3. ReplyResultView.swift 更新
- ChatParser使用でOCRテキストを解析
- 相手のメッセージのみを抽出してAPIに送信
- `isShortMode`, `mainMessage` をAPIに送信

### 4. ShareViewController.swift 更新
- **UI改善**: シチュエーション選択を2列グリッドに変更（枠超え解消）
- **ChatParser使用**: テキスト解析
- **新機能**: 「メインアプリで続ける」ボタン追加

### 5. Cloud Functions (index.js) 更新
- **パラメータ対応**: `partnerName`, `userMessage`, `replyLength`
- **プロンプト改善**:
  - システムプロンプトに会話分析手順を追加
  - ユーザープロンプトに相手の名前と意図を反映
  - 長文/短文の指示を動的に変更（`replyLength === "long"` ? "3〜5文" : "1〜3文"）

### 6. フォルダ構造修正
- **変更前**: `20_PRINZ/PRINZ/PRINZ/` （3階層）
- **変更後**: `20_PRINZ/PRINZ/` （2階層）
- Mac側のXcodeプロジェクトと構造を統一

---

## 🚀 デプロイ状況

### Cloud Functions
- ✅ デプロイ完了（2026-01-27 22:50頃）
- リージョン: `asia-northeast1`
- ランタイム: Node.js 20 (2nd Gen)

### GitHub
- ✅ リポジトリ: `https://github.com/emukaijapan/PRINZ.git`
- ✅ 最新コミット: `d410702` (security: GoogleService-Info.plistをGit管理から除外)
- ✅ 前コミット: `1b6e3a8` (refactor: フォルダ構造を修正)
- ✅ 前々コミット: `9872f71` (feat: AI回答品質改善 - ChatParser追加と全機能実装)

---

## ⚠️ 残っている作業（Mac側）

### 1. GoogleService-Info.plist の配置
- **場所**: `firebase/GoogleService-Info.plist` または `PRINZ/GoogleService-Info.plist`
- **手順**:
  ```bash
  cd /Users/emukaijapan/01_Dev/PRINZ
  cp firebase/GoogleService-Info.plist PRINZ/
  ```

### 2. Xcodeでの設定
1. **GoogleService-Info.plistを追加**
   - Project Navigator で `PRINZ` フォルダを右クリック
   - `Add Files to "PRINZ"...`
   - `GoogleService-Info.plist` を選択
   - ✅ `Copy items if needed` にチェック
   - ✅ Targets: `PRINZ` と `ShareExtension` の両方にチェック

2. **ChatParser.swiftを追加**
   - Project Navigator で `PRINZ/Shared/Services` を右クリック
   - `Add Files to "PRINZ"...`
   - `ChatParser.swift` を選択
   - ✅ Targets: `PRINZ` と `ShareExtension` の両方にチェック

3. **ビルド確認**
   ```
   Cmd + B
   ```

### 3. Git同期
```bash
cd /Users/emukaijapan/01_Dev/PRINZ
git pull origin main
```

---

## 🔍 テスト項目（次回セッション）

### 1. シチュエーション選択UI
- ShareExtensionで画像を共有
- シチュエーション選択が2列グリッドになっているか
- 枠がはみ出していないか

### 2. 長文/短文切り替え
- メインアプリで「短文」「長文」ボタンをタップ
- AI回答の長さが変わるか

### 3. 相手の名前抽出
- LINEスクリーンショットを共有
- ログで相手の名前が抽出されているか
- 例: `Partner Name: 田中`

### 4. メインアプリへの遷移
- ShareExtensionで「メインアプリで続ける」ボタンをタップ
- メインアプリが開くか

### 5. AI回答の品質
- 相手のメッセージに対する返信が自然か
- キーワードを活かしているか
- 質問に答えているか

---

## 📊 技術詳細

### プロジェクト構造
```
20_PRINZ/
  ├── PRINZ/
  │   ├── Shared/
  │   │   ├── Models/
  │   │   └── Services/
  │   │       ├── ChatParser.swift (新規)
  │   │       ├── FirebaseService.swift (更新)
  │   │       └── ...
  │   └── Views/
  │       └── ReplyResultView.swift (更新)
  ├── ShareExtension/
  │   └── ShareViewController.swift (更新)
  ├── firebase/
  │   └── functions/
  │       └── index.js (更新)
  ├── docs/
  ├── memories/
  └── TODO.md
```

### Firebase設定
- **プロジェクトID**: `prinz-1f0bf`
- **Bundle ID**: `com.prinz.PRINZ`
- **API Key**: `AIzaSyAt18rKevLIIr1QoGOMJ3rKK23WBnvP5nI`
- **Secret Manager**: `OPENAI_API_KEY` (バージョン3)

---

## 🐛 既知の問題

### 1. Xcodeでファイルが赤色表示
- **原因**: フォルダ構造変更後、Xcodeがファイルを見つけられない
- **解決策**: Mac側で `git pull` 後、Xcodeでファイルを再追加

### 2. GoogleService-Info.plist が見つからない
- **原因**: Gitから除外したため、Mac側にファイルがない
- **解決策**: `firebase/GoogleService-Info.plist` を `PRINZ/` にコピーしてXcodeに追加

---

## 📝 次回セッションの開始手順

1. **Mac側でGit同期**
   ```bash
   cd /Users/emukaijapan/01_Dev/PRINZ
   git pull origin main
   ```

2. **GoogleService-Info.plistを配置**
   ```bash
   cp firebase/GoogleService-Info.plist PRINZ/
   ```

3. **Xcodeで設定**
   - GoogleService-Info.plist を追加
   - ChatParser.swift を追加
   - ビルド確認

4. **実機テスト**
   - 上記のテスト項目を実施
   - フィードバックを収集

---

## 🎉 成果

- ✅ ChatParser実装完了
- ✅ API連携強化（3つの新パラメータ）
- ✅ UI改善（2列グリッド、メインアプリ遷移ボタン）
- ✅ Cloud Functions改善（プロンプト改善、長文/短文対応）
- ✅ フォルダ構造統一
- ✅ GitHubにpush完了
- ✅ セキュリティ対応（GoogleService-Info.plist除外）

**推定作業時間**: 約2時間
