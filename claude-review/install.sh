#!/usr/bin/env bash
# Installs `claude-review` (opt-in pre-push Claude review) as a uv tool, with
# sensitive-scan alongside it as the gate. Both come from the data-engineering
# toolkit, pinned to one commit.
#
#   bash claude-review/install.sh            # pinned REF below
#   bash claude-review/install.sh <sha>      # another commit
#
# Then enable it per repo: see claude-review/README.md.

set -euo pipefail

# Bump deliberately, after reading the diff of tooling/claude-review and
# tooling/sensitive-scan between the old and new commit.
REF="${1:-c1307c6}"
SRC="git+https://github.com/kellypj24/data-engineering@${REF}"

command -v uv >/dev/null || { echo "uv not found: https://docs.astral.sh/uv/" >&2; exit 1; }

uv tool install --force --python ">=3.11" \
  "claude-review @ ${SRC}#subdirectory=tooling/claude-review" \
  --with "sensitive-scan @ ${SRC}#subdirectory=tooling/sensitive-scan"

# The gate must import from the tool's environment, or claude-review sends nothing.
tool_python="$(uv tool dir)/claude-review/bin/python"
"$tool_python" -c "import sensitive_scan.scan" \
  || { echo "sensitive-scan is not importable by claude-review" >&2; exit 1; }

claude-review --help >/dev/null
echo "  ✓ claude-review installed at ${REF} ($(command -v claude-review))"
