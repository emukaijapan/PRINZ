# PRINZ iOS Firebase SDK セットアップガイド (2026-01-27更新)

**最終更新**: 2026-01-27  
**対象**: PRINZ iOSアプリ Firebase連携  
**前提条件**: Cloud Functions (第2世代) デプロイ済み

---

## 📋 事前準備（Mac作業前）

### GoogleService-Info.plist のダウンロード

**Windows/WSL環境で実行:**

```bash
# Firebase Consoleから直接ダウンロード
# または、Firebase CLIでダウンロード
cd /home/emukaijapan/20_PRINZ/PRINZ/firebase
firebase apps:sdkconfig ios > GoogleService-Info.plist
```

**転送方法（いずれか）:**
- GitHub経由（推奨）: プロジェクトにコミット→Mac側でpull
- iCloud Drive
- OneDrive
- AirDrop
- USBメモリ

---

## 🍎 Mac環境での作業手順

### Step 1: Gitリポジトリを最新化

```bash
cd ~/Developer/dev-projects-monorepo/004_PRINZ
git pull
```

**確認ポイント:**
- `PRINZ/firebase/functions/index.js` が第2世代形式になっている
- `PRINZ/firebase/functions/package.json` に `firebase-functions: ^5.0.0` が含まれている

---

### Step 2: GoogleService-Info.plist の配置

#### 2.1 ファイルの確認

```bash
# ファイルが存在するか確認
ls -la ~/Developer/dev-projects-monorepo/004_PRINZ/PRINZ/firebase/GoogleService-Info.plist
```

#### 2.2 PRINZアプリディレクトリにコピー

```bash
cp ~/Developer/dev-projects-monorepo/004_PRINZ/PRINZ/firebase/GoogleService-Info.plist \
   ~/Developer/dev-projects-monorepo/004_PRINZ/PRINZ/PRINZ/
```

**配置先の確認:**
```
004_PRINZ/
└── PRINZ/
    ├── PRINZ/
    │   ├── GoogleService-Info.plist  ← ここに配置
    │   ├── PRINZApp.swift
    │   └── ...
    └── ShareExtension/
```

---

### Step 3: Xcodeプロジェクトを開く

```bash
cd ~/Developer/dev-projects-monorepo/004_PRINZ/PRINZ
open PRINZ.xcodeproj
```

---

### Step 4: Firebase SDK を Swift Package Manager で追加

#### 4.1 パッケージの追加

1. Xcodeメニュー: **File → Add Package Dependencies...**
2. 検索欄に入力:
   ```
   https://github.com/firebase/firebase-ios-sdk
   ```
3. **Dependency Rule**: "Up to Next Major Version" (11.0.0 以上)
4. **Add Package** をクリック

#### 4.2 必要なモジュールを選択

**PRINZターゲット** に以下を追加:
- ✅ **FirebaseAuth**
- ✅ **FirebaseFunctions**
- ✅ **FirebaseFirestore**

**ShareExtensionターゲット** に以下を追加:
- ✅ **FirebaseFunctions**
- ✅ **FirebaseAuth** (認証が必要な場合)

→ **Add Package** をクリック

---

### Step 5: GoogleService-Info.plist をXcodeに追加

#### 5.1 ファイルをプロジェクトに追加

1. Finderで `GoogleService-Info.plist` を選択
2. Xcodeの**プロジェクトナビゲーター**（左サイドバー）を表示
3. `PRINZ/PRINZ/` フォルダに**ドラッグ&ドロップ**

#### 5.2 ターゲット設定

ダイアログで以下を設定:
- ✅ **Copy items if needed**
- **Add to targets**:
  - ✅ **PRINZ**
  - ✅ **ShareExtension**

→ **Finish** をクリック

#### 5.3 確認

プロジェクトナビゲーターで以下を確認:
```
PRINZ/
├── PRINZ/
│   ├── GoogleService-Info.plist  ← 追加されている
│   ├── PRINZApp.swift
│   └── ...
```

ファイルを選択して、右サイドバーの **Target Membership** を確認:
- ✅ PRINZ
- ✅ ShareExtension

---

### Step 6: Firebase初期化コードの確認

#### 6.1 PRINZApp.swift を確認

`PRINZ/PRINZ/PRINZApp.swift` を開いて、以下のコードがあることを確認:

```swift
import SwiftUI
import Firebase

@main
struct PRINZApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

**もし存在しない場合は追加:**

```swift
import Firebase  // ← 追加

