# Status

Current state only; history is in git and the PRs. Update this file in the same PR as the
work it describes.

_Updated 2026-10-28._

## Now

- Installed: statusline, notify hooks, `pre-push-check`, `word-budget`, `secret-guard`.
  `install.sh` merges hooks per event, so reruns are safe.

## Next

1. Version `~/.claude/CLAUDE.md` and the `ship-pr` skill here, linked into place by
   `install.sh`.
2. rtk: measure its saving in light-labs' `mart_claude_*` marts and decide whether to keep
   the hook. It hides some output, and its command rewrites leave auto mode without a
   verdict.
3. Statusline progress for background eval runs.
4. A plan-archive skill: fold a finished plan into the README or spec, then move it to
   `docs/archive/`.

## Open decisions

None.

## Blocked on

Nothing.
