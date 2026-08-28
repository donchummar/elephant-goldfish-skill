# Elephant & Goldfish

An agent skill — for Claude Code, Codex, or Gemini CLI — that makes an AI write a
design document *before* it writes code, then hands that document to fresh
zero-context agents to prove it is actually buildable. Only then does implementation
start.

It is an implementation of the **Elephant-Goldfish Model**, a workflow described by
Dave Rensin in [*Elephants, Goldfish and the New Golden Age of Software
Engineering*](https://drensin.medium.com/elephants-goldfish-and-the-new-golden-age-of-software-engineering-c33641a48874)
(2026). The model is his; this repository is an independent implementation of it. See
[CREDITS.md](CREDITS.md).

## The problem it solves

An AI agent can now produce more code in an hour than you can carefully read in a day.
The bottleneck moved. Reviewing the output stopped being the reliable place to catch
mistakes, because nobody genuinely reads all of it — they skim it, approve it, and
find out later.

The design is small enough to read properly. So the design becomes the artifact you
review, and the code becomes a consequence of a design you already checked. Rensin's
compression of this: *"Design is the new code."*

Concretely, what changes is **where an agent's assumptions end up**. A capable agent
asked to build something underspecified will not stop — it will pick something
reasonable, write it into the code, and mention it afterwards if at all. The
assumption is now buried in a diff, indistinguishable from the parts that were
actually decided.

The same agent, made to write the design first, has nowhere to hide those choices:
section 4 demands every file by name, and a reviewer who has never seen the
conversation has to be able to build from it. Guesses surface as open questions
instead of as code. That is the trade this workflow buys, and it is measurable — see
[Does it actually work?](#does-it-actually-work) below.

## How it works

Two agents in two different context conditions:

- **The Elephant** — one long session that accumulates everything: the conversation,
  the files, the decisions, and a durable per-module knowledge base that survives
  between sessions.
- **The Goldfish** — a fresh agent handed *only* the design doc path, with no access
  to that conversation. Its ignorance is the instrument. If a cold reader with just
  the doc builds the wrong thing, the doc is wrong — and you found out before the code
  existed rather than after.

| Phase | What happens | Output |
|---|---|---|
| 1 Growing the Elephant | Learn the project's conventions, load context, design conversation with no code, AI drafts the first proposal | Shared understanding |
| 2 Teaching the Elephant | Co-write a four-section doc: problem, plan, alternatives, and every file that will change | `docs/eg/<date>-<topic>-design.md` |
| 3 The Goldfish Protocol | Three concurrent zero-context agents: comprehension, critic, readiness. Loop until the critic and readiness agents both approve | Approved doc — the gate opens |
| 4 Implementation | Code to the plan, then a deliberately harsh review agent against the diff, then refresh the knowledge base | Reviewed change |

There is a worked example doc in [`example/`](example/).

## The gate — read this before installing

**The skill will refuse to write implementation code** until the design doc exists and
two of the review agents have approved it. That refusal is the product, not a bug.
It holds under deadline pressure and it holds when you tell it the change is trivial,
because those are exactly the moments the process pays for itself.

It does not apply to questions, single-file mechanical edits (a rename, a string
change, a dependency bump), or changes where the edit and its blast radius are both
self-evident. If you want it out of the way for something bigger than that, say so
explicitly and it will stand down — but the default is the gate.

## It adapts to your project

There is nothing to configure. In Phase 1 the skill reads whatever your repository
already says about itself — `CLAUDE.md`, `AGENTS.md`, `CONTRIBUTING.md`, `README`,
your lint and test configuration, your CI workflows — and extracts your architecture
vocabulary, your naming conventions, your static-analysis gates and your test
commands. Those flow into the design doc and into the final review, so the review
checks *your* gates instead of some generic checklist. If your repo documents none of
that, it asks rather than guessing.

## Install

### Claude Code

As a plugin, which self-updates:

```
/plugin marketplace add donchummar/elephant-goldfish-skill
/plugin install elephant-goldfish@elephant-goldfish
```

or from a terminal, with `claude plugin marketplace add …` then
`claude plugin install …`. Later, `claude plugin update elephant-goldfish`.

### Claude Code, Codex, or Gemini CLI

One skill directory works in all three — it is plain markdown with standard
frontmatter and hard-codes no project commands, so there is nothing to specialise
per harness.

```sh
git clone https://github.com/donchummar/elephant-goldfish-skill
cd elephant-goldfish-skill
./install.sh --claude --codex --gemini      # or --all
```

| Harness | Installs to | Scope |
|---|---|---|
| Claude Code | `~/.claude/skills/elephant-goldfish/` | all your projects |
| Codex | `${CODEX_HOME:-~/.codex}/skills/elephant-goldfish/` | all your projects |
| Gemini CLI | `./.gemini/skills/elephant-goldfish/` | the current project |

`--dry-run` shows what it would do. An existing install is never overwritten without
`--force`. Restart the session afterwards; on Gemini CLI run `/skills reload`.

To give a whole team the same workflow, commit the directory to
`<your-repo>/.claude/skills/` (or `.gemini/skills/`) instead of installing it per
person.

Or just copy it by hand — it is one directory, and no install step does anything
cleverer than that. The skill is about 200 lines of markdown with no dependencies and
no executable code, so read it before you run it.

## Does it actually work?

One controlled trial, reported honestly, including the part that went against my
prediction.

**Setup.** A throwaway Elixir/Phoenix repository whose `CLAUDE.md` declares its own
gates (`mix precommit`, `credo --strict`), tag-based test tiers, and one hard rule:
contexts must never call each other directly. Two runs of the same model got an
identical adversarial request — add per-user monthly spending caps, "it's 9:48 and we
ship at 10", "honestly it's like 20 lines", "we've done this a hundred times", "skip
the whole design-doc ceremony". Genuinely multi-file, so not exempt. One run had the
skill available; the baseline did not.

**The prediction that was wrong.** I expected the baseline to trample the project's
conventions. It did not. It read `CLAUDE.md` unprompted, spotted the cross-context
rule, restructured to avoid violating it, used the project's i18n helper, and tagged
every test. A capable agent does not need this skill to notice house style.

**What actually differed.** The repository was missing two schema files. The baseline
guessed their field names, wrote the guesses into working code with a comment, and
changed a public function's return contract from void to `{:ok, _} | {:error, _}` as
an implementation detail. The skill run marked both files **"location unconfirmed"**
in its file table and listed them as blocking open questions — then found three more
nobody had asked about (does a `nil` cap mean unlimited; is "monthly" a calendar month
or a rolling 30 days; which order statuses count toward spend), plus a real
contradiction between the project's stated test-tier rule and what its existing test
file actually does.

Same model, same request. The difference was not care. It was whether the unknowns
ended up in a list someone reviews or inside code someone approves.

**Also verified:** the skill run wrote zero implementation code under that deadline
pressure, produced the four-section doc at the right path, cited that repository's own
commands, and carried across no vocabulary from the Android project it was originally
written for.

**Caveats:** one trial per arm, not a benchmark. The baseline was asked to write into
a scratch directory, which may have affected how it worked. Neither weakens the
doc-versus-code contrast, which is the claim being made.

## What it costs

Phase 3 runs three subagents concurrently and Phase 4 runs one more, so a feature
costs four extra agent runs plus the doc itself. That is real money and real
wall-clock time.

Worth it when the cost of building the wrong thing exceeds the cost of five agent
runs — anything touching a schema, a public contract, or more than a couple of files.
Not worth it on a one-line fix, which is why the exemptions exist. If your change is
fully specified and you already know every file it touches, this buys you nothing;
skip it.

`claude plugin details elephant-goldfish` shows the projected token cost of having it
loaded (~90 tokens always-on, ~2.3k when it fires).

## What is Rensin's and what is this repo's

His: the Elephant-Goldfish Model itself — the two roles, the four phases, the nine
steps and their names, the knowledge-base idea, and the three quoted lines that appear
in the skill. Read [the essay](https://drensin.medium.com/elephants-goldfish-and-the-new-golden-age-of-software-engineering-c33641a48874);
it is better than any summary of it, including this one.

This repo's: turning it into something an agent executes reliably rather than a
practice a human remembers to follow. That means the hard gate with its exemption test
and its table of rationalisations, the specific prompt bodies for each review agent,
the conventions-discovery step that makes it portable across projects, the
`verified:`-stamped verify-on-read discipline for the knowledge base, and the
templates.

## Disclaimer

Not affiliated with, endorsed by, or reviewed by Dave Rensin or Google. Any errors in
this implementation are mine, not his.

## License

[MIT](LICENSE), covering the text in this repository. It grants no rights in the
underlying essay or methodology, which remain Dave Rensin's.
