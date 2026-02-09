# Antigravity VS Code マーケットプレイス連携

**日付**: 2026-02-04

## 概要

Antigravity で VS Code のマーケットプレイスを利用するための設定方法。

## 設定方法

`settings.json` に以下を追記することで、VS Code のマーケットプレイスから拡張機能をインストールできるようになる。

```json
{
    "antigravity.marketplaceExtensionGalleryServiceURL": "https://marketplace.visualstudio.com/_apis/public/gallery",
    "antigravity.marketplaceGalleryItemURL": "https://marketplace.visualstudio.com/items"
}
```

## 設定ファイルの場所

- **WSL2 Ubuntu**: `~/.config/Antigravity/User/settings.json`

## 注意事項

- 自己責任で利用すること
- 一部の拡張機能（特にMicrosoft製）はライセンス上の制限がある可能性あり
- 動作確認中（2026-02-04時点）

## 所感

- GitHub Copilot、Codex、Cline と比較して Antigravity が今までで一番便利
- GitHub Copilot は Agent モードより通常のコード補完に強みがある（比較対象として少し違う）
