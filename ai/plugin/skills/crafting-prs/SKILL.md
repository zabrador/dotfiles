---
name: crafting-prs
description: Write, review, or improve pull-request titles and descriptions so a reviewer can understand the behavior, reasoning, and evidence with little prior context. Use when drafting a PR or updating its prose after scope changes, including stacked PRs. This is a writing standard, not a CI watcher, code-review workflow, or git-history editor. Commit subjects and bodies belong to crafting-commits.
---

# Make a PR easy to review

Write for a capable reviewer with little context and limited time. Explain the
decisions they would otherwise have to reconstruct from the diff. A good
description makes the change easier to assess; more words or a polished tone
are not evidence of improvement.

This skill owns PR titles and descriptions. `crafting-commits` owns the durable
explanation of each individual commit. `maintaining-prs` consults this standard
when maintenance changes what a PR says. Git operations and history rewriting
remain with `making-git-changes`; decomposition remains with `planning-commits`.

## Establish the facts and scope

Read the request, repository instructions and required PR template, existing
description, live base and head, relevant commits, and the actual per-layer
diff. Inspect implementation and tests behind material claims. Supplied style
examples show ways to explain a change; they are not evidence about this code.
When the user supplies sufficient excerpts for a draft, work from those facts
and identify any material uncertainty instead of requiring remote access.

For each PR, work out the concrete problem and outcome, the decision the
reviewer needs to accept, the invariant or failure case easiest to miss, the
minimum dependency context, and the available validation. These are thinking
aids, not five mandatory sections. Ask for missing intent only if the code and
conversation cannot establish it.

Each description must be true at its own head relative to its actual base.
Do not attribute a child's guarantee to a parent, or confuse a new provider
implementation with selecting it as the default. An adjacent layer may explain
a dependency without becoming part of this PR's claimed behavior.

Before updating a live PR, capture the original title and body with the PR
URL, head SHA, and capture time before editing. This preserves before/after
evidence; a Git backup cannot recover a previous PR description.

## Explain what the reviewer needs to decide

Make the title identify the concrete outcome or responsibility change. Follow
repository title conventions; Conventional Commits syntax for commits does
not automatically apply to PR titles. Revisit both title and body when scope
changes so they describe the final diff.

Lead the description with what happens differently, for whom, and under what
trigger. A concrete example can establish the behavior before introducing
symbols. For a refactor, lead with the responsibility being moved and the
reason that boundary matters.

Group the explanation around consequential decisions. Connect mechanism and
reason nearby: "Startup uses the runtime factories, so preflight checks the
models the actions actually use." Where relevant, identify who chooses policy,
performs I/O, interprets responses, or owns cleanup. Replace vague promises
such as "preserves behavior" with the particular invariants worth checking.

Give a review route when it saves effort. Actual commit order may separate an
equivalence check from a new behavior; a few targeted code pointers may locate
a critical contract. A small mapping can use a sentence or table. Questions
are optional headings, not a required style. Avoid file inventories and lists
of implementation details that leave the reader to infer their significance.

State material boundaries precisely. Say what survives a partial failure,
what remains unknown, or which isolation the code actually enforces. An
attempted write is not guaranteed delivery. Documenting a limitation does not
mitigate it. Keep exclusions only when they answer a real scope question.

Preserve required template sections and useful existing prose. A tiny rename
may need one sentence within that template. Do not add ceremony, repeat the
opening in every section, or narrate abandoned proposals and review history.

## Preserve the verification evidence

Describe what evidence supports, including its limits:

- **Coverage:** tests contain assertions about a behavior. This does not mean
  those tests were run or passed.
- **Execution:** an observed run had a particular result. Preserve known
  failures, partial runs, and untested paths unless newer evidence supersedes
  them. Keep the relevant command or scope, revision, and source when known;
  explicitly leave unknown provenance unknown.
- **Reported evidence:** attribute an author's smoke test or historical result
  instead of presenting it as a run you observed. Keep manual checks distinct
  from automated assertions.

Explain why relevant failures constrain confidence; do not erase them while
shortening the Testing section. Claims that failures are pre-existing need
evidence too. Link or collapse lengthy logs when useful. A prose-only edit
neither requires a fresh suite run nor permits claiming one occurred.

## Check and deliver

Read the prose without the chat. Supply necessary context that exists only in
conversation, and verify important claims in the appropriate layer: defaults,
ordering, cleanup, failure handling, and isolation when mentioned. Verify
changing provider or price claims if material; historical examples do not
establish current product facts.

Try a shorter version. Keep the extra detail only if its removal would make
the reviewer reconstruct a consequential fact. Leaving already-good text
unchanged is a successful outcome. Read the
[review examples](references/review-examples.md) when calibrating structure or
evaluating a substantial rewrite.

Difficulty explaining the PR can reveal a design or commit-structure problem.
If the evidence shows unrelated outcomes bundled together, unclear ownership,
or commits that mix an equivalence check with new behavior, briefly flag the
specific obstacle to the user alongside the best accurate draft. Suggest
`planning-commits` for decomposition or unresolved boundaries, or
`replanning-branches` for reshaping an already-committed branch. This is a
heads-up, not an instruction to perform that work: do not start restructuring
without a separate request. Complexity or missing context alone does not prove
a design flaw, and smoother prose should not conceal a real structural issue.

Deliver only the requested artifacts. A draft stays a draft; an authorized
description update changes the description. Neither implies rewriting commit
messages, changing code, or starting background maintenance. Consult
`maintaining-prs` before GitHub writes for applicable scope rules; an explicitly
requested editorial update stays within its named PRs and fields.

Before publishing an authorized update, refresh the live head, base, title,
and body. Reconcile changed evidence and preserve external edits rather than
overwriting a stale snapshot. After writing, read back the published title and
body. If history rewriting is separately authorized, delegate its mechanics
to `making-git-changes` and its messages to `crafting-commits`.
