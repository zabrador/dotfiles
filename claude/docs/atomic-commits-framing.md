# Atomic Commits Skill System: Conceptual Framing

Design rationale and settled decisions for the two-skill system that helps Claude produce atomic git commits. The audience is someone reasoning about the design of these skills — future-you revising them, or an LLM helping with revisions. The SKILL.md files and source articles serve readers learning atomic commits.

## What we're building

Two coordinated Claude skills for Claude Code:

- **commit-planning** — the planning and decompositional skill. Understands what makes a commit atomic; lays out the sequence of atomic commits a change requires; revises the plan when execution reveals it was wrong (and creates one post-hoc when none existed).
- **atomic-commits** — the execution skill. Runs at each commit point. Generic gut-check on the current diff; if atomic, writes a Conventional Commits message and commits; if not, defers to `commit-planning`.

`commit-planning` owns the deep understanding and produces the commit plan. `atomic-commits` owns the mechanics and defers to `commit-planning` whenever the current diff isn't atomic.

## Three altitudes of planning

When thinking about where work lives, three levels:

1. **Feature planning** — given a roadmap item, what's the sequence of shippable slices? Produces tickets/PRs. *Out of scope for both skills.*
2. **Implementation planning** — given a single ticket, what's the sequence of commits that gets there? `commit-planning`'s territory.
3. **Commit execution** — given the current diff, gut-check it and commit. `atomic-commits`'s territory.

The boundary between levels 1 and 2 is **shippability to users**. Feature planning produces units that can ship independently and provide value on their own; implementation planning produces units that advance the codebase correctly but don't necessarily ship alone (e.g., a refactor commit enabling a later feature commit).

## commit-planning

**Scope:** Producing the sequence of atomic commits a coding change requires, and revising that plan when execution diverges from it. The primary skill in the cluster — fires up front to lay out the work and again on the fly whenever the plan needs to change.

**Owns:**
- The **principle** of commit atomicity (SRP analogy + "and" heuristic as its linguistic form)
- The **generative move** for arriving at atomic commits ("work backward from the feature: what would the code need to look like for this change to be small?")
- The **verification** criteria (passes CI, deployable, no dead code, plus the revert test)
- The refactor → feature → cleanup pattern ("make the change easy, then make the easy change")
- Vertical vs horizontal slicing heuristics
- Recognition of the "this task is actually a feature, slice it first" signal
- Recognition of when a commit-assignment problem is a software-design problem in disguise
- The commit plan: produced up front, revised when execution diverges, created post-hoc when none existed

**Triggers:**
- Plan mode is active — any change Claude is planning, trivial or not
- `atomic-commits` defers because the current diff isn't atomic
- User explicitly asks to plan, split, reorganize, or clean up commits

## atomic-commits

**Scope:** Executing a single commit at the moment of committing.

**Owns:**
- A compact atomicity gut check (not full analysis), independent of any plan
- Conventional Commits message format
- Git mechanics (status, diff, add, commit)
- The handoff to `commit-planning` when the gut check fails

**Triggers:**
- User asks Claude to commit
- Claude finishes a planned commit unit and is about to commit it

**Explicitly does not own:**
- Full decomposition of tangled trees (defers to `commit-planning`)
- Deep atomicity reasoning (uses a compact checklist instead)
- Refactor/feature/cleanup decomposition
- Awareness of the plan — the gut check is plan-independent by design

## Workflow

**Primary: plan, then execute.** When Claude takes on a non-trivial coding change, `commit-planning` runs first and lays out the sequence of atomic commits the change needs. Plan mode is the canonical trigger — whenever Claude enters plan mode, producing a commit plan is part of the work. Trivial changes collapse to single-commit plans at near-zero overhead, so there's no triviality threshold to apply. Claude then executes against the plan, invoking `atomic-commits` at each commit point.

**Replanning and recovery.** Plans drift on contact with code. Execution can reveal an unanticipated refactor, a hidden dependency, or a commit boundary the plan missed. The mechanism: `atomic-commits` runs a generic gut-check against the current diff, independent of any plan. If the diff fails the check, `atomic-commits` defers to `commit-planning`, which updates the plan (or creates one from scratch, for cases where Claude went straight to committing without planning first). Work resumes against the revised plan.

