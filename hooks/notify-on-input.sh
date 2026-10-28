#!/usr/bin/env bash
# Hook: fires on Claude Notification events (permission prompts, idle waiting).
# Plays a soft chime + sends a macOS notification so you know Claude needs you.
# Register in settings.json under hooks.Notification.
# Override the sound with $CLAUDE_INPUT_SOUND (path to an .aiff/.wav/.mp3).

input=$(cat)
message=$(echo "$input" | jq -r '.message // "Waiting for input"')

SOUND="${CLAUDE_INPUT_SOUND:-/System/Library/Sounds/Tink.aiff}"
[ -f "$SOUND" ] && command -v afplay &>/dev/null && afplay "$SOUND" &>/dev/null &

if command -v osascript &>/dev/null; then
  osascript -e "display notification \"$message\" with title \"Claude Code\""
elif command -v notify-send &>/dev/null; then
  notify-send "Claude Code" "$message"
fi

echo '{"continue": true}'
