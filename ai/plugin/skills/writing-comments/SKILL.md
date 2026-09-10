---
name: writing-comments
description: The standard for what a good code comment looks like — TSDoc/docblocks and implementation comments. Use this skill whenever writing, editing, reviewing, auditing, or removing comments in code; whenever judging whether existing TSDoc or JSDoc is sufficient; whenever adding TSDoc to a function, type, or module; and whenever asked to document a function or review comments for quality. Presence is not success — apply this skill to comments that already exist, not only to missing ones. This skill judges comments only. It does not govern README structure, ADRs, or other documentation formats, and it does not apply to pull-request review comments or commit messages.
---

This skill defines the standard a code comment must meet — TSDoc on
interfaces, and comments inside implementations. It assumes the code
already exists and judges comments against it. It does not govern prose
style, README structure, or documentation formats.

A comment is untyped, untested, invisible to refactoring, and
unverifiable. It is the least durable thing in the file. Absence of an
implementation comment is the correct outcome for most blocks.

Presence is not a pass. A file where every export has a one-line
restatement of its name fails. Verbosity and insufficiency are
independent — a docblock can be both at once. A docblock that explains
why the code is this way but never says what a caller gets is
under-effort however long it is.

**Volume.** Interface comments: a brief TSDoc summary that passes gate 4.
Tags appear only when they add what the type does not. Implementation
comments stay sparse. A helper with one summary line and no tags is the
intended output, not under-effort — provided the summary is a contract,
not a restated name.

When judging existing comments, run gate 4 first on every exported
symbol in scope, then the rejection gates on each comment. Scope is
whatever you were asked to look at: a diff, a file, a package. When
writing new comments, write the contract (gate 4), then run gates 1–3
on whatever else you were about to add.

Each principle is a test with an answer. If the test has no answer, do
not write the comment.

## Gates — every comment

### 1. Different abstraction level, or no comment

Every comment must move **down** (precision on a declaration),
**off-axis** (external fact: RFC, ticket, rejected alternative, measured
number), or **up** (intuition on a long body whose phases are real but
whose seams are not). Same-level prose restates the code.

*Test: name the direction. No answer, no comment.*

```ts
// Bad — same-level label
// Validate the input
if (!email.includes("@")) throw new Error("invalid email");

// Good — no comment (the check is obvious), or precision the type cannot carry:
// Empty and whitespace-only both fail; `@` is the only format check.
if (email.trim() === "" || !email.includes("@")) {
  throw new Error("invalid email");
}
```

```ts
// Bad — two phases in fifteen lines is a label, not intuition
// Fetch the user, then apply the policy
const user = await repo.find(id);
const decision = policy.evaluate(user, request);

// Good — delete the comment
```

### 2. Obviousness is a property of the reader, not the writer

The author holds the context that makes things obvious. For a model the
miscalibration is directional: language mechanics are obvious and should
go uncommented; local context — an invariant three modules away, why
this call must precede that one — is where shared knowledge is wrongly
assumed.

*Test: would a competent engineer new to this file recover this from the
code, the types, and nearby names?*

```ts
// Bad — language mechanics
const ids = items.map((item) => item.id); // Map to ids

// Good — non-local ordering constraint
// Policy reads the request-scoped principal bound above; calling it first throws.
const decision = policy.evaluate(request);
```

### 3. Assert only what can be sourced

Rationale that cannot be traced is rationale being invented. "Using a
Map for O(1) lookup" on a three-element collection, "batching to reduce
load" where nothing was measured — these look like knowledge and get
trusted downstream.

*Test: can I point to the ticket, the test, adjacent code, or the
conversation this came from? If not: write nothing, or mark it
explicitly unverified.*

```ts
// Bad — invented why
// Use a Map here for O(1) lookup by id.
const byId = new Map(ALLOWED_ROLES.map((role) => [role.id, role]));

// Good — silence, or a sourced external fact
// node-fetch#1767: redirect + custom Host is dropped. Remove when on undici.
headers.delete("host");
```

## Interface comments (TSDoc)

### 4. Cognitive leverage is the bar

A caller must be able to use the function correctly without reading the
body.

*Test: from the docblock and the signature alone — not the body — state
what the caller gets, and what the edge values the signature already
exposes mean (null, empty, throws). If you needed the body for any of
that, the docblock fails. A three-line `@example` call site is the
TypeScript check when a sentence is not enough.*

