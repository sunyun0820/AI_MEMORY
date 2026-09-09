# Refine Reference

Refine은 **이미 AI_MEMORY에 저장되어 있는 Memory 저장소 자체를 현재 품질 기준으로 정제하는 유지보수 모드**입니다.

권장 호출:

```text
agent_memory refine
```

`agent-memory refine`, `메모리 전체 정제해`, `기존 메모리 리파인해` 같은 명확한 요청도 동일하게 처리합니다.

## 범위

Refine의 기본 대상은 현재 active Memory 전체입니다.

```text
memory/rules/
memory/lessons/
memory/incidents/
memory/projects/<project>/
```

Memory가 Remember, Backfill, 수동 작성 중 어디에서 만들어졌는지는 품질 판정 기준이 아닙니다.

`memory/archive/`는 기본 정제 대상에서 제외하고, Memory끼리의 중복/충돌 이력을 확인할 때만 참고합니다. `TOOL_CANDIDATES.md`도 Refine 기본 대상이 아닙니다.

Refine은 Backfill과 다릅니다.

```text
Backfill = 현재 대화/작업 세션 → 놓친 Memory 추출
Refine   = 기존 AI_MEMORY 저장소 → Memory 자체 품질 개선
```

## 가장 중요한 경계: Refine은 Source Audit이 아니다

Refine은 **source-blind maintenance**가 기본입니다.

일반 `agent_memory refine` 중에는 다음을 하지 않습니다.

- AI_MEMORY 밖의 프로젝트 저장소를 찾거나 열기
- 현재 PC의 프로젝트 Source 존재 여부 조사
- 파일/모듈/구현체 개수 세기
- 현재 구현과 과거 Memory를 일괄 대조
- 빌드, 실행, DB 접속, 로그 수집 등 별도 프로젝트 검증 작업
- Source가 없다는 이유로 `confidence`, `scope`, `status` 변경
- Source가 없다는 이유로 `VERIFY`, `ARCHIVE`, `REFINE` 판정
- `소스 미확보`, `현재 소스 확인 필요`, `원본 프로젝트 부재` 같은 문구를 Memory에 추가

Refine의 판단 재료는 **Memory 자체**입니다.

- 본문
- metadata
- 적용 범위
- 기록된 검증/근거
- occurrences / last_seen / updated
- 다른 active Memory
- archive에 남은 Memory 이력
- 명시적으로 기록된 사용자/팀 수정

프로젝트 Source가 현재 없어도, `C-MOS 3.5.2에서 확인된 구조`처럼 시점/버전 경계가 분명한 지식은 정상적인 project Memory입니다.

사용자가 별도로 `현재 Source와 대조해서 검증해`라고 명시한 경우에만 Source fact-check를 별도 작업으로 수행할 수 있습니다. 그 작업은 기본 Refine이 아닙니다.

## 목표

Refine의 목적은 파일 수를 줄이는 것이 아니라 **신호 대비 잡음, 재사용성, 재발 방지 가치, 적용 정확도**를 높이는 것입니다.

특히 다음 문제를 교정합니다.

- 구현 요약/변경 이력이 Memory의 중심이 된 경우
- 같은 내용을 project/lesson/incident에 중복 저장한 경우
- 특정 프로젝트 사례에서 공용 Lesson을 뽑지 못한 경우
- 프로젝트 전용 구현/호환성 정책을 global Lesson으로 과잉 승격한 경우
- 적용 범위나 예외가 없어 다른 환경에서 오용될 위험이 있는 경우
- 재발 방지/오판 방지 포인트가 빠진 경우
- Memory끼리 서로 상충하거나 같은 지식을 다른 강도로 표현한 경우
- 너무 긴 설명 때문에 Recall 비용이 커진 경우
- 더 강한 Memory가 있는데 약한 중복 Memory가 남아 있는 경우

`현재 Source와 다르다`는 것은 Refine의 자동 검사 항목이 아닙니다. 현재 Source와의 사실 확인은 실제 작업/Recall 이후 단계의 책임입니다.

## 정제 판정

각 Memory를 아래 중 하나로 분류합니다.

### KEEP

현재 품질 기준을 이미 충족합니다. 불필요한 문장 수정은 하지 않습니다.

### REFINE

핵심 지식은 가치가 있지만 다음 보완이 필요합니다.

- 핵심 지식 중심으로 압축
- 적용 조건/예외 보완
- Avoid / Recurrence Prevention 보완
- 기록된 근거를 이해하기 쉽게 정리
- 잘못 넓어진 scope를 Memory 자체의 내용에 맞게 축소
- 일반 원칙과 프로젝트 구현 방법 분리
- 버전/시점 경계를 명확히 하여 현재 사실처럼 오해되지 않게 수정

