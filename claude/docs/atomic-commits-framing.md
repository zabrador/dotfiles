# Atomic Commits Skill System: Conceptual Framing

This document captures the conceptual approach and settled decisions for a two-skill system that helps Claude produce atomic git commits. It is intended to be uploaded to the Project's knowledge base so that future Claude sessions can pick up without requiring the framing to be re-derived.

## What we're building

Two coordinated Claude skills for Claude Code:

- **commit-planning** (Skill 1) — the conceptual and decompositional skill. Understands what makes a commit atomic; helps plan work as a sequence of atomic commits; carves up tangled working trees into coherent commits.
- **atomic-commits** (Skill 2) — the execution skill. Runs at the moment of commit. Quick gut check that the current diff is atomic, crafts a Conventional Commits message, runs the git commands.

Skill 1 owns the deep understanding. Skill 2 owns the mechanics and defers to Skill 1 when decomposition work is required.

## Three altitudes of planning

When thinking about where work lives, three levels:

1. **Feature planning** — given a roadmap item, what's the sequence of shippable slices? Produces tickets/PRs. *Out of scope for both skills.*
2. **Implementation planning** — given a single ticket, what's the sequence of commits that gets there? *Skill 1's territory.*
3. **Commit execution** — given a completed unit of work, craft the commit. *Skill 2's territory.*

The boundary between levels 1 and 2 is **shippability to users**. Feature planning produces units that can ship independently and provide value on their own; implementation planning produces units that advance the codebase correctly but don't necessarily ship alone (e.g., a refactor commit enabling a later feature commit).

## Skill 1: commit-planning

**Scope:** Decomposing implementation work into atomic commits. Applicable during planning mode before coding, when Claude notices mid-work that the task has multiple concerns, and as a fallback when Skill 2 encounters a tangled working tree.

**Owns:**
- The conceptual definition of an atomic commit (including the SRP analogy)
- The three operational criteria (passes CI, deployable, no dead code) plus the revert test
- The refactor → feature → cleanup pattern ("make the change easy, then make the easy change")
- Vertical vs horizontal slicing heuristics
- Recognition of the "this task is actually a feature, slice it first" signal
- Recovery path for tangled working trees

**Triggers:**
- User enters planning mode for a non-trivial change
- User asks to split, reorganize, or clean up commits
- Skill 2 detects a non-atomic diff and invokes Skill 1

## Skill 2: atomic-commits

**Scope:** Executing a single commit at the moment of committing.

**Owns:**
- A compact atomicity gut check (not full analysis)
- Conventional Commits message format
- Git mechanics (status, diff, add, commit)
- An escape hatch: if the gut check fails, stop and defer to Skill 1

**Triggers:**
- User asks Claude to commit
- Claude reaches a natural breakpoint in the commit-as-you-go workflow and is about to commit

**Explicitly does not own:**
- Full decomposition of tangled trees (defers to Skill 1)
- Deep atomicity reasoning (uses a compact checklist instead)
- Refactor/feature/cleanup decomposition

## Workflow

**Primary: commit as you go.** At natural breakpoints during the work — refactor finished, function added, feature wired up — pause and commit before continuing. This avoids producing a tangled working tree that resists clean splitting. It mostly sidesteps the "impossible to split" failure mode by ensuring work never becomes tangled in the first place.

**Fallback: tangled-tree recovery.** If a working tree is already mixed (multiple concerns committed together in the staging area or working copy), Skill 2 invokes Skill 1 to produce a decomposition plan, then commits each piece per the plan.

## Conventions

- **Commit messages:** Conventional Commits (`type(scope): summary`)
- **Mixed concerns:** Pragmatic stance — split when it clearly helps review, don't force splits for small mixed changes that would produce awkward single-line commits
- **Target platform:** Claude Code (has git access)

## Source material

Four articles anchor the skills:

