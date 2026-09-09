---
id: MEM-20260909-2nd-battery-persistence-and-query-patterns
type: project
scope: project
project: 2nd-battery
domain: persistence
tags: [cmos, repository, entity, mybatis, history, bulk, transaction]
status: active
confidence: medium
created: 2026-09-09
updated: 2026-09-10
last_seen: 2026-09-09
occurrences: 1
source_agent: codex
---

# 2nd-battery 저장·이력·Bulk와 활성 SQL provider 경계

## Core Knowledge / Applicability

2026-09-09 조사본의 생산 저장은 로컬 Repository 구현보다 Manager가 MES-Core `CommonRepository`·업무 Extension을 조합하는 경로가 중심이다. mapper 보관본의 위치·이름은 실제 실행 provider나 읽기 전용 동작의 증거가 아니다.

Framework의 실패 전달·CUD 계약은 [트랜잭션](../cmos-frame/persistence-and-transaction.md), [엔티티·이력](../cmos-frame/extension-contracts-and-invariants.md)을 따른다. 아래는 프로젝트의 호출 선택에 관한 정적 지식이며, 경로는 [탐색 지도](source-navigation-map.md)에 둔다.

## 저장 수단과 Entity

| 요구 | 대표 호출 | 경계 |
|---|---|---|
| 기준정보 CUD | RECIPEITEMManager → CommonRepository | row-state, 복합키, common-data, Hist |
| 상태·업무 변경 | PRODUCTIONLotManager/WORKORDERManager → 도메인 Extension | 검증·옵션·이력 부수효과 포함 |
| 화면 조회·가공 | DbContext.selectList(statement, Map) → pivot | 조건명·alias·컬럼 순서 |
| 조회 후 저장 | BOM/Recipe/Packing Manager의 SQL 조회 → Entity/Extension | 같은 요청 Context와 저장 범위 |
| 직접 SQL 쓰기 | RECIPEDEFINITIONManager → DbContext.insert | Entity CUD의 이력·범위와 동등하다고 가정하지 않음 |
| 목록 CUD / 업무 Bulk | create/upsert(list,true) / LotUpsert·upsertLotBulk | List 인자와 업무 Bulk는 다른 계약 |

로컬 CoreRepository subclass는 connector/document/plugin sample이었다. `TestEntity`도 공통 getter 일부가 null인 Z_TEST용으로 생산 Entity 템플릿이 아니다.

- MES-Core `Recipeitem`은 CIM_RECIPEITEM, 복합키 RECIPEITEMID+SITEID다.
- `Recipeitemhist`는 CIM_RECIPEITEMHIST이며 LASTEVENTSEQ가 Id, insertable=false다. 본 Entity PK를 Hist PK에 복제하는 구조가 아니다.
- Entity 생성에는 메시지 변환, `new Lot`, `Factory.getEntity`, `DbContext.convertToEntityObject`가 쓰였다. 단일 생성 방식 강제 규칙으로 일반화하지 않는다.
- 신규 필드는 Map 통과 여부 외에도 key/SITEID, `@Column`, setter의 touched, Hist 필드와 mapper 결과를 함께 확인한다.

## 삭제·saveHist·영향행 수

| 호출 | 기록된 의미 / 함정 |
|---|---|
| RecipeItem delete → upsert(DELETE,true) | 논리 삭제+이력. JavaDoc의 “실제 삭제”보다 RequestType을 따른다 |
| ProductWorkOrderRel REALDEL → realDelete(...,true) | 물리 삭제+이력. DEL과 같은 row-state가 아님 |
| BOM deleteBom → REALDELETE,true | 첫 Product/Site 전체 교체의 삭제. 단건 삭제 표본이 아님 |
| BOM create/delete → dbTransactionCheck(count,size×2) | 본 행+Hist를 묶은 반환 count. SQL batch 횟수가 아님 |
| Material upsertMaterialInterface | 실제 upsert는 saveHist=false 고정인데 기대 count는 전달 saveHist 사용 |

프로젝트에 `deleteBiz` 직접 호출 문자열이 없더라도 `RequestType.DELETE`가 CoreRepository의 논리 삭제로 이어졌다. saveHist 변경 시 기대 count도 함께 검토한다. 총 count가 맞는 것을 각 행의 성공·실제 DB commit 증거로 확대하지 않는다.

