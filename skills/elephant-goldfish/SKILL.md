---
name: elephant-goldfish
description: Use when starting non-trivial implementation work — a new feature, subsystem, migration, or any change spanning multiple files — especially under time pressure or when told "this one is simple, skip the process". Design-doc first; validate the doc with fresh zero-context subagents before writing any implementation code.
---

# Elephant & Goldfish

An implementation of the **Elephant-Goldfish Model**, a workflow described by Dave
Rensin in *Elephants, Goldfish and the New Golden Age of Software Engineering*
(2026). Full citation in `CREDITS.md`. This is an independent implementation and is
not affiliated with, endorsed by, or reviewed by Dave Rensin or Google.

Rensin's one-line summary of the loop:

> "Feed the Elephant; test it against the Goldfish."

## The two roles

The names are a mnemonic for two different context conditions — not a code pattern.

- **Elephant** — this session and the design doc it produces. It carries everything
  accumulated: the conversation, the files read, the decisions made, and the durable
  per-module knowledge base (`<module>/.eg/knowledge.md`).
- **Goldfish** — a fresh subagent launched with *only* a handed-off artifact in its
  prompt, and no access to this conversation. Its ignorance is the measuring
  instrument. If a cold reader holding just the doc arrives somewhere other than
  where you intended, the doc is wrong, not the reader.

Why the doc and not the code, in Rensin's words:

> "Design is the new code."
>
> "sizeof(docs) << sizeof(code)"

The practical version: when an AI produces more code per hour than a human can
carefully read, the human-readable design becomes the cheapest place to catch a
mistake. Reviewing a page of intent beats reviewing a thousand lines of consequence.

## The hard gate

**Write no implementation code until both of these are true:**

1. the four-section design doc exists, and
2. the **critic** goldfish and the **readiness** goldfish have both approved it.

Violating the letter of this gate violates its spirit. "I'll write the doc
afterwards", "I already understand this one", and "what I just described *is* the
plan" all mean the gate is open when it should be shut.

### Exemptions — the gate does not apply

- Questions and explanations, where no code is produced.
- A single-file mechanical edit: a rename, a string change, a dependency bump, a
  one-line fix.
- Changes where both the edit and its blast radius are self-evident.

If you are unsure whether something qualifies, it does not. Run the protocol.

### Red flags — stop, this is the sound of rationalising

| The thought | What is actually true |
|---|---|
| "We ship in ten minutes, there's no time for process" | The gate is what protects the release. Skipping design under deadline is how one mistake becomes many. |
| "We've done this a hundred times" | Then the doc takes minutes and the goldfish approves immediately. Speed is the reward for clarity, not a reason to skip it. |
| "It's only about twenty lines" | Line count is not blast radius. Apply the exemption test above rather than a gut feel. |
| "Let me just investigate and get started" | Investigation is Phase 1. It is not permission to start coding. |
| "The plan is in my head" | A plan a goldfish cannot read is exactly the failure this process exists to prevent. |

## The protocol — four phases, nine steps

### Phase 1 — Growing the Elephant (no code)

**Step 0 — Learn the house style.** Read whatever the project already says about
itself, in this order of preference: `CLAUDE.md`, `AGENTS.md`, `CONTRIBUTING.md`,
`README`, then the lint / format / test configuration and CI workflow files.
Extract four things and carry them into Phase 2 and Phase 4:

- the architecture pattern and layer names in use,
- naming and file-placement conventions,
- the static-analysis and formatting gates, with their exact commands,
- the test commands, and how tests are partitioned or tagged.

If the project documents none of this, say so plainly and ask for the gate and test
commands rather than guessing. Never invent a command and present it as the
project's own.

**Step 1 — Context loading.** Read each in-scope module's `.eg/knowledge.md` first
(see below), then the relevant source. Summarise back what you understood, so
misreadings get corrected now rather than in the doc.

**Step 2 — The "no code" rule.** Hold a design conversation. Ask clarifying
questions, surface constraints, challenge assumptions. Write no implementation code.

**Step 3 — The sycophant challenge.** Agreement is a warning sign. If you notice
yourself endorsing rather than examining, return to critic mode and interrogate your
own claims: why do I believe this? What would make it false? You are most useful
when you stress-test the thinking, least useful when you validate it.

