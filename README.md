# claude-toolkit

Portable Claude Code enhancements: status line, hooks, global `CLAUDE.md`, skills and prompts.

## Install

```bash
git clone https://github.com/kellypj24/claude-toolkit ~/claude-toolkit
cd ~/claude-toolkit
bash install.sh
```

Restart Claude Code. The status line appears at the bottom of every session.

## Status line

Shows (left to right):
- **Model** — current Claude model name
- **Directory** — basename of the session's current directory (`~` at home)
- **Branch** — git branch of that directory
- **Context %** — percentage of context window used, with a bar (green/yellow/red)
- **Tokens** — input token count for current context
- **Cost** — estimated session cost in USD
- **5h limit** — 5-hour rate limit consumption %
- **7d limit** — 7-day rate limit consumption %
- **Eval runs** — `⚙ <stage> <done>/<total> ✓<passed>` per background eval run; hidden when none.
  Reads `*.run.json` in `CLAUDE_EVAL_DIR` (default `~/light-labs/var/evals`), skipping
  files untouched for 15 min (a killed run)

The script lives at `statusline/statusline.sh`. `install.sh` copies it to
`~/.claude/statusline/statusline.sh` and updates `~/.claude/settings.json`.

To tweak the display, edit `statusline/statusline.sh` and re-run `bash install.sh`.

## Hooks

| File | Event | What it does |
|------|-------|--------------|
| `hooks/notify-on-stop.sh` | Stop | Chime + macOS notification when Claude finishes (`CLAUDE_STOP_SOUND` overrides) |
| `hooks/notify-on-input.sh` | Notification | Chime + notification on permission prompts and idle waits (`CLAUDE_INPUT_SOUND` overrides) |
| `hooks/pre-push-check.sh` | PreToolUse (Bash) | Blocks `git push` until local validation is confirmed; `git config claude.prepushAck true` lets `PREPUSH_ACK=1` through |
| `hooks/secret-guard.sh` | UserPromptSubmit | Blocks a prompt holding a credential (keychain `-w` value, bot token, API key, 48-hex token) before the model sees it, so it never lands in a transcript. `!` commands skip it: use `security add-generic-password ... -w` with no value |
| `hooks/word-budget.sh` | SessionStart | Flags `~/.claude/CLAUDE.md`, any `MEMORY.md` index or a personal skill over its word budget; silent otherwise |

`install.sh` registers each hook for its event unless that command is
already registered, so hooks you add by hand survive a reinstall.

Budgets (400 / 1,000 / 800 words) are constants at the top of
`word-budget.sh`; raise one only by editing it. `bash hooks/word-budget.sh -v`
prints every count and exits 1 when anything is over.

## CLAUDE.md and skills

`claude/CLAUDE.md` is the global instruction file. Each directory in `skills/` is a
personal skill. `install.sh` symlinks them to `~/.claude/CLAUDE.md` and
`~/.claude/skills/<name>`, so an edit on either side is an edit to the repo; a real
file already there is moved to `<name>.bak` first.

| Skill | Use |
|-------|-----|
| `ship-pr` | Local lint/format/typecheck/test gauntlet, commit, push, open the PR |
| `plan-archive` | Fold a finished plan into the README, spec or `STATUS.md`; `git mv` it from `docs/plans/` to `docs/archive/YYYY-MM-DD-<slug>.md` |

## Prompts

Ready-to-paste system prompts in `prompts/system-prompts/`:

| File | Use case |
|------|----------|
| `senior-engineer.md` | General coding sessions |
| `data-engineer.md` | dbt / Airflow / pipeline work |
| `rubber-duck.md` | Problem-solving, thinking out loud |

## claude-review

Opt-in pre-push Claude review for any repo that uses pre-commit. Separate
installer (needs `uv` and network): `bash claude-review/install.sh`, then
enable per repo. See [claude-review/README.md](claude-review/README.md).

## Taking it with you

The only machine-specific path is in `~/.claude/settings.json` (the absolute path
to the statusline script). `install.sh` writes that path at install time, so on a
new machine just clone the repo and re-run `bash install.sh`.
