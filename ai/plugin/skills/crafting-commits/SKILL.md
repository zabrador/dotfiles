---
name: crafting-commits
description: Judge commit atomicity and write subjects and bodies that make each change understandable on its own. Use when creating or modifying a commit (including amends, squashes, and conflict resolution), or when asked to draft, review, or improve commit messages. Covers Conventional Commits, durable explanations, and accuracy at each commit's tree. Git mechanics belong to making-git-changes, decomposition to planning-commits, and PR titles and descriptions to crafting-prs.
---

This skill defines the standard a git commit must meet — whether the commit is
being created fresh or reshaped by a mutation (amend, squash, conflict
resolution). It judges; it does not execute. The companion `making-git-changes`
skill owns the git mechanics and consults this standard after any operation
that creates or modifies a commit. For deep conceptual reasoning about atomic
commits, or decomposition of tangled changes into a sequence of commits, defer
to `planning-commits`.

For message-only work, inspect the relevant diff and existing message, then
draft or edit the requested prose. The creation gates below do not require a
new test run or history rewrite merely to suggest a message. Flag unrelated
changes honestly; better wording cannot make a mixed commit atomic. A request
for a draft does not authorize committing it or changing commit boundaries.

## The gut check

Before a commit is created (or after its content changes), verify the diff
satisfies all four of these:

1. **Passes CI** — tests, lints, and type checks remain green.
2. **Is deployable** — no half-wired states that compile but crash at runtime.
3. **Introduces no dead code** — any new function has a caller added in the same commit.
4. **Passes the revert test** — reverting this commit would remove only the described change, nothing else.

Sharp message-level self-check: if the title needs "and" to bridge unrelated
changes, inspect whether the diff needs splitting. The word itself is not a
failure; one coherent change can affect several operations.

The `planning-commits` skill owns the reasoning behind these criteria and the
techniques for splitting a non-atomic diff. This skill uses them as a checklist.

If the diff does not pass, stop. Do not commit. See "When the diff is not
atomic" below.

## Conventional Commits format

All commit messages use: `type(scope): short summary`

Common types:
- `feat` — new user-visible functionality
- `fix` — bug fix
- `refactor` — behavior-preserving code change
- `docs` — documentation only
- `test` — adding or modifying tests
- `chore` — maintenance (dependencies, config, tooling)
- `perf` — performance improvement without behavior change
- `style` — formatting only (whitespace, semicolons)

The subject identifies the concrete change in imperative mood ("add", "fix",
"remove"). Prefer a specific behavior or boundary to "improve reliability" or
"address review feedback". Aim for a full subject under about 70 characters;
do not sacrifice meaning to hit a count. Choose the type from the actual diff:
calling a behavior change `refactor` does not make it behavior-preserving.

## Write for a reader of git show

A reader months later should understand this unit without the PR discussion.
Reduce the reasoning they must reconstruct. Read the diff against this commit's
parent, relevant code, repository guidance, and the existing message before
writing. Earlier or later stack layers are context, not evidence for what this
commit implements. Ask for missing intent only when code and supplied context
cannot establish it; never invent the author's motivation.

Use a body when the subject leaves useful reasoning unexplained. State the
action and its reason together, then the non-obvious invariant or consequence
that makes the change understandable:

- **Refactor:** identify the responsibility that moves and the concrete
  behavior that must remain equivalent. Name preserved properties when
  "unchanged behavior" would leave the reader guessing what to check.
- **Bug fix:** explain a concrete failure sequence and the corrected outcome.
  Include timing or partial-failure boundaries when they determine correctness.
- **API or provider addition:** explain the contract and ownership of policy,
  I/O, decoding, or cleanup where relevant. Distinguish availability from
  adoption: exporting an implementation does not make it the default.

These are lenses, not required sections. A tiny rename can need only a subject.
Keep already-good text when it supplies the necessary reasoning. Do not turn
every message into a miniature PR description, file inventory, or chronology
of attempted solutions. Mention an adjacent commit only when it materially
helps explain this boundary; the explanation must still stand on its own.

Verify important claims at this commit's tree. Distinguish a logging attempt
from guaranteed delivery, missing data from zero, and a disclosed limitation
from a mitigation. Include exclusions only when they resolve a real scope
question. Check changing provider or pricing facts if they are material;
examples are not permanent facts about products.

If validation is mentioned, distinguish test coverage, an observed run, and
an author-reported result. Preserve relevant failures and untested paths unless
newer evidence supersedes them; retain the result's source and revision when
available, and identify missing provenance rather than inventing it. Editing
prose does not establish that tests passed.

Separate the body from the subject with a blank line. Wrap prose near 72
characters at natural word boundaries; leave a long token, identifier, or URL
intact. Try a shorter version: retain extra detail only when removing it would
force the reader to reconstruct an important fact.

Read [message examples](references/message-examples.md) when calibrating body
depth or reviewing a substantial rewrite. They explain the judgment behind
the edits rather than prescribing a template. Use `crafting-prs` for the
review context spanning a whole PR.

## The message stays true under mutation

Mutations produce commits too. When an operation changes what an existing
commit contains — a fix squashed in via `--amend` or `--fixup`, hunks altered
by conflict resolution during a rebase — re-judge the commit as if it were
being created now:

- **The message must describe the commit as it now is.** A squash that extends
  behavior can silently falsify a message that was accurate yesterday.
- **The gut check applies to the merged result, not the delta.** The combined
  diff must still be atomic and pass the revert test.
- If the mutation made the message wrong, amend the message in the same
  operation. If it made the commit non-atomic, the shape was wrong — defer to
  `planning-commits` (see its fix-placement section) rather than leaving a
  dishonest commit.

## When the diff is not atomic

If the gut check fails, do not commit. Handle it one of two ways:

- **If the `planning-commits` skill is available**, invoke it to produce a
  decomposition plan, then execute that plan one planned commit at a time via
  `making-git-changes`, checking each against this standard.
- **If `planning-commits` is not available**, tell the user the diff contains
  multiple concerns and needs to be split before committing. Offer to help
  identify the logical groupings, but do not attempt full decomposition
  independently — that's planning work, outside this skill's scope.
