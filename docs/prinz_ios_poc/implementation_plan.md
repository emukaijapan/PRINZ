# PRINZ iOS App PoC - 実装計画

サイバーパンク×魔法の鏡をコンセプトにした、Share ExtensionとVision FrameworkによるOCRベースの返信案生成アプリのPoCを構築します。

## ユーザーレビュー必須項目

> [!IMPORTANT]
> **デザイン要件の厳守**
> - ネオンパープル (#D000FF) とネオンシアン (#00FFFF) をアクセントカラーとして使用
> - ピュアブラック背景とすりガラス効果を多用
> - ゲーミングPC風の近未来的UIを実現

> [!IMPORTANT]
> **ローカライゼーション（必須）**
> - **全てのUI文言は日本語** - ボタン、ラベル、プレースホルダー、エラーメッセージなど
> - **OCR言語設定**: `["ja-JP"]` を指定して日本語テキストを正確に認識
> - **モックデータも日本語**: 返信案は全て日本語で生成

> [!WARNING]
> **プライバシー重視の設計**
> - 画像は一切サーバーに送信しない
> - OCRは100% Vision Framework（オンデバイス処理）で実行
> - App Groupを使用したローカルデータ共有のみ

> [!CAUTION]
> **メモリクラッシュ防止**
> - Share Extensionでは画像を最大2048pxにリサイズしてからOCR実行
> - 高解像度スクリーンショットによるメモリ不足を防ぐ

## 提案する変更内容

### コアアプリケーション

#### [NEW] [PRINZ.xcodeproj](file:///s:/01_Dev/004_PRINZ/PRINZ/PRINZ.xcodeproj)
Xcodeプロジェクトファイル。メインアプリとShare Extensionの2つのターゲットを含む。

#### [NEW] [PRINZApp.swift](file:///s:/01_Dev/004_PRINZ/PRINZ/PRINZ/PRINZApp.swift)
SwiftUIアプリのエントリーポイント。App Groupの初期化を含む。

#### [NEW] [ContentView.swift](file:///s:/01_Dev/004_PRINZ/PRINZ/PRINZ/ContentView.swift)
メインのタブビュー。履歴画面と設定画面を切り替え。

---

### デザインシステム

#### [NEW] [Color+Extensions.swift](file:///s:/01_Dev/004_PRINZ/PRINZ/PRINZ/DesignSystem/Color+Extensions.swift)
ネオンカラーパレットの定義:
- `neonPurple`: #D000FF
- `neonCyan`: #00FFFF
- `darkBackground`: #000000
- `glassBackground`: 半透明の暗色

#### [NEW] [NeonButtonStyle.swift](file:///s:/01_Dev/004_PRINZ/PRINZ/PRINZ/DesignSystem/NeonButtonStyle.swift)
ネオングロー効果付きのカスタムボタンスタイル。パープルとシアンのバリエーションを提供。

#### [NEW] [GlassCard.swift](file:///s:/01_Dev/004_PRINZ/PRINZ/PRINZ/DesignSystem/GlassCard.swift)
すりガラス効果のカードコンポーネント。履歴表示などに使用。

---

### メインアプリ画面

#### [NEW] [HistoryView.swift](file:///s:/01_Dev/004_PRINZ/PRINZ/PRINZ/Views/HistoryView.swift)
過去の返信案履歴をカード形式で表示。App Groupから共有データを読み込み。

#### [NEW] [SettingsView.swift](file:///s:/01_Dev/004_PRINZ/PRINZ/PRINZ/Views/SettingsView.swift)
ユーザー属性（年齢・性別）の入力フォーム。ゲーミングUI風のスライダーとトグルを使用。

---

### Share Extension

#### [NEW] [ShareViewController.swift](file:///s:/01_Dev/004_PRINZ/PRINZ/ShareExtension/ShareViewController.swift)
Share Extensionのメインロジック:
1. 共有された画像を受け取る
2. Vision FrameworkでOCR実行
3. コンテキスト選択UIを表示
4. 返信案を生成して表示
5. タップでコピー機能

#### [NEW] [ContextSelectionView.swift](file:///s:/01_Dev/004_PRINZ/PRINZ/ShareExtension/Views/ContextSelectionView.swift)
状況タグ選択UI（マッチ直後 / デート打診 / 喧嘩など）。ネオンボタンで実装。

#### [NEW] [ScanningAnimationView.swift](file:///s:/01_Dev/004_PRINZ/PRINZ/ShareExtension/Views/ScanningAnimationView.swift)
「魔法の鏡」がスキャンしているようなレーダーアニメーション。

#### [NEW] [ReplyOptionsView.swift](file:///s:/01_Dev/004_PRINZ/PRINZ/ShareExtension/Views/ReplyOptionsView.swift)
LINE風吹き出しUIで3つの返信案を表示（ネオンダークモード配色）。

#### [NEW] [Info.plist](file:///s:/01_Dev/004_PRINZ/PRINZ/ShareExtension/Info.plist)
Share Extension設定:
- `NSExtensionActivationSupportsImageWithMaxCount`: 1
- `NSExtensionActivationRule`: 画像のみ受け入れ

---

### サービス層

#### [NEW] [OCRService.swift](file:///s:/01_Dev/004_PRINZ/PRINZ/Shared/Services/OCRService.swift)
Vision Frameworkを使用したOCRサービス。`VNRecognizeTextRequest`で日本語と英語のテキストを認識。

#### [NEW] [ReplyGenerator.swift](file:///s:/01_Dev/004_PRINZ/PRINZ/Shared/Services/ReplyGenerator.swift)
モックAIサービス。3つの固定パターン（安牌、ちょい攻め、変化球）を返す。

#### [NEW] [DataManager.swift](file:///s:/01_Dev/004_PRINZ/PRINZ/Shared/Services/DataManager.swift)
App Groupを使用したデータ永続化。履歴の保存と読み込み。

---

### モデル

#### [NEW] [Reply.swift](file:///s:/01_Dev/004_PRINZ/PRINZ/Shared/Models/Reply.swift)
返信案のデータモデル。ID、テキスト、タイプ、タイムスタンプを含む。

#### [NEW] [Context.swift](file:///s:/01_Dev/004_PRINZ/PRINZ/Shared/Models/Context.swift)
会話コンテキストの列挙型（マッチ直後、デート打診、喧嘩など）。

---

### アセット

#### [NEW] [Assets.xcassets](file:///s:/01_Dev/004_PRINZ/PRINZ/PRINZ/Assets.xcassets)
アプリアイコン、カラーセット、SF Symbolsの`crown.fill`をベースにしたロゴ。

## 検証計画

### 自動テスト
現段階ではPoCのため、ユニットテストは最小限とします。主要なロジック（OCRService、ReplyGenerator）の基本的な動作確認のみ実装。

### 手動検証
1. **Share Extension起動確認**
   - 写真アプリからスクリーンショットを選択
   - 共有シートからPRINZを選択
   - Extensionが起動することを確認

2. **OCR機能確認**
   - LINEのスクリーンショットを共有
   - テキストが正しく抽出されることを確認
   - デバッグ領域に抽出テキストが表示されることを確認

3. **UI/UXフロー確認**
   - コンテキスト選択画面が表示されることを確認
   - スキャンアニメーションが動作することを確認
   - 3つの返信案が表示されることを確認
   - タップでクリップボードにコピーされることを確認

4. **デザイン確認**
   - ネオンカラー（パープル/シアン）が正しく適用されていることを確認
   - すりガラス効果とグロー効果が表示されることを確認
   - サイバーパンク×魔法の鏡の雰囲気が再現されていることを確認

5. **データ共有確認**
   - Share Extensionで生成した返信案がメインアプリの履歴に表示されることを確認
   - App Groupを通じたデータ共有が正常に動作することを確認
