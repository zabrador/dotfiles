---
name: atomic-commits
description: Execute a single atomic git commit in Claude Code — perform a quick gut check on the current diff, craft a Conventional Commits message, and run the commit. Use this skill whenever the user asks to commit, whenever Claude is about to commit, and at natural breakpoints during commit-as-you-go workflows. This skill does not perform decomposition of tangled changes; when the current diff contains multiple concerns, it defers to the commit-planning skill to produce a plan first.
---

This skill executes a single atomic commit in Claude Code. It performs a quick check that the current diff is atomic, crafts a Conventional Commits message, and runs the commit. For deep conceptual reasoning about atomic commits, or decomposition of tangled changes into a sequence of commits, it defers to the companion `commit-planning` skill.

## The gut check

Before committing, verify the current diff satisfies all four of these:

1. **Passes CI** — tests, lints, and type checks remain green.
2. **Is deployable** — no half-wired states that compile but crash at runtime.
3. **Introduces no dead code** — any new function has a caller added in the same commit.
4. **Passes the revert test** — reverting this commit would remove only the described change, nothing else.

Sharp message-level self-check: if the commit title would need the word "and" to describe what changed, the diff is not atomic.

The `commit-planning` skill owns the reasoning behind these criteria and the techniques for splitting a non-atomic diff. This skill uses them as a checklist.

If the diff does not pass, stop. Do not commit. See "When the diff is not atomic" below.

## Conventional Commits format

All commit messages use: `type(scope): short summary`

Common types:
- `feat` — new user-visible functionality
- `fix` — bug fix
- `refactor` — behavior-preserving code change
- `docs` — documentation only
- `test` — adding or modifying tests
- `chore` — maintenance (dependencies, config, tooling)
- `perf` — performance improvement without behavior change
- `style` — formatting only (whitespace, semicolons)

Message rules:
- Summary under ~70 characters.
- Imperative mood ("add", "fix", "remove" — not "added" or "adds").
- Focus on *why* over *what*; the diff shows the what.
- For non-trivial changes, add a body (blank line after summary) wrapped to ~72 characters.

## Running the commit

1. Run `git status` and `git diff` (plus `git diff --staged` if anything is already staged) to see what's about to be committed.
2. Apply the gut check above.
3. If it passes: stage the intended changes with `git add <files>` or `git add -p` for hunk-level selection, craft the message, and run `git commit`.
4. If it does not pass: stop and defer to `commit-planning`.

## When the diff is not atomic

If the gut check fails, do not commit. Handle it one of two ways:

- **If the `commit-planning` skill is available**, invoke it to produce a decomposition plan, then execute that plan by committing each planned commit one at a time using the steps above.
- **If `commit-planning` is not available**, tell the user the diff contains multiple concerns and needs to be split before committing. Offer to help identify the logical groupings, but do not attempt full decomposition independently — that's planning work, outside this skill's scope.
