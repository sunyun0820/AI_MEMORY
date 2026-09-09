# Refine Reference

Refine은 **이미 AI_MEMORY에 저장되어 있는 Memory 저장소 자체를 현재 품질 기준으로 정제하는 유지보수 모드**입니다.

권장 호출:

```text
agent_memory refine
```

`agent-memory refine`, `메모리 전체 정제해`, `기존 메모리 리파인해` 같은 명확한 요청도 동일하게 처리합니다.

## 범위

Refine은 Memory가 만들어진 경로를 구분하지 않습니다.

- Remember/Learn으로 저장된 Memory
- Backfill로 저장된 Memory
- 과거 수동으로 작성된 Memory
- `memory/rules/`
- `memory/lessons/`
- `memory/incidents/`
- `memory/projects/<project>/`

즉 **현재 active Memory 전체가 기본 대상**입니다.

`memory/archive/`는 기본 정제 대상에서 제외하고, 중복/충돌 확인에 필요한 경우에만 참고합니다. Archive를 자동으로 active로 복원하지 않습니다.

Refine은 현재 대화 세션을 채굴하는 Backfill과 다릅니다.

```text
Backfill = 대화/작업 세션 → 새 Memory 후보 추출
Refine   = 기존 Memory 저장소 → 품질 재평가/정제
```

## 목표

Refine의 목적은 Memory 수를 늘리는 것이 아닙니다.

다음 Agent가 더 적은 탐색과 시행착오로 정확하게 판단하도록 **신호 대비 잡음 비율을 높이는 것**이 목적입니다.

특히 다음 문제를 교정합니다.

- 구현 요약/변경 이력이 Memory의 중심이 된 경우
- 같은 내용을 project/lesson/incident에 중복 저장한 경우
- 특정 프로젝트 사례에서 공용 Lesson을 뽑지 못한 경우
- 프로젝트 전용 구현/호환성 정책을 공용 Lesson 또는 `scope: global`로 과잉 승격한 경우
- 적용 범위나 예외가 없어 과잉 일반화 위험이 있는 경우
- 재발 방지/오판 방지 포인트가 빠진 경우
- 현재 코드와 충돌하거나 오래된 내용
- 너무 긴 설명 때문에 Recall 비용이 커진 경우
- 이미 더 강한 Memory가 있는데 약한 중복 Memory가 남아 있는 경우

## 정제 판정

각 Memory를 아래 중 하나로 분류합니다.

### KEEP

현재 품질 기준을 이미 충족합니다. 불필요한 문장 수정은 하지 않습니다.

### REFINE

핵심 지식은 가치가 있지만 구현 일지, 중복 설명, 불필요한 맥락이 많거나 적용 범위/재발 방지가 부족합니다.

- 핵심 지식 중심으로 압축
- 적용 조건/예외 보완
- Avoid / Recurrence Prevention 보완
- 검증 근거 명확화
- 잘못 넓어진 scope를 실제 근거 범위로 축소
- 일반 원칙과 프로젝트 구현 방법 분리

### GENERALIZE

특정 프로젝트/Incident에서 더 넓게 재사용할 수 있는 메커니즘이 확인됩니다.

- 원본의 프로젝트 고유 사실은 필요한 경우 유지
- 별도 공용 Lesson이 실제로 다른 미래 가치를 가질 때만 생성
- 프로젝트 이름만 제거한 복사본은 만들지 않음
- 일반화 범위를 증거보다 넓히지 않음
- 프로젝트 전용 전제를 제거해도 일반화된 명제가 그대로 성립할 때만 생성
- 로컬 성공 증거와 global 적용성 증거를 혼동하지 않음

### MERGE

동일하거나 사실상 같은 지식이 여러 파일에 존재합니다.

- 가장 강하고 검증된 Memory를 기준으로 병합
- 새로운 근거/적용범위/재발방지 정보만 보존
- occurrences/updated/last_seen 등 메타데이터를 합리적으로 갱신
- 병합 후 불필요한 중복 파일은 제거 또는 archive

### ARCHIVE

현재 active Memory로 유지할 가치가 낮습니다.

예:

- 단순 구현 완료 기록
- Git/current source에서 쉽게 복원되는 변경 요약
- 세션 진행상태
- 더 강한 Memory에 완전히 흡수된 중복
- 현재 상태와 충돌하고 더 이상 유효하지 않은 과거 지식

