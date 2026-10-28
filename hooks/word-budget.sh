#!/usr/bin/env bash
# Word budget for instruction text that loads into every session.
# Prints nothing when every file is under budget, so as a SessionStart hook it
# only adds context when something needs trimming. -v prints every file.
# Exits 1 when over budget unless run as a hook (CLAUDE_HOOK=1).
# Raising a budget is a deliberate edit here, as with Grove's CONSTITUTION.md rule 12.

set -uo pipefail
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"

CLAUDE_MD_BUDGET=400
MEMORY_INDEX_BUDGET=1000
SKILL_BUDGET=800

verbose=0
[[ "${1:-}" == "-v" ]] && verbose=1
over=0

check() {
  local file="$1" budget="$2" words
  [[ -f "$file" ]] || return 0
  words=$(wc -w < "$file" | tr -d ' ')
  if (( words > budget )); then
    over=1
    echo "word budget: ${file/#$HOME/~} is $words words, budget $budget; trim it before adding more"
  elif (( verbose )); then
    echo "ok: ${file/#$HOME/~} $words/$budget"
  fi
}

check "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_MD_BUDGET"
for f in "$CLAUDE_DIR"/projects/*/memory/MEMORY.md; do
  check "$f" "$MEMORY_INDEX_BUDGET"
done
# synced/ holds skills managed by claude.ai, not ours to trim.
for f in "$CLAUDE_DIR"/skills/*/SKILL.md; do
  [[ "$f" == "$CLAUDE_DIR/skills/synced/"* ]] && continue
  check "$f" "$SKILL_BUDGET"
done

[[ "${CLAUDE_HOOK:-}" == 1 ]] && exit 0
exit "$over"
