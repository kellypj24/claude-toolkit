---
name: plan-archive
description: Use when the user says a plan is done, finished or shipped, or asks to archive, retire or close out a plan. Folds the plan's lasting decisions into the README, spec or STATUS.md, then moves the plan to docs/archive/ with git mv.
---

# plan-archive

A plan is scaffolding. Once its work has merged, its lasting content belongs in the
docs that describe the system, and the plan itself goes to the archive.

## Convention

| State | Path |
|---|---|
| Active | `docs/plans/<slug>.md`, one file per plan; step plans are sections, not files |
| Done | `docs/archive/YYYY-MM-DD-<slug>.md`, dated the day it is archived |

Takes a plan path as an argument. Without one, list `docs/plans/*.md` and ask which.
A plan found elsewhere (repo root, `docs/*-plan.md`) is archived the same way.

## Steps

1. Check the branch (`git branch --show-current`). On `main`, branch first:
   `archive-<slug>`.
2. Read the plan. Confirm its work has landed: the PRs or commits it names are merged.
   If any part is unfinished, stop and say which; don't archive a half-done plan.
3. Sort its content:
   - **Lasting**: decisions, constraints, interfaces, rationale someone will need
     later. Fold each into the doc that owns it: README for usage, the spec or
     design doc for behaviour, `STATUS.md` for open decisions that remain.
   - **Transient**: task lists, step order, estimates, progress notes. Leave them in
     the plan; git and the archive keep them.
4. Show the user the edits to the target docs before writing them.
5. `git mv docs/plans/<slug>.md docs/archive/$(date +%F)-<slug>.md`.
6. Update `STATUS.md`: drop the plan from Now/Next, keep any open decision it left.
7. Fix links to the old path (`grep -rn '<slug>.md'`).
8. Commit: `docs: archive <slug> plan`. Ship with the ship-pr skill.

## Don't

- Copy the whole plan into the README. Only what a reader needs after the work is done.
- Delete the plan. The archive is the record.
- Edit the archived file beyond the move.
