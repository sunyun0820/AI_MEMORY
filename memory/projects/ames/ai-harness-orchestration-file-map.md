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
updated: 2026-09-08
last_seen: 2026-09-08
occurrences: 1
source_agent: codex
---

# AMES THiRA MES 마이그레이션 AI 하네스의 역할과 파일 경계

## Context

`E:\2.ISSUE\AMES\thira-mes-linux-ver-271`에서 RHEL 9/.NET 10 마이그레이션 작업을 위한 AI 하네스를 조사하고, 초보자용 HTML 교재를 만들었다. 저장소는 작업 담당자와 독립 검사자를 분리하고, 지휘 절차가 두 역할의 순서를 조율하는 구조를 문서와 파일로 정의한다.

## Verified Structure

- 작업 담당(Generator)은 `.claude/agents/migrator.md`와 `.codex/agents/migrator.toml`에 정의된다. 하나의 TASK만 맡고, 허용 범위의 파일을 수정하며, `Verify`까지만 올린다.
- 독립 검사자(Evaluator)는 `.claude/agents/verifier.md`와 `.codex/agents/verifier.toml`에 정의된다. 작업자의 구현 컨텍스트를 넘겨받지 않고 V1 빌드, V2 public API diff, V3 TASK 테스트를 실제 실행해 PASS/FAIL/보류를 보고한다.
- 지휘 순서는 `.claude/commands/task-cycle.md`와 `.agents/skills/thira-task-harness/references/commands.md`에 정의된다. 시작 게이트 확인 → migrator → `Verify` 확인 → 별도 verifier → 결과 처리 순서다.
- 병렬 분해 절차는 `.claude/commands/task-parallel.md`와 같은 Codex references에 정의된다. `docs/STATUS.md`가 독립 작업과 선행 의존 관계의 기준이다. 폴더가 다르다는 이유만으로 임의 병렬화하지 않는다.
- 작업 계약·상태·증거는 `docs/tasks/TASK-XXX-*.md`와 `docs/STATUS.md`에, 문제와 재검증 기록은 `docs/verification/ISSUES.md`에 남는다. `docs/adr/ADR-008-agent-harness.md`는 이 구조의 설계 배경을 설명한다.

## Reusable Rule

이 프로젝트에서 멀티에이전트는 여러 AI가 역할을 나눠 참여하는 구조이고, 오케스트레이션은 지휘 절차가 역할·순서·실패 처리를 조율하는 구조다. `migrator`와 `verifier` 파일만 존재한다고 실제 서브에이전트 실행이 증명되는 것은 아니며, 현재 도구가 역할 파일을 읽고 별도 세션/worktree를 생성했는지와 실제 로그를 확인해야 한다.

## Durable Risks / Boundaries

- 같은 저장소에는 Claude용 `.claude/` 절차와 Codex용 `.codex/`·`.agents/skills/` 절차가 함께 있어 설명과 상태 전환 규칙이 완전히 동일하다고 가정하지 않는다.
- 현재 확인한 파일에서 Claude `settings.json`의 `hooks` 객체는 비어 있고, `.codex/hooks.json`은 다른 절대 경로의 PowerShell 훅을 가리킨다. guard 스크립트가 존재한다는 사실만으로 현 위치에서 자동 차단이 활성화됐다고 보고하지 않는다.
- `docs/STATUS.md`의 실제 선후 관계가 오래된 병렬 명령 예시보다 우선한다. 과거 기록의 PASS/Verified는 재실행 결과가 아니므로 현재 환경의 빌드·테스트·DB·운영 증거로 재사용하지 않는다.

## Verification

관련 저장소의 `AGENTS.md`, `CLAUDE.md`, `README.md`, 역할·명령·스킬 파일, `ADR-008`, `STATUS.md`, TASK/ISSUES 기록을 읽어 파일 간 역할과 상태 처리 규칙을 대조했다. 이번 세션에는 마이그레이션, 빌드, 테스트, DB 접속, Git 변경, 훅 실행을 수행하지 않았다. 관련 문서와 실제 실행 결과가 충돌하면 현재 코드·설정·로그를 우선한다.

## Refine Verification Boundary

2026-09-08 전체 정제에서 위 원본 저장소 경로는 현재 머신에서 확인되지 않았다. 파일 구조와 hooks 상태는 원본 조사 당시의 관찰이며 현재 설치·실행 상태로 단정하지 않는다. AMES 작업을 재개하면 실제 checkout의 역할·명령·상태 문서와 hooks 경로를 다시 대조한다. 초보자용 교재 제작 사실은 구조의 실행 증거가 아니다.
