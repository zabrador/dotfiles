---
name: planning-commits
description: Plan the decomposition of coding work into atomic git commits. Use this skill whenever plan mode is active (trivial or not — a trivial change produces a single-commit plan), when mid-work changes have started spanning multiple concerns, when asked to split or reorganize commits, when a working tree is tangled and needs to be separated into discrete commits, when a late fix must be placed into an existing commit sequence (squash into the commit it corrects vs. a new commit — e.g. during PR maintenance), or when the crafting-commits gut check fails and a decomposition is needed. Also use whenever the user mentions atomic commits, commit decomposition, or asks how to structure a sequence of commits.
---

This skill handles the planning and decomposition of coding work into atomic git commits. It operates at the implementation-planning altitude: given a task that is about to be worked on (or was just completed without commits being made along the way), it produces the sequence of atomic commits that will land the work cleanly.

Two companion skills handle execution: `crafting-commits` defines the standard each commit must meet, and `making-git-changes` runs the git operations. When this skill produces a plan, they execute against it. When `crafting-commits`' gut check finds the current diff isn't atomic and can't be safely committed, this skill takes over to produce a decomposition.

## What makes a commit atomic

Atomicity has three roles to play, each answering a different question. They are not competing definitions — they're a principle, a method, and a test, working together.

### Principle — what an atomic commit *is*

An atomic commit does exactly one thing — it's the version-control equivalent of the single responsibility principle. Operationalized linguistically: a commit is atomic if its title can be written as a single meaningful sentence without an "and" bridging unrelated work. If the title needs "and" to describe what changed, the commit is probably two commits.

### Generative move — how to *arrive* at atomic commits

Work backward from the feature: **what would the code need to look like for this change to be small?**

This is the move that produces atomic commits, not just defines them. It is especially load-bearing when staring at a tangled working tree, where the question reframes "how do I split this mess?" into "how should the code have looked so this wouldn't have been a mess?" The answer usually surfaces an enabling refactor that should have come — and should now come — first.

### Verification — how to *check* a commit you've produced

A planned commit is atomic when, once implemented, it will satisfy all three of these criteria:

1. **Passes CI.** Tests, lints, and type checks remain green after this commit lands.
2. **Is deployable.** The codebase at this commit could, in principle, be shipped. No half-wired states that compile but crash at runtime.
3. **Introduces no dead code.** Every function added has a caller added in the same commit; every config option added is used. Helpers do not precede their first use.

Plus the **revert test**: if this commit were reverted later, would that revert remove only the changes described in the commit message, and nothing else? If reverting would also take legitimate unrelated changes with it, the commit isn't atomic — split the plan.

## Decomposing a task into commits

This is the core planning activity. Given a coding task, produce a sequence of atomic commits that will land it. Trivial changes produce a single-commit plan.

### The refactor → feature → cleanup pattern

The most common and reliable decomposition: **make the change easy, then make the easy change.**

- **Refactor** commit(s): restructure existing code so the new change becomes natural. Behavior-preserving. No new functionality.
- **Feature** commit: the actual new behavior, built on top of the refactor.
- **Cleanup** commit(s): remove now-obsolete code, adjust naming, tidy up.

Each is its own commit. This separation means that if the feature is later reverted, the refactor and cleanup remain as independent improvements to the codebase.

Apply the generative move from above: working backward from the feature surfaces the enabling refactor, which goes first.

### Vertical versus horizontal slicing

At the ticket or PR level, prefer **vertical slicing** — thin full-stack wedges, each of which delivers some value to users. Do not plan a series of PRs where one is "all the backend" and another is "all the frontend"; those cannot ship independently, and splitting layer-by-layer risks overbuilding parts that turn out not to fit.

*Within* a PR, at the commit level, **horizontal layering is often correct**. A single commit that touches three layers at once is usually too big to review atomically, even when the PR it belongs to is a vertical slice. The refactor → feature → cleanup pattern above is inherently horizontal.

The heuristic inverts because the units have different purposes. PRs need to ship independently; commits within a PR need to be reviewable and revertible, which often means layering.

## Planning ahead, committing as you execute

Produce the commit sequence up front — typically when plan mode is active — then execute against it, invoking `making-git-changes` at each planned commit point (each commit checked against `crafting-commits`). Trivial changes collapse to a single-commit plan; there's no triviality threshold.

Plans drift on contact with code. When the current diff no longer matches the next planned unit (an unanticipated refactor, a hidden dependency, a missed boundary), pause and revise the plan before continuing. Don't accumulate mixed concerns hoping to sort them later.

The question to ask when revising is the generative one: *what would make the next change small?* If the answer points to an enabling refactor that hasn't been done yet, that refactor becomes the next commit, not the feature work itself.

