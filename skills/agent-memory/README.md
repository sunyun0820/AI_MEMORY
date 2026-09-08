# agent-memory 사용법

`agent-memory`는 AI_MEMORY의 장기 엔지니어링 기억을 조회/저장/회고/정제하는 공용 Skill입니다.

핵심 목적은 구현 이력을 보관하는 것이 아니라 **과거 경험을 일반화하고, 다음 작업에서 같은 실수와 탐색 낭비를 줄이는 것**입니다.

## 기본 호출

권장 호출은 아래 네 가지입니다.

```text
agent_memory recall
agent_memory remember
agent_memory backfill
agent_memory refine
```

`agent-memory`처럼 하이픈으로 적어도 됩니다. Agent가 자연어 호출을 인식하는 경우에는 `이거 기억해`, `이 세션 백필해`, `기존 메모리 전체 정제해`처럼 말해도 됩니다.

## 차이

| 모드 | 목적 | 저장/수정 | 사용 시점 |
|---|---|---:|---|
| `recall` | 현재 작업에 적용 가능한 과거 규칙/교훈/실패 방지 지식 조회 | X | 비단순 작업 전, 보통 자동 |
| `remember` / `learn` | 지금 확인된 지식을 재사용 가능한 형태로 정제해 저장 | O | 작업 도중 필요한 시점 |
| `backfill` | 현재 세션 전체를 회고해 놓친 재사용 지식 복구 + Tool 후보/개선사항 누적 | O | 작업 완료 후 또는 과거 세션 정리 |
| `refine` | 이미 저장된 active Memory 전체를 새 품질 기준으로 재평가/정제 | O | 기존 Memory 품질 정리, 구조 개편 후 |

## 네 모드의 공통 판단

Recall / Remember / Backfill / Refine은 같은 기준을 사용합니다.

```text
단순 구현 이력인가?
→ 미래에 재사용 가능한가?
→ 다른 모듈/프로젝트에도 적용 가능한가?
→ 어떤 실수/오판을 재발 방지할 수 있는가?
→ 언제 적용되고 언제 적용하면 안 되는가?
→ 검증된 내용인가?
→ 기존 Memory와 중복되는가?
→ 더 짧게 압축할 수 있는가?
```

구현 완료, 변경 파일 목록, 진행 상태는 기본적으로 장기 Memory 가치가 낮습니다.

반대로 아래는 우선순위가 높습니다.

- 재발 방지 가치가 있는 실패/오판/잘못된 가정
- 확인하기 어려웠던 Root Cause와 검증된 해결
- 숨은 불변조건, 위험한 경계, 데이터 정합성 규칙
- 설계 선택 이유와 폐기한 대안
- 검증된 디버깅/빌드/배포/DB/마이그레이션 절차
- 현재 사례에서 다른 곳에도 쓸 수 있게 일반화한 Lesson
- 탐색 비용을 크게 줄이는 중요한 Source Navigation 지식

## Remember

현재 작업 중 중요한 지식을 확정했다면:

```text
agent_memory remember
```

Remember는 현재 내용을 그대로 저장하지 않고 먼저 **공용화 가능성**을 확인합니다.

예를 들어 특정 프로젝트의 수량 UPDATE 오류에서:

```text
프로젝트 전용 지식
- 실제 파일/메서드와 구체적인 Root Cause

공용 Lesson
- 기존 수량성 데이터 UPDATE 시 집계값이 전체 new 값이 아니라 delta(new-old)를 반영하는지 확인
```

처럼 분리할 수 있습니다.

둘 다 저장하는 것은 서로 다른 미래 가치가 있을 때만 허용합니다. 같은 내용을 문장만 바꿔 중복 저장하지 않습니다.

Memory는 가능하면 아래 정도만 알 수 있게 짧게 유지합니다.

```text
무슨 지식인가?
왜 중요한가?
언제 적용하는가?
무엇을 피하거나 확인해야 하는가?
무엇으로 검증했는가?
```

## Recall

Recall은 단순히 현재 작업과 이름이 같은 Memory만 검색하지 않습니다.

현재 작업의 `operation`, `state transition`, `invariant`, `failure class`, `architecture pattern`을 같이 보고 다른 프로젝트에서 나온 공용 Lesson도 메커니즘이 같으면 적용 가능성을 확인합니다.