## Bulk 저장 컬럼

`PRODUCTIONPackingManager.upsertLotWithInBox`는 저장 Lot을 재조회해 INBOX/OUTBOX/PALLETID·공정 node를 확인한 뒤 INBOX를 설정하고 `LotUpsert.setBulkColumnList(List.of(INBOX)) → upsertLotBulk(UPDATE,lotList,options)`를 호출한다.

setter를 추가해도 bulkColumnList에 없는 필드가 저장된다고 가정하지 않는다. 변경 컬럼 확대는 이력·동시 갱신과 함께 검토한다. null 조회 분기에서 lot.getLotid()를 부르는 코드가 있어 예외 처리까지 복사하지 않는다. 보관 `SP_BULK...` 파일의 존재만으로 이 Java 경로가 그 SP를 실행한다고 판단하지 않는다.

## Transaction·lock

일반 Rule/Manager는 요청 DbContext를 사용했다. 직접 SeparatedTransaction 표본은 web-ui/test의 TesterEvent·TesterLoop·TesterPivot에 있었고, 생산 Rule의 표준으로 삼지 않는다. LoginController의 실패 commit과 파일/Kafka 효과는 [연동 경계](integration-and-web-boundaries.md)에 둔다.

프로젝트의 직접 select4Update/selectWithLock 호출 부재는 Core 내부 lock 부재의 증거가 아니다. get→create/update, BOM 교체, ID 발급, 목록 상태 변경의 경쟁 방지는 조회 코드만으로 보장되지 않는다.

## SQL provider와 탐색 순서

보관 위치는 `services/src/main/resources/sql-back`이며 MSSQL은 `mssql/{api,core,custom,modeler,storedquery}`, Oracle/PostgreSQL은 `oracle/mes/...`, `postgresql/mes/...` 배치였다. web-ui의 resources/sql에는 `.gitkeep`만 있고 cmos.json에는 prefix override가 없었다.

인접 Framework의 기본 mapper prefix는 `sql`, custom은 `custom`이며 prefix+DBMS를 탐색했다. **sql-back/mssql은 sql/mssql와 다르므로 보관본 수정만으로 실행 Query가 바뀐다고 가정하지 않는다.** 실제 제공자는 resolved JAR·외부 resource·배포 인자와 연결해 확인한다.

SQL 작업 순서는 호출 statement ID → 활성 provider → DBMS XML → namespace/id 중복 → 입력 조건·결과 alias/컬럼 순서다. 중복·DBMS 차이·직접 INSERT가 포함된 sql-back 전체를 확인 없이 활성화하지 않는다.

## 보존할 SQL 반례

- `SelectRecipeItemList4Master`: SITEID, ID/이름 LIKE, ISUSABLE 조건 표본. MSSQL COLLATE·문자열 결합을 PostgreSQL에 그대로 복사하지 않는다.
- `SelectProductOrderListForWo`: 일자 생성·지시/계획 join의 DBMS 차이와 마지막 PLANDATE/PLANQTY 순서가 Java pivot에 연결된다. WORKORDERTYPE/PRODUCTORDERTYPE 조건 불일치는 [조회 흐름](runtime-and-business-flow.md)을 참조한다.
- MSSQL `InsertTraceDataParameter4RecipeActive_THiRAMES.Service.Biz_00001_sql.xml`: **태그는 select지만 본문은 INSERT**다. Manager가 넣는 SITEID를 WHERE에서 사용하지 않고 전체 후보를 NOT EXISTS로 처리했다. read-only나 사이트 제한 표본으로 삼지 않는다.
- MSSQL/PostgreSQL `SelectOrderDateListForWo` Biz/UI 두 파일은 모두 `com.thirautech.cmos.mes.SelectOrderDateListForWo-00001`를 선언했다. CLASSID가 다른 파일명도 runtime ID 중복을 막지 못한다.

## Evidence

2026-09-09 `.scratch/knowledge-map-review/persistence-and-query-patterns.md`의 전체 보관 XML 파싱·ID 비교와 대표 Java/인접 Core 정적 대조 기록에 근거한다. well-formed XML 파싱은 통과했지만 DBMS별 ID 집합은 달랐다. 이 기록은 MyBatis 로딩·SQL 문법·DB 실행·실제 provider 확인 결과가 아니다.
