# PR Maintenance Skill System: Conceptual Framing

Design rationale and settled decisions for the skills that keep the user's open
PRs healthy — plus the whole-system map across both skill clusters.
The audience is someone reasoning about the design of these skills — future-you
revising them, or an LLM helping with revisions. The SKILL.md files serve the
agent doing the work. Companion doc:
[`atomic-commits-framing.md`](atomic-commits-framing.md) covers the
atomic-commits cluster (`planning-commits` / `crafting-commits` /
`replanning-branches`) in depth; this doc does not restate it.

## What we're building

Two skills:

- **maintaining-prs** — orchestration, triage, and repair of the user's open
  PRs: which PRs are in scope (opt-in by label), how watching is organized
  (root scheduler spawning one agent per stack), what authorizes a change
  (exactly three triggers), and the single standard procedure that performs
  every change.
- **making-git-changes** — execution mechanics for all git state changes:
  forward commits, history discipline, lease-pinned force-pushing, worktree
  isolation, stacked-branch rebasing, conflict-resolution heuristics. Grew
  from `maintaining-prs`'s original Git Methods appendix (extracted as
  `rewriting-history`, later absorbing forward-commit mechanics); shared by
  both clusters and triggered directly by ad-hoc git requests.

## The whole-system map

Five skills, two clusters, one shared executor:

| Skill | Cluster | Role |
| --- | --- | --- |
| `planning-commits` | atomic commits | plans forward work and fix placement; owns atomicity doctrine |
| `replanning-branches` | atomic commits | plans the re-decomposition of committed history |
| `crafting-commits` | atomic commits | defines the standard every commit must meet (gut check, format, honesty) |
| `maintaining-prs` | PR maintenance | watches, triages, and repairs open PRs |
| `making-git-changes` | shared executor | executes all git state changes safely, for any caller |

The clusters split by **concern, not by time**: the atomic-commits cluster owns
the shape of commit history (what the commits should be); the PR-maintenance
cluster owns PR health (CI, conflicts, review flow, delegation boundaries). A
PR-maintenance session always *starts* from a published branch, but the split is
not a pipeline — whenever a repair touches code, the commit-shape question
re-arises and the atomic-commits skills govern it. The phase split (planning vs
execution) applies across both clusters — `making-git-changes` is the single
executor for every git state change, and `crafting-commits` is the
plan-independent standard it consults whenever a commit is created or modified.

Delegation edges:

