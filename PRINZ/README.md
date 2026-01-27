# PRINZ - iOS Share Extension PoC

<div align="center">

![PRINZ Logo](https://img.shields.io/badge/PRINZ-👑-D000FF?style=for-the-badge)
![Swift](https://img.shields.io/badge/Swift-5.9+-FA7343?style=for-the-badge&logo=swift&logoColor=white)
![SwiftUI](https://img.shields.io/badge/SwiftUI-iOS%2017+-0066CC?style=for-the-badge&logo=swift&logoColor=white)
![Vision](https://img.shields.io/badge/Vision-Framework-00FFFF?style=for-the-badge)

**サイバーパンク × 魔法の鏡**

LINEのスクリーンショットから返信案を生成するiOSアプリ

</div>

---

## 🎯 概要

**PRINZ**は、Share ExtensionとVision Frameworkを使用した、オンデバイスOCRベースの返信案生成アプリです。

### 主な機能

- 📸 **Share Extension**: 写真アプリやLINEから直接スクリーンショットを共有
- 🔍 **オンデバイスOCR**: Vision Frameworkで日本語テキストを抽出（プライバシー重視）
- 🎭 **コンテキスト選択**: 状況に応じた返信案を生成（マッチ直後、デート打診、喧嘩、脈あり確認）
- 💬 **3つの返信パターン**: 安牌、ちょい攻め、変化球
- 📋 **ワンタップコピー**: 返信案をタップしてクリップボードにコピー
- 📜 **履歴機能**: 過去の返信案を確認

---

## 🎨 デザインコンセプト

**「ゲーミングPC × 魔法の鏡」**

- **カラーパレット**:
  - 背景: ピュアブラック (#000000)
  - アクセント1: ネオンパープル (#D000FF)
  - アクセント2: ネオンシアン (#00FFFF)
- **スタイル**: すりガラス効果（Glassmorphism）とネオングロー
- **ロゴ**: 王冠（👑）モチーフ

---

## 🏗️ プロジェクト構成

```
PRINZ/
├── PRINZ/                          # メインアプリ
│   ├── PRINZApp.swift             # アプリエントリーポイント
│   ├── ContentView.swift          # タブビュー
│   ├── DesignSystem/              # デザインシステム
│   │   ├── Color+Extensions.swift
│   │   ├── NeonButtonStyle.swift
│   │   └── GlassCard.swift
│   ├── Views/                     # メインアプリビュー
│   │   ├── HistoryView.swift     # 履歴画面
│   │   └── SettingsView.swift    # 設定画面
│   ├── Shared/                    # 共有コード
│   │   ├── Models/
│   │   │   ├── Reply.swift
│   │   │   └── Context.swift
│   │   └── Services/
│   │       ├── OCRService.swift
│   │       ├── ReplyGenerator.swift
│   │       └── DataManager.swift
│   └── PRINZ.entitlements
│
└── ShareExtension/                # Share Extension
    ├── ShareViewController.swift  # メインロジック
    ├── Views/
    │   ├── ContextSelectionView.swift
    │   ├── ScanningAnimationView.swift
    │   └── ReplyOptionsView.swift
    ├── Info.plist
    └── ShareExtension.entitlements
```

---

## 🚀 セットアップ手順

### 1. Xcodeプロジェクトを開く

```bash
cd s:\01_Dev\004_PRINZ\PRINZ
open PRINZ.xcodeproj
```

### 2. App Groupを有効化

**メインアプリ:**
1. `PRINZ` ターゲットを選択
2. `Signing & Capabilities` タブを開く
3. `+ Capability` → `App Groups` を追加
4. `group.com.prinz.app` にチェック

**Share Extension:**
1. `ShareExtension` ターゲットを選択
2. 同様に `App Groups` を追加
3. `group.com.prinz.app` にチェック

### 3. ビルドと実行

1. シミュレーターまたは実機を選択
2. `PRINZ` スキームを選択してビルド
3. アプリを起動

---

## 📱 使い方

### Share Extensionの使用

1. **写真アプリ**または**LINE**でスクリーンショットを開く
2. **共有ボタン**（□↑）をタップ
3. **PRINZ**を選択
4. **状況を選択**（マッチ直後、デート打診、喧嘩、脈あり確認）
5. **解析中...**（OCR実行）
6. **3つの返信案**が表示される
7. **タップしてコピー**
8. LINEに戻って貼り付け

### メインアプリ

- **履歴タブ**: 過去の返信案を確認
- **設定タブ**: 年齢・性別を設定（将来的にパーソナライズに使用）

---

## 🔒 プライバシーとセキュリティ

- ✅ **画像は一切サーバーに送信されません**
- ✅ **OCRは100%オンデバイス処理**（Vision Framework）
- ✅ **データはApp Group内でローカル保存のみ**
- ✅ **メモリクラッシュ防止**: 画像を最大2048pxにリサイズ

---

## 🛠️ 技術スタック

| カテゴリ | 技術 |
|---------|------|
| 言語 | Swift 5.9+ |
| UIフレームワーク | SwiftUI |
| OCR | Vision Framework (`VNRecognizeTextRequest`) |
| データ共有 | App Groups |
| 拡張機能 | Share Extension |
| 言語設定 | 日本語 (`ja-JP`) |

---

## 📝 実装の詳細

### OCRサービス（`OCRService.swift`）

- **日本語認識**: `recognitionLanguages = ["ja-JP", "en-US"]`
- **高精度モード**: `recognitionLevel = .accurate`
- **メモリ最適化**: 画像を2048pxにリサイズ

### モックAI（`ReplyGenerator.swift`）

現在はモックデータを返します。将来的にはLLM APIと統合可能。

```swift
// コンテキストに応じた返信案
case .matchStart:
    - "楽しかった！また行こう！" (安牌)
    - "おつー、今度は飲みね🍻" (ちょい攻め)
    - "逆にいつ空いてるの？笑" (変化球)
```

---

## 🎯 今後の拡張案

- [ ] 実際のLLM API統合（OpenAI、Claude、Gemini）
- [ ] ユーザー属性に基づくパーソナライズ
- [ ] 返信案の編集機能
- [ ] お気に入り機能
- [ ] iCloudバックアップ
- [ ] ウィジェット対応

---

## 📄 ライセンス

このプロジェクトはPoCとして作成されました。

---

## 👤 作成者

Senior iOS Engineer Agent  
Specializing in SwiftUI, Share Extensions, and Vision Framework

---

<div align="center">

**Made with 💜 and 🔮**

</div>
