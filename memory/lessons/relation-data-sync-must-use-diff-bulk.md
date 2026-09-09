---
id: MEM-20260908-155201
type: lesson
scope: global
project: mes-core
domain: cds
tags:
  - java
  - bulk-operation
  - relation-sync
  - diff
  - performance
status: active
confidence: high
created: 2026-09-08
updated: 2026-09-08
last_seen: 2026-09-08
occurrences: 1
source_agent: antigravity
---

# 관계 전체 목록 동기화는 완전한 키로 차집합을 계산할 것

## Core Knowledge

관계의 목표 전체 목록을 받는 동기화는 `삭제 = 기존 - 요청`, `추가 = 요청 - 기존`을 Set으로 계산하여 변경분만 반영할 수 있다. 멤버십 비교는 평균 O(N+M)이며 유지 행의 불필요한 삭제·재등록을 줄인다.

## Applicability

- 요청이 특정 소유자·테넌트·분류 범위의 **완전한 목표 목록**이어야 한다. patch 요청에서 누락을 삭제로 해석하지 않는다.
- 동일 ID가 다른 범위에 존재하면 복합키로 비교한다. 단일 ID만 쓸 때는 나머지 키가 고정됐음을 검증한다.
- 유지 행에 변경 가능한 속성이 있으면 별도 UPDATE diff가 필요하다. 빈 목록의 의미, 중복 입력, 동시 저장과 트랜잭션 경계도 확인한다.

## Avoid / Recurrence Prevention

삭제된 상위 관계의 종속 행만 같은 키 범위로 정리한다. bulk 메서드를 호출했다는 사실만으로 SQL 왕복이 1회이거나 모든 DBMS에서 동일하다고 단정하지 않는다. 이종 DBMS에서 SQL 함수·엔티티 조회 모두 실제 생성 쿼리를 확인한다.

예시로 기존 300건·요청 200건·공통 100건이면 삭제 200건·추가 100건이다. 본 관계 행의 쓰기 대상은 전체 교체 500건에서 diff 300건으로 40% 줄지만, 이는 산술 비교이며 조회·종속 행·이력·실제 SQL 실행 횟수나 성능 측정값은 아니다.

## Verification

2026-09-08 `cmos frame/core/.../userclassmenurel/MD_UserClassMenuRelSave.java`에서 HashSet 비교, create/realDeleteBulk, 종속 권한 조회를 정적 확인했다. 현재 예시는 MENUID만 비교하고 첫 요청의 MENUCLASSID로 범위를 정하므로 혼합 분류·빈 목록에 대한 일반적 안전성을 보장하지 않는다. 원본의 “300/200, 유지·삭제·추가 각 100, 60% 감소”는 집합 수량이 맞지 않아 교정했다. DB 실행·성능 측정은 하지 않았다.
