---
name: branch-redecomposition
description: Re-decompose an existing committed branch into a clean atomic commit sequence on a fresh branch off the merge-base. Use this skill when the user wants to reshape a finished branch's commit history before review, clean up an ad-hoc branch built without commit discipline, or apply atomic-commit discipline retroactively. Use whenever the user mentions re-decomposing a branch, redoing commits on a branch, restructuring a branch's history, or rebasing for cleanliness on an existing branch. This skill builds on `commit-planning` for atomicity reasoning — it adds patterns that only apply when re-shaping committed history, not when planning fresh work.
---

This skill handles re-shaping an existing committed branch into a clean sequence of atomic commits on a fresh branch off the merge-base. It operates one step removed from `commit-planning`: same atomicity criteria, same decomposition heuristics, but with workflow-specific patterns that only matter when the starting point is committed history rather than uncommitted work.

The companion skills handle the parts this one delegates. `commit-planning` owns the conceptual definition of atomicity (the principle, the generative move, the verification criteria) and the general decomposition heuristics (refactor → feature → cleanup, vertical/horizontal slicing). `atomic-commits` owns single-commit execution. This skill provides the workflow framing and the patterns specific to re-decomposition.

## Default to a fresh branch off the merge-base

When asked to re-decompose committed history, default to a fresh branch starting at the merge-base, not an in-place force-push of the original.

- The original commits remain as a reference and a fallback.
- The fresh branch is the new candidate; no risk of clobbering review state, anchored PR comments, or collaborator branch state.
- It removes the temptation to do unnecessary in-place rewriting just because the tools make it possible.

In-place rebase plus force-push is a separate, riskier workflow. Treat it as a follow-up that requires explicit confirmation about: open PR review state, reviewer-anchored comments, and collaborator branch state. The default never assumes any of that is safe.

## Decompose from the diff, not from the existing commit log

The single biggest trap in re-decomposition is anchoring on the previous commit messages. The original author's grouping reflects:

- Their work order
- Mid-stream pivots (features tried, reverted, replaced)
- Coarse-grained "checkpoint" commits during exploration
- Polish commits that ended up at the tail of the branch but are foundationally part of the change

…not the cleanest atomic decomposition.

**The right input is `merge-base..HEAD` as a single tangled patch.** Treat it the way `commit-planning`'s recovery section treats an uncommitted diff: group hunks by *concern*, not by which existing commit they came from.

The original commit titles are at most a *signal* of seams that exist in the diff — useful as a hint about where natural boundaries might be — never a structural template.

A change appearing late in the previous branch's commit log does not imply it's a layered refinement. It may simply have been built late but be foundationally part of the abstraction. Position is not a signal of foundationality. Whether a behavior is foundational or layered is a software-design question — see `commit-planning`'s "When the commit boundary is really a design question" section for when to escalate.

## Iterate toward the final diff with synthesized intermediate states

Many atomic commits cannot be assembled by raw hunk-pick from the final diff. A foundational commit usually needs *less* than what's in the final shape — a minimal version of the new abstraction, with later commits additively layering on features.

That minimal version is **synthesized intermediate code** that does not appear verbatim anywhere in `merge-base..HEAD`. You write it for the commit; later commits modify or extend it; the final state converges with the original branch's HEAD (or close to it).

This is the refactor → feature → cleanup pattern from `commit-planning`, applied at the commit level. *Make the change easy* (write minimal foundational scaffolding), then *make the easy change* (each layered feature is its own commit).

### Functional equivalence, not byte equivalence

A direct corollary: the new branch's `merge-base..HEAD` diff *will* differ from the original's, because the synthesized intermediate code drifts. Verification therefore relies on **functional / test parity**, not byte parity.

This trade-off is explicit and load-bearing. Trying to enforce byte parity forces some commits to be non-atomic just to match the original's incidental shape. Accept the drift; verify with tests.

## Importer before exporter

The most common atomicity violation in re-decomposition: **commit N removes a helper that commit N+M still imports.**

