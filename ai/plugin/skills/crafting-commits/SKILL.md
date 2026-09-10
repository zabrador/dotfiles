---
name: crafting-commits
description: The standard for what a good git commit looks like — a quick atomicity gut check, Conventional Commits message format, and the honesty rule that a message must describe the commit as it now is. Use this skill whenever a commit is about to be created or an existing commit's content is about to change (committing, amending, squashing, resolving conflicts in a rebase), and whenever asked to write, review, or fix a commit message. This skill judges commits; executing git operations belongs to the making-git-changes skill, and decomposition of tangled changes belongs to planning-commits.
---

This skill defines the standard a git commit must meet — whether the commit is
being created fresh or reshaped by a mutation (amend, squash, conflict
resolution). It judges; it does not execute. The companion `making-git-changes`
skill owns the git mechanics and consults this standard after any operation
that creates or modifies a commit. For deep conceptual reasoning about atomic
commits, or decomposition of tangled changes into a sequence of commits, defer
to `planning-commits`.

## The gut check

Before a commit is created (or after its content changes), verify the diff
satisfies all four of these:

1. **Passes CI** — tests, lints, and type checks remain green.
2. **Is deployable** — no half-wired states that compile but crash at runtime.
3. **Introduces no dead code** — any new function has a caller added in the same commit.
4. **Passes the revert test** — reverting this commit would remove only the described change, nothing else.

Sharp message-level self-check: if the commit title would need the word "and"
to describe what changed, the diff is not atomic.

The `planning-commits` skill owns the reasoning behind these criteria and the
techniques for splitting a non-atomic diff. This skill uses them as a checklist.

If the diff does not pass, stop. Do not commit. See "When the diff is not
atomic" below.

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

## The message stays true under mutation

Mutations produce commits too. When an operation changes what an existing
commit contains — a fix squashed in via `--amend` or `--fixup`, hunks altered
by conflict resolution during a rebase — re-judge the commit as if it were
being created now:

- **The message must describe the commit as it now is.** A squash that extends
  behavior can silently falsify a message that was accurate yesterday.
- **The gut check applies to the merged result, not the delta.** The combined
  diff must still be atomic and pass the revert test.
- If the mutation made the message wrong, amend the message in the same
  operation. If it made the commit non-atomic, the shape was wrong — defer to
  `planning-commits` (see its fix-placement section) rather than leaving a
  dishonest commit.

## When the diff is not atomic

If the gut check fails, do not commit. Handle it one of two ways:

- **If the `planning-commits` skill is available**, invoke it to produce a
  decomposition plan, then execute that plan one planned commit at a time via
  `making-git-changes`, checking each against this standard.
- **If `planning-commits` is not available**, tell the user the diff contains
  multiple concerns and needs to be split before committing. Offer to help
  identify the logical groupings, but do not attempt full decomposition
  independently — that's planning work, outside this skill's scope.
