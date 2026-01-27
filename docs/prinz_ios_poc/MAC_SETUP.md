# PRINZ - Mac環境セットアップ手順

## 📋 現在の状況

✅ **完了:**
- Windowsでソースコード作成完了（16個のSwiftファイル）
- GitHubにプッシュ完了（`emukaijapan/dev-projects-monorepo`）

🎯 **次のステップ:**
- MacでGitリポジトリをクローン
- Xcodeプロジェクトを作成
- ソースコードをインポート
- ビルド・実行確認

---

## ステップ2: Macでリポジトリをクローン

### 1. ターミナルを開く

```bash
# Developerディレクトリに移動（なければ作成）
mkdir -p ~/01_Dev
cd ~/01_Dev
```

### 2. リポジトリをクローン

```bash
git clone https://github.com/emukaijapan/dev-projects-monorepo.git
cd dev-projects-monorepo/004_PRINZ
```

### 3. ファイル構成を確認

```bash
ls -la PRINZ/
```

以下のような構成が表示されるはずです:
```
PRINZ/
├── PRINZ/                    # メインアプリ
│   ├── PRINZApp.swift
│   ├── ContentView.swift
│   ├── DesignSystem/
│   ├── Views/
│   └── Shared/
├── ShareExtension/           # Share Extension
│   ├── ShareViewController.swift
│   └── Views/
├── README.md
└── .gitignore
```

---

## ステップ3: Xcodeプロジェクトを作成

### 1. Xcodeを起動

```bash
open -a Xcode
```

### 2. 新規プロジェクトを作成

1. **File** → **New** → **Project...**
2. **iOS** → **App** を選択
3. 以下の設定を入力:
   - **Product Name**: `PRINZ`
   - **Team**: （あなたのApple Developer Team）
   - **Organization Identifier**: `com.prinz` または任意
   - **Interface**: `SwiftUI`
   - **Language**: `Swift`
   - **Storage**: `None`
4. **保存場所**: `~/Developer/dev-projects-monorepo/004_PRINZ/PRINZ`
   - ⚠️ **重要**: 既存の`PRINZ`ディレクトリを選択し、**上書き**する

### 3. 既存ファイルをXcodeプロジェクトに追加

Xcodeが生成したデフォルトファイルを削除し、作成済みファイルをインポート:

1. **左サイドバー**で `ContentView.swift`（Xcodeが生成したもの）を削除
2. **File** → **Add Files to "PRINZ"...**
3. 以下のディレクトリを選択して追加:
   - `PRINZ/DesignSystem/` （フォルダごと）
   - `PRINZ/Views/` （フォルダごと）
   - `PRINZ/Shared/` （フォルダごと）
   - `PRINZ/PRINZApp.swift`
   - `PRINZ/ContentView.swift`
4. オプション設定:
   - ✅ **Copy items if needed** をチェック
   - ✅ **Create groups** を選択
   - ✅ **Add to targets**: PRINZ にチェック

---

## ステップ4: Share Extensionターゲットを追加

### 1. 新規ターゲットを追加

1. **File** → **New** → **Target...**
2. **iOS** → **Share Extension** を選択
3. 設定:
   - **Product Name**: `ShareExtension`
   - **Language**: `Swift`
   - **Activate "ShareExtension" scheme?** → **Activate**

### 2. Share Extensionファイルを追加

1. Xcodeが生成したデフォルトの `ShareViewController.swift` を削除
2. **File** → **Add Files to "PRINZ"...**
3. 以下を選択して追加:
   - `ShareExtension/ShareViewController.swift`
   - `ShareExtension/Views/` （フォルダごと）
4. オプション設定:
   - ✅ **Add to targets**: **ShareExtension** にチェック

### 3. 共有コードをShare Extensionに追加

Share Extensionでも使用するファイルを追加:

1. **左サイドバー**で `PRINZ/Shared/` フォルダを選択
2. **File Inspector** (右サイドバー) を開く
3. **Target Membership** で以下にチェック:
   - ✅ PRINZ
   - ✅ ShareExtension

同様に `DesignSystem/` フォルダ内の全ファイルも両方のターゲットに追加。

---

## ステップ5: App Groupを設定

### 1. メインアプリの設定

1. **PRINZ** ターゲットを選択
2. **Signing & Capabilities** タブを開く
3. **+ Capability** → **App Groups** を追加
4. **App Groups** セクションで:
   - **+** ボタンをクリック
   - `group.com.prinz.app` を入力
   - チェックを入れる

