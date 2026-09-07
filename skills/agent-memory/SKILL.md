---
name: agent-memory
description: Shared engineering memory for coding agents. Automatically use Recall mode before non-trivial analysis, design, architecture, coding, debugging, review, refactoring, migration, build/deployment, database, security, or existing-codebase work when past rules, project knowledge, lessons, incidents, or prior mistakes may help. Use Learn/write mode only when the user explicitly asks to remember, save, learn, update memory, 기록해, 기억해, 메모리에 남겨, 저장해, 업데이트해, or otherwise requests persistence.
---

# Agent Memory

Use the shared `AI_MEMORY` repository as selective long-term engineering memory.

This skill has two distinct modes:

- **Recall**: automatic when relevant before substantial engineering analysis, design, or execution.
- **Learn**: manual only; requires an explicit user request to persist or update knowledge.

Never treat task completion by itself as permission to write memory.

## Resolve memory home

Resolve the memory repository in this order:

1. Environment variable `AI_MEMORY_HOME`.
2. If unavailable, infer the repository only when the installed skill link clearly resolves back to the AI_MEMORY repository.
3. If the repository cannot be found, continue the user's task without inventing memory.

Do not assume a fixed drive such as `E:\AI_MEMORY`.

Before any write, update, promotion, or archival operation, read `MEMORY_POLICY.md`.

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

1. Identify the current repository/project, technology, module/component, requested analysis/design objective, operation, error text, and failure class where applicable.
2. Read `memory/rules/global.md` if it exists.
3. Check whether relevant project-scoped memory exists under `memory/projects/<project>/`.
4. Extract a small set of discriminative search terms from the task.
5. Search `INDEX.md` first.
6. If needed, search memory metadata, headings, and content using `scripts/search-memory.ps1`, `rg`, or an equivalent native text search.
7. Load only the most relevant memory files, normally no more than 3–7.
8. Prioritize in this order:
   - active global rules;
   - active current-project knowledge/rules;
   - matching lessons;
   - matching incidents.
9. Validate each retrieved memory against the current source/configuration before relying on it.
10. Apply useful memory silently unless mentioning it materially helps explain a decision.

## Recall constraints

- Never load the whole repository merely "for context".
- Do not treat memory as authoritative when current code, tests, configuration, official documentation, or explicit user instructions contradict it.
- Do not modify memory during Recall.
- Do not create a memory merely because Recall found nothing.
- Do not block the user's task if shared memory is unavailable.

# Mode B — Learn

## Entry condition

Enter Learn mode **only when the user explicitly asks to persist or update knowledge**.

Examples of explicit intent include:

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

## Learn procedure

1. Read `MEMORY_POLICY.md`.
2. Summarize only the reusable engineering knowledge from the work or decision.
3. Determine whether the candidate is actually worth preserving.
4. Search existing memory before creating anything.
5. Compare candidates using:
   - error/failure signature;
   - technology and module/component;
   - root cause;
   - design/architecture constraint or decision;
   - wrong approach or agent mistake;
   - correct resolution;
   - reusable rule/pattern.
6. If substantially the same memory already exists, update it instead of creating a duplicate.
7. Otherwise classify and create a concise new memory using `templates/MEMORY_TEMPLATE.md`.
8. Rebuild `INDEX.md` after a successful write/update.
9. Report briefly what was stored or updated.

## What is usually worth storing

- a verified, non-obvious root cause;
- a meaningful agent mistake or unsafe assumption that should not recur;
- a reusable debugging/build/deployment/database sequence;
- a verified architecture/design constraint or decision that is likely to matter again;
- an important project invariant, boundary, or prohibition;
- a repeated failure pattern likely to recur;
- a correction to an existing memory that was incomplete or wrong.

## What should not be stored

- trivial successful work;
- generic programming syntax/reference knowledge;
- temporary session state;
- raw conversation transcripts;
- raw logs when a compact root-cause summary is sufficient;
- unverified speculation;
- secrets, passwords, API keys, tokens, private keys, or authentication material;
- personal or sensitive information that is not necessary for reusable engineering knowledge.

# Classification

Use the narrowest appropriate category.

- `rule`: verified durable instruction that should constrain future work repeatedly.
- `lesson`: reusable problem-solving knowledge or engineering pattern.
- `incident`: a concrete failure and its verified root cause/resolution.
- `project`: knowledge valid only for a specific project/repository.

Prefer `lesson` or `incident` when uncertain. Do not promote uncertain knowledge to `rule`.

# Deduplication and updates

Before creating a new memory, search for an existing equivalent or near-equivalent item.

If one exists:

- update the existing file;
- increment `occurrences` when the schema contains it;
- refresh `last_seen` / `updated` where applicable;
- add only genuinely new evidence, constraints, or a better solution;
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

Keep each memory compact enough to recognize the situation and safely reuse the lesson without replaying the original conversation.
