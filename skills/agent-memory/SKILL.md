---
name: agent-memory
description: Shared engineering memory for coding agents. Automatically use Recall mode before non-trivial analysis, design, architecture, coding, debugging, review, refactoring, migration, build/deployment, database, security, or existing-codebase work when past rules, project knowledge, lessons, incidents, or prior mistakes may help. Use Learn/Remember only when the user explicitly asks to remember/save/update knowledge. Use Backfill only when the user explicitly asks to retrospectively review the current session/history and persist reusable knowledge. Use Refine only when the user explicitly asks to review and improve the already-stored AI_MEMORY repository itself, for example `agent_memory refine`, `agent-memory refine`, `메모리 전체 정제해`, or `기존 메모리 리파인해`.
---

# Agent Memory

Use the shared `AI_MEMORY` repository as selective long-term engineering memory.

This skill has four distinct modes:

- **Recall**: automatic when relevant before substantial engineering analysis, design, or execution.
- **Learn / Remember**: manual only; targeted persistence of important knowledge discovered during the current work.
- **Backfill**: manual only; retrospective review of the current session/history to recover reusable knowledge that was not stored while the work was happening.
- **Refine**: manual only; repository-wide maintenance of already stored Memory, regardless of whether it originally came from Remember, Backfill, or manual authoring.

Never treat task completion by itself as permission to write memory.

## Invocation

Recommended plain-text calls:

```text
agent_memory recall
agent_memory remember
agent_memory backfill
agent_memory refine
```

`agent-memory` with a hyphen is also acceptable. Natural-language equivalents are valid when intent is clear.

- `recall`: normally automatic, but can be requested explicitly.
- `remember` / `learn`: save or update a specific piece of current knowledge.
- `backfill`: review the available current session/history, select durable knowledge, deduplicate it against existing memory, persist only worthwhile items, and accumulate worthwhile Tool candidates/improvements in the shared candidate backlog.
- `refine`: review the already stored active Memory repository, improve signal-to-noise, generalize reusable lessons, merge duplicates, archive low-value/stale content, and rebuild the index.

Backfill is broader than Remember. Refine is different from both because it starts from **existing Memory files**, not from the current task/session.

For detailed mode checklists:

- Backfill: read `references/backfill.md` only when Backfill is invoked.
- Refine: read `references/refine.md` only when Refine is invoked.

## Resolve memory home

Resolve the memory repository in this order:

1. Environment variable `AI_MEMORY_HOME`.
2. If unavailable, infer the repository only when the installed skill link clearly resolves back to the AI_MEMORY repository.
3. If the repository cannot be found, continue the user's task without inventing memory.

Do not assume a fixed drive such as `E:\AI_MEMORY`.

Before any write, update, promotion, archival, Learn/Remember, Backfill, or Refine operation, read `MEMORY_POLICY.md`.

# Shared Memory Intelligence

Recall, Remember, Backfill, and Refine use the same quality model. The goal is not to preserve or replay implementation history. The goal is to turn past work into compact knowledge that improves future decisions.

For every candidate, recalled item, or stored Memory under review, reason through:

1. **Distill** — Is this durable knowledge, or merely an implementation summary/change log?
2. **Transfer** — Can the underlying mechanism apply outside the current file/module/project?
3. **Prevent** — What wrong assumption, failure, regression, or unsafe approach should a future Agent avoid?
4. **Bound** — Under what conditions does the knowledge apply, and when should it not be generalized?
5. **Verify** — Is it supported by code, config, tests, logs, official docs, or explicit user/team instruction?
6. **Deduplicate** — Is there already a stronger equivalent memory?
7. **Compress** — Can the useful knowledge be stated more simply without losing safety or applicability?

A strong Memory usually answers, compactly:

```text
What is the durable knowledge?
Why does it matter?
When does it apply?
What should be avoided or checked?
How was it verified?
```

## Generalization rule

When a specific project incident reveals a broader engineering mechanism, actively check whether a separate reusable Lesson is justified.

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

Typical triggers include existing-system analysis, architecture/design, code modification, debugging, review/refactoring, migration, build/deployment, database/security work, repeated work, and known project/module work.

