# PRINZ iOS Firebase SDK セットアップ - Mac作業手順

**実行日**: 2026-01-27  
**所要時間**: 約15分

---

## 📋 事前確認

✅ Cloud Functions (第2世代) デプロイ済み  
✅ GoogleService-Info.plist ダウンロード済み  
✅ Mac環境でXcodeインストール済み

---

## 🚀 作業手順（Mac）

### 1. Gitリポジトリを最新化

```bash
cd ~/Developer/dev-projects-monorepo/004_PRINZ
git pull
```

---

### 2. GoogleService-Info.plist を配置

```bash
# firebaseフォルダから PRINZアプリディレクトリにコピー
cp PRINZ/firebase/GoogleService-Info.plist PRINZ/PRINZ/
```

**確認:**
```bash
ls -la PRINZ/PRINZ/GoogleService-Info.plist
```

---

### 3. Xcodeプロジェクトを開く

```bash
cd PRINZ
open PRINZ.xcodeproj
```

---

### 4. Firebase SDK を追加

#### 4.1 パッケージ追加
1. **File → Add Package Dependencies...**
2. 検索: `https://github.com/firebase/firebase-ios-sdk`
3. **Add Package**

#### 4.2 モジュール選択

**PRINZターゲット:**
- ✅ FirebaseAuth
- ✅ FirebaseFunctions
- ✅ FirebaseFirestore

**ShareExtensionターゲット:**
- ✅ FirebaseFunctions
- ✅ FirebaseAuth

→ **Add Package**

---

### 5. GoogleService-Info.plist をXcodeに追加

1. Finderで `GoogleService-Info.plist` を選択
2. Xcodeの `PRINZ/PRINZ/` フォルダにドラッグ&ドロップ
3. ダイアログ設定:
   - ✅ Copy items if needed
   - ✅ PRINZ (Add to targets)
   - ✅ ShareExtension (Add to targets)
4. **Finish**

---

### 6. Firebase初期化コード確認

`PRINZ/PRINZ/PRINZApp.swift` を開いて確認:

```swift
import SwiftUI
import Firebase  // ← 追加されているか確認

@main
struct PRINZApp: App {
    init() {
        FirebaseApp.configure()  // ← 追加されているか確認
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

**もし存在しない場合は追加してください。**

---

### 7. ビルド & 実行

```
Shift + Cmd + K  (Clean)
Cmd + B          (Build)
Cmd + R          (Run)
```

**成功の確認:**
- ビルドエラーなし
- アプリ起動成功
- コンソールに `Firebase App initialized` 表示

---

## ✅ 完了チェック

- [ ] Git pull完了
- [ ] GoogleService-Info.plist 配置完了
- [ ] Firebase SDK追加完了
- [ ] GoogleService-Info.plist Xcodeに追加完了
- [ ] Firebase初期化コード確認
- [ ] ビルド成功
- [ ] シミュレーター起動成功

---

## 🐛 トラブルシューティング

### "No such module 'Firebase'"
→ `File → Packages → Reset Package Caches` → 再ビルド

### "GoogleService-Info.plist not found"
→ ファイルを選択 → Target Membership で PRINZ & ShareExtension にチェック

### ビルドエラー
→ `Shift + Cmd + K` でクリーン → 再ビルド

---

## 📱 次のステップ

### 実機テスト準備

1. **Signing設定**
   - Signing & Capabilities
   - Team を選択
   - Bundle Identifier 確認

2. **実機接続**
   - iPhoneをMacに接続
   - Xcodeでデバイス選択

3. **実行**
   - `Cmd + R`

4. **Share Extension テスト**
   - 写真アプリでスクリーンショット開く
   - 共有 → PRINZ
   - 返信案が表示されることを確認

---

**詳細ガイド**: `docs/MAC_IOS_FIREBASE_SETUP_v2.md`