**Step 4 — The first-draft proposal, drafted by you.** Propose the first design
yourself, in prose plus a text block diagram. Your partner's job is to react and
correct. Making the AI draft first is what reveals whether it actually understands
the system, rather than whether it can agree fluently.

### Phase 2 — Teaching the Elephant

Co-write the design doc to `docs/eg/YYYY-MM-DD-<topic>-design.md` using
`references/design-doc-template.md`. Four sections:

1. **The problem** — what and why, in plain language, no solution.
2. **The technical plan** — the chosen approach, named in the project's own layer
   and pattern vocabulary from step 0.
3. **Alternatives** — what was considered and rejected, and why.
4. **Detailed implementation** — every file that will change, by exact path, with
   the change described per file, plus the test plan and its commands.

**Build it iteratively.** A doc produced in one shot conceals the assumptions this
process exists to expose.

### Phase 3 — The goldfish protocol

Launch fresh subagents whose prompts contain **only the design doc path** and the
task — never this conversation. Prompt bodies are in `references/goldfish-prompts.md`.
Run all three concurrently.

- **Step 5 — The comprehension test.** The goldfish explains the system back using
  only the doc and the files it cites. Divergence from intent means the doc is
  unclear. Fix the doc.
- **Step 6 — The critic review.** A skeptical expert hunts gaps, risks, wrong
  assumptions, and anything that breaks against this project's real constraints.
  Expect roughly a third of its findings to be worth acting on; that third is the
  point.
- **Step 7 — Implementation readiness.** "Could you build a correct first pass from
  this document alone? If not, what precisely is missing?"

Fold the findings back in and re-run until the critic and readiness goldfish both
approve. Then a human reviews. Only now does the gate open.

### Phase 4 — Implementation

**Step 8 — Coding with guardrails.** Follow the plan as written. Conform to the
conventions and gates gathered in step 0 — the project's patterns, not your
defaults, and not the conventions of whatever project you saw last. Deviating from
the approved plan means returning to the doc, not improvising past it.

**Step 9 — The "mean" code review.** Launch one more fresh goldfish against the
diff alone, briefed to assume the author was careless, and to check both strict
readability and every gate from step 0. Fix what it finds.

Then: refresh the knowledge base for each module you touched, and stop before
committing. The human authorises commits, and follows the project's own commit
conventions.

## The per-module knowledge base

Each module carries `<module>/.eg/knowledge.md` — the durable elephant, co-located
with the code it describes, so that returning to a module weeks later skips the cold
start. Format in `references/knowledge-file-template.md`.

**Verify on read.** Treat every entry as a hint, never as truth. Spot-check a claim
against current code before relying on it. Each entry carries a
`verified: <commit> <date>` stamp; when that stamp lags the module's recent history,
distrust it. Correct or delete anything stale — a knowledge base nobody prunes
becomes a confident liar.

**Update on write.** After finishing work in a module, refresh its file and re-stamp
`verified` with the current commit and date.

Whether these files are committed or ignored is the project's call. Ignoring them
(`docs/eg/`, `**/.eg/`) keeps them personal; committing them makes them shared team
memory. Both work; decide once, deliberately.

## Quick reference

| Phase | Steps | Output |
|---|---|---|
| 1 Growing the Elephant | House style · Context loading · No code · Sycophant challenge · AI drafts first | Shared understanding |
| 2 Teaching the Elephant | Iterative four-section doc, every file enumerated | `docs/eg/<date>-<topic>-design.md` |
| 3 Goldfish protocol | Comprehension · Critic · Readiness, concurrent, loop until both pass | Approved doc — **the gate opens** |
| 4 Implementation | Code to the plan · Mean review · Refresh knowledge · stop before committing | Reviewed change, current `.eg/` |

## Common mistakes

- **Reading "verify" as testing after the fact.** The gate is approval of a document
  before code exists, not a test run after it does.
- **Feeding the goldfish the conversation.** A subagent that can see this chat is no
  longer a goldfish; the asymmetry is the whole measurement. Hand over the artifact
  path and nothing else.
- **One-shotting the doc.** Iteration is what surfaces the assumptions.
- **Trusting a stale `.eg/` entry.** Verify on read, every time.
- **Importing conventions from elsewhere.** Step 0 exists so the review checks this
  project's gates rather than the ones you happen to remember.
