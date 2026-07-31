---
name: maintaining-prs
description: >
  Rules and methods for maintaining, fixing, and shepherding the user's open PRs
  to green — rebasing broken branches, resolving conflicts, diagnosing CI failures,
  and orchestrating background watchers. Use this skill whenever asked to fix a PR,
  investigate red CI, update a stacked PR after its parent merged, or
  "babysit"/watch PRs. A plain rebase request outside any PR-maintenance context
  is rewriting-history's territory, not this skill's. Also consult it before any GitHub write on the user's
  behalf. The mechanics of git mutation itself (rebase, amend, force-push,
  conflict resolution) are owned by the rewriting-history skill, and the shape
  of any repair (squash into an existing commit vs. new commits) is decided by
  planning-commits.
---

# Maintaining PRs

How to keep the user's PRs healthy: clean history, resolved conflicts, green CI —
without overstepping into decisions that belong to the user.

The structure mirrors the call hierarchy: **scope** applies to every layer →
**orchestration** defines a root scheduler that spawns one agent per stack →
**triggers** are what a stack agent escalates into a fix → the **standard change
procedure** is the only path that mutates git.

**Before any git mutation (rebase, amend, force-push, conflict resolution), read
the companion `rewriting-history` skill.** It owns the general git doctrine —
history discipline, safe force-pushing, worktree isolation, stacked-branch
rebasing, conflict-resolution heuristics — and is deliberately self-contained
and repo-agnostic. This file covers only what is specific to maintaining the
user's PRs; repo-specific facts belong in each target repo's own config (see
"Repo/environment specifics" below).

## Scope

**Which PRs.** Scope is **opt-in via label**. A PR is in scope iff both hold:

- It is **authored by the user**, and
- It carries the **`maintained-by:agent`** label.

Unlabeled PRs are invisible: no watching, no pushes, no GitHub writes of any
kind. The default for any PR is therefore *untouched* — the label is the user's
explicit delegation, and only the user adds or removes it (never the agent).
Maintain **all** labeled PRs proactively, not just the one that prompted the
session. Draft/ready status doesn't matter: a labeled draft is watched and fixed
like any other PR, so it's green when the user is ready to promote it.

**Stacks inherit the strictest member.** The cascade must be able to push every
branch it moves, so a stack is mutable only if **every PR in it** carries the
label. In a mixed stack, watch and report on the labeled PRs but never run the
change procedure — surface the mix to the user instead.

**Which actions.** Merge-state changes — merging, arming or disarming
auto-merge — and **promoting a draft to ready** are **never in scope, on any
PR**. The terminal state of this workflow is *green and reported*; merging and
promotion are the user's decisions.

## Orchestration

Two layers. **All meaningful work happens in stack agents; the root agent is a
pure scheduler** — it never touches git, never writes to GitHub, and never fixes
anything itself.

The unit of ownership is the **stack**: a chain of stacked in-scope PRs, base to
tip. An independent PR is a singleton stack. Because rebasing any PR in a stack
requires rebasing from the stack's base (a child cannot move to latest `main`
without its ancestors moving first), the stack is also the natural unit of
mutation — one owner per stack means no locking is needed at all.

**Root agent:**

