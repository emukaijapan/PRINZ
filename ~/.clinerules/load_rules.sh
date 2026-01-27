#!/bin/bash

# .clinerulesを読み込むスクリプト
RULES_FILE="$HOME/.clinerules/.clinerules"
CONFIG_FILE="$HOME/.clinerules/cline_config.json"

if [ ! -f "$RULES_FILE" ]; then
    echo "Error: .clinerules file not found at $RULES_FILE"
    exit 1
fi

echo "Loading .clinerules..."
echo "========================"
cat "$RULES_FILE"
echo "========================"

if [ -f "$CONFIG_FILE" ]; then
    echo "Config:"
    jq . "$CONFIG_FILE"
fi

echo "Rules loaded successfully"