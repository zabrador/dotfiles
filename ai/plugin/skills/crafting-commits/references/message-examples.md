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