````ts
// Bad — restates the name
/** Get the user. */
export async function getUser(id: UserId): Promise<User | null>

// Good — contract the signature does not carry. `@example` when a
// caller would still have to guess the edge case; not a replay of
// `getUser(id)`.
/**
 * Returns the user, or `null` if they have been deleted.
 *
 * @example
 * ```ts
 * const user = await getUser(id);
 * if (user === null) return;
 * ```
 */
export async function getUser(id: UserId): Promise<User | null>
````

````ts
// Bad — articulate, and still insufficient: argues the design, never
// states the contract. Do not keep the essay and prepend a sentence.
/**
 * We used to hit the identity service on every request. That stampeded
 * it during login spikes, so a cache sits in front now and the store
 * is the source of truth. The cache is safe to drop if this moves
 * behind the edge worker. Callers should use this helper rather than
 * the store so eviction stays centralized. A miss still goes to the
 * store; a hit returns whatever was last written.
 */
export async function getUser(id: UserId): Promise<User | null>

// Good — contract first, then a call site. The design argument leaves.
/**
 * Returns the user, or `null` if they have been deleted.
 *
 * @example
 * ```ts
 * const user = await getUser(id);
 * if (user === null) return;
 * ```
 */
export async function getUser(id: UserId): Promise<User | null>
````

### 5. No implementation leakage

A docblock mentioning the cache, the retry loop, or the query is
contaminated. It over-promises, couples callers to internals, and rots
on the first refactor. A freshness or staleness claim is the cache
leaking unless the function's job is "possibly cached" — that hedge
belongs on a strained signature (principle 12), not on an ordinary
lookup.

*Test: would this comment survive a total rewrite of the body?*

```ts
// Bad — leaks the cache and the store
/** Looks up the user in Redis, then queries Postgres on a miss. */
export async function getUser(id: UserId): Promise<User | null>

// Good — survives a rewrite of the body
/** Returns the user, or `null` if they have been deleted. */
export async function getUser(id: UserId): Promise<User | null>
```

### 6. Summary always; tags only when they add precision

A one-line summary is nearly always available at a higher abstraction
than the signature: it states the function's role, not its mechanics.
Tags earn their place only when carrying what the types don't: units,
bounds, null semantics, thrown errors, ownership.

*Test: strip every tag whose content is derivable from the signature.*

```ts
// Bad — tag inflation
/**
 * Resolve a user by id.
 * @param id - The user ID
 * @returns The user, or null
 */
export async function getUser(id: UserId): Promise<User | null>

// Good — summary only; the types already say the rest
/** Returns the user, or `null` if they have been deleted. */
export async function getUser(id: UserId): Promise<User | null>

// Good — tag carries a fact the type does not
/**
 * Sleep before the next retry.
 * @param timeoutMs Deadline in milliseconds, exclusive.
 */
export function wait(timeoutMs: number): Promise<void>
```

## TypeScript

The type is the first comment. Do not write JSDoc type annotations
(`@param {string} id`) in `.ts` files. Do not `@param` a name the
signature already typed. That is Effective TypeScript Item 31, and
it is principle 6 with a TypeScript name.

A branded id, a discriminated union, or a `readonly` parameter
replaces prose that would have enumerated the same fact.

`@example` is the TypeScript-native sufficiency check. If you cannot
write a three-line call site from the docblock and signature, gate 4
failed. A contract sentence plus an `@example` is the shape to copy
from type-fest. Keep the ` * ` gutter on every line of a multiline
block — type-fest omits it; we do not:

````ts
/**
 * Make the given keys required; leave the rest as they are.
 *
 * @example
 * ```ts
 * type Draft = { id: UserId; email?: string };
 * type Ready = SetRequired<Draft, "email">;
 * // => { id: UserId; email: string }
 * ```
 */
export type SetRequired<T, K extends keyof T> = Omit<T, K> & Required<Pick<T, K>>;
````

Durable tags: `@deprecated`, `@see`, `{@link}`, `@example`. A
`@param` or `@returns` that restates the signature is not.

## Implementation comments

### 7. Precision or external fact. Higher-level summary is the rare exception. Never how.

Implementation comments attach precision to declarations, or external
fact to whatever it constrains. Higher-level summary is permitted only
where a long body has genuine phases and extraction would make it harder
to follow — try extraction first.