### GENERALIZE

특정 프로젝트/Incident에서 더 넓게 재사용할 수 있는 메커니즘이 확인됩니다.

- 원본의 프로젝트 고유 사실은 필요한 경우 유지
- 별도 공용 Lesson이 실제로 다른 미래 가치를 가질 때만 생성
- 프로젝트 이름만 제거한 복사본은 만들지 않음
- 일반화 범위를 기록된 근거보다 넓히지 않음
- 프로젝트 전용 전제를 제거해도 일반화된 명제가 성립할 때만 생성

### MERGE

동일하거나 사실상 같은 지식이 여러 파일에 존재합니다.

- 미래 가치가 가장 높은 Memory를 기준으로 병합
- 새 근거/적용범위/재발방지 정보만 보존
- occurrences/updated/last_seen 등 메타데이터를 합리적으로 갱신
- project/incident/lesson이 서로 다른 미래 가치를 가지면 억지로 합치지 않음

### ARCHIVE

현재 active Memory로 유지할 가치가 낮습니다.

예:

- 단순 구현 완료 기록
- 세션 진행상태
- 미래 판단 가치가 거의 없는 변경 목록
- 더 강한 Memory에 완전히 흡수된 중복
- 명시적 사용자 수정이나 더 최신 Memory에 의해 대체된 과거 내용

Source를 현재 확인할 수 없다는 이유만으로 Archive하지 않습니다.

### VERIFY

`VERIFY`는 **Memory 자체가 불확실한 경우**입니다.

예:

- 원래부터 추정/가설로 기록되어 있음
- 같은 사실에 대해 active Memory끼리 직접 충돌함
- metadata와 본문이 서로 모순됨
- Memory 내부에 기록된 근거가 서로 다른 결론을 가리킴

다음은 VERIFY 사유가 아닙니다.

```text
현재 PC에 project source가 없음
source path를 모름
원본 repository를 clone하지 않음
구현 파일을 지금 열 수 없음
DB/실행환경에 접근할 수 없음
```

VERIFY로 남길 때도 `소스 미확보` 같은 표현을 추가하지 않습니다. Memory 자체의 불확실한 주장만 설명합니다.

## 과잉 일반화 차단 게이트

Refine에서 중요한 오류 중 하나는 **프로젝트에서 성공한 구현을 공용 원칙으로 승격하는 것**입니다.

모든 `scope: global` Memory와 GENERALIZE 후보에 대해 아래 질문에 답합니다.

```text
1. 프로젝트명/클래스명/라우트명/버전/클라이언트 관례를 제거해도 핵심 명제가 성립하는가?
2. Memory에 기록된 근거는 특정 프로젝트에서의 성공만 말하는가,
   아니면 일반화된 메커니즘도 설명하는가?
3. 해결 방법이 현재 아키텍처나 호환성 정책 때문에 선택된 것은 아닌가?
4. 다른 프로젝트에 그대로 적용했을 때 기능 장애, 보안 회귀, 정합성 문제 가능성이 있는가?
5. 일반 원칙과 프로젝트 구현 방법을 분리할 수 있는가?
6. 적용 조건과 예외를 한두 문장으로 명확히 적을 수 있는가?
```

판정 규칙:

- 1~4 중 하나라도 불명확하면 새 global 승격 금지
- 기존 global이 게이트를 통과하지 못하면 실제 적용 범위에 맞게 REFINE
- 일반화 여부가 애매하면 좁은 범위를 선택
- 이를 해결하려고 외부 Source를 찾지 않음

### 예시 1

```text
공용 원칙:
민감한 자격 증명은 URL query string에 노출하지 않는다.

프로젝트 구현:
특정 로그인 폼에서는 input name 제거로 네이티브 GET 직렬화를 막았다.

판정:
- 공용 원칙은 global lesson 가능
- name 제거는 해당 폼/JS 전송 계약에 의존하므로 project 범위
```

### 예시 2

```text
프로젝트 호환성 정책:
특정 클라이언트가 이전 인증 토큰을 남긴 상태로 재로그인하므로
로그인 엔드포인트에서 일부 토큰 상태를 필터 단계에서 통과시킨다.

판정:
- 해당 인증 흐름의 project 계약
- 일반 JWT 보안 원칙으로 승격 금지
```

## Refine 절차