### 2. Share Extensionの設定

1. **ShareExtension** ターゲットを選択
2. 同様に **App Groups** を追加
3. 同じ `group.com.prinz.app` にチェック

### 3. Entitlementsファイルを置き換え

既に作成済みのEntitlementsファイルを使用:

1. Xcodeが生成した `PRINZ.entitlements` を削除
2. **Add Files to "PRINZ"...** で `PRINZ/PRINZ.entitlements` を追加
3. 同様に `ShareExtension/ShareExtension.entitlements` を追加

---

## ステップ6: Info.plistを設定

### Share ExtensionのInfo.plist

1. Xcodeが生成した `ShareExtension/Info.plist` を削除
2. 作成済みの `ShareExtension/Info.plist` を追加
3. または、手動で以下を設定:
   - `NSExtension` → `NSExtensionAttributes` → `NSExtensionActivationRule`
   - `NSExtensionActivationSupportsImageWithMaxCount` = `1`

---

## ステップ7: ビルドと実行

### 1. ビルド設定

1. **Product** → **Scheme** → **PRINZ** を選択
2. シミュレーターまたは実機を選択（iOS 17.0以上）

### 2. ビルド

```
⌘ + B (Command + B)
```

エラーが出た場合:
- Missing imports → `import SwiftUI` を追加
- Target membership → ファイルが正しいターゲットに追加されているか確認

### 3. 実行

```
⌘ + R (Command + R)
```

メインアプリが起動し、以下が表示されるはずです:
- **履歴タブ**: 空状態（王冠アイコン + メッセージ）
- **設定タブ**: 年齢スライダー、性別選択

---

## ステップ8: Share Extensionをテスト

### 1. 写真アプリでテスト

1. **写真アプリ**を開く
2. 任意の画像を選択
3. **共有ボタン** (□↑) をタップ
4. **PRINZ** を選択
5. 以下のフローを確認:
   - コンテキスト選択画面が表示される
   - 「解析中...」アニメーションが表示される
   - 3つの返信案が表示される
   - タップでコピーできる

### 2. デバッグ

Share Extensionのログを確認:

1. **Product** → **Scheme** → **ShareExtension** を選択
2. **⌘ + R** で実行
3. 写真アプリから共有
4. Xcodeのコンソールで `print()` の出力を確認

---

## ステップ9: Xcodeプロジェクトファイルをコミット

### 1. Gitステータス確認

```bash
cd ~/Developer/dev-projects-monorepo/004_PRINZ
git status
```

### 2. Xcodeプロジェクトファイルを追加

```bash
git add PRINZ/PRINZ.xcodeproj/
git add PRINZ/PRINZ.xcworkspace/  # もし生成されていれば
```

### 3. コミット

```bash
git commit -m "Add Xcode project files for PRINZ

- Created Xcode project with PRINZ app target
- Added ShareExtension target
- Configured App Groups
- Set up build settings and entitlements"
```

### 4. プッシュ

```bash
git push origin main
```

---

## ✅ 完了チェックリスト

- [ ] Gitリポジトリをクローン
- [ ] Xcodeプロジェクトを作成
- [ ] メインアプリのファイルをインポート
- [ ] Share Extensionターゲットを追加
- [ ] App Groupを設定
- [ ] メインアプリがビルド成功
- [ ] Share Extensionがビルド成功
- [ ] メインアプリが実行できる
- [ ] Share Extensionが動作する
- [ ] Xcodeプロジェクトファイルをコミット

---

## 🆘 トラブルシューティング

### ビルドエラー: "No such module 'SwiftUI'"

**解決策:**
- Deployment Target を iOS 17.0 以上に設定
- **Build Settings** → **iOS Deployment Target** → `17.0`

### Share Extensionが表示されない

**解決策:**
1. Info.plistの設定を確認
2. 実機で試す（シミュレーターでは表示されない場合がある）
3. アプリを一度削除して再インストール

### App Groupエラー

**解決策:**
1. Apple Developer Portalで App Group を登録
2. Provisioning Profileを再生成
3. Xcodeで自動署名を有効化

---

## 📞 次のステップ

ビルドが成功したら、Windowsに戻って以下を確認:

```bash
cd s:\01_Dev\004_PRINZ
git pull
```

Xcodeプロジェクトファイル（`.xcodeproj`）が同期されていることを確認してください。

以降は、両環境でGit同期しながら開発を進められます！
