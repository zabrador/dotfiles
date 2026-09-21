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
  replanning-branches. This skill checks commit readiness; crafting-commits
  owns subjects and bodies.
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
2. **Will the operation create or change a commit's contents?** Apply the
   readiness check below to the whole resulting commit, including amends,
   squashes, and conflict resolutions. Use `crafting-commits` to write or check
   the message against that result.
3. **Pure replay** — a clean rebase preserving the changes does not require a
   new decomposition plan. Resolve conflicts under the safety doctrine below;
   if resolution changes the commit's meaning, recheck readiness and its message.

## Commit readiness

Before committing, verify the resulting diff against `planning-commits`' criteria:

- Relevant tests, lint, and type checks pass; run applicable repository checks
  and report actual results rather than assuming CI is green.
- It is deployable, with no half-wired runtime state.
- New functions have callers and new configuration is used in the same commit.
- Reverting it would remove the described change without unrelated work.

Judge the complete commit, not only a fixup delta. If a check fails, address
validation failures or consult `planning-commits` for a decomposition before
committing. If the planner is unavailable, explain the blocking concern; do
not silently bundle unrelated changes. These are execution gates, not
prerequisites for drafting a message.

## Forward commits

1. Run `git status` and `git diff` (plus `git diff --staged` if anything is
   already staged) to see what's about to be committed.
2. Apply the readiness check above; stop and address any failure.
3. If it passes: stage the intended changes with `git add <files>` or
   `git add -p` for hunk-level selection, craft the message with `crafting-commits`,
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
  - After the squash lands, re-check readiness of the combined commit and
    its message via `crafting-commits`.

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
