# PRINZ - Mac コマンド＆デバッグガイド

## 📥 最新コードを取得

```bash
cd ~/Developer/dev-projects-monorepo
git pull origin main
```

## 🔨 Xcodeでビルド

```bash
# Xcodeプロジェクトを開く
open 004_PRINZ/PRINZ/PRINZ.xcodeproj
```

Xcode内で:
- `⌘ + B` でビルド
- `⌘ + R` で実行

---

## 🐛 Share Extensionが動作しない問題のデバッグ

### 1. 基本チェック

**Share Extensionターゲットがビルドされているか確認:**
1. Xcode左上の「PRINZ」をクリック
2. 「ShareExtension」スキームを選択
3. `⌘ + B` でビルド

**両方のターゲットにApp Groupが設定されているか:**
1. PRINZターゲット → Signing & Capabilities → App Groups
2. ShareExtensionターゲット → 同上
3. 両方に `group.com.prinz.app` があることを確認

### 2. Info.plist確認

ShareExtension/Info.plistに以下があるか確認:
```xml
<key>NSExtensionActivationRule</key>
<dict>
    <key>NSExtensionActivationSupportsImageWithMaxCount</key>
    <integer>1</integer>
</dict>
```

### 3. コンソールログでデバッグ

**Share Extensionのログを見る方法:**

1. Xcodeでスキームを「ShareExtension」に変更
2. 実行ボタン横の「▶」をクリック
3. 「Ask on Launch」ダイアログで「Photos」を選択
4. 写真アプリで画像を選択 → 共有 → PRINZ
5. Xcodeのコンソールにログが表示される

### 4. よくある問題と解決策

**問題: 共有シートにPRINZが表示されない**
```
解決策:
1. 実機で試す（シミュレーターだと表示されないことがある）
2. アプリを削除して再インストール
3. iPhoneを再起動
```

**問題: 画像を選択しても何も起こらない**
```
解決策:
1. ShareViewController.swiftのprint文を追加してデバッグ
2. extensionContext?.inputItemsが取得できているか確認
```

**問題: OCRが動作しない**
```
解決策:
1. 画像が正しく読み込まれているか確認
2. Vision frameworkのエラーをキャッチして表示
```

### 5. デバッグ用コード追加

ShareViewController.swiftの`loadSharedImage`関数に以下を追加:

```swift
print("🔍 extensionContext: \(String(describing: extensionContext))")
print("🔍 inputItems count: \(extensionContext?.inputItems.count ?? 0)")

if let items = extensionContext?.inputItems as? [NSExtensionItem] {
    for item in items {
        print("🔍 Item: \(item)")
        print("🔍 Attachments: \(item.attachments ?? [])")
    }
}
```

### 6. 実機でテストする場合

```bash
# デバイスをMacに接続
# Xcodeでデバイスを選択
# 開発者証明書でサインイン
# ⌘ + R で実機にインストール
```

---

## 📝 変更をコミット（Mac側で変更した場合）

```bash
cd ~/Developer/dev-projects-monorepo
git add .
git commit -m "Fix Share Extension issue"
git push origin main
```

## 🔄 Windowsで変更を取得

```powershell
cd s:\01_Dev
git pull origin main
```
