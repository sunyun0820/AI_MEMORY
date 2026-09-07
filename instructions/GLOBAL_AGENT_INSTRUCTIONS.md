# Shared Agent Memory

Use the `agent-memory` skill as shared long-term engineering memory.

## Automatic recall

For non-trivial engineering work, automatically use `agent-memory` in **Recall** mode before substantial analysis, design, decision-making, or modification when past rules, project knowledge, lessons, incidents, or prior mistakes could materially help.

Typical cases include:

- system/source/problem analysis;
- feature, API, architecture, data model, migration, or integration design;
- technical trade-off and impact analysis;
- coding, debugging, code review, and refactoring;
- build/deployment failures;
- database work;
- security work;
- changes to an existing codebase;
- repeated or similar engineering work.

Do not require the user to invoke memory first. Skip automatic recall for trivial questions or tiny one-off operations where past engineering context is unlikely to matter.

Use only relevant memories. Never load the entire memory repository into context.

## Manual learning only

Do **not** write, update, promote, or archive shared memory automatically after completing a task.

Use `agent-memory` in **Learn** mode only when the user explicitly asks to preserve or update the experience, for example: "기억해", "메모리에 남겨", "저장해", "업데이트해", "이거 학습해", "learn this", or an equivalent explicit request.

When learning is requested, deduplicate and follow `MEMORY_POLICY.md` before writing.

## Precedence

Current source code, configuration, tests, official documentation, and explicit user/project instructions take precedence over stale or conflicting memory.
