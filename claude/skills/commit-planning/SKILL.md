---
name: commit-planning
description: Plan the decomposition of coding work into atomic git commits. Use this skill when planning a non-trivial change before coding, when mid-work changes have started spanning multiple concerns, when asked to split or reorganize commits, when a working tree is tangled and needs to be separated into discrete commits, or when the atomic-commits skill needs help because a diff isn't atomic. Also use whenever the user mentions atomic commits, commit decomposition, or asks how to structure a sequence of commits.
---

This skill handles the planning and decomposition of coding work into atomic git commits. It operates at the implementation-planning altitude: given a task that is about to be worked on (or was just completed without commits being made along the way), it produces the sequence of atomic commits that will land the work cleanly.

A companion skill, `atomic-commits`, handles the mechanics of actually writing commit messages and running git commands. When this skill produces a plan, `atomic-commits` executes against it. When `atomic-commits` detects that the current diff isn't atomic and can't be safely committed, this skill takes over to produce a decomposition.

## What makes a commit atomic

An atomic commit does exactly one thing — it's the version-control equivalent of the single responsibility principle. The test isn't "how many lines" or "how many files"; it's whether the change can be described in a single meaningful sentence without tacking on "and also..." for unrelated work.

A planned commit is atomic when, once implemented, it will satisfy all three of these criteria:

1. **Passes CI.** Tests, lints, and type checks remain green after this commit lands.
2. **Is deployable.** The codebase at this commit could, in principle, be shipped. No half-wired states that compile but crash at runtime.
3. **Introduces no dead code.** Every function added has a caller added in the same commit; every config option added is used. Helpers do not precede their first use.

Plus the **revert test**: if this commit were reverted later, would that revert remove only the changes described in the commit message, and nothing else? If reverting would also take legitimate unrelated changes with it, the commit isn't atomic — split the plan.

## Decomposing a task into commits

This is the core planning activity. Given a non-trivial task, produce a sequence of atomic commits that will land it.

### The refactor → feature → cleanup pattern

The most common and reliable decomposition: **make the change easy, then make the easy change.**

- **Refactor** commit(s): restructure existing code so the new change becomes natural. Behavior-preserving. No new functionality.
- **Feature** commit: the actual new behavior, built on top of the refactor.
- **Cleanup** commit(s): remove now-obsolete code, adjust naming, tidy up.

Each is its own commit. This separation means that if the feature is later reverted, the refactor and cleanup remain as independent improvements to the codebase.

When planning, work backward from the feature: "What would the code need to look like for this change to be small?" The answer describes the enabling refactor, which goes first.

### Vertical versus horizontal slicing

At the ticket or PR level, prefer **vertical slicing** — thin full-stack wedges, each of which delivers some value to users. Do not plan a series of PRs where one is "all the backend" and another is "all the frontend"; those cannot ship independently, and splitting layer-by-layer risks overbuilding parts that turn out not to fit.

*Within* a PR, at the commit level, **horizontal layering is often correct**. A single commit that touches three layers at once is usually too big to review atomically, even when the PR it belongs to is a vertical slice. The refactor → feature → cleanup pattern above is inherently horizontal.

The heuristic inverts because the units have different purposes. PRs need to ship independently; commits within a PR need to be reviewable and revertible, which often means layering.

### The "and" heuristic

A planning sanity check: for each commit being planned, write out the one-sentence title it would have. If any title needs the word "and" to describe what the commit does, that commit is probably multiple commits. Split it before coding begins.

## Planning during work: commit as you go

The ideal isn't to plan every commit up front and then execute — it's to plan the next commit at each natural breakpoint. When a logical unit is complete (a refactor finished, a function added, a feature wired up), pause, commit it via `atomic-commits`, and plan the next unit.

This avoids the most common failure mode: accumulating a large batch of changes and then trying to split them apart. Tangled working trees resist clean separation in ways that are much easier to prevent than to fix.

When in the middle of work and noticing that the current changes have started to span multiple concerns, that's the signal to pause, commit what's complete, and start the next unit cleanly. Don't wait until the whole task is done.

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

1. **Inventory.** Run `git status` and `git diff` to see everything present. Group changes by logical concern, not by file — a single file often contributes to multiple commits.

2. **Order the plan.** Determine what order the commits must go in. Refactors usually come first (since feature code may depend on them), features next, cleanup last. If a planned "refactor" commit would reference a function that only exists after the "feature" commit, the refactor isn't actually independent — either reorder, or accept they must be one commit.

3. **Check each planned commit against the criteria.** Will it pass CI? Is it deployable? Does it leave dead code? Does it pass the revert test?

4. **Accept honest non-atomic commits when necessary.** If changes are genuinely inseparable — a refactor that couldn't have been done without the feature it enables — plan them as a single commit with a message that honestly describes both. A truthful non-atomic commit is better than a dishonest "atomic" one.

Once the plan is in place, `atomic-commits` executes it, staging hunks (`git add -p`) and committing one planned commit at a time.

## What to avoid

- **Don't** plan horizontal slicing at the PR level. A PR that's all backend and no frontend can't ship, and splitting work that way defeats the point of vertical slices.
- **Don't** plan commits that introduce dead code "for a future commit." Every commit stands alone; helpers go with their first caller.
- **Don't** plan a catch-all "small mixed fix" commit that bundles unrelated changes because they're each too small to commit alone. Those are still separate commits.
- **Don't** produce a commit plan for a task that's really a feature. Flag the need for feature slicing instead.
- **Don't** force splits on small cohesive changes just to have more commits. A small change that does one thing is already atomic.
