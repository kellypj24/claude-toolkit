#!/usr/bin/env bash
# Hook: fires on Claude Stop/StopFailure events.
# Sends a macOS notification so you know Claude finished while you were away.
# Register in settings.json under hooks.Stop and hooks.StopFailure.

input=$(cat)
session=$(echo "$input" | jq -r '.session_id // ""' | cut -c1-8)

# Use osascript on macOS, notify-send on Linux
if command -v osascript &>/dev/null; then
  osascript -e "display notification \"Session $session finished\" with title \"Claude Code\""
elif command -v notify-send &>/dev/null; then
  notify-send "Claude Code" "Session $session finished"
fi

echo '{"continue": true}'
