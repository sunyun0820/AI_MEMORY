---
name: agent-memory
description: Recall relevant shared engineering memory before substantial analysis, design, coding, debugging, or review when past context can help. Remember, Backfill, and Refine require an explicit request to save, recover, or improve stored knowledge.
---

# Agent Memory

Use AI_MEMORY as selective engineering reference knowledge. Preserve useful lessons, failure prevention, rules, and bounded project knowledge; never treat task completion as permission to save memory.

## Resolve the repository

Use `AI_MEMORY_HOME`, or the repository clearly identified by this skill's installed link. Do not guess a drive. If unavailable, continue the task and report Recall as unavailable. Search helpers resolve canonical/junction paths and accept `-Root`; copied skills require an environment variable or explicit root.

## Essential boundaries

- Current code, config, tests, official documentation, and explicit user instructions outrank recalled memory during real work.
- Memory is source-independent: do not acquire project source merely to Remember, Backfill, or Refine. Evidence already encountered in the current work may be used.
- Do not lower confidence, archive, or mark VERIFY merely because project source is unavailable. Preserve historical version/scope boundaries. VERIFY means uncertainty or contradiction inside the memory itself.
- No secrets, automatic memory writes, or scope expansion. DB/Git/external-action authorization rules still apply.
- Use relevant memories only. Recalled facts may be combined as temporary working knowledge without claiming stronger evidence or automatically saving the combination.

## Recall

Use before substantial engineering work when past knowledge could help. Skip trivial questions and isolated one-off operations. A completed Recall for the same continuing task can be reused as described below.

For a new retrieval:

1. Resolve the repository and identify the project, operation, and failure mechanism using context already available.
2. Batch a few discriminating names and mechanism terms in one search. Prefer the full-content helper below; a targeted INDEX search is also valid. INDEX contains metadata, not every API/body term: an inconclusive index-only search needs one targeted body search before concluding no relevant memory exists.
3. Read the smallest useful set, usually 1-3 files initially, batching independent reads. Include applicable global rules and transferable lessons, not only project-name matches. This is not a quota or a hard maximum: expand only for missing constraints, contradictory evidence, or uncovered mechanisms.
4. Apply each item within its evidence and version/scope. Use current task source when execution depends on present implementation details. Stop retrieval once the task has enough relevant guidance.

```powershell
# Run from AI_MEMORY, using names/mechanisms from the actual task.
.\scripts\search-memory.ps1 -Query 'project-name','failure-mechanism' -Project 'project-name'
```

`-Project` boosts matching projects without filtering out global/analogous lessons. Results default to 5 files; use `-MaxFiles` for a justified expansion. Use `-AsObject` for structured consumers and `-IncludeArchived` only when history is relevant. Terms are literal, case-insensitive OR matches, ranked by exact ID, project/global applicability, distinct term coverage, metadata matches, and capped hit count.

Reading this skill alone does not complete Recall. Completion means an actual search plus reading useful candidates, an actual search finding nothing relevant, or valid reuse of an earlier completed retrieval. Do not repeatedly reread INDEX or the skill to prove compliance. Do not read write-mode references, run setup/doctor, or rebuild indexes during normal Recall.

### Reuse within a continuing task

Reuse a completed retrieval when its project, operation, failure mechanism, applicable constraints, and relevant evidence are still available in the conversation. A progress question, wording change, or follow-up on the same finding does not restart Recall. Reuse previous no-match results under the same conditions. This is conversation reuse, not a persistent filesystem cache.

Retrieve only the affected context again when the project/mechanism/constraints change, new evidence contradicts the recalled facts, relevant memory changes or synchronization are observed, the user asks for a fresh check, or prior evidence is unavailable/stale after a long gap or resumed session. Do not launch a timestamp/hash scan on every follow-up merely to qualify for reuse. Never describe reused historical facts as freshly verified current source.

## Explicit write modes

Before any write, read the repository's `MEMORY_POLICY.md` and [references/write-modes.md](references/write-modes.md). Only load the additional reference for the requested mode:

- **Remember / Learn** (`agent_memory remember`, `기억해`, `저장해`): distill current evidence into durable reference knowledge; deduplicate first.
- **Backfill** (`agent_memory backfill`, explicit session retrospective/persistence): read [references/backfill.md](references/backfill.md); recover knowledge from available session history without a new source audit.
- **Refine** (`agent_memory refine`, `기존 메모리 전체 정제해`): read [references/refine.md](references/refine.md); classify and improve active stored memory using memory itself. This is not a source audit.

The hyphenated `agent-memory` spelling and clear natural-language equivalents are valid. Preserve evidence, safety, generalization, and manual-learning boundaries from the policy and mode reference. After authorized memory changes, rebuild INDEX and inspect generated paths; run structural validation when appropriate.
