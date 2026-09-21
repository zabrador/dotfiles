# Commit messages that explain the unit

These examples adapt the supplied Ruly rewrite into generic terms. They are
illustrations, not factual claims about another repository. Keep a revision
only when the inspected code supports it.

Source comparisons: [configuration refactor (#193354)](https://github.com/VantaInc/obsidian/pull/193354),
[persistence and preflight (#192047)](https://github.com/VantaInc/obsidian/pull/192047),
and [invocation accounting (#193314)](https://github.com/VantaInc/obsidian/pull/193314).
The generic adaptations below include tighter failure qualifications than the
approved rewrite; they do not reproduce its wording as a required standard.

## Make equivalence checkable

Subject: `refactor(publishing): group body configuration under pr`

Before:

> Move the body fields under one pr object without changing rendering.

After:

> Move the existing body declarations beneath one `pr` object. Preserve their
> headings, templates, generated values, and render order; the configuration
> shape and its plumbing change together.

The original was accurate but left "unchanged" undefined. The revision gives
the reviewer specific equivalence checks. Do not append a paragraph about
future title support unless that dependency helps explain the current change.

## Explain the failure sequence

Subject: `fix(worker): persist execution before publication`

Before:

> Checkpoint execution before publication so failed publication is recoverable.

After:

> After execution is pushed, save its execution evidence and charged attempt
> before publishing the PR. Once that checkpoint succeeds, a publication
> failure leaves the completed work available for recovery on the next turn.
>
> Record publication evidence only after publication succeeds, so the early
> checkpoint does not claim a PR exists prematurely.

The useful addition is the ordering and the checkpoint-success condition.
Do not claim the work is durable if the checkpoint itself can fail. Mention
label writes only if this commit's persistence implementation warrants it.

## Bound a telemetry guarantee

Subject: `feat(harness): report invocation timing and usage`

Before:

> Log timing and token usage for each invocation, including failures.

After:

> Attempt one completion log for each invocation, including provider and
> report-validation failures. Measure the full lifecycle through cleanup.
>
> Allocate accounting per call so overlapping calls cannot share usage.
> Extract available counts before validation; missing counts remain unknown.
> A logging failure must preserve the invocation's original result or error.

The extra detail earns its place by exposing the lifecycle, concurrency, and
failure contracts. "Attempt" avoids promising delivery by a fallible sink.
Do not repeat those claims without checking the actual implementation.

## Leave sufficient prose alone

Subject: `refactor(harness): use action defaults for preflight`

> Create startup harnesses through the same action factories used at runtime
> so readiness checks use the models each action will actually select.

This already connects mechanism to consequence. Keep it if it is accurate;
adding headings or restating the factory inventory would increase effort.

For a consistent rename, `refactor(parser): rename tokenOffset to byteOffset`
may be sufficient by itself. A body is useful only if it explains something
the subject leaves unresolved.
