---
name: agent-memory
description: Shared engineering memory for coding agents. Automatically use Recall mode before non-trivial analysis, design, architecture, coding, debugging, review, refactoring, migration, build/deployment, database, security, or existing-codebase work when past rules, project knowledge, lessons, incidents, or prior mistakes may help. Use Learn/Remember only when the user explicitly asks to remember/save/update knowledge. Use Backfill only when the user explicitly asks to retrospectively review the current session/history and persist reusable knowledge. Use Refine only when the user explicitly asks to review and improve the already-stored AI_MEMORY repository itself, for example `agent_memory refine`, `agent-memory refine`, `메모리 전체 정제해`, or `기존 메모리 리파인해`.
---

# Agent Memory

Use the shared `AI_MEMORY` repository as selective long-term engineering memory.

The goal is not to preserve implementation history or mirror current source. The goal is to preserve **reference knowledge** that improves future decisions: reusable lessons, recurrence prevention, important rules, past failures, and project/version-specific structure or constraints.

This skill has four modes:

- **Recall**: retrieve relevant past knowledge before substantial work.
- **Learn / Remember**: explicitly persist important knowledge from the current work.
- **Backfill**: explicitly review the available current session/history and recover durable knowledge that was not stored earlier.
- **Refine**: explicitly maintain and improve already stored active Memory.

Never treat task completion by itself as permission to write Memory.

## Invocation

```text
agent_memory recall
agent_memory remember
agent_memory backfill
agent_memory refine
```

`agent-memory` with a hyphen and clear natural-language equivalents are also valid.

Before any write, update, promotion, archival, Remember, Backfill, or Refine operation, read `MEMORY_POLICY.md`.

For detailed mode guidance:

- Backfill: read `references/backfill.md` only when Backfill is invoked.
- Refine: read `references/refine.md` only when Refine is invoked.

## Resolve memory home

Resolve the Memory repository in this order:

1. Environment variable `AI_MEMORY_HOME`.
2. If unavailable, infer it only when the installed skill link clearly resolves back to the AI_MEMORY repository.
3. If the repository cannot be found, continue the user's task without inventing Memory.

Do not assume a fixed drive such as `E:\AI_MEMORY`.

# Core contract: Memory is not Source

AI_MEMORY is a **source-independent reference layer**.

```text
Remember  = current work → durable Memory
Backfill  = current session/history → recovered Memory
Refine    = existing Memory repository → better Memory
Recall    = Memory → reference for current work
```

Hard rules:

- Do not require project Source to exist in order to keep, store, or refine Memory.
- Do not search for project Source merely to validate Memory.
- Do not write `source unavailable`, `source not acquired`, `needs current source check`, or equivalent repository-access state into Memory.
- Do not lower `confidence`, change `scope`, archive, or mark `VERIFY` merely because current Source is unavailable.
- Remember/Backfill may use code, config, tests, logs, docs, or user/team instruction **already encountered in the current work/session** as evidence.
- Refine is **Memory-repository maintenance by default**. It must not become Source Audit.
- Recall is different: when Memory is applied to a real task and current code/config/tests are available, the current task state is the final fact. Memory remains advisory.

Project/version memories are valid even when their original Source is not currently available, as long as they are bounded appropriately, for example `C-MOS 3.5.2에서 확인된 구조` rather than `C-MOS는 항상 이 구조다`.

# Shared Memory Intelligence

For every candidate, recalled item, or stored Memory under review, reason through:

1. **Distill** — durable knowledge or mere implementation log?
2. **Transfer** — project-only fact or transferable mechanism?
3. **Prevent** — what failure, wrong assumption, regression, or unsafe approach should not recur?
4. **Bound** — when does it apply and when should it not be generalized?
5. **Evidence** — what already-known evidence or experience supports the statement?
6. **Deduplicate** — is there already a stronger equivalent Memory?
7. **Compress** — can it be stated more simply without losing safety or applicability?

`Evidence` does **not** mean acquiring new Source. Use evidence already present in the current task/session or already recorded in Memory.

A strong Memory usually answers:

```text
What is the durable knowledge?
Why does it matter?
When does it apply?
What should be avoided or checked?
What evidence or experience produced it?
```

## Generalization rule

When a specific project incident reveals a broader engineering mechanism, check whether a separate reusable Lesson is justified.

Store project-specific and generalized Memory separately only when they provide distinct future value. Do not create a project-less copy by simply removing names.

A local implementation that worked is not automatically a global rule. Separate the **general principle** from the **project-specific implementation choice**.

# Mode A — Recall

## When to use

Automatically use Recall before substantial work when prior engineering context could materially improve correctness, safety, consistency, or efficiency.

Normally skip Recall for trivial syntax questions, tiny conversions, isolated command lookups, or generic factual questions where project Memory is unlikely to matter.

## Recall procedure