1. `MEMORY_POLICY.md`를 읽습니다.
2. `INDEX.md`와 `memory/` 구조를 확인하고 active Memory 전체 목록을 만듭니다.
3. **AI_MEMORY 밖의 프로젝트 Source는 탐색하지 않습니다.**
4. 각 Memory에 다음을 적용합니다:
   - Distill
   - Transfer
   - Prevent
   - Bound
   - Evidence
   - Deduplicate
   - Compress
5. Memory마다 KEEP / REFINE / GENERALIZE / MERGE / ARCHIVE / VERIFY 중 하나를 판정합니다.
6. 전체 판정표를 내부적으로 만든 뒤 수정합니다. 파일을 읽는 즉시 즉흥적으로 연쇄 수정하지 않습니다.
7. 모든 `scope: global` Memory와 GENERALIZE 후보에 과잉 일반화 차단 게이트를 적용합니다.
8. project 전용 정책/구현과 일반 원칙이 한 파일에 섞여 있으면 분리 가능성을 검토합니다.
9. cross-project Lesson은 메커니즘과 적용 경계가 실제로 같은지 Memory 내용 기준으로 판단합니다.
10. `rule`은 가장 보수적으로 다룹니다.
11. project Memory는 프로젝트 고유 navigation/architecture/invariant/versioned knowledge가 미래 가치가 있으면 유지합니다.
12. incident는 실제 실패 사례와 root cause가 future diagnosis에 가치가 있으면 유지합니다.
13. Memory 내부의 직접 충돌만 `VERIFY` 후보로 취급합니다. Source 부재는 무시합니다.
14. 변경 후 `scripts/rebuild-index.ps1`로 `INDEX.md`를 재생성합니다.
15. 가능하면 `doctor.ps1`로 **AI_MEMORY 구조만** 검증합니다.
16. 최종 보고는 수량과 핵심 품질 변화만 제공합니다.

## 정제 우선순위

높은 가치:

1. 재발 방지 / 잘못된 가정 방지
2. 숨은 invariant / boundary / dependency
3. 기록된 root cause와 해결 메커니즘
4. 다른 작업에 전이 가능한 Lesson
5. 설계 의사결정의 이유와 폐기 조건
6. 검증/디버깅/운영 절차
7. 탐색 비용을 크게 줄이는 Source Navigation / 버전 구조 지식

낮은 가치:

1. 구현 완료 요약
2. 파일/클래스 변경 목록
3. 단순 빌드 성공 기록
4. 일회성 상태
5. 미래 판단에 추가 가치를 주지 않는 단순 변경 설명

낮은 가치 판단을 위해 현재 Source를 직접 확인하지 않습니다.

## 안전 규칙

- Refine은 명시적으로 호출할 때만 Memory를 수정합니다.
- Refine은 Memory 유지보수이며 project-source 구현/감사 작업이 아닙니다.
- Refine 중 AI_MEMORY 밖의 Source 탐색을 시작하지 않습니다.
- Source 부재를 Memory 품질 결함으로 취급하지 않습니다.
- 검증되지 않은 내용을 일반화하지 않습니다.
- 좁은 범위의 정확한 Memory가 넓은 범위의 애매한 Memory보다 우선합니다.
- 기존 Memory가 구체적이고 강한데 새 표현이 더 추상적이라는 이유만으로 덮어쓰지 않습니다.
- 공용화는 범위를 넓히는 작업이 아니라 재사용 가능한 메커니즘과 적용 경계를 함께 추출하는 작업입니다.
- 프로젝트 구현 선택을 일반 원칙으로 바꾸지 않습니다.
- Memory 수를 줄이는 것 자체를 목표로 하지 않습니다.
- `TOOL_CANDIDATES.md`는 Refine 기본 대상이 아닙니다.
- Refine 과정에서 Tool 아이디어가 떠올라도 자동 구현하거나 backlog를 억지로 변경하지 않습니다.

## 전체 규모가 클 때

Memory가 많아 한 번에 안전하게 처리하기 어렵다면 임의로 일부만 처리하고 전체 완료라고 보고하지 않습니다.

```text
1. rules
2. lessons
3. incidents
4. projects/<project> 단위
5. cross-category dedup/generalization
6. INDEX 재생성 및 doctor
```

사용자가 전체 Refine을 요청했다면 모든 배치가 끝나야 전체 완료입니다.

## 최종 보고 형식

```text
Refine 결과
- 전체 검토: N
- KEEP: N
- REFINE: N
- GENERALIZE: N
- MERGE: N
- ARCHIVE/REMOVE: N
- VERIFY/보류: N
- 신규 공용 Lesson: N
- INDEX 재생성: 완료/미완료
- doctor: PASS / PASS_WITH_WARNINGS / 미실행
- 프로젝트 Source Audit: 수행하지 않음
```
