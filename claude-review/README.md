# claude-review across repos

`claude-review` is an opt-in, fail-open Claude review of a push, gated by
sensitive-scan. It lives in data-engineering at `tooling/claude-review/`; its
README ("Adopt → Install once per machine") is the reference for installing,
enabling per repo, and env vars.

This folder holds only my pinned install:

```bash
bash claude-review/install.sh          # the commit pinned in install.sh
bash claude-review/install.sh <sha>    # another commit
```

Per repo: merge `pre-commit-snippet.yaml` into `.pre-commit-config.yaml`, run
`pre-commit install --hook-type pre-push`, then `CLAUDE_REVIEW=1 git push`.
