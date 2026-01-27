# PRINZ AI 連携プロセス修復 - 実装計画

## フェーズ 1: Cloud Functions の修正

### 1.1 index.js の Rate Limit ロジック明確化

**対象ファイル:** `firebase/functions/index.js`

**現在のコード (行 69-92):**
```javascript
if (DEV_MODE) {
  // 開発モード: 認証なしでも許可、デバイスIDまたはランダムIDを使用
  userId = context.auth?.uid || data.deviceId || `dev_${Date.now()}`;
  console.log(`[DEV MODE] User ID: ${userId}`);
  // DEV_MODEではRate Limitingをスキップ
} else {
  // 本番モード: 認証必須
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "認証が必要です"
    );
  }
  userId = context.auth.uid;

  // Rate Limiting チェック（本番のみ）
  const allowed = await checkRateLimit(userId);
  if (!allowed) {
    throw new functions.https.HttpsError(
      "resource-exhausted",
      "本日の利用上限に達しました。プレミアムにアップグレードしてください。"
    );
  }
}
```

**分析:**
- 現在のコードは既に `DEV_MODE` の場合は `checkRateLimit` を呼び出していない
- NOT_FOUND エラーは `checkPremiumStatus` が `users` コレクションを参照していることが原因の可能性

**推奨修正:**
```javascript
// 行 220-229 の checkPremiumStatus を修正
async function checkPremiumStatus(userId) {
  // DEV_MODE では常に false を返す（Firestore 参照をスキップ）
  if (DEV_MODE) {
    return false;
  }
  
  const userRef = db.collection("users").doc(userId);
  const userDoc = await userRef.get();
  
  if (!userDoc.exists) {
    return false;
  }
  
  return userDoc.data().isPremium === true;
}
```

---

### 1.2 OpenAI 接続エラーの解消

**Firebase Console での確認項目:**

1. **ネットワーク出力設定**
   - Firebase Console > Functions > [generateReply] > 詳細
   - 「出力設定」が「すべてのトラフィック」であることを確認
   - 「VPC コネクタのみ」になっている場合、変更が必要

2. **Secret Manager 設定**
   - Firebase Console > Cloud Secret Manager
   - `OPENAI_API_KEY` が存在し、正しい値が設定されているか確認
   - Functions が Secret にアクセスする権限があるか確認

3. **デプロイコマンド確認**
```bash
firebase deploy --only functions --set-secrets OPENAI_API_KEY=OPENAI_API_KEY:latest
```

**OpenAI クライアント設定の追加オプション:**
```javascript
openai = new OpenAI({
  apiKey: apiKey,
  timeout: 30000,
  maxRetries: 2,
  // プロキシ設定（必要な場合）
  // httpAgent: new https.Agent({ rejectUnauthorized: false }),
});
```

---

## フェーズ 2: iOS Share Extension の確認

### 2.1 Signal 9 対策

**分析結果:**
- `ShareViewController.swift` の `generateAIReplies` は既に `Task { }` で非同期化済み
- `unsafeForcedSync` や `semaphore.wait()` は未使用

**確認済みの非同期パターン (行 428-455):**
```swift
private func generateAIReplies(with message: String) {
    guard let context = selectedContext else {
        fallbackToMockReplies()
        return
    }
    
    Task {
        do {
            // Firebase経由でAI返信を生成
            let result = try await FirebaseService.shared.generateReplies(...)
            
            await MainActor.run {
                generatedReplies = result.replies
                DataManager.shared.saveReplies(result.replies)
                currentStep = .results
            }
        } catch {
            await MainActor.run {
                fallbackToMockReplies()
            }
        }
    }
}
```

**ステータス:** ✅ コードは適切に非同期化されている

---

### 2.2 Code=-54 (Permission Denied) 対策

**確認項目:**

1. **App Group 設定**
   - `DataManager.swift` は `group.com.prinz.app` を使用
   - Xcode > [ShareExtension Target] > Signing & Capabilities > App Groups
   - メインアプリと Share Extension で同じ App Group が有効化されているか確認

2. **Entitlements ファイル確認**
   - `ShareExtension/ShareExtension.entitlements`
   - `PRINZ/PRINZ.entitlements`
   - 両方に `com.apple.security.application-groups` が含まれているか確認

3. **FileManager アクセス**
   - `DataManager` が `containerURL(forSecurityApplicationGroupIdentifier:)` のみを使用していることを確認 ✅

---

## デプロイ手順

1. **Cloud Functions のデプロイ**
```bash
cd firebase/functions
npm install
firebase deploy --only functions
```

2. **Firebase Console での確認**
   - Functions ログで API キー取得成功を確認
   - ネットワーク出力設定を確認

3. **iOS アプリのテスト**
   - Xcode でビルド・実行
   - Share Extension から画像を共有
   - AI 返信生成が成功するか確認

---

## 完了条件

- [ ] `DEV_MODE = true` で Firestore NOT_FOUND エラーが発生しない
- [ ] OpenAI API への接続が成功する
- [ ] Share Extension で Signal 9 が発生しない
- [ ] App Group 経由でのデータ共有が正常に動作する