Normally skip Recall for trivial syntax questions, tiny conversions, isolated command lookups, or generic factual questions where project memory is unlikely to matter.

The user does not need to ask for Recall explicitly.

## Recall procedure

1. Identify the current repository/project, technology, module/component, operation, state transition, invariant, objective, failure class, and likely regression risks.
2. Read `memory/rules/global.md` if it exists.
3. Check relevant project memory under `memory/projects/<project>/`.
4. Extract a small set of discriminative terms from both **names** and **mechanism**. Do not search only exact class/error keywords.
5. Search `INDEX.md` first.
6. If needed, search metadata/headings/content with `scripts/search-memory.ps1`, `rg`, or equivalent native text search.
7. Load only the most relevant Memory files, normally no more than 3–7.
8. Build a small applicability set from:
   - active global rules;
   - active current-project knowledge/rules;
   - transferable lessons whose mechanism matches the current work;
   - directly matching or strongly analogous incidents.
9. For each item decide whether it is directly applicable, analogically reusable after validation, or not applicable because conditions differ.
10. Extract recurrence-prevention guidance, prior wrong assumptions, dangerous shortcuts, and validation checks that can prevent repeating past mistakes.
11. Validate relevant Memory against current source/configuration/tests before relying on it.
12. Apply useful Memory silently unless mentioning it materially helps explain a decision.

## Recall behavior

Recall is not merely semantic search. It acts as a lightweight pre-mortem/code-review pass using prior experience.

Before substantial execution ask internally:

```text
What similar mistake has happened before?
What reusable Lesson applies even if it came from another project?
What hidden project constraint must not be broken?
What assumption should be verified instead of guessed?
```

Do not force an analogy. Cross-project Memory is useful only when the underlying mechanism and applicability conditions actually match.

## Recall constraints

- Never load the whole repository merely "for context".
- Do not treat Memory as authoritative when current code, tests, configuration, official documentation, or explicit user instructions contradict it.
- Do not modify Memory during Recall.
- Do not create a Memory merely because Recall found nothing.
- Do not block the user's task if shared Memory is unavailable.

# Mode B — Learn / Remember

## Entry condition

Enter Learn/Remember only when the user explicitly asks to persist or update knowledge.

Examples:

- `agent_memory remember`
- `agent_memory learn`
- "이거 기억해"
- "메모리에 남겨"
- "이번 작업 저장해"
- "이 실수 학습해"
- "기존 메모리 업데이트해"
- "이 규칙 앞으로 기억해"

Do not infer permission merely because the task was hard, an important bug was fixed, reusable knowledge was discovered, or the task is finished.

## Learn / Remember procedure

1. Read `MEMORY_POLICY.md`.
2. Identify the specific knowledge the user intends to preserve.
3. Remove implementation-log noise and isolate the durable fact, constraint, lesson, decision rationale, failure pattern, or workflow.
4. Run Shared Memory Intelligence: Distill, Transfer, Prevent, Bound, Verify, Deduplicate, Compress.
5. Explicitly check generalization potential:
   - project-only invariant/behavior;
   - reusable lesson within similar modules;
   - broadly reusable engineering lesson/rule.
6. Explicitly derive recurrence-prevention value when relevant:
   - what wrong assumption caused trouble;
   - what future Agent should check first;
   - what approach should be avoided;
   - what verification closes the risk.
7. Define applicability and exceptions. Do not turn one local case into a global rule without evidence.
8. Search existing Memory before creating anything.
9. Compare candidates by operation/state transition, error signature, technology/module, root cause, invariant, wrong approach, correct resolution, reusable pattern, and applicability scope.
10. If substantially the same Memory exists, update it rather than creating a duplicate.
11. If a specific project fact and a generalized Lesson both have distinct future value, they may be stored separately, but keep each concise and avoid repeating the same content.
12. Otherwise classify and create the smallest useful Memory using `templates/MEMORY_TEMPLATE.md`.
13. Rebuild `INDEX.md` after a successful write/update.
14. Report briefly what was stored or updated, including whether any project-specific knowledge was generalized into a reusable Lesson.

