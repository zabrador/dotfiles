# Explain decisions, not a template

These examples adapt the supplied Ruly PR-description comparisons. The source
descriptions were often already useful. The improvements below clarify causal
reasoning and boundaries; they are not instructions to reproduce headings or
length. Verify every claim against the target PR before using similar prose.

Source comparisons: [provider ownership (#192608)](https://github.com/VantaInc/obsidian/pull/192608),
[preflight causality (#192047)](https://github.com/VantaInc/obsidian/pull/192047),
and [logging contracts (#193314)](https://github.com/VantaInc/obsidian/pull/193314).
The supplied handoff preserves historical before text and validation limits;
live GitHub descriptions may change and do not establish those earlier facts.

## Turn capabilities into ownership boundaries

Before:

> Add a second provider harness, keep its concerns in that class, and extract
> usage before report validation. Read the decoder, agent, and tests.

After:

> Add a second provider behind the existing harness contract. Its implementation
> owns command construction, response decoding, validation, and temporary-file
> cleanup, so actions and the shared lifecycle need no provider-specific branch.
>
> Extract available usage before report validation so invalid reports can still
> contribute diagnostics. Missing counts remain unknown. The implementation is
> available for direct injection; action defaults remain on the existing provider.

The reviewer can now check where responsibility ends and whether callers have
actually switched. A file list locates code but does not explain that decision.

## Add a missing causal link to good prose

Before:

> Put authentication, plugin, and model-access checks on the provider instance
> configured for that action.

After:

> Put authentication, plugin, and model-access checks on the provider instance.
> Startup uses the same action factories as runtime, so preflight checks the
> defaults the actions will actually use.

The improvement is the reason the mechanism matters. If the original already
contains that causal link, leave it alone. It does not need question headings
or an architecture essay.

## Separate contracts in a review route

Before:

> Standardize logging and add invocation diagnostics. Propagate the logger,
> add output formats, report completion and duration, and collect token usage.

After:

> The first commit establishes one operational-log format and passes the
> command's logger through callers; command results stay on stdout. Review that
> output contract before the second commit's invocation accounting.
>
> Each invocation attempts one completion log after cleanup, including failure
> paths. Accounting belongs to the call, so overlapping calls cannot leak usage.
> Missing counts remain unknown, and logger failure preserves the original
> invocation result.

The sequence earns its place because it separates two contracts. Use a simpler
paragraph when the actual diff has no useful commit progression.

## Preserve inconvenient evidence

Existing evidence:

> At revision abc123, the author reported 811/813 tests passing. The two
> subprocess failures were also reproduced on the base. Top-level error
> formatting was checked manually. No full deployment run was performed.

An edit may shorten this to:

> Author-reported at abc123: 811/813 tests passed; both subprocess failures
> also reproduced on the base. Error formatting was checked manually; full
> deployment remains untested.

Replacing it with "Tests cover logging and error handling" loses evidence.
"All tests pass" invents evidence. If only the handoff records the old run,
attribute it to that source; do not claim to have inspected logs or rerun tests.

## Scale down to the change

For a rename whose purpose is to clarify units:

> Rename `offset` to `byteOffset` to make its unit explicit; values and parsing
> behavior are unchanged.

That can be the entire Changes section. Preserve required repository sections
with brief, truthful entries; do not manufacture three review questions.
