# Shared Agent Memory — always-on instruction snippet

아래 내용을 각 Agent의 전역/프로젝트 지침에 짧게 추가하는 것을 권장합니다.

```text
Shared engineering memory is available through the `agent-memory` skill.
For any non-trivial coding, debugging, build, deployment, migration, database, architecture, or security task, use `agent-memory` to recall relevant rules/lessons before making changes.
After the task, use the same skill only when a reusable root cause, meaningful agent mistake, project invariant, or recurring pattern was discovered. Do not store trivial work or secrets.
Never load the entire memory repository; retrieve only relevant items.
```

이 지침 자체에는 과거 메모리 내용을 넣지 않습니다. 메모리를 찾는 방법만 고정합니다.