삭제보다 Archive가 추적 가치가 있을 때 `memory/archive/`로 이동합니다. 명백한 쓰레기/중복이며 보존 가치가 없을 때만 제거합니다.

### VERIFY

가치는 있어 보이지만 현재 근거로 확정하기 어렵습니다.

- 추측으로 보완하지 않음
- 강한 rule/lesson으로 승격하지 않음
- 가능한 경우 현재 소스/설정/테스트로 확인
- 확인할 수 없으면 유지하되 confidence/status/본문에 한계를 명확히 하거나, active 판단에 부적절하면 archive
- global 적용성이 불명확하면 scope를 확대하지 않고 검증 보류

## 과잉 일반화 차단 게이트

Refine에서 가장 먼저 잡아야 하는 오류 중 하나는 **프로젝트에서 성공한 구현을 곧바로 공용 원칙으로 승격하는 것**입니다.

모든 `scope: global` Memory와 모든 `GENERALIZE` 후보에 대해 아래 질문에 답합니다.

```text
1. 프로젝트명/클래스명/라우트명/버전/클라이언트 관례를 제거해도 핵심 명제가 그대로 성립하는가?
2. 현재 증거는 "이 프로젝트에서 이 구현이 동작했다"만 증명하는가,
   아니면 "일반화된 명제 자체"도 지지하는가?
3. 이 해결 방법이 현재 아키텍처나 호환성 정책 때문에 선택된 것은 아닌가?
4. 다른 프로젝트에 그대로 적용했을 때 기능 장애, 보안 회귀, 정합성 문제 가능성이 있는가?
5. 원칙과 구현 방법을 분리할 수 있는가?
6. 적용 조건과 예외를 한두 문장으로 명확히 적을 수 있는가?
```

판정 규칙:

- 1~4 중 하나라도 불명확하면 **새 global 승격 금지**.
- 기존 `scope: global`인데 위 게이트를 통과하지 못하면 `REFINE` 또는 `VERIFY` 대상으로 보고 실제 적용 범위로 축소합니다.
- 특정 프로젝트에서의 라이브 테스트/빌드 성공/취약점 차단 성공은 **프로젝트 사실의 강한 증거**이지, global 적용성의 자동 증거가 아닙니다.
- 일반 원칙은 global로 남기고 구체 구현 방법은 project로 분리할 수 있습니다.
- 일반화 여부가 애매하면 좁은 범위를 선택합니다. 나중에 더 강한 근거가 생기면 다시 승격할 수 있습니다.

### 판정 예시

```text
공용 원칙 후보:
민감한 자격 증명은 URL query string에 노출하지 않는다.

프로젝트 구현:
현재 로그인 폼에서는 특정 input의 name을 제거해 네이티브 GET 직렬화를 막는다.

판정:
- 공용 원칙은 근거가 충분하면 global lesson 가능
- name 제거는 현재 HTML/JS 전송 구조에 의존하므로 project 범위
```

```text
프로젝트 호환성 정책:
특정 클라이언트가 이전 인증 토큰을 남긴 상태로 재로그인하므로,
로그인 엔드포인트에서 일부 토큰 상태를 필터 단계에서 통과시킨다.

판정:
- 클라이언트/인증 흐름에 의존하는 project 계약
- 일반 인증/JWT 보안 원칙으로 승격 금지
```

## Refine 절차

1. `MEMORY_POLICY.md`를 읽습니다.
2. `INDEX.md`와 `memory/` 구조를 확인하고 active Memory 전체 목록을 만듭니다.
3. Memory의 생성 경로(Remember/Backfill/수동)는 품질 판정에 사용하지 않습니다.
4. 각 Memory에 Shared Memory Intelligence를 적용합니다:
   - Distill
   - Transfer
   - Prevent
   - Bound
   - Verify
   - Deduplicate
   - Compress