- `crafting-commits` → `planning-commits` (diff isn't atomic; needs a plan)
- `replanning-branches` → `planning-commits` (atomicity criteria),
  → `making-git-changes` (execution)
- `maintaining-prs` → `planning-commits` (shape of any repair: squash vs new
  commits), → `making-git-changes` (execution)
- `making-git-changes` → `crafting-commits` (after any operation that creates
  or modifies a commit); also fires directly on ad-hoc asks ("commit this",
  "rebase this onto main", "squash these fixups", "resolve this conflict")
  with no parent skill active

The case grid behind the routing — content × sequence — determines which
planner, if any, leads a git change:

|  | Sequence is new | Sequence exists |
| --- | --- | --- |
| **New content** | fresh work → `planning-commits` | fix placement → `planning-commits` |
| **Existing content** | re-decomposition → `replanning-branches` | pure replay (rebase onto newer base, conflicts, re-trigger) → no planner |

Plan-first applies wherever commit shape changes; pure replay needs only the
safety doctrine, with `crafting-commits`' honesty rule as the backstop.

Routing, by ask — the utterance and the skill that should lead:

- "Rebase this onto main", "squash these fixups", "resolve this conflict",
  "force-push this safely" → `making-git-changes`: the shape is already known;
  only execution is needed.
- "Clean up this branch's commits", "split this into atomic commits", "redo
  this branch's history" → `replanning-branches` (committed history) or
  `planning-commits` (uncommitted working tree).
- "Fix my PR", "why is CI red", "watch my PRs", "address the review comments"
  → `maintaining-prs`: triage precedes any mutation, and mutation happens only
  through its change procedure.
- "Commit this" → `making-git-changes`, judged against `crafting-commits`.

## maintaining-prs

**Scope:** Keeping the user's open PRs green — clean history, resolved
conflicts, passing CI — without overstepping into decisions that belong to the
user. Its subject is published branches, but it never decides what a branch's
commits should be — the shape of any repair is delegated to the atomic-commits
skills.

**Owns:**
- Opt-in scope via the `maintained-by:agent` label; the label is the user's
  delegation and only the user touches it
- The two-layer orchestration model: root agent as roster-keeper and waker
  of watchers, sole voice to the user, running the recurring pass (fetch →
  reconstruct → reconcile-and-wake) on an unattended 20–30 minute cadence;
  one dormant-but-wakeable stack agent per stack owning detection, triage,
  and all mutation
- The stack as the unit of ownership and mutation (singleton stacks for
  independent PRs)
- The three triggers (confirmed-real red CI, conflicts/dirty history,
  qualifying review feedback) and their triage doctrine
- The standard change procedure — the only path that mutates git — and its
  mandatory report template
- The 👍-as-delegation rule for third-party review comments
- The hard boundary: merging, auto-merge, and draft promotion are never in
  scope; the terminal state is *green and reported*
- The Stack Topology Reconstruction appendix (GitHub-specific, single-consumer)

**Explicitly does not own:**
- Git execution mechanics (`making-git-changes`)
- What a branch's commit sequence should be (`planning-commits` /
  `replanning-branches`)
- Merge-state changes or draft promotion (nobody — reserved to the user)

## making-git-changes

**Scope:** How to execute any git state change safely, for any caller —
forward commits and mutations alike. Mechanics, not sequence design, not
judgment.

**Owns:**
- The route-before-execute rules: a shape decision must exist when commit
  shape changes (already made in plan-led work; consult a planner when
  absent), `crafting-commits` check after any commit is created or modified,
  doctrine only for pure replay
- Forward-commit mechanics (staging, `git add -p`, `git commit`)
- History discipline (rebase-not-merge; squash fixes into the commit they fix)
- Safe force-pushing (`--force-with-lease`, lease pinned to the inspected SHA)
- Working-tree hygiene (isolated worktrees; reset before rebase; backup
  branches before destructive reorders)
- Stacked-branch rebasing (`--onto` after a parent merges)
- Conflict-resolution heuristics (append-append, follow-the-deletion,
  marker greps, pre-push hook as arbiter)
- Co-author trailers across rewritten history

**Explicitly does not own:**
- Atomicity and commit-sequence design (`planning-commits`,
  `replanning-branches`)
