#!/usr/bin/env bash
# Installs claude-toolkit enhancements into ~/.claude/
# Run from the repo root: bash install.sh

set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "Installing claude-toolkit from $REPO_DIR"

# ── Statusline ─────────────────────────────────────────────────────────────────
mkdir -p "$CLAUDE_DIR/statusline"
cp "$REPO_DIR/statusline/statusline.sh" "$CLAUDE_DIR/statusline/statusline.sh"
chmod +x "$CLAUDE_DIR/statusline/statusline.sh"
echo "  ✓ statusline installed"

# ── Hooks ──────────────────────────────────────────────────────────────────────
if ls "$REPO_DIR/hooks/"*.sh 2>/dev/null | grep -q .; then
  mkdir -p "$CLAUDE_DIR/hooks"
  for hook in "$REPO_DIR/hooks/"*.sh; do
    cp "$hook" "$CLAUDE_DIR/hooks/"
    chmod +x "$CLAUDE_DIR/hooks/$(basename "$hook")"
  done
  echo "  ✓ hooks installed"
fi

# ── Settings ───────────────────────────────────────────────────────────────────
SETTINGS="$CLAUDE_DIR/settings.json"
STATUSLINE_CMD="$CLAUDE_DIR/statusline/statusline.sh"

# Read existing settings or start fresh
if [[ -f "$SETTINGS" ]]; then
  existing=$(cat "$SETTINGS")
else
  existing="{}"
fi

# Merge statusLine config using jq
updated=$(echo "$existing" | jq \
  --arg cmd "$STATUSLINE_CMD" \
  '. + {
    "statusLine": {
      "type": "command",
      "command": $cmd,
      "padding": 1,
      "refreshInterval": 10
    }
  }')

echo "$updated" > "$SETTINGS"
echo "  ✓ settings.json updated"

echo ""
echo "Done. Restart Claude Code to see the status line."