## Conventions

- **Commit messages:** Conventional Commits (`type(scope): summary`)
- **Mixed concerns:** Pragmatic stance — split when it clearly helps review, don't force splits for small mixed changes that would produce awkward single-line commits
- **Target platform:** Claude Code (has git access)

## Source material

Four articles anchor the skills:

- **Aleksandr Hovhannisyan, [Make Atomic Git Commits](https://www.aleksandrhovhannisyan.com/blog/atomic-git-commits/).** Foundational. Contributes the single-responsibility-principle analogy and the **revert test**: a commit is atomic if reverting it would remove only the changes described in its message, nothing else.
- **Sandro Dzneladze, [A Developer's Guide to Atomic Git Commits](https://medium.com/@sandrodz/a-developers-guide-to-atomic-git-commits-c7b873b39223).** Best source for the Conventional Commits integration. Contributes "as small as possible, but complete" framing.
- **Joël Quenneville, [Working Iteratively](https://thoughtbot.com/blog/working-iteratively) (Thoughtbot).** Contributes the sharp three atomicity criteria we use (passes CI, deployable, no dead code), the **refactor → feature → cleanup** pattern ("make the change easy, then make the easy change"), and the **"and" heuristic** for commit titles.
- **German Velasco, [Break apart your features into full-stack slices](https://thoughtbot.com/blog/break-apart-your-features-into-full-stack-slices) (Thoughtbot).** Operates one altitude up (feature slicing). Relevant as supporting material for `commit-planning`'s "this task is actually a feature" recovery path, and for the vertical-vs-horizontal slicing nuance.

Secondary sources reviewed but not anchored on: Samuel Faure (primarily motivational), PHP Architect (tactical git commands — useful for `atomic-commits`'s mechanics section but not the framing), Fausto Núñez Alberro (general practice argument), and several shallower articles.

## Key concepts encoded across both skills

**Atomicity, in three roles.** Not five competing definitions but three jobs:
- **Principle.** A commit does one thing — version-control SRP. The "and" heuristic is its linguistic form: if the title needs "and" to describe what changed, the commit is probably multiple commits.
- **Generative move.** "Work backward from the feature: what would the code need to look like for this change to be small?" The move that produces atomic commits, especially in the tangled-tree case.
- **Verification.** A commit is atomic when it passes CI, is deployable, introduces no dead code, and passes the revert test (reverting removes only the described change, nothing else).

**The refactor → feature → cleanup pattern.** When a task naturally has multiple commits, structure them as (1) refactors that enable the feature, (2) the feature itself, (3) cleanup afterward — each as its own commit. "Make the change easy, then make the easy change."

**Commit assignment as design proxy.** "Which commit does this behavior belong to?" is sometimes "is this behavior intrinsic to the abstraction, or a per-consumer concern?" in disguise — a software-design question that commit-planning recognizes and defers to. Resolve the design; the commit sequence follows.

**Vertical slicing with inversion.** At the ticket/PR level, slice vertically (thin full-stack wedges). Within a PR at the commit level, horizontal layering (enabling refactor, then feature) is often correct because those units don't need to ship independently — they need to be reviewable and revertible.

## How to engage

- **Push back on scope creep between `commit-planning` and `atomic-commits`.** Content that belongs to one should not migrate to the other without explicit reconsideration.
- **When introducing a concept drawn from the source articles, name the source.**

---

## Appendix: Decisions log

Decisions captured with reasoning so future sessions don't re-litigate them. Ordered roughly by when they were settled.

**Build the skills to help structure work atomically, not just to execute commits at the end.**
Tangled working trees resist clean splits regardless of tooling quality; the leverage is upstream, not at the moment of commit. Revisit if planning-phase triggers prove unreliable in practice.

**Split into two skills along phase lines, not knowledge-type lines.**
Conceptual-only skills trigger poorly because skills fire when tied to a moment of work. Phase-based splits (planning / execution) give each skill an unambiguous trigger moment.

**Plan-led with in-flight replanning as the primary workflow.**
*Supersedes an earlier "commit-as-you-go" decision.* Plan mode is the natural rhythm of Claude Code work, and laying out the commit sequence is a natural extension of it. The original objection — that planning-phase-only guidance is too ambitious for one skill — was made when only one skill was contemplated; split across two skills, the planner carries the conceptual load and the executor stays slim. Plan-led isn't end-of-work splitting (which produces tangled trees); replanning during execution handles plan drift honestly rather than pretending plans are rigid.

**`atomic-commits`'s gut check stays plan-independent.**
The skill checks the current diff against atomicity criteria, never against a plan. This keeps `atomic-commits` slim, decoupled, and robust when no plan exists in context (e.g., the user jumped straight to committing). The plan, when it exists, lives in Claude's working memory and shapes Claude's coding behavior — not `atomic-commits`'s logic.

**`commit-planning` always fires in plan mode, regardless of triviality.**
A trivial change just produces a single-commit plan at near-zero overhead, so there's no triviality threshold to apply. Keeps the trigger sharp; spares the skill from having to make a judgment call about whether to fire.

**Conventional Commits.**
User preference. Widely adopted, tool-friendly (semantic-release, changelog generators), and well-represented in source material.

**Pragmatic stance on mixed concerns.**
User preference. Split when it clearly helps review; don't force splits for small mixed changes that would produce awkward one-line commits.

**The refactor → feature → cleanup pattern lives in `commit-planning`, not `atomic-commits`.**
It's decompositional guidance, not execution guidance. `atomic-commits` only needs to recognize "this diff spans multiple concerns" and defer.

**`atomic-commits` slims down substantially; conceptual content migrates to `commit-planning`.**
Most of the atomicity framework is planning knowledge that `commit-planning` should own. `atomic-commits` becomes roughly 30–40 lines: gut check, message format, git mechanics, handoff to `commit-planning`.

**When `atomic-commits` fires without `commit-planning` available, handle honestly.**
If a diff fails the gut check and `commit-planning` isn't invokable, `atomic-commits` tells the user the diff needs splitting and offers to help — rather than silently producing a bad commit or attempting full decomposition itself.

**Feature-level slicing is out of scope for both skills.**
Velasco's full-stack-slice framing operates at a different altitude (feature → tickets). Keeping it out of scope prevents `commit-planning` from having an ambiguous trigger story. Retained as supporting material for the "this task is actually a feature" recovery path.

**Atomicity reframed as three roles, not a flat list of definitions.**
The original framing stacked SRP, the single-sentence test, the three operational criteria, the revert test, and the "and" heuristic as if they were five attempts at one definition. They actually answer three different questions — what atomicity *is* (principle), how to *arrive* at it (generative move), and how to *check* it (verification). Reorganized along those three roles, with the "work backward from the feature" generative move promoted from a buried tip in the refactor pattern to a top-level concept threaded through Planning-during-work and Recovery. The generative move is what makes tangled-tree recovery tractable; burying it in the refactor pattern hid it from exactly the case where it does the most work.

**Foundational vs layered is software design, not commit planning.**
*Supersedes an earlier decision to add the heuristic to `commit-planning`.* The two tests (spec-identity, consumer-universality) are general software-design heuristics, independent of how work is decomposed into commits. Putting them in `commit-planning` made it a vehicle for design knowledge it doesn't own. The narrower commit-planning-specific insight that remains is the recognition that *when commit-assignment is hard, the question is usually a design question in disguise — resolve the design first*. That escalation stays in `commit-planning` as a short section parallel to "this task is actually a feature"; the design heuristics themselves don't.

## Open questions

- How explicit does `commit-planning`'s SKILL.md description need to be about plan mode, so that "fires in plan mode" actually happens reliably and isn't aspirational? Skill triggers are classifier-shaped — the description has to give Claude a sharp signal.
- How does `commit-planning` surface itself when `atomic-commits` invokes it — explicit reference, natural invocation, or something else? To be decided during the design of `commit-planning`.
- Should behavior differ between Claude Code and other surfaces? Current scope is Claude Code only.
