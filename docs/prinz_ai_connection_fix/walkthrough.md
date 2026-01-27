# PRINZ AI 連携プロセス修復 - ウォークスルー

## 実施日時
2026-01-25

## 修正内容のサマリ

### 1. Cloud Functions の修正

#### 1.1 `checkPremiumStatus` 関数の DEV_MODE 対応

**ファイル:** `firebase/functions/index.js`

**変更内容:**
`checkPremiumStatus` 関数に DEV_MODE チェックを追加し、開発モード時は Firestore の `users` コレクションへのアクセスをスキップするように修正しました。

**変更前:**
```javascript
async function checkPremiumStatus(userId) {
  const userRef = db.collection("users").doc(userId);
  const userDoc = await userRef.get();

  if (!userDoc.exists) {
    return false;
  }

  return userDoc.data().isPremium === true;
}
```

**変更後:**
```javascript
async function checkPremiumStatus(userId) {
  // DEV_MODEでは Firestore 参照をスキップ（NOT_FOUND 対策）
  if (DEV_MODE) {
    console.log(`[DEV MODE] Skipping premium status check for: ${userId}`);
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

**影響範囲:**
- `checkRateLimit` 関数（`checkPremiumStatus` を呼び出し）
- `getRemainingCount` 関数（`checkPremiumStatus` を呼び出し）

これにより、`DEV_MODE = true` の場合、Firestore の `users` コレクションが未作成でも NOT_FOUND エラーが発生しなくなります。

---

### 2. Share Extension の分析結果

#### 2.1 Signal 9 対策

**ファイル:** `ShareExtension/ShareViewController.swift`

**分析結果:**
- `unsafeForcedSync` は使用されていない ✅
- `semaphore.wait()` や `DispatchGroup.wait()` は使用されていない ✅
- AI 通信処理は既に `Task { }` + `async/await` で非同期化されている ✅

**現在の実装（行 428-455）:**
```swift
private func generateAIReplies(with message: String) {
    Task {
        do {
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

**結論:** コードレベルでは問題なし。実機での Signal 9 発生は別の原因（メモリ不足、Extension のタイムアウトなど）の可能性あり。

---

#### 2.2 Code=-54 (Permission Denied) 対策

**ファイル:** `PRINZ/Shared/Services/DataManager.swift`

**分析結果:**
- App Group identifier: `group.com.prinz.app`
- `containerURL(forSecurityApplicationGroupIdentifier:)` のみを使用 ✅
- App Group 外の領域へのアクセスなし ✅

**確認が必要な項目:**
1. Xcode の Signing & Capabilities で App Groups が有効化されているか
2. メインアプリと Share Extension で同じ App Group が設定されているか
3. Provisioning Profile に App Group が含まれているか

---

## 残作業

### Firebase Console での確認
- [ ] Functions > [generateReply] > ネットワーク出力設定 = 「すべてのトラフィック」
- [ ] Secret Manager > OPENAI_API_KEY が正しく設定されている

### デプロイ
- [ ] `firebase deploy --only functions` を実行

### iOS テスト
- [ ] 実機で Share Extension をテスト
- [ ] Signal 9 が発生しないことを確認
- [ ] AI 返信生成が成功することを確認

---

## 注意事項

1. **本番リリース時:** `DEV_MODE = false` に変更し、Firestore に `users` コレクションを作成する必要があります
2. **OpenAI 接続エラー:** Firebase Console でのネットワーク設定確認が必要です（コード修正では解決できない可能性あり）