1. Identify current project/repository, technology, module/component, operation, state transition, invariant, objective, failure class, and likely regression risks.
2. Read active global rules when relevant.
3. Check relevant `memory/projects/<project>/` knowledge.
4. Search `INDEX.md` using both names and mechanisms.
5. If needed, search Memory content with `scripts/search-memory.ps1`, `rg`, or equivalent local text search.
6. Load only the most relevant Memory files, normally 3–7.
7. Build a small applicability set from global rules, current-project knowledge, transferable lessons, and analogous incidents.
8. Decide whether each item is directly applicable, analogically reusable after validation, or not applicable because conditions differ.
9. Extract recurrence-prevention guidance, prior wrong assumptions, dangerous shortcuts, and useful validation checks.
10. Apply useful Memory as a reference.
11. When actual execution depends on current implementation details, validate against the **current task's available source/config/tests** before changing code or making a factual claim about the present system.

## Recall constraints

- Never load the whole Memory repository merely for context.
- Memory is not authoritative over current code/config/tests/official docs/user instruction during actual work.
- Do not modify Memory during Recall.
- Do not create Memory merely because Recall found nothing.
- Do not block the user's task if shared Memory is unavailable.

# Mode B — Learn / Remember

## Entry condition

Enter Remember only when the user explicitly asks to persist or update knowledge, for example:

```text
agent_memory remember
이거 기억해
메모리에 남겨
이 실수 학습해
기존 메모리 업데이트해
```

## Remember procedure

1. Read `MEMORY_POLICY.md`.
2. Identify the specific knowledge the user intends to preserve.
3. Remove implementation-log noise and isolate the durable fact, constraint, lesson, decision rationale, failure pattern, or workflow.
4. Apply Distill, Transfer, Prevent, Bound, Evidence, Deduplicate, Compress.
5. Determine the narrowest correct scope:
   - project/version-specific invariant or behavior;
   - reusable lesson within similar systems;
   - truly broad engineering lesson/rule.
6. Derive recurrence-prevention value when relevant.
7. Define applicability and exceptions. Do not turn one local case into a global rule.
8. Use **evidence already available in the current work**. Do not locate or scan another project repository merely to strengthen a Memory candidate.
9. Search existing Memory before creating anything.
10. Update an equivalent Memory instead of creating a duplicate.
11. If project fact and generalized Lesson have distinct future value, store both concisely without repeating the same content.
12. Create the smallest useful Memory using `templates/MEMORY_TEMPLATE.md`.
13. Rebuild `INDEX.md` after a successful Memory write/update.
14. Report briefly what was stored or updated.

## Remember source rule

Remember is allowed to capture facts learned from current Source because the Source was part of the work. It is **not** allowed to turn Memory persistence into a second source-analysis task.

If the current work only established a historical/project fact such as `version X used structure Y`, store it with that boundary. Do not mark it weak merely because another machine does not currently have that Source checkout.

## Usually worth storing

- verified, non-obvious root cause;
- meaningful Agent mistake or unsafe assumption that should not recur;
- reusable debugging/build/deployment/database sequence;
- architecture/design constraint or decision likely to matter again;
- important project/version invariant, boundary, or prohibition;
- repeated failure pattern;
- transferable pattern discovered from a specific incident;
- correction to an existing Memory that was incomplete or wrong.

## Usually not worth storing

- trivial successful work;
- implementation summaries with no reusable knowledge;
- file/class change lists;
- generic syntax/reference knowledge;
- temporary session state;
- raw transcripts/logs when a compact summary is sufficient;
- unverified speculation presented as fact;
- secrets or unnecessary personal/sensitive information.

# Mode C — Backfill

## Entry condition

Enter Backfill only when the user explicitly requests retrospective session review/persistence.

```text
agent_memory backfill
```

Backfill starts from the **available current session/history**, not from a new audit of project Source.

## Backfill procedure

1. Read `MEMORY_POLICY.md` and `references/backfill.md`.
2. Determine how much of the current session/history is actually available. Never invent missing history.
3. Review the available session retrospectively without starting from an implementation summary.
4. Apply the same quality checks as Remember.
5. Prioritize mistakes, wrong assumptions, root causes, hidden constraints, design rationale, reusable verification workflows, transferable lessons, durable unresolved risks, and Tool candidates.
6. Prefer final established outcomes over intermediate guesses.
7. Treat code/config/test/log evidence already present in the session as optional supporting evidence.
8. **Do not reopen, discover, or scan project Source solely to validate Backfill candidates.**
9. Search existing Memory and merge near-duplicates.
10. Write only durable knowledge.
11. Update `TOOL_CANDIDATES.md` only when worthwhile Tool candidates/improvements exist, following `references/backfill.md`.
12. Rebuild `INDEX.md` only after Memory changes.
13. Report briefly what was stored/updated and any session-history limitation.

## Backfill constraints

