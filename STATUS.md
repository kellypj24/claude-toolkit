# Status

Current state only; history is in git and the PRs. Update this file in the same PR as the
work it describes.

_Updated 2026-10-28._

## Now

- Installed: statusline, notify hooks, `pre-push-check`, `word-budget`, `secret-guard`.
  `install.sh` merges hooks per event, so reruns are safe.
- `claude/CLAUDE.md` and `skills/` (`ship-pr`, `plan-archive`) are symlinked into
  `~/.claude` by `install.sh`.
- Plan convention: active in `docs/plans/<slug>.md`, done in
  `docs/archive/YYYY-MM-DD-<slug>.md` (the `plan-archive` skill).

## Next

1. rtk: measure its saving in light-labs' `mart_claude_*` marts and decide whether to keep
   the hook. It hides some output, and its command rewrites leave auto mode without a
   verdict.
2. Statusline progress for background eval runs.

## Open decisions

None.

## Blocked on

Nothing.
