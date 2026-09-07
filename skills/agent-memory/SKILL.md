---
name: agent-memory
description: Shared engineering memory workflow for coding agents. Use before non-trivial coding, debugging, build, deployment, migration, database, architecture, security, or repeated engineering work to retrieve relevant project rules, lessons, and incidents; use again after completion when a reusable lesson, agent mistake, root cause, project invariant, or repeated pattern should be stored or updated.
---

# Agent Memory

Use the shared memory repository as selective long-term engineering memory.

## Memory home

Resolve the repository in this order:

1. Environment variable `AI_MEMORY_HOME`.
2. If unavailable on Windows, `E:\AI_MEMORY`.
3. If the path does not exist, do not invent memory. Continue the task and state that shared memory was unavailable only if it materially affects the result.

Read `MEMORY_POLICY.md` before writing or promoting memory.

## Mode A — Recall before work

Use this for non-trivial engineering work.

1. Read `memory/rules/global.md`.
2. Identify the current project/repository name and check whether `memory/projects/<project>/` exists.
3. Extract 3–8 discriminative keywords from the task: technology, error text, module, component, operation, and failure class.
4. Search `INDEX.md` first, then recursively search memory metadata/headings/content if needed.
5. Load only the most relevant memories, normally 3–7 files maximum.
6. Prioritize:
   - active global rules
   - active current-project rules/knowledge
   - matching lessons
   - matching incidents
7. Apply a memory only after checking that its assumptions still fit the current code/configuration.
8. Never load the entire memory repository merely for context.

If `rg` is available, prefer it for search. Otherwise use the shell's native text search.

## Mode B — Learn after work

After the task is completed or a root cause is established, decide whether the result deserves long-term memory.

### Store when

- a non-obvious root cause was verified;
- the agent made a meaningful wrong assumption or unsafe/unnecessary modification;
- a reusable debugging/build/deployment/database sequence was discovered;
- an important project invariant, boundary, or prohibition was discovered;
- the same failure/pattern is likely to recur;
- an existing memory was proven incomplete or incorrect.

### Do not store when

- it was a trivial successful task;
- the content is generic syntax/reference knowledge;
- the information is temporary session state;
- the conclusion is unverified speculation;
- it contains secrets, credentials, tokens, private keys, or personal authentication information;
- it would mostly duplicate logs or conversation transcripts.

## Deduplicate before writing

1. Search by error text, component/module, root cause, technology, and reusable-rule wording.
2. If an existing memory describes substantially the same pattern, update it instead of creating a new file.
3. On update, increment `occurrences`, refresh `last_seen` and `updated`, and add only genuinely new evidence or a better solution.

## Classification

- `rule`: verified instruction that should repeatedly constrain future work.
- `lesson`: reusable problem-solving knowledge/pattern.
- `incident`: concrete failure/incident and its root cause/resolution.
- `project`: knowledge valid only for one project/repository.

Prefer `lesson` or `incident` when uncertain. Do not promote speculative knowledge to `rule`.

## File format

Use the schema in `templates/MEMORY_TEMPLATE.md`.

For a new memory, use an ID such as `MEM-YYYYMMDD-HHMMSS` and a concise filename such as:

`20260907-152500-maven-class-resolution.md`

Suggested locations:

- `memory/lessons/<file>.md`
- `memory/incidents/<file>.md`
- `memory/projects/<project>/<file>.md`
- only verified durable rules in `memory/rules/<file>.md`

Keep each memory compact. Preserve only context needed to recognize and correctly reuse the lesson.

## Rule promotion

A repeated item may become a rule when it is both important and verified. Repetition alone is not enough.

Typical evidence:

- repeated occurrence across tasks;
- tests/builds consistently validate the rule;
- project source/configuration proves the invariant;
- official documentation or explicit user/team instruction confirms it.

## After any write/update

Run `scripts/rebuild-index.ps1` from the memory repository if PowerShell is available. If not, update `INDEX.md` conservatively.

Do not rewrite unrelated memories.
