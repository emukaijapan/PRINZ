import os
from antigravity.customizations import RulesManager

CLINERULES_PATH = os.path.expanduser("~/.clinerules/.clinerules")

def load_clinerules():
    """Load .clinerules and register as Antigravity Rules"""
    if os.path.exists(CLINERULES_PATH):
        with open(CLINERULES_PATH, "r") as f:
            rules_content = f.read()
            RulesManager.register_rules("clinerules", rules_content)
            print("✅ .clinerules loaded as Antigravity Rules")
    else:
        print("⚠️ .clinerules file not found")

def initialize():
    """Plugin initialization"""
    load_clinerules()