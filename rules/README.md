# Shared Rules

이 디렉터리는 모든 개발 Agent에 공통으로 적용할 안전·행동 규칙의 canonical source입니다.

## Canonical sources

- `db-safety.md`
- `git-safety.md`
- `engineering-principles.md`

위 세 파일만 직접 수정합니다.

`RULES.md`는 위 세 파일을 정해진 순서로 합친 배포용 aggregator이며 `setup.ps1`이 자동으로 재생성합니다. 직접 수정하지 않습니다.

## 적용 흐름

```text
rules/*.md
   │
   ├─ Codex / Claude / Gemini 계열
   │     ↓
   │   rules/RULES.md
   │     +
   │   instructions/GLOBAL_AGENT_INSTRUCTIONS.md
   │
   └─ Cursor
         ↓
       adapters/cursor-plugin/rules/
       ├─ db-safety.mdc
       ├─ git-safety.mdc
       └─ engineering-principles.mdc
```

Agent별 배포 위치:

```text
Codex       → ~/.codex/AGENTS.md
Claude Code → ~/.claude/CLAUDE.md
Gemini CLI  → ~/.gemini/GEMINI.md
Antigravity → ~/.gemini/GEMINI.md
Cursor      → ~/.cursor/plugins/local/ai-memory
```

Cursor에서는 `agent-memory` Skill이 Memory 동작을 담당하고, 이 디렉터리의 canonical Rule 3개는 local plugin의 독립된 `alwaysApply` Rule 3개로 배포됩니다.

## 변경 방법

1. canonical rule 파일을 수정합니다.
2. `setup.ps1`을 실행합니다.
3. `doctor.ps1`을 실행합니다.
4. Cursor가 실행 중이면 `Developer: Reload Window`를 실행합니다.

`doctor.ps1`은 aggregator, Cursor adapter 3개, 실제 local plugin 복사본, 다른 Agent의 managed block이 현재 canonical source와 일치하는지 검증합니다.
