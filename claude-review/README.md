# claude-review across repos

`claude-review` is an opt-in, fail-open Claude review of a push, gated by
sensitive-scan. Source and behaviour: `tooling/claude-review/` in
[data-engineering](https://github.com/kellypj24/data-engineering). This folder
installs it once per machine and enables it per repo.

## Install (once per machine)

```bash
bash claude-review/install.sh          # the commit pinned in install.sh
bash claude-review/install.sh <sha>    # another commit
```

Puts `claude-review` on `PATH` via `uv tool`, with sensitive-scan in the same
environment. Without the scanner it sends nothing, so the script fails if it
cannot import it.

## Enable (per repo)

Merge `pre-commit-snippet.yaml` into the repo's `.pre-commit-config.yaml`, then:

```bash
pre-commit install --hook-type pre-push
CLAUDE_REVIEW=1 git push     # reviewed
git push                     # not reviewed
```

Optional per repo: a `.sensitive-scan.toml` to choose scanner packs. Without
one, every pack is on.

| Env var | Default | |
|---|---|---|
| `CLAUDE_REVIEW_MODEL` | CLI default | `--model` for the review |
| `CLAUDE_REVIEW_MAX_FILES` | 20 | |
| `CLAUDE_REVIEW_MAX_BYTES` | 100000 | |
| `CLAUDE_REVIEW_TIMEOUT` | 180 | seconds |

A warning starting `UNAVAILABLE (NOT A PASS):` means the push went through
unreviewed.

## Why not a global git hook

`core.hooksPath` replaces every repo's `.git/hooks`, including the ones
pre-commit installs, and `claude-review` reads the push range from pre-commit's
`PRE_COMMIT_FROM_REF` / `PRE_COMMIT_TO_REF`, not from a raw hook's stdin.

## Updating

Bump `REF` in `install.sh` after reading the diff of `tooling/claude-review/`
and `tooling/sensitive-scan/` between the two commits, then re-run it.