5. Memory마다 KEEP / REFINE / GENERALIZE / MERGE / ARCHIVE / VERIFY 중 하나를 판정합니다.
6. 우선 전체 판정표를 내부적으로 만든 뒤 수정합니다. 파일을 읽는 즉시 즉흥적으로 연쇄 수정하지 않습니다.
7. **모든 `scope: global` Memory와 GENERALIZE 후보에 과잉 일반화 차단 게이트를 적용합니다.** 기존 scope/type은 근거로 취급하지 않습니다.
8. project 전용 정책/구현과 일반 원칙이 한 파일에 섞여 있으면 분리 가능성을 검토합니다. 단, 같은 내용을 두 파일로 복제하지 않습니다.
9. cross-project/general Lesson 후보는 **메커니즘이 실제로 같은지** 확인합니다.
10. `rule`은 가장 보수적으로 다룹니다. 명시적 사용자/팀 지시, 소스 불변조건, 반복 검증 등 근거 없이 약화·확대·승격하지 않습니다.
11. project Memory는 프로젝트 고유 navigation/architecture/invariant 가치가 있으면 유지합니다. 단순 구현 구조 나열은 압축/정리합니다.
12. incident는 실제 실패 사례와 root cause가 future diagnosis에 가치가 있으면 유지합니다. 별도 Lesson이 있어도 구체 사례 자체가 진단 가치가 있으면 무조건 제거하지 않습니다.
13. 변경 후 `scripts/rebuild-index.ps1`로 `INDEX.md`를 재생성합니다.
14. 가능하면 `doctor.ps1` 또는 관련 구조 검증을 실행합니다.
15. 최종 보고는 짧게 수량과 핵심 변화만 제공합니다.

## 정제 우선순위

높은 가치:

1. 재발 방지 / 잘못된 가정 방지
2. 숨은 invariant / boundary / dependency
3. 검증된 root cause와 해결 메커니즘
4. 다른 작업에 전이 가능한 Lesson
5. 설계 의사결정의 이유와 폐기 조건
6. 검증/디버깅/운영 절차
7. 탐색 비용을 크게 줄이는 Source Navigation

낮은 가치:

1. 구현 완료 요약
2. 파일/클래스 변경 목록
3. 단순 빌드 성공
4. 일회성 상태
5. 소스/Git에서 즉시 복원 가능한 설명

## 안전 규칙

- Refine은 **명시적으로 호출할 때만** Memory를 수정합니다.
- 현재 프로젝트 소스는 검증을 위해 읽을 수 있지만 Refine의 목적은 프로젝트 구현 변경이 아닙니다.
- 검증되지 않은 내용을 일반화하지 않습니다.
- **좁은 범위의 정확한 Memory가 넓은 범위의 애매한 Memory보다 우선합니다.**
- 기존 Memory가 구체적이고 강한데 새 표현이 더 추상적이라는 이유만으로 덮어쓰지 않습니다.
- 공용화는 범위를 넓히는 작업이 아니라 **재사용 가능한 메커니즘과 적용 경계를 함께 추출하는 작업**입니다.
- 프로젝트 구현 선택을 일반 원칙으로 바꾸지 않습니다. 필요하면 원칙과 구현을 분리합니다.
- Memory 수를 줄이는 것 자체를 목표로 하지 않습니다. 미래 가치가 서로 다르면 project + incident + lesson이 함께 존재할 수 있습니다.
- `TOOL_CANDIDATES.md`는 Refine의 기본 대상이 아닙니다. Tool 후보 정리는 별도 작업으로 취급합니다.
- Refine 과정에서 새로운 Tool 아이디어가 떠올라도 자동 구현하거나 backlog를 억지로 변경하지 않습니다.

## 전체 규모가 클 때

Memory가 많아 한 번에 안전하게 처리하기 어렵다면 임의로 일부만 처리하고 전체 완료라고 보고하지 않습니다.

다음처럼 배치로 나누고 진행 상태를 명시합니다.

```text
1. rules
2. lessons
3. incidents
4. projects/<project> 단위
5. cross-category dedup/generalization
6. global-scope 재검증
7. INDEX 재생성 및 최종 검증
```

사용자가 `전체 refine`을 요청했다면 모든 배치가 끝나야 전체 완료입니다.

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
- global scope 축소: N
- 신규 공용 Lesson: N
- INDEX 재생성: 완료/미완료
- 검증: PASS / PASS_WITH_WARNINGS / 미실행
```

길게 각 Memory 구현 내용을 다시 요약하지 않습니다.
