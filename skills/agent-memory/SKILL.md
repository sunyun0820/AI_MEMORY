---
name: agent-memory
description: Shared engineering memory for coding agents. Automatically use Recall mode before non-trivial analysis, design, architecture, coding, debugging, review, refactoring, migration, build/deployment, database, security, or existing-codebase work when past rules, project knowledge, lessons, incidents, or prior mistakes may help. Use Learn/Remember mode only when the user explicitly asks to remember, save, learn, update memory, 기록해, 기억해, 메모리에 남겨, 저장해, 업데이트해, or otherwise requests targeted persistence. Use Backfill mode only when the user explicitly asks to retrospectively review the current session/history and persist reusable knowledge, for example `agent_memory backfill`, `agent-memory backfill`, `이 세션 백필해`, or `이 세션 회고해서 기억 반영해`.
---

# Agent Memory

Use the shared `AI_MEMORY` repository as selective long-term engineering memory.

This skill has three distinct modes:

- **Recall**: automatic when relevant before substantial engineering analysis, design, or execution.
- **Learn / Remember**: manual only; targeted persistence of important knowledge discovered during the current work.
- **Backfill**: manual only; retrospective review of the current session/history to recover reusable knowledge that was not stored while the work was happening.

Never treat task completion by itself as permission to write memory.

## Invocation

Recommended plain-text calls that work consistently across Agents:

```text
agent_memory recall
agent_memory remember
agent_memory backfill
```

`agent-memory` with a hyphen is also acceptable. Natural-language equivalents are valid when intent is clear.

- `recall`: normally automatic, but can be requested explicitly.
- `remember` / `learn`: save or update a specific piece of current knowledge.
- `backfill`: review the available current session/history, select durable knowledge, deduplicate it against existing memory, persist only worthwhile items, and accumulate worthwhile Tool candidates/improvements in the shared candidate backlog.

Backfill is intentionally broader than Remember. For the detailed Backfill checklist, read `references/backfill.md` only when Backfill mode is invoked.

## Resolve memory home

Resolve the memory repository in this order:

1. Environment variable `AI_MEMORY_HOME`.
2. If unavailable, infer the repository only when the installed skill link clearly resolves back to the AI_MEMORY repository.
3. If the repository cannot be found, continue the user's task without inventing memory.

Do not assume a fixed drive such as `E:\AI_MEMORY`.

Before any write, update, promotion, archival, Learn/Remember, or Backfill operation, read `MEMORY_POLICY.md`.

# Shared Memory Intelligence

Recall, Remember, Backfill must use the same reasoning model. The goal is not to preserve or replay implementation history. The goal is to turn past work into compact knowledge that improves future decisions.

For every candidate or recalled memory, reason through these questions:

1. **Distill** — Is this durable knowledge, or merely an implementation summary/change log?
2. **Transfer** — Can the underlying mechanism apply outside the current file/module/project?
3. **Prevent** — What wrong assumption, failure, regression, or unsafe approach should a future Agent avoid?
4. **Bound** — Under what conditions does the knowledge apply, and when should it not be generalized?
5. **Verify** — Is it supported by code, config, tests, logs, official docs, or explicit user/team instruction?
6. **Deduplicate** — Is there already a stronger equivalent memory?
7. **Compress** — Can the useful knowledge be stated much more simply without losing safety or applicability?

A strong memory usually answers, in compact form:

```text
What is the durable knowledge?
Why does it matter?
When does it apply?
What should be avoided or checked?
How was it verified?
```

## Generalization rule

When a specific project incident reveals a broader engineering rule, actively check whether a separate reusable Lesson is justified.

Example:

```text
Specific project memory:
ETI LOTDEFECT has a concrete Qty double-deduction failure with known source/root cause.

Transferable lesson:
When updating quantity-bearing existing data, derived/header quantities must be checked for delta(new-old) handling instead of reapplying the full new value.
```

Store both only when they provide distinct future value. Do not duplicate the same prose into project + lesson files.

## Low-value implementation history

Treat these as low-value by default:

