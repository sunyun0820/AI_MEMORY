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

# 관계/권한(Relation) 데이터 동기화 시 전체 삭제/재등록 대신 Set 기반 diff로 변경분만 처리

## Context

MES 기준정보(CDS)에서 사용자 그룹별 메뉴 권한(`Userclassmenurel`) 및 메뉴별 버튼 권한(`Userclassobjectrel`)을 저장하는 서비스(`MD_UserClassMenuRelSave.java`)를 구현/리팩토링하는 상황.
한 권한에 접근 가능한 메뉴는 수백 개에 달하며, 수신된 메뉴 목록에 맞춰 기존 권한을 갱신해야 한다.

## Symptom

1. **전체 삭제 후 전체 등록(Delete All + Insert All) 방식의 문제**:
   기존 권한이 300개이고 수신된 메뉴가 200개(100개 유지, 100개 삭제, 100개 신규 추가)일 때, 전체 삭제 후 전체 등록을 수행하면 불필요하게 300건 DELETE + 200건 INSERT(총 500건)의 DB I/O가 발생한다.
   이로 인해 DB 트랜잭션 락(Lock) 경합, Undo/Redo 로그 폭증, 불필요한 성능 저하가 발생한다.
2. **List 중첩 루프(Nested Loop) 방식의 문제**:
   기존 리스트와 수신 리스트를 중첩 순회(`where`, O(N×M))하며 건별 비교할 경우, 메뉴 건수가 늘어남에 따라 수만 회의 비교 연산으로 CPU 병목이 발생한다.
3. **특정 DBMS 종속 쿼리 사용**:
   삭제된 메뉴의 버튼 권한을 삭제하기 위해 MSSQL 전용 함수(`STRING_SPLIT`)를 사용하는 XML 쿼리를 호출하여 Oracle, PostgreSQL 등 이종 DBMS 환경에서 런타임 장애 위험이 발생한다.

## Root Cause

관계 테이블 갱신 시 "전체 삭제 후 재등록"으로 단순화하여 DB I/O를 낭비하거나, 메모리 비교를 비효율적인 O(N×M) 루프로 작성함.
또한 다중 DBMS 환경을 고려하지 않고 특정 DB 전용 함수가 포함된 쿼리로 종속 데이터를 조회/삭제하려 함.

## Wrong Approach

- **전체 교체(Delete All -> Insert All)**: 구현은 간단하나 변경 없는 데이터까지 삭제/재등록되어 DB I/O가 수 배 증가함.
- **Nested Loop O(N×M)**: 컬렉션을 중첩 순회하며 매칭 여부를 검사하여 CPU 사이클을 낭비함.

## Correct Approach

1. **HashSet 기반 O(N+M) 차집합(diff) 계산**:
   - 수신 목록의 ID를 `Set<String>`(`requestedMenuIds`)으로 수집.
   - DB에 저장된 기존 목록의 ID를 `Set<String>`(`storedMenuIds`)으로 수집.
2. **삭제 대상 추출 및 벌크 삭제**:
   - `storedMenuList` 중 `requestedMenuIds`에 포함되지 않는 항목만 추출하여 `commonRepository.realDeleteBulk(removeList, true)` 수행.
3. **추가 대상 추출 및 벌크 등록**:
   - `requestedMenuList` 중 `storedMenuIds`에 포함되지 않는 항목만 추출하여 `commonRepository.createBulk(addList, true)` 수행.
4. **유지 대상**:
   - DB 변경 작업을 일체 수행하지 않음 (DB I/O 0건).
5. **종속 관계(버튼 권한 등) 정리**:
   - 삭제 대상 메뉴 ID 목록(`removedMenuIds`)에 대해서만 엔티티 조건 객체(`whereObj`)를 생성하여 조회 후 벌크 삭제.
   - 특정 DBMS 전용 함수(`STRING_SPLIT` 등)에 의존하는 MyBatis SQL을 사용하지 않고 엔티티 조건 조회를 활용해 이종 DBMS 호환성을 확보함.

## Reusable Rule

- 마스터-디테일 또는 관계(Relation) 데이터 동기화 시 "전체 삭제 후 재등록"을 지양하고, `Set` 기반 차집합(diff)을 통해 실제 변경분(삭제/추가)만 Bulk I/O로 처리하라.
- 하위 종속 데이터를 정리할 때는 특정 DBMS 전용 SQL 함수 대신 공용 엔티티 조건 조회를 활용하여 멀티 DBMS 호환성을 유지하라.

## Verification

`MD_UserClassMenuRelSave.java`에 반영 완료. 기존 300건/수신 200건(100유지, 100삭제, 100추가) 기준 DB I/O가 500건에서 200건으로 60% 감소하며, 비교 연산 복잡도가 O(N×M)에서 O(N+M)으로 개선됨을 확인.