*Test: is this precision, a sourced external fact, or a rare
inseparable-phases summary? If none, delete it.*

The `// Fetch the user, then apply the policy` example under principle 1
is illegal here too. Two phases in fifteen lines is a label.

### 8. Precision facts are the legitimate downward move

Units, inclusive/exclusive bounds, null semantics, ownership and
lifetime, invariants holding across a block. Only when the type does
not already say so.

*Test: is this fact absent from the type?*

```ts
// Bad — the type already says number, number
// The start and end of the range
function sliceRange(start: number, end: number): Range

// Good — convention the type cannot express
/** Inclusive start, exclusive end — same convention as `String.slice`. */
function sliceRange(start: number, end: number): Range
```

### 9. Sparse by default. Each line pays rent.

Most blocks correctly have no implementation comment. If a comment is
not doing work under gates 1–3, delete it rather than rewriting it.

## Durability

### 10. Anchor to durable references; never to the diff

The RFC clause, the issue number, the browser version, the linked
answer. These stay checkable. Diff-relative comments — "now uses the
new client", "changed to handle the null case", "updated to use the
new helper" — are anchored to a moment and dead within a month.

*Test: does this read correctly to someone who never saw the change
that introduced it?*

```ts
// Bad — written from the edit
// Now uses the new billing client
const invoice = await billing.invoices.create(input);

// Good — a future reader can check whether the constraint still holds
// Stripe requires idempotency keys on retries (docs: idempotent-requests).
const invoice = await billing.invoices.create(input, { idempotencyKey });
```

### 11. Reference, never duplicate

Any comment restating a value, a case list, or another module's
behaviour is stale by construction. Write the local constraint; point
at a durable reference if one exists. Do not copy another module's
docs into this file, and do not create a design-notes file as a side
effect of commenting.

```ts
// Bad — duplicates the union, will rot when a state is added
// Status is "queued", "running", or "done"
function handle(status: JobStatus) {}

// Good — the type is the list; comment only what it does not say
/** Terminal states (`done`, `failed`) are ignored; see `JobStatus`. */
function handle(status: JobStatus) {}
```

## Design feedback

### 12. A comment that resists writing is a design result

Long, hedged, or conditional-laden interface comments mean the
abstraction is strained. Write the honest caller-facing comment anyway —
hedges included if the caller needs them. Do not append a refactor
confession to the comment. Raise the design smell in the current
conversation or PR.

*Test: did the comment take a paragraph of hedges or conditionals? If
yes, mention it outside the code. Fire only when the comment itself is
that evidence — not "this helper could be cleaner."*

```ts
// Bad — process note in the caller-facing contract
/**
 * Returns the cached user if present, otherwise loads from the store.
 * Callers cannot tell which path ran; treat the result as possibly stale.
 *
 * This probably needs to be refactored.
 */
export function getUser(id: UserId): User | null

// Good — honest hedges, no confession in the file
/**
 * Returns the cached user if present, otherwise loads from the store.
 * Callers cannot tell which path ran; treat the result as possibly stale.
 */
export function getUser(id: UserId): User | null
```

Raise the smell in the conversation or PR, not in the comment: this
signature conflates cache lookup with fetch; the caller cannot tell
which they got.

## Reviewing comments

Scope is whatever you were asked to look at: a diff, a file, a package.
For each exported symbol in that scope, run gate 4 first — absent and
present-but-insufficient both fail. Then apply the rejection gates to
every comment in scope. Delete comments that fail. Strip tags that
restate the signature. Replace diff-relative wording ("now", "new",
"changed to", "updated to") with a durable reference or with nothing.

Do not add comments to unchanged code just because it is uncommented,
except for exported symbols whose docblock fails gate 4. Do not leave
commented-out code.

## What not to do

- Do not treat a present docblock as a pass. Judge the contract.
- Do not invent a why. Silence beats a plausible story.
- Do not comment language mechanics, restated names, or section labels.
- Do not put implementation details in a docblock.
- Do not keep a design essay and prepend a contract sentence.
- Do not write JSDoc types (`@param {string}`) in `.ts` files.
- Do not omit the ` * ` gutter on multiline TSDoc.
- Do not write comments from the perspective of the change.
- Do not use a comment where a rename or a type would do.
- Do not require comments to be written before the body. Judge them
  against the code as it is.