This avoids the most common failure mode: accumulating a large batch of changes and then trying to split them apart. Tangled working trees resist clean separation in ways that are much easier to prevent than to fix.

## Placing a fix into an existing commit sequence

Sometimes a small change arrives after a commit sequence already exists — a
review fix, a bug found while a PR is being maintained, a follow-up to work
already committed. The planning question is disposition: does this change
**correct** one of the existing commits, or is it a **new atomic unit**?

- **Correction** — the revert test decides. If reverting commit N should take
  this change with it (it fixes, completes, or adjusts what N's message
  claims), the change belongs inside N. Execution is a squash; the
  `making-git-changes` skill owns the mechanics.
- **New unit** — if the change does something no existing commit's message
  claims (new behavior, a review-requested addition), it is its own commit with
  its own message, executed via `making-git-changes` against `crafting-commits`'
  standard. Squashing it into an unrelated commit makes that commit dishonest
  and breaks the revert test.
- **Mixed** — split it: squash the corrective part, commit the new part
  separately.

This is plan revision in miniature, and no triviality threshold applies — as
with plan mode, a trivial disposition costs nothing to decide explicitly.
Placing a single fix stays this skill's territory; `replanning-branches` takes
over only when the task is reshaping a branch's whole sequence.

## When the commit boundary is really a design question

Sometimes "which commit does this behavior belong to?" is really "is this behavior intrinsic to the abstraction, or a per-consumer concern?" — a software-design question, not a planning question. If you can't decide where a behavior goes in your commit sequence, the design probably hasn't decided yet either. Resolve the design first; the commit sequence follows.

## Recognizing that a "task" is actually a feature

Sometimes what's been framed as a single task is actually a feature — a unit that needs to be sliced into multiple shippable tickets before commit-level planning makes sense.

Signals that this is happening:
- The task involves multiple distinct user-visible behaviors.
- Different parts of the task serve different users or use cases.
- The task's surface area spans many unrelated parts of the codebase.
- No thin vertical slice of the task delivers any value on its own.

When this happens, don't produce a commit plan anyway. Instead, flag the issue and suggest that the feature be sliced first. Commit planning operates one altitude below feature slicing; applying it to an un-sliced feature produces commits that are individually atomic but collectively incoherent — reviewable but not shippable, revertible but not meaningful.

## Recovery: when the working tree is already tangled

Sometimes a work session produces mixed changes before commit planning happened — feature work plus an inline refactor plus a stray fix, all sitting in the uncommitted diff. The task is to produce a decomposition plan that separates them.

The leverage here is upstream of the diff. Tangled trees resist clean splits because the code wasn't shaped for the change to be small in the first place. So the first step is the generative re-frame, not hunk-sorting.

1. **Re-frame using the generative move.** Before inventorying, ask: *what would the code need to look like for the change I just made to have been small?* The answer usually surfaces an enabling refactor that should have come first — and that tells you what commit one is. Without this step, the inventory below produces a sort of the existing mess; with it, the inventory produces a sequence that makes sense.

2. **Inventory.** Run `git status` and `git diff` to see everything present. Group changes by logical concern, not by file — a single file often contributes to multiple commits.

3. **Order the plan.** Determine what order the commits must go in. Refactors usually come first (since feature code may depend on them), features next, cleanup last. If a planned "refactor" commit would reference a function that only exists after the "feature" commit, the refactor isn't actually independent — either reorder, or accept they must be one commit.

4. **Check each planned commit against the criteria.** Will it pass CI? Is it deployable? Does it leave dead code? Does it pass the revert test?

5. **Accept honest non-atomic commits when necessary.** If changes are genuinely inseparable — a refactor that couldn't have been done without the feature it enables — plan them as a single commit with a message that honestly describes both. A truthful non-atomic commit is better than a dishonest "atomic" one.

Once the plan is in place, `making-git-changes` executes it, staging hunks (`git add -p`) and committing one planned commit at a time, each checked against `crafting-commits`.

## What to avoid

- **Don't** plan horizontal slicing at the PR level. A PR that's all backend and no frontend can't ship, and splitting work that way defeats the point of vertical slices.
- **Don't** plan commits that introduce dead code "for a future commit." Every commit stands alone; helpers go with their first caller.
- **Don't** plan a catch-all "small mixed fix" commit that bundles unrelated changes because they're each too small to commit alone. Those are still separate commits.
- **Don't** produce a commit plan for a task that's really a feature. Flag the need for feature slicing instead.
- **Don't** force splits on small cohesive changes just to have more commits. A small change that does one thing is already atomic.
