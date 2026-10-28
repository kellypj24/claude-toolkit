# claude-toolkit

Portable Claude Code enhancements: status line, hooks, and prompts.

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

The script lives at `statusline/statusline.sh`. `install.sh` copies it to
`~/.claude/statusline/statusline.sh` and updates `~/.claude/settings.json`.

To tweak the display, edit `statusline/statusline.sh` and re-run `bash install.sh`.

## Hooks

| File | Event | What it does |
|------|-------|--------------|
| `hooks/notify-on-stop.sh` | Stop | Chime + macOS notification when Claude finishes (`CLAUDE_STOP_SOUND` overrides) |
| `hooks/notify-on-input.sh` | Notification | Chime + notification on permission prompts and idle waits (`CLAUDE_INPUT_SOUND` overrides) |
| `hooks/pre-push-check.sh` | PreToolUse (Bash) | Blocks `git push` until local validation is confirmed; `git config claude.prepushAck true` lets `PREPUSH_ACK=1` through |
| `hooks/word-budget.sh` | SessionStart | Flags `~/.claude/CLAUDE.md`, any `MEMORY.md` index or a personal skill over its word budget; silent otherwise |

`install.sh` registers each hook for its event unless that command is
already registered, so hooks you add by hand survive a reinstall.

Budgets (400 / 1,000 / 800 words) are constants at the top of
`word-budget.sh`; raise one only by editing it. `bash hooks/word-budget.sh -v`
prints every count and exits 1 when anything is over.

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