- Enumerates in-scope PRs, groups them into **stacks by topology** (per the
  [Stack Topology Reconstruction appendix](#stack-topology-reconstruction)), and
  spawns **one headless background agent per stack**.
- Keeps the PR→stack→agent assignment current by re-running reconstruction,
  **re-checking labels on every pass** — a label added or removed is a scope
  change, handled like a topology change. On either kind of change — a parent
  merges (detected via the merged-parent gap check in the appendix), a new PR is
  stacked onto an existing one, a stack splits, a label changes — **respawn the
  affected stack's agent with the new roster** rather than mutating it.
- Is the **sole voice to the user**: stack agents report to root, never to the
  user directly. Root relays only real events — a check terminalizing, a genuine
  failure, an approval dismissal — not every poll.

**Stack agent** (one per stack, owns every PR in it end-to-end):

- Watches CI and comments on **all PRs in its stack**, and performs all **triage**
  (the trigger sections below).
- On a confirmed trigger on any PR in the stack: runs the **standard change
  procedure** — a full-stack cascade — in its own isolated worktree. Fixes within
  a stack are inherently serial (one agent); fixes across stacks run in parallel.
- After pushing, **returns to watching the resulting CI runs** — a push always
  needs a watcher, and this agent is it.
- Stays scoped to its own stack, with one read-only exception: the flake
  cross-reference in CI triage may query other PRs' recent runs directly
  (e.g. `gh run list` repo-wide). No shared state between agents.
- **If a git/GitHub operation is blocked by a safety classifier** (checkout,
  push, etc.), abort the procedure and report to root — which surfaces it to the
  user. Never work around a block.

## Triggers — what requires a change

Exactly three things authorize running the change procedure. A trigger on **any
PR in the stack** fires the procedure for the whole stack. Anything else: watch,
don't touch.

### 1. Red CI (after triage confirms it's real)

Triage before acting — a red check is not automatically a code problem:

- **Is it even blocking?** Before any further analysis, check whether the failing
  check gates merge at all — workflow-level conclusion, required-check status. A
  non-blocking failure does not authorize the change procedure.
- **Check staleness next.** Compare the failing run's `headSha` to the branch HEAD.
  Also remember that `pull_request` events test an ephemeral merge of the branch with
  *current* `main` — a failure may come from `main` advancing, not from the branch.
- **Distinguish flake from failure.** Check whether other PRs hit the same
  shard/error at the same time — matching failures across unrelated PRs indicate
  infra flake, not a code problem. Do this by **direct read-only query** of recent
  runs repo-wide (e.g. `gh run list`); there is no shared state between agents.
- **Don't trust `gh run view --log-failed` alone.** It often shows only cleanup noise.
  Grep the full `--log` for the real error, filtering out dependency-build lines.

Dispositions:

- **Non-blocking failure** → no change procedure. Report it to root once (with
  the check name and why it doesn't gate merge) and keep watching. A rebase here
  buys nothing.
- **Real failure** → run the change procedure with a fix. If the failure is new
  lint violations after a rebase, `main` likely introduced fresh instances of a
  newly-enabled rule → grandfather them the same way existing ones were.
- **Confirmed flake** → *still* run the change procedure, with no code change:
  the unconditional rebase onto latest `main` picks up any upstream fix and
  re-triggers CI.
- **Human-gated check** → no change procedure. Some blocking checks can only be
  cleared by a specific human action (an admin approval, an escape-hatch review) —
  they are not fixable in code, and a rebase buys nothing. Report to root naming
  the check and the specific human action needed; keep watching.

### 2. Git conflicts or dirty history

- The branch conflicts with `main` (`mergeable: "CONFLICTING"`), **or**
- A merge commit has appeared on the branch (e.g. someone clicked GitHub's
  "Update branch") — replace it with a clean rebase.

Reading `mergeable`:

- **`UNKNOWN` is not a conflict** — it usually means GitHub is still computing.
  Re-poll before concluding anything; firing a full-stack cascade on `UNKNOWN`
  is a false trigger.
- **`CONFLICTING` anywhere in a stack blocks everything above it** — which is
  exactly why the change procedure always cascades the whole stack.

### 3. Qualifying review feedback

- **The user's own comments: always address them.** Treat them as direct instructions.
- **Anyone else's comments: address only if the user has reacted with a 👍
  (thumbs up).** The user's reaction is the delegation signal — it means "yes, do
  this one." No reaction (or any other reaction) means the comment is not yours to
  act on; leave it for the user to triage. Non-qualifying comments get no reply
  either — silence, not "I'm not authorized."
- **After addressing feedback in code, reply to the thread** stating what was done
  and referencing the commit. **Self-identify as an agent** so it's clear the user
  isn't the one responding — open with a prefix like
  `🤖 Claude, on <user>'s behalf:`.
- **Batch qualifying feedback.** Collect all currently-👍'd comments and address
  them in **one push per review pass, not one push per comment** — push-per-nit
  multiplies CI runs, approval dismissals, and bot-review passes. If human review
  is in progress, prefer holding the batch until it resolves.
- **Never resolve threads.** Whether the response is satisfactory is the
  commenter's (or the user's) call — the agent reports; humans close.

> **Maintainer note (for the skill's author, not the agent):** reserve 👍 for
> false positives and blocking items on rule-rollout PRs. 👍-ing advisory
> completeness nits from bot reviewers creates an unbounded loop —
> static-analysis completeness demands never terminate.

## Standard change procedure

Every trigger funnels into this one sequence — it is the only path that mutates
git. It runs inside the stack's agent and always operates on the **whole stack,
base to tip**, regardless of which PR triggered it:

1. **Isolate.** Create/enter an isolated worktree area for the stack (e.g.
   `/tmp/bsit-<stack>`); hard-reset each branch to `origin/<branch>` so you're
   working from what's actually on the remote.
2. **Cascade-rebase, base to tip — always, unconditionally**, even if nothing is
   behind and even for trivial changes:
   - Rebase the stack's **base branch** onto latest `origin/main`. If the base's
     parent PR merged, use `git rebase --onto origin/main <parent-tip>` (see
     `rewriting-history`, "Stacked branches").
   - Then rebase each child onto its parent's **new** tip, in order down the stack.
   - Resolve conflicts per `rewriting-history`'s conflict-resolution heuristics.
   - If `main` hasn't advanced, upstream rebases produce identical SHAs and
     naturally no-op — only branches at and below the actual change will move.
3. **Make the change** (if any) at the triggered PR. The shape of the change is
   decided by `planning-commits`, never ad hoc: consult it to determine whether
   the change corrects an existing commit, is one or more new atomic commits,
   or splits into a mix (see its "Placing a fix into an existing commit
   sequence" section). Execute each part with its owning executor — squashes
   per `rewriting-history`'s mechanics (`--amend` for HEAD, `--fixup` +
   `--autosquash` for earlier commits), new commits via `committing-changes` —
   then continue the cascade through the descendants. Keep adjacent
   docs/comments in sync with any behavior change, in the same commit.
4. **Validate** each rebased branch: grep for leftover conflict markers; run the
   pre-push hook clean.
5. **Push only the branches whose SHAs changed**, each with `--force-with-lease`,
   lease pinned to the inspected remote SHA. Unchanged branches are not pushed —
   no gratuitous approval dismissal on untouched ancestors.
6. **Aftermath:**
   - If the change addressed review feedback, **reply to each addressed thread**
     (self-identified, referencing the commit — see trigger 3). Never resolve
     the thread.
   - **Report to root using the mandatory template.** Every report after a change
     procedure MUST include all of:
     - trigger (which one, on which PR)
     - change made (or "pure rebase")
     - old → new SHA **per branch**
     - lease pinned y/n
     - approvals dismissed y/n (per PR; → REVIEW_REQUIRED)
     - threads replied to
     - PR description still accurate y/n (update it if that's within your remit)
     - current CI state
     A report missing any of these is incomplete — root should bounce it back
     rather than chase details. Root relays the user-relevant parts.
   - Return to watching the resulting CI runs across the stack.

## Repo/environment specifics

Every repo has facts this workflow depends on that this skill cannot supply.
Learn them before the first change procedure in a repo, and re-verify each
session:

- **The validation hook.** What pre-push (or equivalent) validation exists — a
  clean run is the conflict-resolution arbiter (see `rewriting-history`).
- **Worktree bootstrap.** What a fresh worktree needs before hooks and builds
  pass (dependency install, generated files), roughly how long it takes, and
  which install-time errors are unrelated noise.
- **Known infra flakes.** Failure signatures that recur across unrelated PRs
  (shard names, error shapes), so flake cross-referencing has priors.
- **Human-gated checks.** Blocking checks only a specific human action can
  clear — report them by name, never attempt a code fix.
- **Branch-naming conventions.** The user's branch prefix, which topology
  reconstruction uses as its merged-parent signal (a `baseRefName` matching
  the prefix with no open PR on it).

Record what you learn in the target repo's own Claude config (its CLAUDE.md or
a checked-in notes file), not in this skill — this file is repo-agnostic and
travels with the user's dotfiles.

---

# Appendix

The section below is deliberately self-contained and repo-agnostic — no
PR-maintenance vocabulary, no repo assumptions — so it can be lifted out as its own
skill without edits. (Git Methods, which used to live here, was lifted out
exactly that way: it is now the `rewriting-history` skill.)

## Stack Topology Reconstruction

How to reconstruct a set of open PRs into stacks (chains linked by base→head
branch refs) from a single API call. Assumes GitHub and `gh`; the trunk branch
is called `main` below.

### Fetch

One call, with the fields needed to link stacks:

```bash
gh pr list --author "@me" --state open --limit 100 \
  --json number,title,headRefName,baseRefName,isDraft,mergeable,reviewDecision,updatedAt
```

### Link

No further tool calls needed — the graph is derivable from the fetched fields:

- Index PRs by `headRefName`.
- A PR's **parent** is the PR whose `headRefName` equals this PR's `baseRefName`.
  Its **children** are the PRs whose `baseRefName` equals this PR's `headRefName`.
- A PR is a **stack base** when `baseRefName == "main"`.
- Walk each base upward through its children to form an ordered chain, base to
  tip. A PR with multiple children is a **fork point** — track each branch of
  the fork as part of the same stack.
- A PR based on `main` with no children is a **standalone** (a singleton stack).

### Resolve gaps (merged parents)

If a PR's `baseRefName` is not `main` but **no open PR has that `headRefName`**,
the parent has likely merged (or been closed). Confirm before treating the PR
as a new base:

```bash
gh pr list --state merged --head <branchName> --json number,title,mergedAt
```

- Parent **merged** → this PR is the stack's new base; its first rebase must
  drop the parent's commits (`git rebase --onto <trunk> <parent-tip>` — see
  Stacked branches above).
- Parent **closed unmerged** or genuinely missing → do not guess; surface it
  for a human decision.

### Reading `mergeable`

- `"CONFLICTING"` on any PR blocks every PR above it in the stack.
- `"UNKNOWN"` means GitHub is still computing — re-poll; it is not a conflict.