- "implemented X";
- changed-file/class lists;
- progress/status summaries;
- obvious current source structure with no hidden constraint;
- successful build/test results with no reusable lesson;
- information that Git diff/current source can cheaply reconstruct.

Keep implementation facts only when they expose a non-obvious invariant, hidden behavior, dangerous boundary, important Source Navigation shortcut, or reusable design/verification knowledge.

# Mode A — Recall

## When to use

Automatically use Recall before substantial work when prior engineering context could materially improve correctness, safety, consistency, or efficiency.

Typical triggers include:

- analyzing an existing system, module, source tree, failure, or technical problem;
- designing a feature, API, architecture, data model, migration, integration, deployment, or implementation approach;
- making an architecture or technical trade-off decision;
- modifying an existing codebase;
- debugging a bug, exception, build failure, deployment failure, data issue, or performance problem;
- code review, refactoring, or impact analysis;
- database/schema/query work;
- security-sensitive analysis or implementation;
- repeated or similar engineering work;
- work involving a known project/module/component where project-specific memory may exist.

Normally skip Recall for trivial operations such as simple syntax questions, tiny conversions, isolated command lookups, or generic factual questions where project memory is unlikely to matter.

The user does not need to ask for Recall explicitly.

## Recall procedure

1. Identify the current repository/project, technology, module/component, operation, state transition, data/architecture invariant, requested objective, error/failure class, and likely regression risks.
2. Read `memory/rules/global.md` if it exists.
3. Check relevant current-project memory under `memory/projects/<project>/`.
4. Extract a small set of discriminative terms from both **names** and **mechanism**. Do not search only exact class/error keywords.
5. Search `INDEX.md` first.
6. If needed, search memory metadata, headings, and content using `scripts/search-memory.ps1`, `rg`, or an equivalent native text search.
7. Load only the most relevant memory files, normally no more than 3–7.
8. Build a small applicability set from:
   - active global rules;
   - active current-project knowledge/rules;
   - transferable lessons whose mechanism matches the current work;
   - directly matching or strongly analogous incidents.
9. For each retrieved item, decide whether it is:
   - **directly applicable**;
   - **analogically reusable** after validation;
   - **not applicable** because its conditions differ.
10. Explicitly extract any recurrence-prevention guidance, prior wrong assumptions, dangerous shortcuts, or validation checks that could prevent repeating a past mistake.
11. Validate relevant memory against current source/configuration/tests before relying on it.
12. Apply useful memory silently unless mentioning it materially helps explain a decision.

## Recall behavior

Recall is not merely semantic search. It acts as a lightweight pre-mortem/code-review pass using prior experience.

Before substantial execution, ask internally:

```text
What similar mistake has happened before?
What reusable Lesson applies even if it came from another project?
What hidden project constraint must not be broken?
What assumption should be verified instead of guessed?
```

Do not force an analogy. Cross-project memory is useful only when the underlying mechanism and applicability conditions actually match.

## Recall constraints

- Never load the whole repository merely "for context".
- Do not treat memory as authoritative when current code, tests, configuration, official documentation, or explicit user instructions contradict it.
- Do not modify memory during Recall.
- Do not create a memory merely because Recall found nothing.
- Do not block the user's task if shared memory is unavailable.

# Mode B — Learn / Remember

## Entry condition

Enter Learn/Remember mode **only when the user explicitly asks to persist or update knowledge**.

Examples of explicit intent include:

- `agent_memory remember`
- `agent_memory learn`
- "이거 기억해"
- "메모리에 남겨"
- "이번 작업 저장해"
- "이 실수 학습해"
- "기존 메모리 업데이트해"
- "이 규칙 앞으로 기억해"
- "learn this"
- "save this to memory"

Do not infer permission to write merely because:

- the task was difficult;
- an important bug was fixed;
- a reusable lesson was discovered;
- a design or analysis was completed;
- the task is finished;
- the agent believes the information would be useful later.

When intent is ambiguous, do not write memory.

## Learn / Remember procedure

