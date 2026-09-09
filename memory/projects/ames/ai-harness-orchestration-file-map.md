---
id: MEM-20260908-ames-ai-harness
type: project
scope: project
project: AMES
domain: ai-harness
tags: [AMES, THiRA-MES, multi-agent, orchestration, migrator, verifier, worktree, task-harness]
status: active
confidence: high
created: 2026-09-08
updated: 2026-09-10
last_seen: 2026-09-08
occurrences: 1
source_agent: codex
---

# AMES THiRA MES 마이그레이션 AI 하네스의 역할과 파일 경계

## Core Knowledge

2026-09-08 조사한 `thira-mes-linux-ver-271`의 RHEL 9/.NET 10 마이그레이션 하네스는 작업 담당자와 독립 검사자를 분리한다. 역할 파일, 실행 순서를 조율하는 절차, 작업 상태·검증 증거는 각각 다른 책임을 갖는다.

## Roles / Navigation

| 책임 | 저장소 상대 경로 | 계약 |
|---|---|---|
| Generator | `.claude/agents/migrator.md`, `.codex/agents/migrator.toml` | 한 TASK의 허용 파일만 수정하고 `Verify`까지 올림 |
| Evaluator | `.claude/agents/verifier.md`, `.codex/agents/verifier.toml` | 작업자의 구현 컨텍스트를 받지 않고 V1 빌드·V2 public API diff·V3 TASK 테스트를 실행해 PASS/FAIL/보류 보고 |
| 순서 조율 | `.claude/commands/task-cycle.md`, `.agents/skills/thira-task-harness/references/commands.md` | 시작 게이트 → migrator → Verify 확인 → 별도 verifier → 결과 처리 |
| 병렬 분해 | `.claude/commands/task-parallel.md`, 위 Codex references | `docs/STATUS.md`의 독립 작업·선행 의존 관계를 따름 |
| 계약·증거 | `docs/tasks/TASK-XXX-*.md`, `docs/STATUS.md`, `docs/verification/ISSUES.md` | 작업 범위·상태와 문제·재검증 결과 보존 |
| 설계 배경 | `docs/adr/ADR-008-agent-harness.md` | 역할 분리와 오케스트레이션의 이유 |

## Applicability / Recurrence Prevention

- 이 조사본의 Claude용 절차와 Codex용 절차가 완전히 같다고 가정하지 않는다. 해당 작업의 역할·명령·상태 전환 계약을 함께 따른다.
- 폴더가 다르다는 이유만으로 병렬화하지 않는다. 실제 선후 관계가 오래된 병렬 명령 예시보다 우선한다.
- 역할 파일의 존재는 별도 에이전트 실행 증거가 아니다. 실제 세션/worktree 생성과 실행 로그를 구분한다.
- 조사 당시 Claude `settings.json`의 `hooks`는 비어 있었고 `.codex/hooks.json`은 다른 절대 경로의 PowerShell 훅을 가리켰다. guard 파일의 존재만으로 자동 차단 활성화를 주장하지 않는다.

## Evidence

2026-09-08 `AGENTS.md`, `CLAUDE.md`, `README.md`, 역할·명령·스킬 파일, ADR-008, STATUS, TASK/ISSUES 기록을 대조한 정적 조사다. 과거 PASS/Verified 표시는 기록된 실행에만 해당하며, 이 구조 조사 자체는 빌드·테스트·훅 실행 결과가 아니다.
