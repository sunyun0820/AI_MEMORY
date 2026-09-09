---
id: MEM-20260909-2nd-battery-extension-patterns-and-invariants
type: project
scope: project
project: 2nd-battery
domain: extension-contracts
tags: [cmos, block, validation, invariants, state, side-effects]
status: active
confidence: medium
created: 2026-09-09
updated: 2026-09-10
last_seen: 2026-09-09
occurrences: 1
source_agent: codex
---

# 2nd-battery 확장 시 유지할 입력·상태·업무 불변조건

## Core Knowledge / Applicability

2026-09-09 정적 조사에서 확인한 프로젝트 확장 조건이다. 코드가 검사하는 조건, 호출자가 지켜야 하지만 완전히 검사되지 않는 전제, 복사하면 안 되는 반례를 구분한다. 모듈 소유권은 [구조](project-architecture.md), 전체 호출은 [업무 흐름](runtime-and-business-flow.md), 경로·심볼은 [탐색 지도](source-navigation-map.md)를 따른다.

## Block·검증·목록 계약

- 조사한 Manager 인터페이스/구현은 BlockController/BlockModule 쌍이다. 공정별 동명 인터페이스는 별도 FQCN이며 공통 Manager로 위임한다. common 인터페이스로 import를 잘못 교체하지 않는다.
- 인접 `ClassInfo.getBlockModuleClass`는 후보가 여러 개면 version 내림차순으로 선택했다. Factory의 단일 구현 제한과 다른 계약이며, 같은 version 동률·프로젝트 resolved JAR의 선택 결과까지 보장하지 않는다. 당시 block.json 예시는 모두 주석이었다.
- `webDataMessage(...)`는 키 존재, process의 `entity.mandatory(...)`는 업무 값 검사로 사용됐다. 빈 값까지 보는 `webDataCheck`와 구분하고 키 검사만 남겨 값 검증을 제거하지 않는다.
- `getWebdataList(Lot.class,0,LOTLIST,...)`는 **WEBDATA[0].DATALIST.LOTLIST**를 읽는다. 첫 Equipment의 SITEID/EQUIPMENTID를 자식에 넣으므로 WEBDATA 직접 필드로 평탄화하거나 여러 header를 모두 처리한다고 가정하지 않는다. 품질은 별도 INSPREQLOTLIST를 사용한다.
- 첫 header·BOM의 첫 Product/Site·Track-In의 첫 Lot Batch/상태는 전체 목록의 동질성 검사가 아니다. 공용 적용 조건은 [첫 항목 기반 목록 검증](../../lessons/header-derived-batch-scope-validation.md)을 따른다.

## 저장·상태 변경

- RecipeItem은 ADD→UPDATE→DEL, ProductWorkOrderRel은 ADD→UPDATE→REALDEL 그룹을 처리한다. BOM은 첫 Product/Site 전체 교체와 BOMID 재생성이다. UI row-state, RequestType, 논리/물리 삭제를 하나의 SAVE 의미로 합치지 않는다.
- BOM은 전체 grid 계약이며 빈 목록은 Rule에서 return한다. dirty-row 전송, 혼합 범위, 전체 삭제, 재정렬 시 ID 변경을 구분한다. Hist=true와 size×2 기대 count의 결합은 [영속 계약](persistence-and-query-patterns.md)을 참조한다.
- Track-In은 DB 현재 Lot, 같은 node, WAITFORRULE·허용 상태, 설비-공정·첫 Batch, Recipe/SQC를 거쳐 Core startLot/trackInLot로 이어진다. wrapper가 짧다고 공통 검증이 없다고 판단하거나 상태 UPDATE로 치환하지 않는다.
- WorkOrder confirm은 Created 대상 재조회 → `checkStateTransition(model,current,target,site)` → common-data → PlanExtension.changeWorkOrderState다. UI state를 DB 현재 상태 대신 신뢰하지 않는다.

## Recipe·품질·ID의 고유 부수효과

- RECIPEDEFINITIONManager.saveRecipe는 동일 계열 최대 버전 검사, 기존 active 일부 hold, 선택 항목 active, ProcessDataParameter/TraceDataParameter INSERT를 포함한다. 새 버전은 Recipeparameter/Mbom 복사를 동반한다.
- holdRecipe가 첫 active만 처리하므로 DB에 active가 하나뿐이라고 입증하지 못한다. MSSQL 보관 INSERT는 SITEID를 WHERE에서 사용하지 않았으므로 모든 Recipe 작업이 사이트로 제한된다고 보지 않는다.
- IQC 요청은 활성 검사정의·자재 검증, 검사요청/대상 생성, 구매·자재 검사 관계를 연결한다. RequestInspection의 default는 작업하지 않았고 저장 순서는 Inspreqlot detail→Inspreq header였다. QMS 테이블만 저장하거나 header-first로 추정하지 않는다.
- Lot ID 입력은 LotCreateType별로 batch/materiallot, cut/lane, site/line/product shortname, calendar-year code/day-of-year, workorder type/shift 등이 달라진다. IdPattern 사용 자체가 공통 ID 규칙이나 동시 발급 보장을 뜻하지 않는다. 관련 달력·코드·라인·설비 기준정보도 업무 계약이다.

## 무비판적으로 복사하면 안 되는 표본

| 기록된 코드 | 피해야 할 오판 |
|---|---|
| SelectPackingProductOrderList → processCancelActiveDeliveryOrder | Select 이름만 보고 읽기 전용으로 분류 |
| RECIPEITEMManager.update의 DELETE 뒤 break | 다중 행 모두 처리한다고 가정 |
| PRODUCTWORKORDERRELManager.create의 기존 행 update 후 create 목록 추가 | 검증된 일반 upsert 템플릿으로 복사 |
| DELIVERYORDERManager의 checkStateTransition 네 번째 인자 getState() | SITEID 위치에 상태를 전달하는 호출을 상태 전이 표본으로 사용 |
| MATERIALManager.upsertMaterialInterface의 실제 saveHist=false / 기대 count는 인자 사용 | 이력 인자만 보고 저장 결과·기대행 수 확정 |
| WORKORDERManager·PRODUCTORDERManager의 null 검사 후 get(0) | 빈 조회 결과까지 안전한 패턴으로 사용 |
| Packing Bulk에서 setter와 bulkColumnList 분리, null 분기의 lot.getLotid() | 추가 필드 저장·예외 처리까지 보장된 표본으로 사용 |
| sql-back의 중복 ID·DBMS 차이·select 태그 안 INSERT | 보관 mapper 전체를 안전하게 활성화 |

이는 기록된 정적 반례이며 모두 운영에서 재현된 장애라는 뜻은 아니다. 실제 파일/Kafka 효과와 로그인 실패 commit의 조건은 [연동 경계](integration-and-web-boundaries.md)에 둔다.

## Evidence

2026-09-09 `.scratch/knowledge-map-review/extension-patterns-and-invariants.md`의 선언·호출·SQL 관찰과 대표 Manager 위임·RecipeItem CUD 재확인 기록을 사용했다. DB 제약·상태 모델 설정·실제 mapper provider·런타임 보상·동시성까지 검증한 불변조건으로 확대하지 않는다.
