# Mac側 iOS Firebase連携 セットアップ手順

**作成日**: 2026-01-17  
**対象**: PRINZ iOSアプリ Firebase連携

---

## 1. Git更新

```bash
cd ~/Developer/PRINZ  # PRINZプロジェクトのディレクトリ
git pull origin main
```

---

## 2. GoogleService-Info.plist を配置

### 2.1 ファイル確認
Windows側でダウンロードした `GoogleService-Info.plist` を Mac に転送してください。

**転送方法（いずれか）**：
- iCloud Drive
- OneDrive
- AirDrop
- USBメモリ

### 2.2 配置先
```bash
# PRINZアプリターゲットのディレクトリに配置
cp ~/Downloads/GoogleService-Info.plist ~/Developer/PRINZ/PRINZ/
```

---

## 3. XcodeでFirebase SDKを追加

### 3.1 パッケージを追加
1. Xcodeでプロジェクトを開く
2. メニュー: **File → Add Package Dependencies...**
3. 検索欄に入力:
   ```
   https://github.com/firebase/firebase-ios-sdk
   ```
4. **Add Package** をクリック

### 3.2 追加するモジュールを選択
以下の3つにチェック:
- ✅ **FirebaseAuth**
- ✅ **FirebaseFunctions**
- ✅ **FirebaseFirestore**

→ **Add Package** をクリック

---

## 4. GoogleService-Info.plist をXcodeに追加

1. Finderで `GoogleService-Info.plist` を選択
2. Xcodeの**プロジェクトナビゲーター**（左サイドバー）を表示
3. `PRINZ/PRINZ/` フォルダに**ドラッグ&ドロップ**
4. ダイアログで設定:
   - ✅ **Copy items if needed**
   - **Add to targets**:
     - ✅ PRINZ
     - ✅ ShareExtension（もし共有する場合）

→ **Finish** をクリック

---

## 5. ビルド確認

### 5.1 ビルド
```
Cmd + B
```

### 5.2 エラーがない場合
コンソールに以下が表示されれば成功:
```
✅ Firebase initialized
✅ App Group Container: /path/to/container
```

---

## 6. 動作テスト（シミュレーター）

1. **Cmd + R** でシミュレーターを起動
2. アプリが正常に起動することを確認
3. コンソールで `Firebase initialized` を確認

---

## トラブルシューティング

### エラー: "No such module 'Firebase'"
→ Firebase SDKパッケージが正しく追加されていない
→ File → Packages → Reset Package Caches を実行

### エラー: "GoogleService-Info.plist not found"
→ ファイルがターゲットに追加されていない
→ Xcodeでファイルを選択 → Target Membership で PRINZ にチェック

### エラー: "FirebaseApp.configure() crash"
→ GoogleService-Info.plist の内容が不正
→ Firebase Consoleから再ダウンロード

---

## 完了後のチェックリスト

- [ ] Git pull完了
- [ ] GoogleService-Info.plist 配置完了
- [ ] Firebase SDK追加完了
- [ ] ビルド成功
- [ ] シミュレーター動作確認

---

## 次のステップ

1. **Firebase Authentication設定**（Apple Sign-In）
2. **Cloud Functions呼び出しテスト**
3. **実機テスト**