- Do not save a session summary merely because the session was long.
- Do not organize Memory around implementation completion.
- Do not save raw conversation/logs or temporary progress.
- Do not save unverified hypotheses as fact.
- Do not acquire missing Source just to improve confidence.
- Existing Tool/Script defects belong in `TOOL_CANDIDATES.md` as `kind: improvement`.
- Backfill may update the candidate backlog but does not implement candidates.
- Never add candidate-only items to `TOOL_INDEX.md`.

# Mode D — Refine

## Entry condition

Enter Refine only when the user explicitly asks to review/clean/improve already stored AI_MEMORY.

```text
agent_memory refine
```

## Refine scope

Default active scope:

```text
memory/rules/
memory/lessons/
memory/incidents/
memory/projects/<project>/
```

`memory/archive/` may be consulted only for Memory-history conflict/dedup context. `TOOL_CANDIDATES.md` is not part of normal Refine scope.

## Refine source rule — hard boundary

Refine is **source-blind by default**.

During ordinary `agent_memory refine`:

- do not locate or open project repositories outside AI_MEMORY;
- do not inspect project file counts, implementations, branches, binaries, DBs, builds, or runtime systems;
- do not write `source unavailable`, `source not acquired`, or `current source check required` into Memory;
- do not reduce confidence/scope/status because project Source is unavailable;
- do not mark `VERIFY` merely because current Source cannot be checked;
- do not transform a historical/versioned fact into an uncertainty simply because its original Source is not mounted now.

The user may explicitly request a **separate source fact-check**. That is not normal Refine behavior.

## Refine procedure

1. Read `MEMORY_POLICY.md` and `references/refine.md`.
2. Read `INDEX.md` and enumerate all active Memory files.
3. Build an internal review table before editing. Classify every Memory as KEEP / REFINE / GENERALIZE / MERGE / ARCHIVE / VERIFY.
4. Apply Distill, Transfer, Prevent, Bound, Evidence, Deduplicate, Compress using Memory content and already recorded evidence only.
5. Suppress implementation-log content while preserving hidden invariants, root causes, recurrence prevention, design rationale, reusable workflows, and valuable navigation/version knowledge.
6. Check project-specific knowledge for a defensible generalized Lesson without over-generalizing.
7. Merge equivalent Memory around the strongest useful version.
8. Treat `rule` most conservatively.
9. Keep project/version Memory when architecture/navigation/invariants remain useful as historical reference.
10. Keep incidents when the concrete failure/root cause still has diagnostic value.
11. For Memory-internal uncertainty or contradictions, use existing Memory metadata/evidence/user corrections. If unresolved, use `VERIFY` without performing Source Audit.
12. Archive low-value/superseded Memory when history is still useful; remove only clearly disposable duplicates/noise.
13. Rebuild `INDEX.md` after all Memory changes.
14. Run `doctor.ps1` or equivalent **AI_MEMORY structural validation** when practical.
15. Report counts and major quality changes only.

## VERIFY semantics

`VERIFY` means **the Memory itself is uncertain**, for example:

- it was originally recorded as a hypothesis;
- two active Memory items make directly incompatible claims;
- metadata/body contradict each other;
- evidence recorded inside Memory is insufficient to distinguish competing claims.

The following do **not** mean VERIFY:

```text
project source is not checked out
source path is unknown
current workstation lacks the project
original implementation file cannot be opened now
```

## Refine constraints

- Refine modifies Memory only when explicitly invoked.
- Refine is Memory maintenance, not project-source implementation or audit work.
- Do not generalize beyond evidence already available in Memory.
- Do not reduce specificity merely to make Memory shorter.
- Do not optimize for fewer files; optimize for future decision value and low noise.
- Project + incident + lesson may coexist when each provides distinct future value.
- `scope: global` and GENERALIZE candidates must pass the generalization boundary test in `MEMORY_POLICY.md`.
- If the Memory repository is too large for one safe pass, process explicit batches and do not claim completion until all active Memory has been reviewed.

# Classification

Use the narrowest appropriate category.

- `rule`: verified durable instruction that should constrain future work repeatedly.
- `lesson`: reusable problem-solving, prevention, validation, or engineering pattern.
- `incident`: concrete failure and its known root cause/resolution.
- `project`: knowledge valid for a specific project/product/version/repository.

Prefer `lesson` or `incident` when uncertain. Do not promote uncertain knowledge to `rule`.

# Deduplication and updates

Before creating a new Memory, search for an existing equivalent or near-equivalent item.

If one exists:

- update the existing file;
- increment `occurrences` when appropriate;
- refresh `last_seen` / `updated` where applicable;
- add only genuinely new evidence, applicability constraints, recurrence-prevention guidance, or a better solution;
- do not create parallel versions of the same lesson.

# Rule promotion

Promotion to `rule` requires importance and already-known verification. Repetition alone is not sufficient, and Refine must not perform new Source Audit merely to justify promotion.

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
