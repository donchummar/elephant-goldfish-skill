# Credits

## Source of the methodology

Dave Rensin, *Elephants, Goldfish and the New Golden Age of Software Engineering*,
Medium, 28 April 2026.

- Essay: <https://drensin.medium.com/elephants-goldfish-and-the-new-golden-age-of-software-engineering-c33641a48874>
- Listed at Google Research: <https://research.google/pubs/elephants-goldfish-and-the-new-golden-age-of-software-engineering/>

The Elephant-Goldfish Model — the two roles, the four phases, the nine steps and their
names, and the per-module knowledge-base idea — is described in that essay. This
repository implements it as an executable agent skill. The essay is the original and
better source; read it.

## Quotations

Three lines from the essay appear in `skills/elephant-goldfish/SKILL.md`, marked as
quotations and attributed:

- "Feed the Elephant; test it against the Goldfish."
- "Design is the new code."
- "sizeof(docs) << sizeof(code)"

They are quoted because paraphrasing them would be worse writing, and because credit
belongs where the phrasing came from. No figures, images, or longer passages from the
essay are reproduced here.

## Original to this repository

- The hard no-code gate: its exemption test, and the table of rationalisations that
  precede skipping it.
- The prompt bodies for the comprehension, critic, readiness and mean-review agents.
- The conventions-discovery step, which makes the workflow portable across projects
  by reading a repository's own documentation instead of hard-coding one project's
  patterns.
- The verify-on-read / update-on-write discipline for the knowledge base, with
  `verified: <commit> <date>` stamps.
- The design-doc, knowledge-file and worked-example templates.

## Relationship to the author

None. This is an independent implementation, not affiliated with, endorsed by, or
reviewed by Dave Rensin or Google.