1. Read `MEMORY_POLICY.md`.
2. Identify the specific knowledge the user intends to preserve.
3. Remove implementation-log noise and isolate the durable fact, constraint, lesson, decision rationale, failure pattern, or workflow.
4. Run the Shared Memory Intelligence checks: Distill, Transfer, Prevent, Bound, Verify, Deduplicate, Compress.
5. Explicitly check **generalization potential**:
   - project-only invariant/behavior;
   - reusable lesson within similar modules;
   - broadly reusable engineering lesson/rule.
6. Explicitly derive **recurrence-prevention value** when relevant:
   - what wrong assumption caused trouble;
   - what future Agent should check first;
   - what approach should be avoided;
   - what verification closes the risk.
7. Define applicability and exceptions. Do not turn one local case into a global rule without evidence.
8. Search existing memory before creating anything.
9. Compare candidates using:
   - operation/state transition;
   - error/failure signature;
   - technology and module/component;
   - root cause;
   - invariant or design constraint;
   - wrong approach or Agent mistake;
   - correct resolution;
   - reusable rule/pattern;
   - applicability scope.
10. If substantially the same memory already exists, update it instead of creating a duplicate.
11. If a specific project fact and a generalized Lesson both have distinct future value, they may be stored separately, but keep each concise and avoid repeating the same content.
12. Otherwise classify and create the smallest useful memory using `templates/MEMORY_TEMPLATE.md`.
13. Rebuild `INDEX.md` after a successful write/update.
14. Report briefly what was stored or updated, including whether any project-specific knowledge was generalized into a reusable Lesson.

## What is usually worth storing

- a verified, non-obvious root cause;
- a meaningful Agent mistake or unsafe assumption that should not recur;
- a reusable debugging/build/deployment/database sequence;
- a verified architecture/design constraint or decision that is likely to matter again;
- an important project invariant, boundary, or prohibition;
- a repeated failure pattern likely to recur;
- a transferable pattern discovered from a specific project incident;
- a correction to an existing memory that was incomplete or wrong.

## What should not be stored

- trivial successful work;
- implementation summaries with no reusable knowledge;
- file/class change lists;
- generic programming syntax/reference knowledge;
- temporary session state;
- raw conversation transcripts;
- raw logs when a compact root-cause summary is sufficient;
- unverified speculation;
- secrets, passwords, API keys, tokens, private keys, or authentication material;
- personal or sensitive information that is not necessary for reusable engineering knowledge.

# Mode C — Backfill

## Entry condition

Enter Backfill mode **only when the user explicitly requests retrospective session review/persistence**.

Recommended invocation:

```text
agent_memory backfill
```

Equivalent requests such as `agent-memory backfill`, `이 세션 백필해`, or `이 세션 회고해서 필요한 기억 반영해` are also valid.

The Backfill invocation itself is explicit permission to persist selected reusable knowledge from the available current session/history and to update the shared Tool candidate backlog when worthwhile candidates are found. It is not permission to modify unrelated project source or to implement Tool candidates.

## Backfill procedure

1. Read `MEMORY_POLICY.md` and `references/backfill.md`.
2. Determine how much of the current session/history is actually available to the host Agent. If earlier context is unavailable or truncated, report that limitation and never invent missing history.
3. Review the available session retrospectively, but do **not** start by summarizing what was implemented.
4. Run the same Shared Memory Intelligence checks used by Remember across the session's candidate knowledge.
5. Prioritize:
   - meaningful mistakes, wrong assumptions, failed edits, rework, and recurrence-prevention rules;
   - verified root causes and correct resolutions;
   - project invariants, hidden constraints, boundaries, dependencies, and dangerous-to-change behavior;
   - architecture/design decisions, selected approaches, rejected alternatives, and the reasons;
   - effective debugging, verification, build, deployment, DB, migration, or test sequences;
   - transferable lessons that can be generalized beyond the original project;
   - reusable procedures and safety checklists;
   - durable unresolved risks or technical debt that future work must know;
   - repeated deterministic work that may be a new Tool candidate;
   - bugs, limitations, path/output issues, or usability problems in an existing Tool/Script that should be classified as an improvement instead of a new Tool.
