---
name: crafting-commits
description: Write, review, or improve commit subjects and bodies so each change is understandable without the PR discussion. Use when a commit message is needed or its accuracy needs checking after an amend, squash, or conflict resolution. Owns writing, not commit readiness or git operations (making-git-changes), decomposition (planning-commits), or PR descriptions (crafting-prs).
---

# Make each commit understandable

Explain the commit to its reviewer and to someone reading `git show` months
later. This skill owns the message; `planning-commits` owns commit boundaries
and `making-git-changes` owns validation and git operations. A request to draft
a message does not require a test run or authorize changing history.

## Subject and format

Use Conventional Commits: `type(scope): short summary`. Choose a type that
matches the diff: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, or
`style`. A behavior change must not be disguised as a refactor.

Name the concrete change in imperative mood: "add", "fix", "remove". Prefer
that to "improve reliability" or "address review feedback". Aim for a full
subject under about 70 characters without sacrificing meaning.

## Explain the change

Assume an average engineer who may struggle with the subject and has neither
project context nor the PR discussion. When code is available, inspect the diff
against this commit's parent and relevant code. For a draft, sufficiently detailed
supplied facts are evidence: do not demand raw diffs or repository access merely
to restate them. Ask only for facts or intent needed to avoid inventing a claim.

Write the message the commit needs. Treat the existing message as evidence,
not a target length or structure. First select the supported change, reason,
and material behavior boundaries readers need to understand or assess this
commit; then write around them. Wording and structure may change freely.
Returning an already-sufficient message unchanged is also fine.

The subject names the change. Use a body when it leaves useful understanding
unexplained: establish the problem, explain what changes, and connect that
change to the benefit. Introduce necessary terms before relying on them. For a
refactor, explain why moving the responsibility helps and which behavior must
remain equivalent. For a fix, make the failure sequence understandable. For an
addition, distinguish making a capability available from callers adopting it.
These are ways to explain, not mandatory sections.

Give each paragraph one explanatory job. Introduce mechanisms after explaining
the problems they solve; keep sentences that define terms or connect causes to
consequences. Read without the chat: what must the reader infer or remember to
understand the next sentence? Each paragraph should add something the reader
still needs. Remove repeated explanations and unnecessary background even when
individual sentences are clear. Omit a body when the subject is enough.

When a commit touches many files and its central implementation is hard to
locate, integrate focal paths beside the responsibilities or behavior they
implement. Let explanation and navigation work in the same sentence. Use
explicit reading instructions only when order matters; omit a separate review
question when the explanation already identifies the judgment. Avoid duplicated
walkthroughs and file inventories; omit navigation when the start is obvious.

Keep claims true at this commit's tree, including failure boundaries. Later
stack layers cannot supply guarantees for an earlier commit. Preserve material
limitations beside the claims they qualify when they affect acceptance, operation,
or interpretation of the change; prefer concrete consequences to disclaimers.
Mention adjacent commits only when needed to explain this unit.
Include validation only when useful to understanding this commit. Distinguish
coverage, run results, and their source; an unknown result does not mean a test
is absent. A changed SHA alone does not invalidate verification of unchanged
code. Preserve applicable evidence and material uncertainty, not an execution diary.

Separate subject and body with a blank line. Wrap prose near 72 characters at
natural word boundaries; leave identifiers and URLs intact. Use
[message examples](references/message-examples.md) to calibrate substantial
rewrites, and `crafting-prs` for explanation spanning a whole PR.

## Keep the message honest

After an amend, squash, or conflict resolution, describe the entire resulting
commit, not just the latest adjustment or the original intent. Revise the
message when its claims no longer match; execution belongs to
`making-git-changes`.

If writing a coherent message exposes unrelated changes or unclear boundaries,
flag the specific problem and suggest `planning-commits`, or
`replanning-branches` for reshaping an existing branch. Still provide an honest
draft when possible. Do not hide mixed concerns behind a vague subject or start
restructuring on a writing-only request. The word "and" alone is not evidence
that a commit needs splitting.