- The standard a commit must meet (`crafting-commits`)
- When a change is *authorized* — callers decide that (`maintaining-prs`'s
  triggers, the user's ad-hoc request); this skill only governs execution

**Triggers:** any imminent git state change — ad-hoc commit, rebase, or
conflict-resolution requests included — and invocation from `maintaining-prs`
or `replanning-branches` at their execution steps.

## Key concepts encoded in this cluster

**Label as delegation.** A PR is in scope iff authored by the user *and*
labeled `maintained-by:agent`. The default for every PR is untouched; the label
is an explicit, revocable, user-only grant. Scope changes are handled like
topology changes (respawn, don't mutate the agent).

**Stack as the unit of ownership and mutation.** Rebasing any PR in a stack
requires rebasing from the stack's base, so the stack is the natural mutation
unit — and one owner per stack means no locking anywhere in the system. Mixed
stacks (some PRs unlabeled) are watch-only: the cascade must be able to push
every branch it moves.

**Three triggers only.** Red CI (after triage confirms it's real and
blocking), conflicts/dirty history, and qualifying review feedback. Everything
else — including `UNKNOWN` mergeability, non-blocking failures, and
human-gated checks — is watch-and-report, not change.

**👍 as the delegation signal.** The user's own comments are instructions;
anyone else's are actionable only once the user reacts with a 👍. Silence for
non-qualifying comments — no "I'm not authorized" replies. Agents self-identify
when replying and never resolve threads.

**One mutation path.** Every trigger funnels into the same standard change
procedure: isolate in a worktree, cascade-rebase base-to-tip unconditionally,
apply the change in the shape `planning-commits` decided (squash, new commit,
or a mix), validate, lease-pinned push of changed SHAs only, mandatory report.
No ad-hoc mutations exist in this system.

**Green and reported, never merged.** The workflow's terminal state stops one
step short of the user's decisions: merging, arming auto-merge, and promoting
drafts are permanently out of scope.

## Conventions

- **Placement test for new content (skill vs doc vs bundled reference).**
  First ask: who reads it, at which moment? Content the *agent needs at a
  moment of work* lives in skill-space; content a *maintainer needs when
  redesigning* lives in `claude/docs/`. Within skill-space: it becomes its
  **own skill** iff it has a trigger moment of its own (a moment of work where
  it's needed and no parent skill is active), ideally with multiple consumers;
  otherwise it stays a **bundled reference** inside its single consumer.
  Rationale: docs have no loading mechanism — nothing fires them — so operative
  guidance must live where a trigger can reach it. A new skill costs a
  classifier slot (every description loads every session), so it must earn the
  trigger.
- **Naming:** the gerund-form rule from the atomic-commits framing doc is
  repo-wide (verb + -ing + object; plural where countable, bare where
  uncountable). Hence `maintaining-prs` and `making-git-changes`.
- **Repo-agnostic appendix style:** sections intended for possible extraction
  are written self-contained — no cluster vocabulary, no repo assumptions — so
  they can be lifted out as a skill without edits. This is how
  the shared git executor was born; `maintaining-prs`'s Stack Topology appendix
  keeps the same property.
- **Collection-level labels live in the plugin name.** Skill slugs describe
  their own scope; framing-doc titles name their cluster; the plugin name
  (`zabrabot`) is the home for the collection-as-a-whole label. It is
  scope-neutral by design — plugin names are effectively immutable once
  installed, and the collection will outgrow any topical label.
- **Repo specifics live in the target repo, not the skill.** Skills carry only
  the *categories* of environment facts to learn (validation hook, worktree
  bootstrap, known flakes, human-gated checks, branch conventions); the facts
  themselves are recorded in each target repo's own Claude config. These
  dotfiles are public — internal repo details don't belong here.

## Source material

Unlike the atomic-commits cluster, no published articles anchor these skills.
The content is practitioner experience from real PR-maintenance and
re-decomposition sessions: the triage heuristics, the flake cross-referencing,
the lease-pinning rule, and the 👍 delegation convention all come from observed
failure modes, not literature.

## How to engage

- **Push back on scope creep across the delegation edges.** Pressure points:
  mutation mechanics drifting back into `maintaining-prs` or
  `replanning-branches` (they cite `making-git-changes`, they don't restate
  it); triage doctrine drifting into `making-git-changes` (it executes, it
  doesn't authorize); merge/promotion capabilities drifting into scope at all.
- **Keep the report template mandatory.** Its fields exist because each one
  answers a question the user otherwise has to ask; trimming it re-opens those
  questions.

---

## Appendix: Decisions log

Decisions captured with reasoning so future sessions don't re-litigate them.

**PR maintenance is its own cluster, split from atomic commits by concern —
not by time.**
Different concerns (PR health: CI, conflicts, review flow, delegation
boundaries vs commit shape: atomicity, decomposition) and different trigger
moments. *Originally labeled pre-push vs post-push; revised:*
`replanning-branches` already operates on pushed branches, and maintenance
repairs re-enter commit shaping through delegation, so a time axis
misdescribes both clusters. The clusters compose as a loop, not a pipeline;
the concern split composes with — and does not revise — the phase and
workflow-mode axes established in the atomic-commits framing doc.

**Repair shape is planner-decided, executor-executed — always.**
The draft skill always squashed fixes into an existing commit: the common case
written down as the only case. But a 👍'd review request can be a genuinely
new atomic unit, and squashing it into an unrelated commit breaks the revert
test. Step 3 of the change procedure now consults `planning-commits` for
disposition — correction (squash), new unit (forward commit), or a mix — and
executes each part via the shared executor (now `making-git-changes`), judged
against the commit standard. "Always consult the planner" follows
the same rationale as "`planning-commits` always fires in plan mode": a
trivial disposition costs nothing to decide explicitly, and a triviality
threshold would blur the trigger. `planning-commits` (not
`replanning-branches`) is the planner because fix placement is incremental
revision of an existing sequence, not re-decomposition of a branch.

**Git Methods extracted into `rewriting-history` as its own skill.**
Access is identical either way (skills and bundled references are both files
on disk), so the decision reduces to whether the content deserves an
autonomous trigger. Three tests said yes: the *orphan-moment* test (ad-hoc
rebases and conflict resolutions happen with no parent skill active — bundled
content would never load there), the *drift* test (doctrine maintained inside
a PR-maintenance skill institutionalizes wrong-owner edits), and the
*dead-weight* test (`maintaining-prs` loads for watch-only sessions where
mutation doctrine is ballast). Extraction also extends the cluster's validated
single-owner pattern rather than inventing a new mechanism. *Revisit if the
skill misfires on branch-reshaping asks (where `replanning-branches` should
lead) or fails to fire on ad-hoc rebases.*

**The placement test is recorded as a repo-wide convention.**
The extraction decision generalized cleanly (audience/moment first, then
trigger-of-its-own), so it's captured under Conventions above for the next
"skill or doc?" question rather than being re-derived.

**Stack Topology Reconstruction stays bundled in `maintaining-prs`.**
It fails the multiple-consumers half of the placement test: GitHub- and
`gh`-specific, with exactly one consumer. It keeps the repo-agnostic
lift-without-edits style. Revisit if a second consumer appears (e.g. a future
stacked-PR authoring skill).

**Renamed `pr-babysitting` → `babysitting-prs` → `maintaining-prs`.**
Two steps. The first was mechanical: the gerund-form rule in the atomic-commits
decisions log requires verb-first slugs, and the draft name was object-first.
The second was word choice: "babysitting" was informal register the user
disliked, and `maintaining-prs` aligns with vocabulary the system had already
committed to — the `maintained-by:agent` scope label, the PR-maintenance
cluster name, and this doc's filename. "Babysit" stays in the skill
description as trigger vocabulary, since it's what the user actually says.
*Nuance to revisit:* the skill name is now nearly the cluster's name, which
the naming convention warns about ("a skill's name describes its own scope,
never the cluster it serves"). Harmless while this is the cluster's only core
skill — the name genuinely describes its own scope — but reconsider if the
cluster grows a sibling.

**`rewriting-history` kept, despite sounding odd out of context.**
It is git's own term of art — the Pro Git chapter covering amend, rebase, and
filter-branch is titled "Rewriting History" — and term-of-art names match what
users actually type, which is what triggering needs. The runner-up,
`mutating-history`, matched this doc's internal vocabulary ("mutation
mechanics", "history mutation") but lost to external convention.
`reshaping-history` was rejected outright: "re-shaping committed history" is
`replanning-branches`' established phrase, and reusing it would blur the
planner/executor boundary.

**One framing doc covers the cluster plus the whole-system map.**
The cross-cluster ownership map (five skills, delegation edges) needs a home,
and a third "system overview" doc would split the audience's attention.
This doc holds the map; `atomic-commits-framing.md` remains the in-depth
reference for its own cluster, unmodified.

**Scope is opt-in via label; the agent never touches the label.**
The default posture for any PR is *untouched*. Watching and (especially)
force-pushing someone's branch is delegation that must be granted explicitly
and revocably, PR by PR — a label is visible in the GitHub UI, auditable, and
removable by the user without talking to the agent.

**Exactly three triggers; everything else is watch-only.**
An agent with push access needs a closed list of things that authorize a
mutation, not judgment calls. The triage doctrine exists to shrink false
positives (staleness, flakes, non-blocking checks, `UNKNOWN` mergeability);
the closed list exists to make false positives the only possible failure mode
— an unauthorized *kind* of action can't happen if it isn't on the list.

**Merging and draft promotion are permanently out of scope.**
The terminal state is *green and reported*. Merging is the one action whose
consequences the user can't undo by re-pushing a branch, and promotion changes
who gets notified and asked to review — both are the user's calls by
construction, not by configuration.

**Repo-specific facts live in the target repo's config, not in the skill.**
*Resolves a former open question.* The draft carried one repo's facts — a
named pre-push hook, a named infra flake, named human-gated checks, a
colleague's branch prefix. Two problems: facts rot invisibly when they live
far from their repo, and these dotfiles are public, so another repo's internal
operational details leak. The section is now a checklist of categories to
learn per repo — each category is the generalized residue of one original
fact — plus an instruction to record findings in the target repo's own Claude
config. The original facts were handed back to the user to relocate.

**`replanning-branches`' mutation mechanics migrated to `rewriting-history`.**
*Resolves a former open question.* The co-author-trailer `rebase --exec`
mechanic and the backup-branch-before-destructive-reorder rule were execution
doctrine living in a planner — the exact drift the how-to-engage section warns
about. No argument for keeping them surfaced: the trailer mechanic is
repo-agnostic git execution with a plausible ad-hoc trigger of its own
("credit Alice on these commits"), and the backup rule generalizes to any
destructive reorder. `replanning-branches` now cites both.

**Plugin distribution: one brand-named plugin (`zabrabot`) under an owner
marketplace (`zabrador`).**
The repo doubles as a plugin marketplace, with `claude/` as the plugin root
via a relative source path — nothing moved. One plugin rather than
per-cluster plugins: the distribution unit matches the stow channel (the
whole collection), and adding topical plugins to the marketplace later is
free if selective installation ever matters. Brand-named rather than topical:
plugin names are effectively immutable once installed (a rename forces a
settings migration), automatic triggering never sees the prefix (skill
descriptions drive it), and the collection will outgrow any topical name.
The plugin channel serves other people; the stow channel serves the user's
own machines. Installing both on one machine duplicates every skill (bare
and namespaced) — don't.

**`rewriting-history` and `committing-changes` refactored into
`making-git-changes` + `crafting-commits`.**
*Supersedes "`rewriting-history` kept, despite sounding odd" above and
reshapes the extraction entry's boundaries.* The standard/mechanics
factorization and its full rationale live in `atomic-commits-framing.md`'s
decisions log; the whole-system consequences live here: `making-git-changes`
is the single executor for every git state change (forward and mutating),
`crafting-commits` is the plan-independent standard consulted whenever a
commit is created or modified, and the case grid above records when a
planner leads and when none does.

**Plugin root relocated from `claude/` to `claude/plugin/`.**
Three path-semantics collisions in quick succession exposed the problem with
`claude/` doubling as plugin root and personal-config tree:
`claude/settings.json` is a reserved plugin-component name,
`.claude/settings.json` is live project settings, and `docs/` plus `user/`
shipped to plugin consumers as dead weight. The plugin root now contains only
published content (the manifest and `skills/`), so reserved component names
are landmines only inside `claude/plugin/` — where using one is deliberate —
and personal files never ship. Consumers are unaffected: the marketplace
`source` path is internal wiring, and the plugin name (`zabrabot:`) doesn't
change.

**Trigger routing is encoded, not just hoped for.**
The skill descriptions carry not-this-skill signals at the known confusion
points (`maintaining-prs` no longer claims "rebase a branch";
`replanning-branches` disclaims plain rebases), and the whole-system map
records ask→skill routing. What remains is empirical — see Open questions.

**Classifier denials: one user-authorized retry, then terminal — never
diagnose in-session.**
A 2026-08-01 session hit four byte-identical denials across three mechanisms
(the direct call, a settings edit that would permit it, an agent spawn whose
prompt merely described it) and spent roughly a third of its turns editing
policy files and spawning test agents to diagnose a gate that surfaces no
reasons and keys on intent, not wording. The retry allowance exists because
one denial in the same session *was* a false positive, cleared by an explicit
user go. Pre-execution denials and post-hoc warnings are kept explicitly
distinct because the session's costliest wrong turn was inferring the denial
gate's reasoning from a warning's policy citation — separate mechanisms,
separate evidence.

**The label supersedes repo docs on agent-authored replies.**
User ruling (2026-08-01): a target repo's AGENTS.md ban on replying on a
human's behalf collided with trigger 3's reply requirement; the user ruled
the skill's standing delegation governs. Encoded so future sessions flag the
conflict once instead of relitigating — the observed session spent several
turns on it, including amending the target repo's AGENTS.md, which didn't
clear the permission gate anyway. The eval baseline confirmed the failure
mode: without the rule, the executor deferred to the repo doc and withheld
the reply.

**Report template extended: judgment calls, human-gated checks, worktree
disposition.**
Per how-to-engage, each template field answers a question the user otherwise
has to ask; all three additions were demanded ad hoc (post-bounce) in the
observed session. Judgment calls, because conflict resolution sometimes
embeds a decision the user must be able to veto (a CODEOWNERS line kept from
`main`); human-gated checks, because agents otherwise report "green except
one thing" without naming the human action; worktree disposition, because
bootstrapped worktrees are multi-GB and were silently orphaned across a
session.

**Stack agents are told their turn-ending semantics: termination, not pause.**
Two of four stack agents in the observed session ended their turn mid-work
with a status line, one explicitly expecting a background monitor to wake it
— but a terminated agent has no live child to wake it, so the result was
silent abandonment that root caught only by bouncing non-template reports.
The skill now states the invariant (wait synchronously; template or
escalation are the only legitimate turn-ending outputs) on the agent side and
tells root to treat non-template output as work-in-progress. This also
answers half of the "agent-architecture spec" open question: the doctrine is
background-agent-aware by construction.

**Enumeration is the first recurring pass — cadence is explicit, unattended
by default.**
User ruling (2026-08-01): root asked permission twice before scheduling the
recurring pass the doctrine implies, leaving a freshly-labeled PR conflicting
and unowned until the user noticed. Two gaps: the skill never defined when a
"pass" happens, and never said root runs unattended — so an agent read "keeps
the assignment current" as a consistency property and treated the timer as a
new authorization. The label is the authorization. A follow-up refinement
removed "initial enumeration" as a concept: the first enumeration is just the
first pass, so every pass is the same code path with no special case. The
stop condition deliberately outlives green moments — open PRs drift as `main`
advances and labels arrive between passes, so a scheduler that stops when
everything is green recreates the missed-label failure it exists to prevent.
On surfaces without a scheduling mechanism, the pass runs per-invocation and
the user is told watching is not continuous (a further partial answer to the
agent-architecture open question).

**Root schedules *and detects*; "pure scheduler" superseded.**
The stateless pass plus termination semantics left "what is new?" with no
owner: stack agents die with their memory, so a 2026-08-04 session improvised
a wall-clock cutoff and missed a user instruction for an hour — and three
approvals entirely, because the reviews endpoint was never polled. The pass
gains a Detect step: a root-persisted watermark and a mandatory four-surface
sweep (review bodies, inline comments, conversation comments, reactions — the
last because a 👍, the delegation signal itself, changes no PR-level field).
Root may also run quiet-stack confirmation itself rather than spawning a
~55k-token agent to observe nothing changed — a deliberate revision of "root
as pure scheduler": root schedules and detects, strictly read-only; stack
agents keep all mutation and all trigger response, and the sweep contract is
identical wherever it runs (trimming it to head SHA/mergeable/CI is the named
failure). The watermark bounds the sweep only from below — acting is
qualification-gated, so over-sweeping is tokens and under-sweeping is a
missed instruction; first pass or lost state means sweep everything open.
Deltas are handed into spawn briefs with their watermark stated, and agents
re-verify before acting — the session's stale skip-list brief was caught only
because the agent didn't trust it.

**Detection lives in dormant-but-wakeable watchers; root sweeps nothing.**
*Supersedes the "root schedules and detects" entry above and its quiet-stack
no-spawn rule, same day, before either shipped.* Root-side detection had a
context flaw caught in review: N stacks × four surfaces every 20–30 minutes
lands every sweep in a session-long context — root drowns, and a root that
compacts is a scheduler that forgets. The invariant that survives
relocation: **sweep outputs land in disposable contexts; long-lived contexts
hold only watermarks and deltas.** Mechanism: root wakes dormant watchers
each pass (context intact), chosen over self-pacing sleep loops (assumes
indefinite idling, and a crashed watcher looks identical to a sleeping one)
and over per-pass disposable detectors (a spawn of overhead every pass, and
detection leaves stack ownership). Wake-based liveness is the load-bearing
detail — the hole this model opens is dead-watcher blindness, and a wake
with no response closes it: respawn with the last reported watermark. The
quiet-stack economics resolve to "dormant, not dead": watchers are woken,
not respawned, so the no-spawn rule is moot and every in-scope stack keeps
its watcher. The watermark discipline and four-surface sweep contract are
unchanged, relocated into the watcher; the turn-ending doctrine gains its
one legitimate quiet exit — a report is what makes dormancy safe to wake.

**Detection is stateless: GitHub is the ledger; the watermark is gone.**
*Supersedes the watermark mechanics in the watcher entry above, same day.*
Two things killed the watermark. First, the reactions rule had already
hollowed it out: a 👍 can land on an old comment and comment listings carry
only reaction counts, so every sweep must re-enumerate every comment anyway —
the watermark bounded almost nothing. Second, it had a seen≠handled gap: it
advances when the sweep completes, not when the work completes, so a watcher
dying between sweep and action strands the item below the bound. The
replacement was already mandated by trigger 3: the self-identified inline
reply. Pending = a qualifying item with no agent response after it; red CI
and conflicts were always current-state checks. Handled-ness now lives in
durable, shared, self-healing state — unhandled work keeps re-surfacing
until it is actually handled. Consequences: the reply is load-bearing, not
courtesy (the user's own instructions get in-thread acknowledgments for
exactly this reason); root's context shrinks to roster + liveness + the
parked-items list (the one exception state — a classifier-parked reply stays
pending on the ledger, and the list stops fresh watchers from re-attempting
it); watcher respawn is lossless by construction; the first-sweep special
case disappears. The rewritten eval cases passed against the watermark skill
(29/29 red), so this change is design-motivated, not eval-motivated — the
cases guard the ledger semantics rather than prove the watermark was
misbehaving. Category lesson, noted twice this project now: before building
a custom state mechanism, check whether durable native state already encodes
what it would track.

## Open questions

- **`maintaining-prs` doubles as an agent-architecture spec** (root scheduler,
  headless background stack agents). How does it degrade on surfaces without
  background agents — does the doctrine still apply single-threaded, and
  should the skill say so?
- **Does the trigger partition hold in practice?** The descriptions now carry
  not-this-skill signals and the system map records ask→skill routing; what
  remains is empirical. Watch real sessions for misfires — especially "rebase"
  asks landing on the wrong side of the mechanics vs sequence-design line.
- **Do the label name (`maintained-by:agent`) and the 👍 convention generalize
  across repos and teams**, or do they need per-repo configuration the way the
  environment-specifics section does?
