---
name: making-git-changes
description: >
  Execution mechanics for changing git state safely — staging and committing,
  amending, squashing fixups into earlier commits, rebasing, lease-pinned
  force-pushing, resolving conflicts, and isolating work in worktrees. Use
  this skill whenever a git state change is about to be made: an ad-hoc
  request to commit or rebase, cleaning merge commits off a branch,
  force-pushing a rewritten branch, rebasing stacked branches after a parent
  merges, or when another skill (maintaining-prs, replanning-branches)
  reaches its execution step. This skill governs how operations are executed
  safely — what the commit sequence should be belongs to planning-commits and
  replanning-branches, and the standard a commit must meet belongs to
  crafting-commits.
---

General-purpose rules for changing git state safely and keeping branches
clean. Deliberately self-contained and repo-agnostic — no assumptions about
any particular repo, host, or workflow.

## Route before you execute

Three questions determine what accompanies any operation here:

1. **Does the operation change what any commit *is* — its content or its
   boundaries?** Then a shape decision must exist before executing. In
   plan-led work it already does — the plan or a fix-placement disposition
   made it; execute against that, don't re-plan. If no such decision exists,
   it is about to be made implicitly — stop and consult the planner:
   `planning-commits` for fresh work or placing a late fix (squash vs. new
   commit), `replanning-branches` for re-decomposing committed history.
2. **Did the operation create or modify a commit?** Check the result against
   `crafting-commits` — the gut check, the message format, and the
   message-stays-true rule. This applies to squashes and amends exactly as it
   does to fresh commits.
3. **Pure replay** — rebasing onto a newer base, resolving conflicts while
   preserving intent, re-triggering CI? No planner, no re-judging beyond
   `crafting-commits`' honesty backstop; the safety doctrine below is what
   matters.

## Forward commits

1. Run `git status` and `git diff` (plus `git diff --staged` if anything is
   already staged) to see what's about to be committed.
2. Check the diff against `crafting-commits`' standard. If it fails, stop and
   defer as that skill directs.
3. If it passes: stage the intended changes with `git add <files>` or
   `git add -p` for hunk-level selection, craft the message per the standard,
   and run `git commit`.

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
  - After the squash lands, re-check the target commit against
    `crafting-commits` — its message must still describe it.

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
- **Branch a backup before destructive reorders.** Before resetting and replaying
  commits in a different order — or any operation that discards the current
  sequence — preserve the current state with `git branch <name>-backup` so the
  original remains available for reference.

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

## Co-author trailers across rewritten history

When every commit on a rewritten branch should carry co-author trailers (e.g.
crediting the branch's original author and an AI assistant):

```
git rebase <base> --exec '
  git commit --amend --no-edit \
    --trailer "Co-Authored-By: <Original Author> <author@email>" \
    --trailer "Co-Authored-By: <AI Assistant> <noreply@example.com>"
'
```

Notes:

- `--exec` runs after each commit is replayed, amending it to add the trailers
  without changing the message.
- `--no-edit` is critical — without it, an editor opens for every commit.
- For GitHub attribution to link to the original author's account, the email
  must match what's registered with their GitHub identity. The most reliable
  choice is the email they used in the original commits:
  `git log --format='%an <%ae>' <original-branch> -1`.
- Safe on local-only branches. Shared branches require a force-push — see
  Safe force-pushing above.