6. Treat plain implementation summaries/change logs as low-value and normally discard them unless they encode a hidden invariant, important navigation map, or future decision constraint.
7. Prefer final verified outcomes over intermediate guesses. Preserve a wrong approach only when remembering why it was wrong would prevent recurrence.
8. Validate important Memory candidates against current source/configuration/tests when practical. Do not promote unverified claims into durable rules.
9. Search existing memory before writing anything and merge near-duplicates instead of creating parallel memories.
10. Classify and write only durable, reusable Memory knowledge using the existing memory schema/template.
11. If Tool candidates or Tool/Script improvements were found, read `TOOL_CANDIDATES.md`, deduplicate by purpose/target/problem, and update the shared backlog according to `references/backfill.md` and `templates/TOOL_CANDIDATE_TEMPLATE.md`.
12. Rebuild `INDEX.md` only after successful Memory changes. Tool candidate backlog changes do not require rebuilding the Memory index.
13. Report briefly:
   - newly stored memories;
   - updated/deduplicated memories;
   - generalized reusable lessons;
   - recurrence-prevention rules or important project constraints discovered;
   - new Tool candidates and Tool/Script improvements;
   - whether each Tool backlog item was newly added or merged into an existing item;
   - notable implementation-summary items intentionally skipped;
   - any session-history coverage limitation.

## Backfill constraints

- Do not save a session summary just because the session was long.
- Do not use implementation completion as the main organizing structure.
- Do not save raw conversation or raw logs.
- Do not store every decision; retain only decisions likely to affect future work.
- Do not store temporary progress/status that becomes stale immediately.
- Do not save an unverified hypothesis as fact in Memory.
- Do not overwrite verified final knowledge with an earlier incorrect conclusion from the same session.
- Tool candidates are separate from Memory and may use `verification: needs-validation`, but do not invent candidates without evidence from the session/work.
- Existing Tool/Script defects belong in `TOOL_CANDIDATES.md` as `kind: improvement`; do not misclassify them as new Tool candidates.
- Backfill may update `TOOL_CANDIDATES.md`, but it does not create, modify, or execute the candidate Tool/Script implementation.
- Never add candidate-only items to `TOOL_INDEX.md`.
- If there is no worthwhile durable Memory knowledge, do not create Memory files.
- If there are no Tool candidates/improvements, do not modify `TOOL_CANDIDATES.md`.
- If neither exists, report that there is nothing worthwhile to persist rather than inventing content.

# Classification

Use the narrowest appropriate category.

- `rule`: verified durable instruction that should constrain future work repeatedly.
- `lesson`: reusable problem-solving, prevention, validation, or engineering pattern.
- `incident`: a concrete failure and its verified root cause/resolution.
- `project`: knowledge valid only for a specific project/repository.

Prefer `lesson` or `incident` when uncertain. Do not promote uncertain knowledge to `rule`.

# Deduplication and updates

Before creating a new memory, search for an existing equivalent or near-equivalent item.

If one exists:

- update the existing file;
- increment `occurrences` when the schema contains it;
- refresh `last_seen` / `updated` where applicable;
- add only genuinely new evidence, applicability constraints, recurrence-prevention guidance, or a better solution;
- do not create parallel versions of the same lesson.

Do not rewrite unrelated memory files.

# Rule promotion

Promotion to `rule` requires both importance and verification. Repetition alone is not sufficient.

Useful evidence includes:

- repeated occurrence across independent tasks;
- source/configuration proving an invariant;
- tests/builds consistently validating the constraint;
- official documentation;
- explicit user/team instruction.

# File locations

Follow the existing repository structure and `templates/MEMORY_TEMPLATE.md`.

Typical locations:

- `memory/rules/`
- `memory/lessons/`
- `memory/incidents/`
- `memory/projects/<project>/`
- `memory/archive/`

Tool candidate backlog:

- `TOOL_CANDIDATES.md`
- `templates/TOOL_CANDIDATE_TEMPLATE.md`

Keep each memory compact enough to recognize the situation, understand its applicability, avoid prior mistakes, and safely reuse the lesson without replaying the original conversation.
