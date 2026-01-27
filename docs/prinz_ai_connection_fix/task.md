# PRINZ AI 連携プロセスの抜本的修復

## 作成日時
2026-01-25

## 概要
PRINZ アプリの AI 連携機能に関する3つの重要な問題を修正するタスク。

## 修正対象

### 1. Firestore 参照ロジックの修正（NOT_FOUND 対策）
**現状の問題:**
- `DEV_MODE = true` であっても、`checkRateLimit` が Firestore を参照
- 開発時に不要な DB 依存が発生

**修正内容:**
- `generateReply` 内の `checkRateLimit` 呼び出し部分を以下に修正:
```javascript
const allowed = DEV_MODE ? true : await checkRateLimit(userId);
```

**対象ファイル:**
- `firebase/functions/index.js`

**ステータス:** ✅ 分析完了・修正準備完了
- 現在の `index.js` を確認済み
- 行69-92にて DEV_MODE 分岐で Rate Limiting 自体はスキップされているが、明示的な条件を追加する

---

### 2. OpenAI への Connection Error の解消
**現状の問題:**
- `getOpenAIClient` にて API キー取得は成功しているが、通信が遮断されている

**確認事項:**
- Firebase Console > Functions > ネットワーク設定にて「出力設定」が「すべてのトラフィック」になっているか確認
- デプロイコマンドに `--set-secrets OPENAI_API_KEY=OPENAI_API_KEY:latest` を含めて環境変数が正確にインスタンスへ注入されているか再監査

**対象ファイル:**
- `firebase/functions/index.js` (secrets 設定は既存)
- デプロイ設定

**ステータス:** ⏳ Firebase Console での確認が必要

---

### 3. Share Extension の Signal 9 対策（iOS）
**現状の問題:**
- `unsafeForcedSync` によるメインスレッド拘束（Signal 9 / システムキル）
- `Code=-54 (permission denied)` エラー

**修正内容:**
- AI 生成の通信処理を async/await ベースの非同期処理に刷新
- Extension ターゲットの DataManager が App Group 以外の領域にアクセスしていないか厳査

**対象ファイル:**
- `ShareExtension/ShareViewController.swift`
- `PRINZ/Shared/Services/DataManager.swift`

**分析結果:**
- `unsafeForcedSync` は検出されず ✅
- `semaphore` や `DispatchGroup.wait()` は検出されず ✅
- `ShareViewController.swift` の `generateAIReplies` は既に `Task { }` + `async/await` で実装済み ✅
- `DataManager.swift` は App Group (`group.com.prinz.app`) のみを使用 ✅

**ステータス:** ✅ コードレベルでは既に非同期化されている可能性が高い
- 実機テストでの Signal 9 発生有無を要確認
- `Code=-54` は App Group の設定ミスが原因の可能性

---

## 次のアクション

1. **index.js の軽微修正**
   - Rate Limit チェックの条件を明示化（すでにスキップされているが安全のため）

2. **Firebase Console 確認**
   - ネットワーク出力設定を「すべてのトラフィック」に
   - Secret Manager から OPENAI_API_KEY が正しく参照されているか確認

3. **iOS 実機テスト**
   - Share Extension で Signal 9 が発生するか確認
   - App Group 設定（Xcode の Capabilities）を確認