## Usually worth storing

- verified, non-obvious root cause;
- meaningful Agent mistake or unsafe assumption that should not recur;
- reusable debugging/build/deployment/database sequence;
- verified architecture/design constraint or decision likely to matter again;
- important project invariant, boundary, or prohibition;
- repeated failure pattern likely to recur;
- transferable pattern discovered from a specific project incident;
- correction to an existing Memory that was incomplete or wrong.

## Usually not worth storing

- trivial successful work;
- implementation summaries with no reusable knowledge;
- file/class change lists;
- generic syntax/reference knowledge;
- temporary session state;
- raw transcripts/logs when a compact summary is sufficient;
- unverified speculation;
- secrets or unnecessary personal/sensitive information.

# Mode C — Backfill

## Entry condition

Enter Backfill only when the user explicitly requests retrospective session review/persistence.

Recommended invocation:

```text
agent_memory backfill
```

Equivalent requests such as `agent-memory backfill`, `이 세션 백필해`, or `이 세션 회고해서 필요한 기억 반영해` are valid.

The Backfill invocation is explicit permission to persist selected reusable knowledge from the available current session/history and to update the shared Tool candidate backlog when worthwhile candidates are found. It is not permission to modify unrelated project source or implement Tool candidates.

## Backfill procedure

1. Read `MEMORY_POLICY.md` and `references/backfill.md`.
2. Determine how much of the current session/history is actually available. If earlier context is unavailable/truncated, report that limitation and never invent missing history.
3. Review the available session retrospectively, but do **not** start by summarizing what was implemented.
4. Run the same Shared Memory Intelligence checks used by Remember.
5. Prioritize:
   - mistakes, wrong assumptions, failed edits, rework, recurrence-prevention rules;
   - verified root causes and correct resolutions;
   - invariants, hidden constraints, boundaries, dependencies, dangerous-to-change behavior;
   - design decisions, selected/rejected approaches and reasons;
   - effective debugging/verification/build/deployment/DB/migration/test sequences;
   - transferable cross-project lessons;
   - reusable procedures/checklists;
   - durable unresolved risks/technical debt;
   - repeated deterministic work that may be a Tool candidate;
   - bugs/limitations/usability issues in an existing Tool/Script that belong as `improvement` candidates.
6. Treat plain implementation summaries/change logs as low-value and normally discard them unless they encode a hidden invariant, important navigation map, or future decision constraint.
7. Prefer final verified outcomes over intermediate guesses. Preserve a wrong approach only when remembering why it was wrong prevents recurrence.
8. Validate important Memory candidates against current source/config/tests when practical.
9. Search existing Memory and merge near-duplicates.
10. Write only durable, reusable knowledge using the existing schema/template.
11. If Tool candidates/improvements are found, read `TOOL_CANDIDATES.md`, deduplicate by purpose/target/problem, and update according to `references/backfill.md` and `templates/TOOL_CANDIDATE_TEMPLATE.md`.
12. Rebuild `INDEX.md` only after Memory changes. Tool candidate backlog changes do not require rebuilding the Memory index.
13. Report briefly new/updated Memory, generalized lessons, recurrence prevention, Tool candidate changes, skipped low-value implementation summaries, and any session-history limitation.

## Backfill constraints

- Do not save a session summary merely because the session was long.
- Do not organize Memory around implementation completion.
- Do not save raw conversation/logs or temporary progress.
- Do not save unverified hypotheses as fact.
- Do not overwrite verified final knowledge with earlier incorrect conclusions.
- Existing Tool/Script defects belong in `TOOL_CANDIDATES.md` as `kind: improvement`.
- Backfill may update candidate backlog but does not implement candidates.
- Never add candidate-only items to `TOOL_INDEX.md`.
- If no worthwhile durable Memory exists, create none.
- If no Tool candidates exist, do not modify `TOOL_CANDIDATES.md`.

# Mode D — Refine

## Entry condition

Enter Refine only when the user explicitly asks to review/clean/improve the already stored AI_MEMORY repository.

Recommended invocation:

```text
agent_memory refine
```

