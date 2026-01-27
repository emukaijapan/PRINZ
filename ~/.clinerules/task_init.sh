#!/bin/bash

# Start New Task時に実行されるスクリプト
CLINERULES_FILE="$HOME/.clinerules/.clinerules"

echo "========================================"
echo "⚡ Start New Task - Loading .clinerules ⚡" 
echo "========================================"

if [ -f "$CLINERULES_FILE" ]; then
    cat "$CLINERULES_FILE"
    echo "----------------------------------------"
    echo "✅ .clinerules を適用しています"
else
    echo "⚠️ 警告: .clinerules ファイルが見つかりません"
fi

echo "========================================"