# agent-memory 사용법

`agent-memory`는 AI_MEMORY의 장기 엔지니어링 기억을 조회/저장/회고/정제하는 공용 Skill입니다.

핵심 목적은 구현 이력을 보관하거나 현재 Source를 복제하는 것이 아니라 **과거 경험을 참고 지식으로 남겨 다음 작업의 실수와 탐색 낭비를 줄이는 것**입니다.

## 기본 호출

```text
agent_memory recall
agent_memory remember
agent_memory backfill
agent_memory refine
```

`agent-memory`처럼 하이픈으로 적어도 됩니다. `이거 기억해`, `이 세션 백필해`, `기존 메모리 전체 정제해` 같은 자연어도 의도가 명확하면 동일하게 처리합니다.

## 네 모드의 차이

| 모드 | 목적 | Source와의 관계 |
|---|---|---|
| `recall` | 현재 작업에 적용 가능한 과거 규칙/교훈/실패 방지 지식 조회 | 실제 작업에서는 현재 Source가 최종 사실, Memory는 참고 |
| `remember` | 지금 확인된 지식을 재사용 가능한 형태로 저장 | 현재 작업에서 이미 본 Source/테스트는 근거로 사용 가능, 별도 Source Audit 금지 |
| `backfill` | 현재 세션을 회고해 놓친 재사용 지식 복구 | 세션/history가 입력, Source를 다시 찾아 검증하지 않음 |
| `refine` | 이미 저장된 active Memory 전체의 품질 정제 | **Memory repository만 대상. Source-blind가 기본** |

## 가장 중요한 원칙

```text
Memory ≠ Source
Memory ≠ Source Audit 결과
Memory = 미래 Agent를 위한 참고 지식
```

- Source가 없다고 Memory 가치가 떨어지지 않습니다.
- `소스 미확보`, `현재 소스 확인 필요` 같은 접근 상태를 Memory에 기록하지 않습니다.
- 특정 프레임워크/프로젝트의 구조는 `C-MOS 3.5.2에서 확인된 구조`처럼 버전/시점 경계를 두고 저장할 수 있습니다.
- 실제 개발할 때 Memory와 현재 코드가 충돌하면 현재 코드/설정/테스트가 우선합니다.

## 공통 판단 기준

```text
단순 구현 이력인가?
→ 미래에 재사용 가능한가?
→ 다른 모듈/프로젝트에도 적용 가능한가?
→ 어떤 실수/오판을 재발 방지할 수 있는가?
→ 언제 적용되고 언제 적용하면 안 되는가?
→ 이미 확보된 근거/경험이 있는가?
→ 기존 Memory와 중복되는가?
→ 더 짧게 압축할 수 있는가?
```

`근거가 있는가`는 **새 Source를 찾으라는 뜻이 아닙니다.** 현재 작업/세션/Memory에 이미 있는 근거를 사용합니다.

## Remember

현재 작업 중 중요한 지식을 확정했다면:

```text
agent_memory remember
```

Remember는 내용을 그대로 저장하지 않고 재사용성, 재발 방지, 적용 경계, 공용화 가능성을 먼저 판단합니다.

예:

```text
프로젝트 전용 지식
- 특정 버전/프로젝트에서 확인된 구조와 Root Cause

공용 Lesson
- 기존 수량성 데이터 UPDATE 시 집계값이 전체 new 값이 아니라 delta(new-old)를 반영하는지 확인
```

둘 다 저장하는 것은 서로 다른 미래 가치가 있을 때만 허용합니다.

## Recall

Recall은 이름이 같은 Memory만 찾지 않습니다. `operation`, `state transition`, `invariant`, `failure class`, `architecture pattern`을 함께 보고 유사한 Lesson을 찾습니다.

Recall된 Memory는 사전 검토 자료입니다. 실제 구현 세부를 판단할 때는 현재 작업의 코드/설정/테스트를 확인합니다.

## Backfill

```text
agent_memory backfill
```

Backfill은 현재 세션/history에서 다음을 찾습니다.

- 잘못된 수정, 잘못된 가정, 시행착오와 재발 방지 규칙
- 중요한 로직, 불변조건, 경계, 의존성
- 설계 결정과 버린 방식 및 이유
- 검증/디버깅/빌드/배포/DB/마이그레이션 노하우
- 다른 작업에도 적용 가능한 공용 Lesson
- 지속적인 미해결 위험/기술 부채
- Tool 후보/기존 Tool 개선사항

Backfill을 위해 프로젝트 Source를 다시 찾거나 파일을 재조사하지 않습니다. 세션에서 이미 얻은 사실만 사용합니다.

## Refine

```text
agent_memory refine
```

Refine은 현재 active Memory 전체를 품질 기준으로 재평가합니다.

```text
KEEP       그대로 유지
REFINE     압축/적용범위/재발방지 보완
GENERALIZE 공용 Lesson 추출
MERGE      중복 병합
ARCHIVE    낮은 가치/대체된 내용 정리
VERIFY     Memory 자체의 주장/근거가 불확실하거나 상충함
```

Refine은 **Source Audit이 아닙니다.**

```text
금지:
- project source 찾기
- 구현체/파일 개수 확인
- 현재 Source와 전체 Memory 대조
- Source가 없어서 confidence 하향
- Source가 없어서 VERIFY 처리
- Memory에 '소스 미확보' 문구 추가
```

`VERIFY`는 Memory 자체가 추정이거나 서로 충돌할 때만 사용합니다.

## Tool 후보 Backlog

Backfill에서 Tool 관련 후보가 발견되면 구현하지 않고 `TOOL_CANDIDATES.md`에 누적합니다.

```text
new-tool    = 새 Tool로 만들 가치가 있는 반복/대량/결정적 작업
improvement = 기존 Tool/Script의 버그, 기능 부족, 안정성/사용성 문제
```

Refine은 Tool 후보 backlog를 기본적으로 정리하지 않습니다.

## 세부 문서

```text
SKILL.md
references/backfill.md
references/refine.md
../../MEMORY_POLICY.md
../../TOOL_CANDIDATES.md
../../templates/MEMORY_TEMPLATE.md
```
