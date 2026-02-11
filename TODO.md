# To-Do List

## ブロッカー
- [x] Apple Developer Program 審査完了

## High Priority
- [x] Windows環境からWSL環境への環境ファイル移行
- [x] Firebase CLI セットアップ (WSL環境)
- [x] Cloud Functions デプロイ
- [x] Firestore Database 初期化
- [x] Firestoreルールのデプロイ
- [x] Cloud Functions 第2世代への移行
- [x] Cloud Functions 動作確認
- [x] GoogleService-Info.plist ダウンロード
- [x] DEV_MODE を false に変更（Codex監査で対応済み）
- [x] RevenueCat SDK を SPM で追加
- [x] iOS側のFirebase SDK設定（Mac環境）
- [x] 実機ビルド・動作確認

## Share Extension 改善 (2026-02-11)
- [x] Firebase Functionsタイムアウト追加（25秒、コールドスタート対策）
- [x] レビュー依頼を31回利用後に変更（カスタムUI）
- [x] SwiftUI View struct問題修正（weak self、UIResponder）
- [x] Share Extension → メインアプリ Paywall誘導
  - [x] URL Scheme `prinz://paywall?plan=weekly` 実装
  - [x] Info.plist に CFBundleURLTypes 追加
  - [x] PRINZApp.swift で onOpenURL ハンドリング
  - [x] extensionContext.open をメインスレッド+0.2秒遅延で実行
  - [x] 失敗時フラグ保存 → 次回起動時Paywall表示（フォールバック）
- [x] Paywall プラン指定機能（?plan=weekly / ?plan=yearly）
- [x] 「トライアルキャンペーン中」メッセージに変更
- [ ] **テスト**: URL Scheme経由でPaywallが開くか確認 ← **要実機テスト**

## Medium Priority
- [ ] Share Extensionでの実機テスト
- [ ] エラーハンドリングの確認
- [ ] エンドツーエンドフロー確認
- [ ] 実機スクリーンショット撮影

## App Store 提出準備
- [x] App Store 掲載文作成 (`docs/appstore-listing.md`)
- [x] SNS投稿文作成（X / Instagram）
- [x] スクショテンプレート作成 (`docs/appstore-screenshots.html`)
- [x] プライバシーポリシー作成
- [x] 利用規約作成
- [x] サポートページ作成
- [ ] App Store Connect スクリーンショット登録
- [ ] App Review 提出

## Firebase Hosting
- [x] upgrade.html 作成（アップグレード案内ページ）
- [ ] firebase deploy --only hosting ← **未デプロイ**

## Backlog
- [ ] Analytics 統合 (Firebase Analytics)
- [ ] エラー監視 (Crashlytics)
- [ ] ランディングページ作成
