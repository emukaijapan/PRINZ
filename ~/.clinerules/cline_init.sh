#!/bin/bash

echo "🔄 cline_init.sh が実行されました"
echo "現在のディレクトリ: $(pwd)"
echo "ユーザー: $(whoami)"

# .clinerules ファイルのパス
CLINERULES_FILE="$HOME/.clinerules/.clinerules"
echo "CLINERULES_FILE: $CLINERULES_FILE"

# ファイルが存在するか確認
if [ -f "$CLINERULES_FILE" ]; then
    echo "🔍 .clinerules を読み込み中..."
    echo "================================"
    cat "$CLINERULES_FILE"
    echo "================================"
    echo "✅ .clinerules を正常に読み込みました"
else
    echo "⚠️ 警告: .clinerules ファイルが見つかりません"
    echo "ファイルパス: $CLINERULES_FILE"
fi
