# Per-module knowledge file template

One file per module, at `<module>/.eg/knowledge.md`. This is the durable elephant:
the thing that lets you return to a module after a month without paying the cold-start
cost again.

**Verify on read.** Every claim here is a hint, not a fact. Spot-check it against
current code before relying on it. If an entry's `verified` stamp lags the module's
recent commit history, distrust the entry.

**Update on write.** After finishing work in the module, refresh the file and
re-stamp `verified` with the current commit and date.

**Keep it lean.** Record slow-moving structure and hard-won gotchas. Line-level
detail rots on the next commit and turns the file into a liability.

Decide once whether these files are committed (shared team memory) or ignored
(personal notes), and be consistent.

---

# <module path>

**Purpose:** <one line>
**Layer / role:** <in this project's own vocabulary>

## Public surface

What other modules touch — entry points, exported types, published events.

| Symbol | Role | verified |
|---|---|---|
| `<name>` | ... | `<commit>` YYYY-MM-DD |

## Key internals

| Symbol | Role | verified |
|---|---|---|
| `<name>` | ... | `<commit>` YYYY-MM-DD |

## Decisions and gotchas

- <the thing that cost an afternoon to learn> — verified: `<commit>` YYYY-MM-DD
- <the constraint that is not visible in the code> — verified: `<commit>` YYYY-MM-DD

## Dependencies

What this module depends on, and what depends on it.