Equivalent requests such as `agent-memory refine`, `메모리 전체 정제해`, `기존 메모리 리파인해` are valid.

## Refine scope

Refine is **origin-agnostic**. It does not care whether a Memory came from Remember, Backfill, or manual authoring.

Default active scope:

- `memory/rules/`
- `memory/lessons/`
- `memory/incidents/`
- `memory/projects/<project>/`

`memory/archive/` is not rewritten by default. It may be consulted for conflict/dedup history, but archived content is never automatically reactivated.

`TOOL_CANDIDATES.md` is not part of normal Refine scope.

## Refine procedure

1. Read `MEMORY_POLICY.md` and `references/refine.md`.
2. Read `INDEX.md` and enumerate all active Memory files. Refine is the exception to the normal Recall rule that avoids loading the whole Memory repository, because repository-wide quality review is the explicit task.
3. Build an internal review table before editing. Classify every Memory as:
   - **KEEP**
   - **REFINE**
   - **GENERALIZE**
   - **MERGE**
   - **ARCHIVE**
   - **VERIFY**
4. Apply Shared Memory Intelligence to every Memory: Distill, Transfer, Prevent, Bound, Verify, Deduplicate, Compress.
5. Suppress implementation-log content and preserve hidden invariants, verified root causes, recurrence prevention, design rationale, reusable workflows, and valuable Source Navigation.
6. Check whether project-specific knowledge exposes a distinct generalized Lesson. Create one only when the reusable mechanism and applicability boundary are defensible and future value differs from the source Memory.
7. Merge equivalent/near-equivalent Memory around the strongest verified version. Preserve genuinely new evidence/applicability/prevention information.
8. Treat `rule` most conservatively. Do not widen, weaken, promote, or delete a rule without strong evidence.
9. Keep project Memory when project-specific architecture/navigation/invariants are valuable. Compress obvious implementation structure.
10. Keep incidents when the concrete failure + root cause still has diagnostic value, even if a generalized Lesson also exists.
11. For stale or conflicting items, validate against current code/config/tests when available. If unresolved, mark/retain uncertainty rather than inventing certainty.
12. Archive low-value/stale/superseded content when history is still useful. Remove only content that is clearly disposable and has no traceability value.
13. Rebuild `INDEX.md` after all Memory changes.
14. Run `doctor.ps1` or equivalent structural validation when practical.
15. Report only counts and major quality changes, not a new implementation-style summary of every Memory.

## Refine constraints

- Refine modifies Memory only when explicitly invoked.
- Refine is repository maintenance, not project-source implementation work.
- Do not generalize beyond evidence.
- Do not reduce specificity merely to make Memory shorter.
- Do not optimize for fewer files; optimize for future decision value and low noise.
- Project + incident + lesson may all coexist when each provides distinct future value.
- If the Memory repository is too large for one safe pass, process explicit batches and do not claim full completion until all active Memory has been reviewed.

# Classification

Use the narrowest appropriate category.

- `rule`: verified durable instruction that should constrain future work repeatedly.
- `lesson`: reusable problem-solving, prevention, validation, or engineering pattern.
- `incident`: a concrete failure and its verified root cause/resolution.
- `project`: knowledge valid only for a specific project/repository.

Prefer `lesson` or `incident` when uncertain. Do not promote uncertain knowledge to `rule`.

# Deduplication and updates

Before creating a new Memory, search for an existing equivalent or near-equivalent item.

If one exists:

- update the existing file;
- increment `occurrences` when appropriate;
- refresh `last_seen` / `updated` where applicable;
- add only genuinely new evidence, applicability constraints, recurrence-prevention guidance, or a better solution;
- do not create parallel versions of the same lesson.

Do not rewrite unrelated Memory files outside the active mode's scope.

# Rule promotion

Promotion to `rule` requires both importance and verification. Repetition alone is not sufficient.

Useful evidence includes repeated occurrence across independent tasks, source/config proving an invariant, tests/builds validating the constraint, official docs, or explicit user/team instruction.

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

Keep each Memory compact enough to recognize the situation, understand applicability, avoid prior mistakes, and safely reuse the lesson without replaying the original conversation.
