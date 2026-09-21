---
name: crafting-prs
description: Write, review, or improve PR titles and descriptions for readers with little context or subject knowledge. Build understanding of the problem, changed behavior, and reasoning while keeping claims accurate. Use when drafting a PR or updating its prose, including stacked PRs. Commit messages belong to crafting-commits; this skill does not start maintenance or rewrite history.
---

# Make the change easy to understand

Assume an average engineer who may struggle with the relevant concepts and
has little project context. Write respectfully, but do not depend on expertise
or inference to fill gaps. Explain necessary terms and causal steps; avoid a
primer on unrelated fundamentals. Success is what the reader understands,
not how many technical facts the description contains.

## Build understanding in order

Give the reader the problem, concrete changed behavior, and why that helps
before introducing the machinery. Then add material qualifications and evidence.
This is an order of explanation, not mandatory headings. A qualification that
prevents a misleading claim belongs beside that claim, even in the opening.

Introduce a concept by its purpose before relying on its name. Use a concrete
scenario when it makes the behavior easier to follow. Connect each new idea to
what the reader already knows: explain why the mechanism solves the problem.
Naming an owner or abstraction is not itself an explanation.

Prefer the same order for explanation and review, usually the commit order
when that offers a useful progression. Add a brief overview if needed. Depart
only when following that order would make the explanation harder to understand.
Retain useful questions and structure; neither questions nor commit-by-commit bullets are
mandatory. Follow the repository template and title conventions.

Optimize reading effort, not word count. Give distinct ideas room to unfold;
keep sentences that define a term or supply a causal link. Remove repetition,
file inventories, and caveats that help no review decision. A short dense bullet
can be worse than several connected sentences. Keep already-good prose; a
small change may still need only one sentence.

## Ground the explanation

Read the request, repository guidance, existing prose, and the diff against the
PR's actual base. Inspect code and tests behind important claims. Sufficient
supplied evidence can support a draft without remote access. Ask for missing
intent only when the available evidence cannot establish it.

Describe this layer at its own head: adding an implementation is different
from selecting it as the default. Examples are writing guidance, not evidence
about this code. Check material guarantees; do not invent a simpler past
behavior, motivation, or causal story to make the narrative work.

## Put details where they help

Keep behavior, reasoning, and qualifications needed to judge the change in the
main explanation. Start Testing with a short account of current confidence:
what was checked and what remains uncertain. Distinguish coverage from a run,
manual checks from automated tests, and reported results from observed ones.

Keep unresolved failures and untested paths visible when they limit confidence.
State relevant scope, such as a whole-stack run rather than a run at this head.
Put reproduction commands, detailed provenance, and useful historical records
in linked or collapsed evidence. Omit superseded failures with no remaining
consequence. A prose-edit session's history is usually not testing evidence;
never imply that editing the description established a passing test run.

## Check the reader's understanding

Read without the chat: could someone with weak subject knowledge explain the
problem, what changes, and why it is preferable? Are necessary terms introduced
before use? Does each technical detail help a review decision, and is it placed
where the reader can understand it? Preserve useful connections when shortening.
See [examples](references/review-examples.md) for substantial rewrites.

If the difficulty comes from unrelated changes or unclear design boundaries,
flag the concrete obstacle alongside an honest draft. Suggest `planning-commits`
or, for an already-committed branch, `replanning-branches`. Do not restructure
without a separate request; complexity or missing context alone is not a flaw.

## Deliver the requested artifact

Drafting or updating prose does not authorize code changes, history rewriting,
or maintenance watchers. Commit messages use `crafting-commits`; git operations
use `making-git-changes`. Consult `maintaining-prs` before GitHub writes for
applicable scope rules, without enrolling a direct editorial request in watching.

Before a live update, save the original title/body, URL, head, and capture time;
Git history does not preserve PR descriptions. Refresh the base, head, and prose
before writing, reconcile external changes, and read back the published result.