Symptoms:

- HEAD compiles fine
- Commits N..N+M-1 fail to typecheck standalone
- Tests don't catch it because the affected files are not in the test's import graph

Cause: the original branch happened to include both the consumer migration and the helper deletion in one big commit, or in an order that doesn't decompose cleanly.

**Fix: reorder so the *importer* migrates before the *exporter* deletes the helper.** Mechanically, this means cherry-picking commits in dependency order rather than chronological order.

### Verification policy

Per-commit verification is ideal but slow. A pragmatic rule:

- Run scoped typecheck (or equivalent) at **every layer boundary** in the plan.
- Run it explicitly **at any commit that removes or restructures a previously exported identifier** — that's where the importer-before-exporter hazard concentrates.
- Run unit tests where they apply, but don't trust them for typecheck-only failures (test files often don't import the affected code paths).

When a violation is found mid-stream, the fix is reorder, not patch. Reset to the last good commit and apply commits in the corrected order. Preserve the broken state in a backup branch first (`git branch <name>-backup`) so the original sequence remains available for reference.

## "Behavior-preserving" can be loose

When migrating consumers onto a new shared component, "behavior-preserving" is often impossible. The migration may inherently change the rendering model, the API surface, or the user-visible flow:

- Nested popovers → flat grouped lists
- Separate sections → grouped headers
- Internal-state filtering → controlled filtering

…in ways no internal restructuring can avoid.

Be honest in the commit message. Use `refactor:` only when user-visible behavior actually doesn't change. When the migration is itself the behavior change, say so in the message body. A truthful "this migration changes the rendering model in these ways" is better than a dishonest `refactor:` that papers over real differences.

## What this skill does not own

- **The atomicity criteria themselves.** Owned by `commit-planning`: the principle (does one thing, "and" heuristic), the generative move ("work backward from the feature"), and the verification criteria (passes CI, deployable, no dead code, revert test).
- **The general decomposition heuristics.** Refactor → feature → cleanup and vertical/horizontal slicing live in `commit-planning`.
- **Single-commit execution.** Once the plan is in place, each commit is executed via `atomic-commits` — staging hunks (`git add -p`), writing the Conventional Commits message, running `git commit`.
- **Foundational vs layered as a design question.** When deciding whether a behavior is intrinsic to the abstraction or per-consumer, that's software design, not re-decomposition. `commit-planning` flags this escalation.
- **In-place rebase plus force-push of shared branches.** Separate workflow, separate confirmations. Not the default this skill produces.

## What to avoid

- **Don't** anchor on the previous commit log's grouping. The original author's order is shaped by their work history, not by atomic boundaries.
- **Don't** force in-place rebase plus force-push on a shared branch as the default. That's a separate, riskier workflow.
- **Don't** enforce byte-equivalence between the new and original branches' diffs. The new branch's intermediate states will drift; verify with tests.
- **Don't** remove an exported identifier in a commit before all later commits' importers have migrated. Reorder so importers move first.
- **Don't** call a commit a `refactor:` when the migration itself changes user-visible behavior. Be honest in the body.

## Appendix: Co-author trailers across rewritten history

When the user wants every commit on the new branch to carry co-author trailers (e.g. crediting the original branch's author and an AI assistant):

```
git rebase <merge-base> --exec '
  git commit --amend --no-edit \
    --trailer "Co-Authored-By: <Original Author> <author@email>" \
    --trailer "Co-Authored-By: <AI Assistant> <noreply@example.com>"
'
```

Notes:

- `--exec` runs after each commit is replayed, amending it to add the trailers without changing the message.
- `--no-edit` is critical — without it, an editor opens for every commit.
- For GitHub attribution to link to the original author's account, the email must match what's registered with their GitHub identity. The most reliable choice is the email they used in the original branch's commits: `git log --format='%an <%ae>' <original-branch> -1`.
- Safe on local-only branches. Shared branches require a force-push, which carries the in-place rewrite risks called out in the fresh-branch section.
