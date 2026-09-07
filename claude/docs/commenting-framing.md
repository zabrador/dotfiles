# Commenting Skill: Conceptual Framing

Design rationale and settled decisions for the skill that governs code
comments. The audience is someone reasoning about the design — future-you
revising it, or an LLM helping with revisions. The SKILL.md serves the agent
doing the work.

## What we're building

One skill:

- **writing-comments** — the standard for TSDoc/docblocks and implementation
  comments. It judges comments against the code as it exists. It does not
  govern prose style, README structure, ADRs, or other documentation formats.

A standalone cluster. It does not route through the atomic-commits or
PR-maintenance skills. Those skills may produce comments as a side effect of
editing code; this skill is the standard those comments should meet.

## Scope

Comments only — TSDoc on interfaces, and comments inside implementations.
The work started as a general complaint about writing quality and narrowed
twice: prose → documentation → comments. The narrowing was the right move.
Comments are a better target than prose because the decision is close to
binary, the failure modes are nameable, and a meaningful fraction is
machine-checkable.

**Cut, and do not reopen:**

- **Prose style, generally.** The original ask. The plan sketched for it —
  anti-pattern list, separate edit pass, frozen eval set — remains valid for
  a future skill.
- **Matching the user's personal voice.** Explicitly rejected. The target is
  neutral and articulate, not personal. No corpus of the user's writing
  feeds this.
- **Documentation formats.** A candidate skill was evaluated and rejected:
  `MoizIbnYousaf/ai-agent-skills`, `skills/code-documentation` (attributed
  upstream to `wshobson/agents`, MIT). It is a format library — README
  skeleton, JSDoc syntax, OpenAPI sample, ADR template — with essentially no
  content about writing quality. It restates formats the model already
  knows, and its templates push toward the over-structured output that
  motivated the original complaint. Its good/bad inline-comment pairs are
  the best part; that *structure* is what this skill steals.
- **Format conventions for a particular monorepo.** Real, but should be
  derived from that repo's house conventions. Out of scope here.
- **A design-notes system for cross-module decisions.** Ousterhout 13.7
  suggests a central file with pointers from the code. Where that file
  lives is a documentation-format question (and interacts with package
  taxonomy work). This skill writes the local constraint and points at a
  durable reference if one exists; it does not create `DESIGN.md` files.

## Sources

**John Ousterhout, *A Philosophy of Software Design*.** The spine. Relevant
chapters: 12 (the four excuses), 13 (comments describe what isn't obvious —
the core), 14 (names; a comment defining an unclear name should usually be
a rename), 15 (write the comments first — *not adopted as a workflow*; see
decisions), 16 (modifying existing code; comments belong in the code, not
the commit log; avoid duplication).

Red flags carried forward: Comment Repeats Code, Implementation
Documentation Contaminates Interface, Hard to Describe, Vague Name.

The precision checklist from 13.3 is the most actionable item in the
literature: for declarations, specify units, inclusive/exclusive bounds,
what null means, who owns the resource, and what invariants hold.

Ousterhout's posture differs from the other sources. They treat comments as
a fallback when code fails to explain itself. He puts comments in the
design loop and treats difficulty writing one as evidence about the design.
We keep the diagnostic (principle 12) and drop the "write comments first"
workflow.

**Ellen Spertus, "Best practices for writing code comments", Stack Overflow
Blog, 23 Dec 2021.** The valuable cluster is rules 6–8, on references:
link the source of copied code, link external standards, comment bug fixes
with issue-tracker references. Rule 9 supplies structured TODOs. Rule 3
anticipates Ousterhout's design-signal argument. On the one conflict —
Spertus says a comment can beat `git blame`; Ousterhout 16.3 says comments
belong in the code rather than the commit log — we follow Ousterhout.

**Jeff Atwood, "Code Tells You How, Comments Tell You Why", Coding Horror,
18 Dec 2006.** Origin of the slogan. Read as a corrective against
comment-everything culture. We take his volume instincts and reject the
"why only" formulation: it leaves a model with no truthful option when the
rationale isn't recoverable, so it invents one.

**MIT Broad Communication Lab, "Coding and Comment Style".** TODO format
(owner, the specific problem, what needs doing), comments as complete
sentences, defining unavoidable abbreviations, comments carry maintenance
cost.

**BowTied_Raptor, "3 Perspectives on How To Comment Your Code", 22 May
2023.** Assessed and mostly discarded. Two points survive: comments create
double-entry bookkeeping that refactoring tools don't help with, and
delete commented-out code.