- **Aleksandr Hovhannisyan, [Make Atomic Git Commits](https://www.aleksandrhovhannisyan.com/blog/atomic-git-commits/).** Foundational. Contributes the single-responsibility-principle analogy and the **revert test**: a commit is atomic if reverting it would remove only the changes described in its message, nothing else.
- **Sandro Dzneladze, [A Developer's Guide to Atomic Git Commits](https://medium.com/@sandrodz/a-developers-guide-to-atomic-git-commits-c7b873b39223).** Best source for the Conventional Commits integration. Contributes "as small as possible, but complete" framing.
- **Joël Quenneville, [Working Iteratively](https://thoughtbot.com/blog/working-iteratively) (Thoughtbot).** Contributes the sharp three atomicity criteria we use (passes CI, deployable, no dead code), the **refactor → feature → cleanup** pattern ("make the change easy, then make the easy change"), and the **"and" heuristic** for commit titles.
- **German Velasco, [Break apart your features into full-stack slices](https://thoughtbot.com/blog/break-apart-your-features-into-full-stack-slices) (Thoughtbot).** Operates one altitude up (feature slicing). Relevant as supporting material for Skill 1's "this task is actually a feature" recovery path, and for the vertical-vs-horizontal slicing nuance.

Secondary sources reviewed but not anchored on: Samuel Faure (primarily motivational), PHP Architect (tactical git commands — useful for Skill 2's mechanics section but not the framing), Fausto Núñez Alberro (general practice argument), and several shallower articles.

## Key concepts encoded across both skills

**Atomicity checks.** A commit is atomic when:
- It passes CI
- It is deployable
- It introduces no dead code
- It passes the revert test (reverting it would remove only the described change, nothing else)

**The "and" heuristic.** If the commit title needs the word "and" to describe what changed, it is probably multiple commits.

**The refactor → feature → cleanup pattern.** When a task naturally has multiple commits, structure them as (1) refactors that enable the feature, (2) the feature itself, (3) cleanup afterward — each as its own commit. "Make the change easy, then make the easy change."

**Vertical slicing with inversion.** At the ticket/PR level, slice vertically (thin full-stack wedges). Within a PR at the commit level, horizontal layering (enabling refactor, then feature) is often correct because those units don't need to ship independently — they need to be reviewable and revertible.

---

## Appendix: Decisions log

Decisions captured with reasoning so future sessions don't re-litigate them. Ordered roughly by when they were settled.

**Build the skill to help structure work atomically, not just to execute commits at the end.**
Initial framing was ambiguous — could have been an end-of-work splitter. Rejected because tangled working trees resist clean splits regardless of tooling quality; the real leverage is structuring work atomically as it happens. Revisit if: planning-phase triggers prove unreliable in practice.

**Split into two skills along phase lines, not knowledge-type lines.**
Considered splitting by knowledge type (conceptual vs tactical). Rejected because conceptual-only skills trigger poorly — skills fire when tied to a moment of work. Phase-based splits (planning / execution) give each skill an unambiguous trigger moment.

**Build Skill 2 first despite Skill 1 being the long-term goal.**
Skill 2 is more constrained, easier to test (observable outputs on a working tree), and produces a working artifact that validates the conceptual framing before we invest in the harder planning-phase skill.

**Commit-as-you-go as the primary workflow.**
Alternatives: end-of-work splitting (rejected — produces tangled trees) and planning-phase-only guidance (too ambitious for a single skill). Commit-as-you-go avoids the tangled-tree problem at its source.

**Conventional Commits.**
User preference. Widely adopted, tool-friendly (semantic-release, changelog generators), and well-represented in source material.

**Pragmatic stance on mixed concerns.**
User preference. Split when it clearly helps review; don't force splits for small mixed changes that would produce awkward one-line commits.

**The refactor → feature → cleanup pattern lives in Skill 1, not Skill 2.**
Initially drafted into Skill 2; removed because it's decompositional guidance, not execution guidance. Skill 2 only needs to recognize "this diff spans multiple concerns" and defer.

**Skill 2 slims down substantially; conceptual content migrates to Skill 1.**
Initial Skill 2 draft included the full atomicity framework. Reconsidered — most of that content is planning knowledge that Skill 1 should own. Skill 2 becomes roughly 30–40 lines: gut check, message format, git mechanics, escape hatch.

**When Skill 2 fires without Skill 1 available, handle honestly.**
If a diff fails the gut check and Skill 1 isn't invokable, Skill 2 tells the user the diff needs splitting and offers to help — rather than silently producing a bad commit or attempting full decomposition itself.

**Feature-level slicing is out of scope for both skills.**
Velasco's full-stack-slice framing operates at a different altitude (feature → tickets). Keeping it out of scope prevents Skill 1 from having an ambiguous trigger story. Retained as supporting material for the "this task is actually a feature" recovery path.

## Open questions

- Does Skill 1 need to trigger specifically during planning mode, or more broadly? Unclear until we test.
- How does Skill 1 surface itself when Skill 2 invokes it — explicit reference, natural invocation, or something else? To be decided during Skill 1 design.
- Should behavior differ between Claude Code and other surfaces? Current scope is Claude Code only.