@main
struct PRINZApp: App {
    init() {
        FirebaseApp.configure()  // ← 追加
    }
    // ...
}
```

---

### Step 7: ビルド確認

#### 7.1 クリーンビルド

```
Shift + Cmd + K  (Clean Build Folder)
Cmd + B          (Build)
```

#### 7.2 ビルド成功の確認

**エラーがなければ成功！**

コンソール出力例:
```
Build Succeeded
```

---

### Step 8: シミュレーターで動作確認

#### 8.1 シミュレーター起動

```
Cmd + R
```

#### 8.2 コンソール確認

Xcodeのコンソール（下部）で以下を確認:

```
[Firebase/Core][I-COR000003] The default Firebase app has not yet been configured.
[Firebase/Core][I-COR000001] Firebase App initialized
```

**成功の目印:**
- アプリが正常に起動
- クラッシュしない
- `Firebase App initialized` のログが表示される

---

### Step 9: Cloud Functions 呼び出しテスト（オプション）

#### 9.1 テストコードの追加

`ContentView.swift` に以下を追加してテスト:

```swift
import SwiftUI
import FirebaseFunctions

struct ContentView: View {
    @State private var testResult = ""
    
    var body: some View {
        VStack {
            Text("PRINZ")
            Button("Test Cloud Functions") {
                testCloudFunction()
            }
            Text(testResult)
        }
    }
    
    func testCloudFunction() {
        let functions = Functions.functions(region: "asia-northeast1")
        
        let data: [String: Any] = [
            "message": "テストメッセージ",
            "personalType": "ナチュラル系",
            "gender": "男性",
            "ageGroup": "20代後半",
            "relationship": "マッチ直後"
        ]
        
        functions.httpsCallable("generateReply").call(data) { result, error in
            if let error = error {
                testResult = "Error: \(error.localizedDescription)"
                return
            }
            
            if let data = result?.data as? [String: Any],
               let success = data["success"] as? Bool,
               success {
                testResult = "✅ Success!"
            }
        }
    }
}
```

#### 9.2 テスト実行

1. アプリを起動（Cmd + R）
2. "Test Cloud Functions" ボタンをタップ
3. "✅ Success!" が表示されればOK

---

## 🔍 トラブルシューティング

### エラー: "No such module 'Firebase'"

**原因**: Firebase SDKパッケージが正しく追加されていない

**解決策**:
```
File → Packages → Reset Package Caches
```
その後、再ビルド（Cmd + B）

---

### エラー: "GoogleService-Info.plist not found"

**原因**: ファイルがターゲットに追加されていない

**解決策**:
1. Xcodeでファイルを選択
2. 右サイドバーの **Target Membership** を確認
3. **PRINZ** と **ShareExtension** にチェック

---

### エラー: "FirebaseApp.configure() crash"

**原因**: GoogleService-Info.plist の内容が不正

**解決策**:
1. Firebase Consoleから再ダウンロード
2. ファイルの内容を確認（XMLフォーマットであること）
3. プロジェクトIDが `prinz-1f0bf` であることを確認

---

### エラー: "Connection error" (Cloud Functions呼び出し時)

**原因**: 
- ネットワーク接続の問題
- Cloud Functionsのデプロイが完了していない
- リージョン設定が間違っている

**解決策**:
1. リージョンが `asia-northeast1` であることを確認
2. Firebase Consoleで関数が正常にデプロイされていることを確認
3. シミュレーターのネットワーク設定を確認

---

## ✅ 完了チェックリスト

- [ ] Git pull完了
- [ ] GoogleService-Info.plist 配置完了
- [ ] Firebase SDK追加完了（FirebaseAuth, FirebaseFunctions, FirebaseFirestore）
- [ ] GoogleService-Info.plist をXcodeに追加完了
- [ ] PRINZApp.swift に Firebase初期化コード追加
- [ ] ビルド成功
- [ ] シミュレーター起動成功
- [ ] Firebase初期化ログ確認
- [ ] Cloud Functions呼び出しテスト成功（オプション）

---

## 📱 次のステップ: 実機テスト

### 実機テストの準備

1. **Apple Developer アカウント設定**
   - Signing & Capabilities で Team を選択
   - Bundle Identifier を確認

2. **実機接続**
   - iPhoneをMacに接続
   - Xcodeでデバイスを選択

3. **ビルド & 実行**
   - Cmd + R で実機にインストール

4. **Share Extension テスト**
   - 写真アプリでスクリーンショットを開く
   - 共有ボタン → PRINZ を選択
   - OCR → Cloud Functions → 返信案表示を確認

---

## 🔗 参考リンク

- Firebase Console: https://console.firebase.google.com/project/prinz-1f0bf/overview
- Firebase iOS SDK: https://github.com/firebase/firebase-ios-sdk
- Firebase Functions (2nd Gen): https://firebase.google.com/docs/functions/2nd-gen-upgrade

---

**作成者**: Antigravity Agent  
**最終更新**: 2026-01-27