**Dan Vanderkam, *Effective TypeScript*, Items 31 and 68.** Item 31
(don't repeat type information in documentation) is principle 6 with a
TypeScript name. Item 68 (use TSDoc on the public surface) is the
volume policy. Not a codebase; the TypeScript-specific reference.

**sindresorhus/type-fest.** Best open-source specimen of the shape:
one contract sentence, then `@example` with real TypeScript, then
`@see` / `{@link}`. `SetRequired` is the pattern. `Simplify` is the
warning — it grows into the articulate essay. Steal the
first-line-plus-example shape, not every paragraph, and not their
flush-left body (no ` * ` gutter). We keep the conventional asterisk
gutter.

## Failure-mode catalogue

The sources address human authors, who fail differently. These are the
machine-authored failures the skill is built to catch:

- **Fabricated rationale.** The most damaging. A model told to explain
  *why* will explain why, including when it has no idea why. Confident
  invention — "using a Map here for O(1) lookup" on a three-element
  collection — looks like knowledge and gets trusted downstream. Worse
  than narration, which is visibly useless.
- **Diff-relative comments.** "Now uses the new client", "changed to
  handle the null case." Written from the perspective of the edit;
  meaningless to anyone reading the file later. Characteristically an
  agent failure.
- **Docblock tag inflation.** `@param userId - The user ID` beside
  `userId: UserId`. Pure restatement; the volume hides real tags.
- **Comments standing in for code.** A comment explaining a vague
  variable should be a rename. A comment enumerating legal states should
  be a type.
- **Stale-by-construction comments.** Any comment restating a value, a
  case list, or another module's behaviour. Prose has no compiler.
- **Section labels posing as summaries.** `// Validate the input` above
  a validation block. Same abstraction level as the code.
- **Articulate but insufficient.** A long, careful docblock that argues
  the design and never states the contract. The dominant miss on a
  thoughtfully commented codebase; opposite of careless slop, and
  independent of volume.

## The twelve principles

Each is a test with an answer, not an exhortation. The operational pairs
live in the skill. The load-bearing shape:

**Gates (every comment).** (1) Name the direction — down toward precision,
off-axis to external fact, or up toward intuition — or write nothing.
(2) Obviousness is a property of the reader; for a model the
miscalibration is directional: language mechanics are obvious, local
context is where shared knowledge is wrongly assumed. (3) Assert only
what can be sourced; otherwise write nothing or mark it unverified.

**Interface comments.** (4) A caller must be able to use the function
without reading the body. The test produces an artifact: from the
docblock and signature alone, state what the caller gets and what the
exposed edge values mean. "Cover the body; is it sufficient?" cannot
fail once you have read the body. (5) No implementation leakage — would
this survive a total rewrite of the body? (6) Summary always; tags only
when they add what the type does not.

**Implementation comments.** (7) Precision or external fact; higher-level
summary is the rare exception; never how. (8) Precision facts are the
legitimate downward move, and only when absent from the type. (9) Sparse
by default; each line pays rent.

**Durability.** (10) Anchor to durable references, never to the diff.
(11) Reference, never duplicate.

**Design feedback.** (12) A comment that resists writing is a design
result. Surfacing is document-and-escalate: write the honest
caller-facing comment, raise the smell in the current conversation or
PR, do not append a confession to the comment.

### The three-way axis

Rationale is not on the up/down axis. The vendor bug, the RFC clause, the
alternative that deadlocked, the measured number — these are facts from
outside the code that no amount of reading recovers. Filing them as
"higher-level" is a category error, and it was that error that once made
principle 7 license block summaries.

- **Down, precision.** Attaches to declarations. Units, bounds, null
  semantics, ownership, invariants. The bulk of legitimate implementation
  comments.
- **Off-axis, external fact.** Attaches to whatever it constrains.
  Highest value, and the category carrying the fabrication risk, which is
  why gate 3 guards it.
- **Up, intuition.** Rare inside a body. Legitimate only for a genuinely
  long procedural stretch with real phases whose seams are not clean
  enough to extract. Try extraction first. `// Fetch the user, then apply
  the policy` at the top of a fifteen-line method is a label, not
  intuition.

### Volume policy

Calibration, not truth, recorded separately for that reason.
Verbosity and insufficiency are independent axes, not one dial.

- **Interface comments: a contract, near-universally.** Every function
  gets a TSDoc summary that passes gate 4. Tag inflation is still the
  over-production failure; a restated name or a design essay with no
  contract is under-effort however long it is.
- **Implementation comments: sparse.** Bias toward fewer than the sources
  would suggest, because the observed failure is over-production.

A helper with a single summary line and no tags is the intended output —
provided the summary is a contract, not a restated name.

## How to engage

- **Do not reopen the scope cuts.** Prose, personal voice, documentation
  formats, and a design-notes system are out.
- **Presence is not a pass.** Do not restore "every function gets a
  summary" as a coverage lint. Gate 4 runs first when judging existing
  comments; missing and present-but-insufficient both fail.
- **Do not add a named audit mode.** Scope is the work you were asked
  to do — a diff, a file, a package.
- **Do not add "write the comments first" as a workflow.** The skill
  assumes the code exists. The anti-narration work is done by gates 1
  and 3 and principle 5.
- **Examples in the skill are constructed TypeScript specimens** of the
  failure catalogue, shaped like type-fest (contract + `@example`)
  with a conventional ` * ` gutter. Replace toys with monorepo
  specimens when a package is marked up; do not invent a second
  parallel set.
- **Do not add a TSDoc tag appendix.** Format is out. The TypeScript
  surface is: no JSDoc types in `.ts`, the type is the first comment,
  `@example` as the sufficiency check, durable tags only.
- **No numeric comment-density target.** Gameable and wrong.
- **Lint rules** (`eslint-plugin-jsdoc` for tag echo; a custom rule for
  diff-relative vocabulary) are independently useful and do not block
  the skill. They do not live in this repo.

---

## Appendix: Decisions log

Decisions captured with reasoning so future sessions don't re-litigate
them. Ordered roughly by when they were settled.

**Comments only; documentation formats stay out.**
The rejected third-party skill is the wrong layer. Templates bias toward
filling the template. Revisit only if a later skill is explicitly about
README/ADR quality.

**Ousterhout's phrasing over Atwood's "why only".**
Both reject same-level narration. "Why only" forces fabricated rationale
when the model cannot recover a why. Permitting a non-why alternative
(precision, or silence) removes the pressure.

**Gate 1 is three-way, not two-way.**
Principle 7 originally read "what and why at a higher level." That
licensed block summaries. Rationale is off-axis, not "higher-level."
The up-direction survives only for long bodies with real phases and
inseparable seams.

**The cost frame is what makes the deletion bias cohere.**
A comment is untyped, untested, invisible to refactoring, and
unverifiable. A model will act on that; it will not act on "please write
fewer comments."

**Q1 — Principle 12 surfaces outside the file, for new and existing
interfaces alike.**
Write the honest caller-facing comment (hedges included if the caller
needs them). Do not add a "this should be refactored" footer — wrong
audience (the docblock is for the caller), wrong durability (those notes
never die), and it converts a design diagnostic into more comment. Raise
the smell in the current conversation or PR. One rule, no
new-vs-existing split: the distinction is something a model will get
wrong, and "stop and redesign" is a behavior it will skip or overdo.
The trigger stays mechanical: fire only when the comment itself is long,
hedged, or conditional-laden. Not "this helper could be cleaner."
This retunes principle 12 from reshape-or-stop to document-and-escalate.

**Q2 — Do not require writing comments first.**
Ousterhout's Ch. 15 presupposes the author is doing design. This skill
assumes the code is already written and judges comments against it. The
same tests apply if comments are written on the way to the body; the
order is not required. What we keep from Ch. 15 is the reason he wanted
comments first — once the body is visible, the cheap move is to narrate
it — and we assign that work to gates 1 and 3 and principle 5.

**Q3 — Cross-module design notes are out of scope.**
Principles 10 and 11 already say: don't duplicate, point at something
durable. Where the target lives is a docs-convention question. The
skill writes the local constraint, points if a reference exists, and
raises a "this wants to be a page" smell in the conversation or PR. It
does not author a design-notes file.

**Q4 — No comment-density target per file.**
A numeric target would be gameable and wrong. Volume is the interface /
implementation split above.

**Field test: the skill was a coverage pass because it was written as
one.**
First real use was an audit of existing comments. The agent counted
whether comments existed. Cause: nine of ten tests are rejection
filters; gate 4's old test ("cover the implementation; is it
sufficient?") cannot fail after you have read the body; "Reviewing a
diff" licensed "exported functions missing a summary" as the one check
on untouched code; Volume sat on the first screen as a bright-line
coverage rule; every Bad example was careless slop, so a thoughtful
codebase looked like someone else's problem. Recalibration: presence is
not a pass; verbosity and insufficiency are independent; gate 4
produces an artifact and runs first when judging; review scope is
whatever you were asked to look at, and the exception is "fails gate 4"
not "has no `/** */`"; the long design-essay-with-no-contract is a
first-class Bad; the Good leads with the contract and does not keep
the essay. Three quality evals sit beside the generation cases (essay,
present-but-empty, audit of a finished file). Do not add a third named
mode. Do not treat "keep the essay, prepend a contract" as the fix.

**Plugin `version` is the `/plugin update` signal.**
Claude compares installed version to `plugin.json`. Shipping a new
skill or a material skill revision without bumping it makes
`/plugin update` a no-op. Bump the minor for additive or recalibrating
skill changes.

**Type-fest shape, conventional gutter.**
Do not turn the skill into a TSDoc tag guide. Add a thin TypeScript
surface: no JSDoc types in `.ts`, the type is the first comment,
`@example` as the gate-4 check when a sentence is not enough, durable
tags only. Copy type-fest's contract-plus-example shape. Do not copy
their flush-left body — multiline TSDoc keeps the ` * ` gutter.
