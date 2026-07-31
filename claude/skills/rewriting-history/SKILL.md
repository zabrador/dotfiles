---
name: rewriting-history
description: >
  Execution doctrine for mutating git history safely — rebasing, amending,
  squashing fixups into earlier commits, force-pushing, resolving conflicts,
  and isolating mutations in worktrees. Use this skill whenever history is
  about to be rewritten or a conflict resolved: an ad-hoc request to rebase a
  branch, cleaning merge commits off a branch, force-pushing a rewritten
  branch, rebasing stacked branches after a parent merges, or when another
  skill (maintaining-prs, replanning-branches) reaches its mutation step. This
  skill governs how a mutation is executed safely, not what the commit
  sequence should be — sequence design belongs to planning-commits and
  replanning-branches, and single forward commits to committing-changes.
---

General-purpose rules for mutating git history safely and keeping branches
clean. Deliberately self-contained and repo-agnostic — no assumptions about
any particular repo, host, or workflow.

Companion skills own the neighboring territory. What the commit sequence
*should be* is planning territory: `planning-commits` for fresh work,
`replanning-branches` for reshaping committed history. Making a single forward
commit — staging, message, `git commit` — is `committing-changes`. This skill
owns only the mutation mechanics: once you know what history should look like,
this is how to get there without losing work or clobbering anyone else's.

## History discipline

- **Rebase onto the base branch, never merge it in.** Branch history should contain
  no merge commits. If a merge commit has been introduced (e.g. via a "update branch"
  button in a code host), replace it with a clean rebase of the branch's own commits.
- **Squash fixes into the commit they fix.** A branch should read as a sequence of
  intentional commits, not commits-plus-corrections:
  - Fix belongs to HEAD → `git commit --amend`
  - Fix belongs to an earlier commit → `git commit --fixup=<sha>`, then
    `git rebase -i --autosquash <base>`
  - Never leave standalone "fix", "oops", or "address review" commits.

## Safe force-pushing

- Always use `--force-with-lease`, never bare `--force`.
- When the remote branch has moved since you last looked, **pin the lease to the
  exact remote SHA you fetched and inspected**:
  `git push --force-with-lease=<branch>:<sha>`. This guarantees you can only
  overwrite state you have actually seen — an unpinned lease can be satisfied by a
  background fetch, silently clobbering someone else's concurrent push.

## Working-tree hygiene

- **Do history mutations in an isolated worktree** (e.g. `git worktree add /tmp/<task>-<id>`),
  not in a checkout shared with other tasks or agents. Multiple actors mutating one
  working tree will corrupt each other's state.
- **Reset before you rebase.** If the local branch may be stale or divergent from the
  remote, hard-reset it to `origin/<branch>` first so you are rebasing what actually
  exists on the remote, not a local fork of it.

## Stacked branches

- When a stacked branch's parent has merged into the base, don't rebase naively —
  that replays the parent's (now-merged) commits. Instead drop them explicitly:
  `git rebase --onto origin/main <parent-tip>` — replaying only the child's own
  commits onto the updated base.

## Conflict resolution

- **Two sides adding independent code at the same location** → keep both sides;
  this is an append-append conflict, not a real disagreement.
- **One side deleted what the other side annotates or configures** (imports,
  suppressions, registrations) → follow the deletion: drop the annotation/config
  for anything the other side removed, keep it only for what survives.
- **Before `git rebase --continue`**, always grep the tree for leftover conflict
  markers (`<<<<<<<`, `=======`, `>>>>>>>`). A rebase that "succeeds" with markers
  committed is worse than one that stops.
- **Use the project's pre-push validation hook (if any) as the final arbiter** that
  a resolution is complete — a clean hook run beats eyeballing the diff.
