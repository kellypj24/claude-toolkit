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

# ── CLAUDE.md and skills ───────────────────────────────────────────────────────
# Symlinked, not copied, so edits made under ~/.claude land in the repo.
# A real file or directory already in place is moved to <name>.bak first.
link() {
  local src="$1" dest="$2"
  if [[ -L "$dest" ]]; then
    [[ "$(readlink "$dest")" == "$src" ]] && return 0
    rm "$dest"
  elif [[ -e "$dest" ]]; then
    mv "$dest" "$dest.bak"
    echo "  ↪ moved existing ${dest/#$HOME/~} to ${dest/#$HOME/~}.bak"
  fi
  ln -s "$src" "$dest"
}

link "$REPO_DIR/claude/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
mkdir -p "$CLAUDE_DIR/skills"
for skill in "$REPO_DIR/skills/"*/; do
  skill="${skill%/}"
  link "$skill" "$CLAUDE_DIR/skills/$(basename "$skill")"
done
echo "  ✓ CLAUDE.md and skills linked"

# ── Settings ───────────────────────────────────────────────────────────────────
SETTINGS="$CLAUDE_DIR/settings.json"
STATUSLINE_CMD="$CLAUDE_DIR/statusline/statusline.sh"

# Read existing settings or start fresh
if [[ -f "$SETTINGS" ]]; then
  existing=$(cat "$SETTINGS")
else
  existing="{}"
fi

HOOKS="$CLAUDE_DIR/hooks"

# Merge statusLine, then add each hook only if its command is not already
# registered for that event, so hooks added outside this repo survive.
updated=$(echo "$existing" | jq \
  --arg cmd "$STATUSLINE_CMD" \
  --arg stop "$HOOKS/notify-on-stop.sh" \
  --arg input "$HOOKS/notify-on-input.sh" \
  --arg prepush "$HOOKS/pre-push-check.sh" \
  --arg budget "CLAUDE_HOOK=1 $HOOKS/word-budget.sh" \
  --arg guard "$HOOKS/secret-guard.sh" \
  'def add_hook($event; $entry):
     ($entry.hooks | map(.command)) as $new
     | if [.hooks[$event][]?.hooks[]?.command] | any(. as $c | $new | index($c))
       then . else .hooks[$event] += [$entry] end;
   . + {
     "statusLine": {
       "type": "command",
       "command": $cmd,
       "padding": 1,
       "refreshInterval": 10
     }
   }
   | add_hook("PreToolUse"; {"matcher": "Bash", "hooks": [{"type": "command", "command": "rtk hook claude"}]})
   | add_hook("PreToolUse"; {"matcher": "Bash", "hooks": [{"type": "command", "command": $prepush}]})
   | add_hook("Stop"; {"hooks": [{"type": "command", "command": $stop}]})
   | add_hook("Notification"; {"hooks": [{"type": "command", "command": $input}]})
   | add_hook("SessionStart"; {"hooks": [{"type": "command", "command": $budget}]})
   | add_hook("UserPromptSubmit"; {"hooks": [{"type": "command", "command": $guard}]})')

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

# ── Word budget ────────────────────────────────────────────────────────────────
bash "$CLAUDE_DIR/hooks/word-budget.sh" -v | sed 's/^/     /'

echo ""
echo "Done. Restart Claude Code to see the status line."
