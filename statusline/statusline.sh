#!/usr/bin/env bash
# Claude Code status line — reads JSON from stdin, prints one line to stdout.
# Install: set statusLine.command in ~/.claude/settings.json to this script's path.

set -euo pipefail

input=$(cat)

# ── Parse fields ──────────────────────────────────────────────────────────────
model=$(echo "$input"    | jq -r '.model.display_name // .model.id // "Claude"')
ctx_pct=$(echo "$input"  | jq -r '[.context_window.used_percentage // 0] | .[0] | floor')
cost=$(echo "$input"     | jq -r '.cost.total_cost_usd // 0 | (. * 10000 | round) / 10000')
rate_5h=$(echo "$input"  | jq -r '[.rate_limits.five_hour.used_percentage // 0] | .[0] | floor')
rate_7d=$(echo "$input"  | jq -r '[.rate_limits.seven_day.used_percentage // 0] | .[0] | floor')
ctx_tokens=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // 0')

# ── Git branch (from filesystem, not Claude JSON) ──────────────────────────────
project_dir="${CLAUDE_PROJECT_DIR:-$PWD}"
branch=""
if branch_raw=$(git -C "$project_dir" rev-parse --abbrev-ref HEAD 2>/dev/null); then
  branch=" $branch_raw"
fi

# ── Progress bar (10 chars wide) ──────────────────────────────────────────────
bar_width=10
filled=$(awk -v pct="$ctx_pct" -v w="$bar_width" 'BEGIN { n=int(pct*w/100); if(n>w)n=w; print n }')
empty=$((bar_width - filled))

bar=""
for ((i=0; i<filled; i++)); do bar+="█"; done
for ((i=0; i<empty; i++)); do bar+="░"; done

# ── Colors ────────────────────────────────────────────────────────────────────
R='\033[0m'
BOLD='\033[1m'
PURPLE='\033[1;35m'
CYAN='\033[36m'
YELLOW='\033[33m'

if   (( ctx_pct > 80 )); then CTX_CLR='\033[31m'   # red
elif (( ctx_pct > 50 )); then CTX_CLR='\033[33m'   # yellow
else                          CTX_CLR='\033[32m'   # green
fi

if   (( rate_5h > 80 )); then RATE_CLR='\033[31m'
elif (( rate_5h > 50 )); then RATE_CLR='\033[33m'
else                          RATE_CLR='\033[36m'
fi

# ── Format cost string ────────────────────────────────────────────────────────
cost_str=$(awk -v c="$cost" 'BEGIN { printf "$%.4f", c }')

# ── Token count (human-readable) ──────────────────────────────────────────────
tok_str=$(awk -v t="$ctx_tokens" 'BEGIN {
  if (t >= 1000) printf "%.1fk", t/1000
  else           printf "%d",    t
}')

# ── Output ────────────────────────────────────────────────────────────────────
printf "${PURPLE}%s${R}" "$model"
printf "%s" "$branch"
printf "  ${CTX_CLR}%s%%${R} %s %s" "$ctx_pct" "$bar" "$tok_str"
printf "  ${CYAN}%s${R}" "$cost_str"
printf "  5h:${RATE_CLR}%s%%${R}" "$rate_5h"
printf "  7d:${YELLOW}%s%%${R}" "$rate_7d"
printf "\n"
