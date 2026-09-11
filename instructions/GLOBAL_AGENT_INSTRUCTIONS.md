# Shared Agent Memory

Use the `agent-memory` skill as shared long-term engineering memory.

## Automatic recall

For non-trivial engineering work, automatically use `agent-memory` in **Recall** mode before substantial analysis, design, decision-making, or modification when past rules, project knowledge, lessons, incidents, or prior mistakes could materially help.

Skip trivial questions and tiny one-off operations where past engineering context is unlikely to help. Never load the whole memory repository for ordinary Recall.

### Recall completion and reuse

For a new task, resolve the memory repository, batch discriminating project/mechanism terms in one search, and read the smallest useful set (usually 1-3 files initially, expanding only when necessary). Use the skill's full-content search helper or targeted INDEX/body searches. INDEX does not contain every body term: do not conclude no relevant memory from an inconclusive index-only search.

Reading SKILL.md alone does not complete Recall. Complete retrieval before substantial work, or reuse a prior completed retrieval when the same task and applicable evidence remain in context. Progress questions and ordinary follow-ups do not restart the gate. Re-search the affected context when the project/mechanism/constraints change, conflicting evidence or relevant memory changes are observed, prior evidence is stale/unavailable, or the user asks for a fresh check. Do not run filesystem checks on every turn solely to reuse context.

An actual search with no useful result may be reused under the same conditions. If the repository is unavailable, continue the user's task and treat Recall as unavailable. Do not invent retrieved knowledge or claim reused facts were freshly verified. Detailed retrieval and write-mode rules live in the agent-memory skill.

## Manual learning only

Do **not** write, update, promote, or archive shared memory automatically after completing a task.

Use `agent-memory` in **Learn** mode only when the user explicitly asks to preserve or update the experience, for example: "기억해", "메모리에 남겨", "저장해", "업데이트해", "이거 학습해", "learn this", or an equivalent explicit request.

When learning is requested, deduplicate and follow `MEMORY_POLICY.md` before writing.

## Tool reuse

For repetitive, bulk, deterministic, or mechanical engineering work, check `AI_MEMORY_HOME/TOOL_INDEX.md` before reproducing the work manually when the shared repository is available.

If a suitable verified Tool exists and is materially more efficient, prefer it. Read only the selected Tool's `TOOL.md`; do not load the entire `tools/` directory.

A Tool's existence is not permission to perform a high-impact action. Respect its `safety` metadata. For `destructive` or `external` Tools, verify that the current user request authorizes the action and check the impact before execution.

Prefer concise structured Tool output over loading large raw results into context.

## Precedence

Current source code, configuration, tests, official documentation, and explicit user/project instructions take precedence over stale or conflicting memory or Tool documentation.
