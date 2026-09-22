# Explain a commit on its own

These adaptations of the supplied Ruly examples teach writing choices, not
facts about another repository. Use only reasons supported by the actual change.
Sources include [configuration (#193354)](https://github.com/VantaInc/obsidian/pull/193354)
and [persistence (#192047)](https://github.com/VantaInc/obsidian/pull/192047).

## Unpack the failure before naming the mechanism

Subject: `fix(worker): persist execution before publication`

Before:

> Checkpoint execution before publication so failed publication is recoverable.

After, when supported by the before/after code:

> Work could be pushed successfully, then a failure creating the PR could leave
> the saved task without a record of that completed work.
>
> Save the execution result and used attempt before starting PR publication.
> Once that save succeeds, publication can fail without losing the record of
> work already done. Record the PR separately after publication succeeds.

The reader learns what can go wrong before encountering the solution. Repeating
"work" connects the steps. The save-success condition keeps the explanation
accurate without adding a catalogue of every possible storage failure.

## Give a refactor a reason, not just an inventory

Subject: `refactor(publishing): group body configuration under pr`

Before:

> Move body configuration under pr, preserving headings, templates, generated
> values, and render order.

After, if the intent is to establish one place for publishing configuration:

> Put the existing PR body settings together under `pr` so campaigns have one
> place to declare their publishing content. Headings, templates, generated
> values, and render order stay the same.

The preserved properties help check equivalence after the reason is clear.
Do not claim title support if that arrives in a later commit.

## Keep a sufficient causal explanation

Subject: `refactor(harness): use action defaults for startup checks`

> Build startup checks from the same configured instances used to run actions,
> so startup checks the credentials and model access those actions need.

No extra paragraph is needed merely to mention ownership, cleanup, or exclusions.
A consistent rename may need only a subject:
`refactor(parser): rename tokenOffset to byteOffset`.

## Correct unsupported evidence without inventing a limitation

Suppose this commit adds an injectable provider; a later commit switches action
factories to it. Supplied tests cover decoding and cleanup with mocks, but their
execution result is unknown.

Before: `feat(harness): switch actions to the second provider`, with a body
claiming "Tests pass."

A supported subject is `feat(harness): add an injectable second provider`.
Explain the capability and unchanged default when useful. Remove "Tests pass";
there is no need to replace it with a testing disclaimer. If discussing evidence,
say which assertions the supplied tests cover and that their run result is
unknown. Do not infer that no live-provider test exists.

A sufficiently detailed description of the resulting change supports this draft
without a raw diff. Direct inspection is appropriate when available or needed to
resolve a material ambiguity, not a prerequisite for every writing request.

## Unpack a dense body without expanding the scope

Dense:

> Validate all persisted tasks independent of read filters and serialize writes
> through each store to enforce unique PR ownership before label mutation.

Clearer, given those facts:

> Selecting one task must not hide another task claiming the same PR. Validate
> the whole saved task list even when the caller requests only part of it.
>
> Updates through the same store run one at a time. Check each proposed claim
> before changing GitHub labels so competing updates cannot both pass validation.

Each paragraph answers a different question about the same change. The second
still limits serialization to the same store; it does not invent cross-process
coordination. Keep this additional explanation only when the subject leaves it
usefully unexplained.

## Integrate focal paths into the explanation

For a broad harness refactor, assuming the supplied responsibilities and behavior
are verified at this commit:

```text
refactor(ruly): introduce action-owned class-based harnesses

Agent configuration and Claude response handling were spread across
Worker, campaign configuration, and actions. Put invocation behind a
configured harness so actions can choose a provider without understanding
its command line or response format.

The contract in agents/harness.ts accepts an action's inputs and returns
a validated report. agents/base-agent-harness.ts owns the shared run
entry point; agents/claude-agent.ts owns Claude's command construction,
schema conversion, and decoding.

Actions select their defaults through factories or accept an injected
harness; actions/execute.ts shows the caller migration. Worker retains
finding interpretation and eligibility. Remove campaign/worker model
and budget settings and their CLI overrides.

Claude/Opus defaults and existing budgets remain unchanged.

Paths are relative to scripts/ruly/src/ruly.
```

The paths locate the implementation while the sentences explain it. A second
walkthrough would repeat those responsibilities; a closing design question
would repeat the opening's purpose. Explicit reading order earns space when
it helps readers establish something they otherwise could not follow.
Supporting changes still require review; do not call migrations mechanical
without evidence of preserved behavior. Small changes may need no paths.

## Choose content independently of the old message's size

An old message may explain the same provider boundary in its introduction,
per-file paragraphs, and a closing review guide. Select the useful facts first:
the separation and reason, relevant behavior changes, and preserved defaults.
Explain each once, using focal paths where helpful. Do not polish all three
versions of the same explanation merely because they were supplied. A short
and a bloated starting message for the same change should lead to comparable
reading effort, without a fixed word count or a requirement to retain wording.
