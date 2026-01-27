# Firebase セットアップガイド

## 概要

PRINZアプリは、セキュリティのためFirebase Cloud Functions経由でOpenAI APIを呼び出します。

```
[iOSアプリ] → [Firebase Functions] → [OpenAI API]
                    ↓
              ・APIキー秘匿
              ・Rate Limiting（1日5回無料）
              ・ユーザー認証
```

---

## 1. Firebase プロジェクト作成

1. [Firebase Console](https://console.firebase.google.com/) にアクセス
2. 「プロジェクトを作成」をクリック
3. プロジェクト名: `prinz-app`
4. Google Analytics: 有効化を推奨

---

## 2. Firebaseサービスの有効化

### 2.1 Authentication
1. Firebase Console → Authentication
2. 「始める」をクリック
3. 「Sign-in method」タブで以下を有効化:
   - **Apple** （App Store審査に必須）
   - Email/Password（開発用）

### 2.2 Firestore Database
1. Firebase Console → Firestore Database
2. 「データベースを作成」
3. 本番環境モード → 東京リージョン（asia-northeast1）

### 2.3 Cloud Functions
1. **Blazeプラン（従量課金）**へのアップグレードが必要
2. Firebase Console → Functions → 「始める」

---

## 3. OpenAI APIキーの設定

```bash
cd firebase/functions

# Firebase CLIでシークレットを設定
firebase functions:secrets:set OPENAI_API_KEY
# プロンプトが表示されたらAPIキーを入力
```

---

## 4. Cloud Functionsのデプロイ

```bash
cd firebase/functions

# 依存関係インストール
npm install

# デプロイ
firebase deploy --only functions
```

---

## 5. iOS側の設定

### 5.1 Firebase SDKの追加

Xcode → File → Add Package Dependencies:
```
https://github.com/firebase/firebase-ios-sdk
```

追加するモジュール:
- FirebaseAuth
- FirebaseFunctions
- FirebaseFirestore

### 5.2 GoogleService-Info.plist

1. Firebase Console → プロジェクト設定 → iOSアプリを追加
2. Bundle ID: `com.prinz.app`
3. `GoogleService-Info.plist` をダウンロード
4. Xcodeプロジェクトに追加

### 5.3 AppDelegateでの初期化

```swift
import Firebase

@main
struct PRINZApp: App {
    init() {
        FirebaseApp.configure()
    }
    // ...
}
```

---

## 6. Rate Limiting設定

`firebase/functions/index.js` で以下を調整:

```javascript
const DAILY_FREE_LIMIT = 5;   // 無料ユーザー
const PREMIUM_LIMIT = 100;    // プレミアムユーザー
```

---

## 7. 課金連携（将来）

プレミアム判定は `users/{userId}.isPremium` で管理:

```javascript
// Cloud Functionsでの判定
async function checkPremiumStatus(userId) {
  const userDoc = await db.collection("users").doc(userId).get();
  return userDoc.data()?.isPremium === true;
}
```

StoreKit 2 でサブスクリプション購入後、Firestoreを更新する仕組みを実装予定。

---

## ファイル構成

```
firebase/
├── .firebaserc          # プロジェクト設定
├── firebase.json         # Firebase設定
├── firestore.rules       # セキュリティルール
├── firestore.indexes.json
└── functions/
    ├── package.json
    └── index.js          # Cloud Functions
```
