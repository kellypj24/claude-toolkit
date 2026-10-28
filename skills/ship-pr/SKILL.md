---
name: ship-pr
description: Use when the user asks to ship a PR, open a PR, push the current branch, merge work, or finish up changes. Runs the repo's local lint/format/typecheck/test gauntlet, confirms branch state, commits if needed, pushes, and opens a PR — never delegates validation to CI.
---

# ship-pr

Carry a feature branch from "code looks done" to "PR opened" without skipping the local CI gauntlet. Codifies the lessons in [[feedback-pre-push-validation]] and [[feedback-branch-verification]].

## Step 1 — Confirm branch state

Run in parallel:
- `git branch --show-current`
- `git status --short`
- `git log --oneline -5`

State the current branch, what's staged/unstaged/untracked, and the last few commits. If the branch looks wrong (e.g. on `main`, or on an unexpected branch), STOP and ask before doing anything else.

## Step 2 — Detect the toolchain

Look for the project's commands in this order. Stop at the first hit:
1. `justfile` — read targets, prefer `just lint`, `just test`, `just typecheck` if present
2. `Makefile` — same pattern
3. `package.json` — read `scripts` (lint, test, typecheck, format)
4. `pyproject.toml` — look for ruff, mypy, pytest config
5. `go.mod` — use `go vet ./...`, `go test ./...`, `gofmt -l .`

Print the four commands you plan to run (lint / format-check / typecheck / tests). If anything is ambiguous, ask the user before running.

## Step 3 — Run the gauntlet

Run each command in this order. **Stop on the first failure** — do not continue to the next step.

1. Lint
2. Format check (not auto-fix — check only, so you don't quietly mutate the working tree)
3. Typecheck
4. Tests

If any step fails:
- Surface the failure output to the user
- Propose a fix
- Apply the fix only after user confirms (or autonomously if the fix is mechanical, e.g. `ruff format .`)
- Re-run the failed step plus everything downstream
- Do **not** proceed to push

## Step 4 — Commit if dirty

If `git status --short` shows uncommitted changes after the gauntlet:
- Draft a conventional-commit-style message based on the diff
- Show it to the user for confirmation before committing
- Commit with a HEREDOC message; include the `Co-Authored-By: Claude` trailer per the user's standard
- Never use `--no-verify`

If the tree is clean, skip this step.

## Step 5 — Push

`git push -u origin HEAD` (or the appropriate remote). The pre-push hook will speed-bump you — confirm in your message which gauntlet steps just passed.

## Step 6 — Open the PR

`gh pr create` with:
- A title under 70 characters
- A body containing: `## Summary` (1–3 bullets on what changed and why) and `## Test plan` (the gauntlet commands that passed)
- Use a HEREDOC for the body

Return the PR URL.

## Failure modes to avoid

- **Don't push partial green.** If typecheck fails, fixing only lint is not enough.
- **Don't auto-format then push without re-running tests.** A format change can mask import-order test failures.
- **Don't skip the branch check.** Stacked PRs make it easy to push to the wrong remote ref.
- **Don't trust "it worked last session."** Re-run the gauntlet if any file has changed since.
