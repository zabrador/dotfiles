---
name: maintaining-prs
description: >
  Rules and methods for maintaining, fixing, and shepherding the user's open PRs
  to green — rebasing broken branches, resolving conflicts, diagnosing CI failures,
  and orchestrating background watchers. Use this skill whenever asked to fix a PR,
  investigate red CI, update a stacked PR after its parent merged, or
  "babysit"/watch PRs. A plain rebase request outside any PR-maintenance context
  is making-git-changes' territory, not this skill's. Also consult it before any GitHub write on the user's
  behalf. The mechanics of git changes (rebase, amend, force-push, conflict
  resolution) are owned by the making-git-changes skill, and the shape of any
  repair (squash into an existing commit vs. new commits) is decided by
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
the companion `making-git-changes` skill.** It owns the general git doctrine —
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

**Session preflight (root, before anything else):**

- **Verify `gh auth status`.** Everything downstream depends on it, and an
  unauthenticated `gh` fails enumeration with less legible errors than the
  auth check itself. If unauthenticated, stop and give the user the concrete
  unblock step (`gh auth login`) — don't enumerate, don't spawn.
- **Resolve the user's branch prefix**: `$BRANCH_PREFIX` if set, else
  `gh api user --jq .login`. Topology reconstruction's merged-parent signal
  and any branch the session creates depend on it; an unresolved prefix
  degrades both silently.
- Re-verify each session — auth expires, and environment variables don't
  travel between machines.

**Root agent:**

- Runs the **pass** (below) on a schedule — root's standing job.
- Is the **sole voice to the user**: stack agents report to root, never to the
  user directly. Root relays only real events — a check terminalizing, a genuine
  failure, an approval dismissal — not every poll. Every relay separates
  *for-your-awareness* from *blocked-on-you*. The label is standing delegation:
  never solicit re-confirmation of an action it already authorizes — an
  imminent rebase that will dismiss an approval is relayed as fact, not posed
  as a question. A heads-up phrased as "tell me now if…" manufactures a gate
  the user then has to clear.

**The pass.** Root runs this check on a cadence: **every 20–30 minutes**, with
the first pass immediately after preflight. Scheduling it is part of starting
the session, not an authorization to raise with the user — the
`maintained-by:agent` label is already the delegation, and a scheduler that
only runs when prompted cannot keep the assignment current. Every pass does
the same three things (the first pass is not special):

1. **Fetch** — enumerate in-scope PRs, re-checking labels: a label added or
   removed is a scope change, handled like a topology change.
2. **Reconstruct** — group the PRs into stacks by topology (per the
   [Stack Topology Reconstruction appendix](#stack-topology-reconstruction)).
3. **Reconcile** — spawn **one headless background agent per stack** that
   lacks one; on any change (a parent merged — the gap check in the appendix —
   a new PR stacked onto an existing one, a stack split, a label changed),
   **respawn the affected stack's agent with the new roster** rather than
   mutating it.

A quiet pass is silent. Keep the schedule until no labeled PRs remain open,
the user ends it, or the session ends — an all-green moment is not a stopping
point, since open PRs drift as `main` advances. On a surface with no
scheduling mechanism, run a pass on every invocation and tell the user that
watching is not continuous.

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
- Runs as a **background agent**, which makes turn-ending semantics
  load-bearing: **ending a turn is termination, not a pause** — no monitor or
  notification will wake a finished agent. Wait on long operations (installs,
  CI runs) synchronously inside the turn. The only legitimate turn-ending
  outputs are the full report template or an explicit escalation; anything
  else is abandoned work-in-progress.
- **If an operation is blocked by a safety classifier**, stop and follow
  "Safety-classifier blocks" below.

**Safety-classifier blocks (any layer).** Any operation — a push, a comment
post, even an agent spawn — may be denied by a pre-execution safety
classifier. Doctrine:

- **Abort and surface the denial** to the user (via root). Never work around a
  block — no rewording, no alternate mechanism, no splitting the operation to
  slip past.
- **One user-authorized retry is legitimate** — denials can be false
  positives, and an explicit user go is the sanctioned way to test that. A
  second identical denial is terminal for the session: park the item, report
  it, and move on.
- **Don't diagnose the gate from inside the session.** Denials are typically
  deterministic on the operation's *intent* and surface no reason. Editing
  policy files, spawning test agents, or A/B-ing wording burns turns, cannot
  clear the block, and shades into working around it. Park the item and hand
  the user a clean reproduction instead.
- **Distinguish pre-execution denials from post-hoc warnings.** A denial
  blocks an action; a warning annotates an action that already succeeded.
  Warnings are audit signal, not obstruction — relay them, and don't infer
  the denial gate's reasoning from a warning's text: they are separate
  mechanisms.

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
- **Repo policy may forbid agent-authored comments — the label supersedes it.**
  Some repos' agent docs ban replying on a human's behalf. The
  `maintained-by:agent` label is the user's explicit, per-PR delegation, and
  for the self-identified replies this skill requires it governs over blanket
  repo docs. Flag the conflict to the user once (the repo doc deserves
  fixing), then reply as normal. If the reply is then blocked at the
  permission layer, that's a safety-classifier block (see Orchestration) —
  park it after at most one user-authorized retry and put the reply's
  substance in your report so the user can post or adapt it.
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
     `making-git-changes`, "Stacked branches").
   - Then rebase each child onto its parent's **new** tip, in order down the stack.
   - Resolve conflicts per `making-git-changes`' conflict-resolution heuristics.
   - If `main` hasn't advanced, upstream rebases produce identical SHAs and
     naturally no-op — only branches at and below the actual change will move.
3. **Make the change** (if any) at the triggered PR. The shape of the change is
   decided by `planning-commits`, never ad hoc: consult it to determine whether
   the change corrects an existing commit, is one or more new atomic commits,
   or splits into a mix (see its "Placing a fix into an existing commit
   sequence" section). Execute via `making-git-changes` — squashes with
   `--amend` for HEAD or `--fixup` + `--autosquash` for earlier commits, new
   commits staged and committed forward — checking every created or modified
   commit against `crafting-commits`' standard, then continue the cascade
   through the descendants. Keep adjacent docs/comments in sync with any
   behavior change, in the same commit.
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
     - judgment calls: any non-mechanical conflict resolution or discretionary
       choice, stated so the user can review it ("none" if none)
     - human-gated checks encountered, by name, with the human action needed
       ("none" if none)
     - worktree disposition (removed, or retained and why)
     A report missing any of these is incomplete — root should bounce it back
     rather than chase details, and treats any non-template turn-ending output
     (a status line, a promise to resume when something completes) as
     work-in-progress rather than a result — even when the agent's task shows
     as completed. Root relays the user-relevant parts.
   - **Dispose of the worktree deliberately.** When the stack reaches *green
     and reported* with nothing in flight, remove its worktree — a
     bootstrapped worktree is often multi-GB, and silently orphaned ones
     outlive the session. If you retain it (more triggers look imminent), say
     so in the report.
   - Return to watching the resulting CI runs across the stack.

## Repo/environment specifics

Every repo has facts this workflow depends on that this skill cannot supply.
Learn them before the first change procedure in a repo, and re-verify each
session:

- **The validation hook.** What pre-push (or equivalent) validation exists — a
  clean run is the conflict-resolution arbiter (see `making-git-changes`).
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
exactly that way: it now lives in the `making-git-changes` skill.)

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
