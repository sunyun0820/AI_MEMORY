# Shared Rules

이 디렉터리는 모든 개발 Agent에 공통으로 적용할 안전·행동 규칙의 원본입니다.

## Canonical sources

- `db-safety.md`
- `git-safety.md`
- `engineering-principles.md`

위 세 파일만 직접 수정합니다.

`RULES.md`는 위 세 파일을 정해진 순서로 합친 **배포용 aggregator**이며 `setup.ps1`이 자동으로 재생성합니다. 직접 수정하지 않습니다.

## 적용 흐름

```text
rules/*.md
   ↓
rules/RULES.md
   ↓
instructions/GLOBAL_AGENT_INSTRUCTIONS.md 와 결합
   ↓
setup.ps1
   ├─ Codex       → ~/.codex/AGENTS.md
   ├─ Cursor      → ~/.cursor/rules/ai-memory.mdc
   ├─ Claude Code → ~/.claude/CLAUDE.md
   └─ Gemini / Antigravity → ~/.gemini/GEMINI.md
```

기존 Agent별 사용자 지침은 유지하고 `AI_MEMORY_MANAGED_START/END` 블록만 추가·갱신합니다.

## 변경 방법

1. canonical rule 파일 중 필요한 파일을 수정합니다.
2. `setup.ps1`을 실행해 `RULES.md`와 Agent별 전역 지침을 동기화합니다.
3. `doctor.ps1`을 실행해 aggregator와 Agent별 배포 내용이 원본과 일치하는지 검증합니다.

`doctor.ps1`은 단순히 파일 존재 여부만 확인하지 않고, 실제 관리 블록의 내용이 현재 AI_MEMORY 원본과 동일한지까지 검증합니다.
