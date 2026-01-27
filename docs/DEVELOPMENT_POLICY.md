# PRINZ 開発ポリシー

## 🎯 基本方針

| 項目 | 内容 |
|------|------|
| **コード編集** | Windows PC |
| **ビルド・テスト** | Mac PC |
| **バージョン管理** | Git/GitHub |
| **フォルダ構造** | Windows/Mac で完全に同一 |

## 📁 フォルダ構造ルール

```
004_PRINZ/                      ← リポジトリルート
├── PRINZ/                      ← Xcodeプロジェクト
│   ├── PRINZ.xcodeproj/        ★ Macで生成・管理
│   ├── PRINZ/                  メインアプリ
│   │   ├── PRINZApp.swift
│   │   ├── ContentView.swift
│   │   ├── DesignSystem/
│   │   ├── Views/
│   │   └── Shared/             共有コード
│   └── ShareExtension/         Share Extension
├── docs/                       ドキュメント
└── @sample/                    参考資料
```

## 🔄 開発ワークフロー

### Windows で編集
```powershell
cd s:\01_Dev\004_PRINZ
# コード編集
git add .
git commit -m "Update feature"
git push
```

### Mac でビルド・テスト
```bash
cd ~/Developer/dev-projects-monorepo/004_PRINZ
git pull
open PRINZ/PRINZ.xcodeproj
# ⌘+B でビルド
# ⌘+R で実行
```

### Mac で変更した場合
```bash
git add .
git commit -m "Fix build issue"
git push
```

### Windows で取得
```powershell
git pull
```

## ⚠️ 禁止事項

- ❌ Windows で `.xcodeproj` ファイルを編集しない
- ❌ Mac で大規模なコード変更をしない（軽微な修正のみ）
- ❌ フォルダ構造を変更する場合は両環境で確認すること

## ✅ 推奨事項

- ✅ Swiftファイルは Windows で作成・編集
- ✅ Xcode設定変更は Mac で行う
- ✅ コミット前に必ずビルド確認（Mac）
- ✅ 新しいファイル追加後は Mac で Xcode にインポート
