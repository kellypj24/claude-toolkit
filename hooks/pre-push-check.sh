#!/usr/bin/env bash
# Hook: speed bump on `git push` — surfaces a local-validation checklist to the model.
# Coexists with rtk hook claude (both run on PreToolUse Bash).
# Register in settings.json under hooks.PreToolUse[matcher=Bash].
#
# Opt-in acknowledgement: in a repo where `git config claude.prepushAck true` is set,
# a push prefixed with `PREPUSH_ACK=1` is allowed through. The prefix is the model's
# statement that the gauntlet ran green on the current tree. Repos without the opt-in
# keep the hard block.

input=$(cat)

# Extract the bash command and cwd robustly via jq; fall back to grep if jq is missing.
if command -v jq >/dev/null 2>&1; then
  cmd=$(echo "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
  cwd=$(echo "$input" | jq -r '.cwd // empty' 2>/dev/null)
else
  cmd=$(echo "$input" | grep -oE '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"command"[[:space:]]*:[[:space:]]*"//;s/"$//')
  cwd=""
fi

# Match a push only when it's the first token of a command segment (optionally after
# `sudo` or env assignments such as PREPUSH_ACK=1). Split on shell separators
# (; && || | &) first. This avoids false positives like `echo 'git push'`.
should_fire=$(echo "$cmd" \
  | tr ';|&' '\n' \
  | sed 's/^[[:space:]]*//' \
  | grep -cE '^(sudo[[:space:]]+)?([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*git[[:space:]]+push([[:space:]]|$)')

if [ "${should_fire:-0}" -eq 0 ]; then
  exit 0
fi

# Which repo is this push for? Prefer a leading `cd <dir> &&`, else the session cwd.
repo_dir=$(echo "$cmd" | sed -nE 's/^[[:space:]]*cd[[:space:]]+([^;&|[:space:]]+).*/\1/p' | head -1)
repo_dir="${repo_dir/#\~/$HOME}"
[ -z "$repo_dir" ] && repo_dir="$cwd"

if echo "$cmd" | grep -qE '(^|[[:space:];&|])PREPUSH_ACK=1[[:space:]]' \
  && [ -n "$repo_dir" ] \
  && [ "$(git -C "$repo_dir" config --get claude.prepushAck 2>/dev/null)" = "true" ]; then
  echo "[pre-push-check] PREPUSH_ACK=1 accepted for $repo_dir (repo opted in)." >&2
  exit 0
fi

cat <<'EOF' >&2
[pre-push-check] About to run `git push`.

Confirm the repo's local validation passed for the CURRENT state of the working tree:
  • lint        (ruff check / golangci-lint / eslint)
  • format      (ruff format --check / gofmt -l / prettier --check)
  • typecheck   (mypy / tsc --noEmit / go vet)
  • tests       (pytest / go test ./... / npm test)

If any of these have not been run on the latest commit, run them first and fix any failures.
In repos that opted in (`git config claude.prepushAck true`), state which commands ran
green on the current tree, then retry the push prefixed with `PREPUSH_ACK=1`.
Otherwise ask PJ to run the push.

Prefer using the `ship-pr` skill — it codifies this flow.
EOF
exit 2
