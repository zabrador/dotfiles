# Build understanding before adding detail

These are adapted excerpts, not complete descriptions or templates. Verify facts
against the target change. The pause example draws on the supplied revisions of
[Ruly #193281](https://github.com/VantaInc/obsidian/pull/193281); the testing example
also reflects [#193338](https://github.com/VantaInc/obsidian/pull/193338). Live PRs
can change; these examples illustrate editorial choices, not current code claims.

## Keep the scenario and useful questions

Dense version:

> The campaign decides eligibility. `isActive` suppresses all worker turns,
> including verification. Paused PRs consume capacity; board state is retained.

More understandable:

> A flag-removal task can become inappropriate if the flag starts rolling out
> again. Deleting the task would lose its progress; pausing lets Ruly keep that
> work until the flag qualifies for removal again.
>
> **What does pausing do?** Ruly stops working on the task, including checking
> whether it is complete. The task stays on the board, Ruly's saved task list,
> with its progress intact.
>
> **Who decides when to pause?** Each campaign—the configuration for a kind of
> work, such as flag removal—checks whether its tasks are still eligible. That
> rule belongs to the campaign because different kinds of work have different
> reasons to stop.
>
> **What happens to an existing PR?** Ruly attempts to add `DO NOT MERGE` so the
> paused work is visibly blocked. The open PR still counts toward the limit on
> simultaneous PRs. Ruly does not remove the label automatically on resume,
> because a person or another tool may also need it to remain blocked.

The extra sentences introduce terms and connect behavior to reasons. The
questions divide the reader's work. They are worth preserving when already
present. This excerpt does not replace the rest of the PR: consequential label
failure behavior and the separate ownership change still need appropriate space.

## Explain the problem before naming its owner

Before:

> Put provider preflight on action-owned harness instances.

After, assuming the diff supports this problem:

> Startup checks could validate one model while an action later selected
> another. Build the startup checks from the same configured instances used to
> run actions, so startup checks the credentials and model access those actions
> actually need.

The reader can understand the mismatch before learning an abstraction's name.
Do not invent that mismatch if it was not possible in the old code. For a
preventive refactor, explain the duplication and future drift it prevents
instead of claiming an existing bug.

## Keep explanation and review in one sequence

For a configuration move followed by new title support:

> Put a campaign's PR title and body settings together. Review the two commits
> in order: the first moves the existing body settings under `pr`, preserving
> headings and rendering. The second adds title settings beside them, so
> publication can resolve the title and body from the same declaration.

The overview explains the destination; the following sentences explain the
same sequence the reviewer will inspect. Do not force this structure onto a
single rename or a history whose ordering makes the explanation harder.

## Preserve current confidence, not an execution diary

Suppose the author reported a failed sandbox run followed by a successful
unrestricted run of the same suite at the same revision. The earlier failures
were resolved; a full Actions campaign remains untested.

Before:

> Observed in the preceding implementation session at abc123: 852 tests across
> 53 files passed, plus typecheck and lint. Initial sandbox subprocess failures
> were cleared by the successful unrestricted run. No tests were rerun for this
> prose-only update. A full Actions campaign remains unverified.

After:

> The author reported 852 tests passing, plus typecheck and lint, at stack tip
> `abc123`. This was a whole-stack run, not a separate run at this PR's head.
> A full Actions campaign remains untested.

The confidence and its limits remain visible. The resolved attempt and editorial
session add no remaining limitation. Put useful commands and detailed run
records in linked or collapsed evidence; do not invent links or provenance.

If the latest result were instead 811/813, preserve that result and its two
failures. A successful subset does not supersede a failed full suite.

## Remove irrelevant caveats; retain necessary qualifications

If a consistent rename changes `offset` to `byteOffset` to clarify its unit:

> Rename `offset` to `byteOffset` to make its unit explicit; parsing is unchanged.

Do not append that the PR does not add caching, change providers, or fix unrelated
bugs. Those exclusions do not explain the rename. In contrast, an injectable
provider addition needs to distinguish availability from default selection if
readers might otherwise infer that actions have switched providers.
