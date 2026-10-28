#!/usr/bin/env bash
# Hook: fires on Claude Stop/StopFailure events.
# Plays a soft chime + sends a macOS notification so you know Claude finished.
# Register in settings.json under hooks.Stop.
# Override the sound with $CLAUDE_STOP_SOUND (path to an .aiff/.wav/.mp3).

input=$(cat)
session=$(echo "$input" | jq -r '.session_id // ""' | cut -c1-8)

SOUND="${CLAUDE_STOP_SOUND:-/System/Library/Sounds/Glass.aiff}"
[ -f "$SOUND" ] && command -v afplay &>/dev/null && afplay "$SOUND" &>/dev/null &

if command -v osascript &>/dev/null; then
  osascript -e "display notification \"Session $session finished\" with title \"Claude Code\""
elif command -v notify-send &>/dev/null; then
  notify-send "Claude Code" "Session $session finished"
fi

echo '{"continue": true}'
