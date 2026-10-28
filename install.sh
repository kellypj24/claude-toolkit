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

STOP_HOOK="$CLAUDE_DIR/hooks/notify-on-stop.sh"
INPUT_HOOK="$CLAUDE_DIR/hooks/notify-on-input.sh"

# Merge statusLine + hooks config using jq
updated=$(echo "$existing" | jq \
  --arg cmd "$STATUSLINE_CMD" \
  --arg stop "$STOP_HOOK" \
  --arg input "$INPUT_HOOK" \
  '. + {
    "statusLine": {
      "type": "command",
      "command": $cmd,
      "padding": 1,
      "refreshInterval": 10
    },
    "hooks": {
      "PreToolUse": [
        {
          "matcher": "Bash",
          "hooks": [{ "type": "command", "command": "rtk hook claude" }]
        }
      ],
      "Stop": [
        { "hooks": [{ "type": "command", "command": $stop }] }
      ],
      "Notification": [
        { "hooks": [{ "type": "command", "command": $input }] }
      ]
    }
  }')

echo "$updated" > "$SETTINGS"
echo "  ✓ settings.json updated"

# ── RTK ────────────────────────────────────────────────────────────────────────
if ! command -v rtk &>/dev/null; then
  echo ""
  echo "  ⚠  rtk not found. Install it to enable token compression (~80% savings):"
  echo "     brew install rtk"
else
  echo "  ✓ rtk already installed ($(rtk --version 2>/dev/null || echo unknown))"
fi

echo ""
echo "Done. Restart Claude Code to see the status line."
