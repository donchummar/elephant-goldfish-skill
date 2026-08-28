# Goldfish prompts

Launch each as a **fresh subagent**. The prompt must contain **only** the artifact
path and the task — never the design conversation. The zero-context isolation is the
entire mechanism; a goldfish that can see the chat is just another elephant.

Run comprehension, critic and readiness concurrently in Phase 3. The mean review runs
alone in Phase 4, against the diff.

Where a prompt below says "this project's gates", substitute the actual commands
gathered in Phase 1 step 0. A named command the goldfish can run beats a category it
has to guess at.

---

## Comprehension goldfish (step 5)

> You have no prior context on this task. Read only the design doc at
> `docs/eg/<file>.md` and the source files it references. Then explain back, in your
> own words: (1) the problem this solves, (2) the approach, (3) exactly what you
> would build, and in which files. Do not read other planning notes. Wherever
> something is ambiguous or you had to guess, say so explicitly and quote the
> passage — that is the most useful thing you can report.

Divergence between its explanation and the actual intent means the doc is unclear.
Fix the **doc**, not the goldfish.

## Critic goldfish (step 6)

> You have no prior context. Read only the design doc at `docs/eg/<file>.md` and the
> code it references. Act as a skeptical expert reviewer. Find gaps, risks, wrong
> assumptions, unhandled edge cases, and anything that will break in this specific
> codebase — concurrency, empty and error states, unauthenticated or logged-out
> paths, migration and rollback, and violations of the project's stated
> architecture. Rank findings by severity. Argue to improve the design rather than
> to be agreeable.

Expect roughly a third of the findings to be high-value. Fold those in; discard the
rest without ceremony.

## Readiness goldfish (step 7)

> You have no prior context. Read only the design doc at `docs/eg/<file>.md`. The
> question: could you implement a correct first pass from this document alone,
> without asking anyone anything? If yes, say so. If no, list precisely what is
> missing — every file, decision, or value you would have to invent. Be concrete.

The gate opens only when the critic and readiness goldfish both approve.

## Mean review goldfish (step 9, against the diff)

> You have no prior context. Review only this diff. Assume the author was careless.
> Tear it apart for strict readability, and check it against this project's gates:
> <the exact format, lint, static-analysis and test commands from step 0>, plus its
> naming and file-placement conventions and any architectural rules it documents.
> List every issue you would block the change on.
