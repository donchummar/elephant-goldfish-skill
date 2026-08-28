# Design doc template

Save to `docs/eg/YYYY-MM-DD-<topic>-design.md`. Build it iteratively — do not produce
it in one shot.

The doc has one hard requirement: it must stand on its own. A cold reader with no
access to the design conversation has to be able to act on it. That reader is the
goldfish, and it is also your teammate in six weeks.

A worked example lives in `example/` at the repo root.

---

# <Feature or change title>

**Date:** YYYY-MM-DD
**Authors:** <human + AI session>
**Status:** draft | goldfish-review | approved

## 1. The problem

What are we solving, and why now? Who is affected — end users, or only people
working in the codebase? What does "done" look like, stated as observable success
criteria someone else could check.

Plain language. No solution in this section.

## 2. The technical plan

The chosen approach, in prose plus a text block diagram. Name the layers and the
data flow using **this project's own vocabulary** — the pattern and layer names
gathered in Phase 1 step 0, not generic ones. State the key decisions, and the
criteria you will judge the finished result against.

```
[ text block diagram: components, and the direction data moves between them ]
```

## 3. Alternatives

Each alternative considered, and **why it was rejected**. This is the section that
tells a cold reader the plan was chosen rather than stumbled into. Include at least
one real alternative; "do nothing" counts when it was genuinely weighed.

## 4. Detailed implementation

Enumerate **every file** that will change, by exact path, with the change described.
A goldfish must be able to build a correct first pass from this table alone.

| File (exact path) | Change | Notes and conventions |
|---|---|---|
| `<path>` | ... | ... |
| `<path>` | ... | ... |
| `<test path>` | ... | which test tier or tag |

**Testing plan.** Which tiers or tags the new tests belong to, and the exact
commands to run them — as the project defines them, not as you would name them.
Note any generated or recorded artifacts that will need updating: snapshots,
fixtures, golden files, schema output.

**Migration and rollback.** How this ships and how it comes back out if it misbehaves.
Delete this heading only when the change genuinely cannot break anything in flight.

**Open questions.** Anything deferred, listed explicitly rather than buried in prose.