Recall의 목표는 **과거를 보여주는 것**이 아니라, 현재 작업에서 과거의 실수와 오판을 반복하지 않도록 사전 검토하는 것입니다.

## Backfill

과거 작업 세션을 다시 열어 아래처럼 한 줄만 입력하면 됩니다.

```text
agent_memory backfill
```

Backfill은 구현 목록부터 만들지 않습니다. 우선 아래를 찾습니다.

- 잘못된 수정, 잘못된 가정, 시행착오와 재발 방지 규칙
- 기존 프로젝트의 중요한 로직, 불변조건, 경계, 의존성
- 설계 결정과 버린 방식 및 이유
- 검증/디버깅/빌드/배포/DB/마이그레이션 노하우
- 다른 작업에도 적용 가능한 공용 Lesson
- 재사용 가능한 작업 절차와 체크리스트
- 지속적인 미해결 위험/기술 부채
- 반복적이고 결정적인 작업의 신규 Tool 후보
- 이미 존재하는 Tool/Script의 버그, 기능 부족, 경로/출력 문제 같은 개선사항

다음 같은 단순 기록은 보통 저장하지 않습니다.

```text
API 구현
Entity 추가
Repository 수정
설정 변경
빌드 성공
```

이 내용에서 숨은 제약, 설계 이유, 재발 방지, Source Navigation 가치가 나오지 않으면 Git/소스에서 다시 확인할 수 있으므로 Memory로 남기지 않습니다.

## Refine

이미 저장된 Memory를 현재 품질 기준으로 한 번 정리하려면:

```text
agent_memory refine
```

Refine은 **Memory가 어디서 만들어졌는지 구분하지 않습니다.**

기본 대상:

```text
Remember로 저장된 Memory
Backfill로 저장된 Memory
과거 수동 작성 Memory
memory/rules/
memory/lessons/
memory/incidents/
memory/projects/<project>/
```

즉 현재 active Memory 전체가 대상입니다.

`memory/archive/`는 기본적으로 다시 쓰지 않고 중복/충돌 확인에 필요할 때만 참고합니다. `TOOL_CANDIDATES.md`도 Refine 기본 대상이 아닙니다.

각 Memory는 다음 중 하나로 판정합니다.

```text
KEEP       그대로 유지
REFINE     압축/적용범위/재발방지 보완
GENERALIZE 공용 Lesson 추출
MERGE      중복 병합
ARCHIVE    낮은 가치/오래된 내용 정리
VERIFY     검증 부족으로 보류 또는 확인
```

Backfill과 Refine의 차이는 명확합니다.

```text
Backfill = 대화/작업 세션을 채굴
Refine   = 이미 저장된 Memory 저장소를 정제
```

Refine은 파일 수를 줄이는 작업이 아니라 **Memory의 신호 대비 잡음과 미래 재사용성을 높이는 작업**입니다.

## Tool 후보 Backlog

Backfill에서 Tool 관련 후보가 발견되면 구현하지 않고 `TOOL_CANDIDATES.md`에 자동 누적합니다.

```text
new-tool    = 새 Tool로 만들 가치가 있는 반복/대량/결정적 작업
improvement = 기존 Tool/Script의 버그, 기능 부족, 안정성/사용성 문제
```

같거나 사실상 같은 후보는 새 항목을 만들지 않고 `occurrences`, `last_seen`, 관련 프로젝트와 새로운 근거를 병합합니다.

Refine은 기본적으로 Tool 후보 backlog를 정리하지 않습니다. Memory 정제와 Tool backlog 관리는 별도 책임으로 둡니다.

## 세부 문서

```text
SKILL.md
references/backfill.md
references/refine.md
../../MEMORY_POLICY.md
../../TOOL_CANDIDATES.md
../../templates/MEMORY_TEMPLATE.md
../../templates/TOOL_CANDIDATE_TEMPLATE.md
```

## 과거 세션 정리 권장 방식

AI_MEMORY 도입 전에 진행했던 주요 세션은 `agent_memory backfill`로 회수하고, 여러 세션의 Backfill/Remember가 어느 정도 쌓였거나 품질 기준을 크게 바꾼 시점에는 `agent_memory refine`으로 전체 active Memory를 한 번 정제합니다.

단순 문법 질문, 한 줄 명령 확인, 구현 내용만 있고 장기 지식과 자동화 후보가 거의 없는 세션은 굳이 Backfill할 필요가 없습니다.
