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
updated: 2026-09-09
last_seen: 2026-09-09
occurrences: 1
source_agent: codex
---

# 2nd-battery · Persistence & Query Patterns

본문은 2026-09-09 원본 검토 문서의 관찰을 기반으로 한다. pull 이후 D:/thira/package/2nd의 core 4개 서비스 모듈·services·web-ui를 확보해 참조 경로와 대표 호출·POM을 재확인했다. 전체 구현·실행 결과를 다시 검증한 것은 아니며 상세 재확인 범위와 경로 약칭은 [탐색 지도](source-navigation-map.md)를 따른다.

Framework 저장/transaction 구현은 [Framework Memory · persistence-and-transaction.md](../cmos-frame/persistence-and-transaction.md), [Framework Memory · extension-contracts-and-invariants.md](../cmos-frame/extension-contracts-and-invariants.md)를 참조한다. 여기에는 PROJECT의 호출 선택과 결합 조건만 남긴다. A=Project-specific, B=조건부 Reusable Pattern.

## 저장 수단 선택 지도

| 유형 | 이 프로젝트의 사용 | 좋은 시작점 | 적용 범위 |
|---|---|---|---|
| 단순 기준정보 CUD | MES Entity + CommonRepository.get/create/upsert | RECIPEITEMManager · common/masterdata (`B-COMMON/service/common/masterdata/RECIPEITEMManager.java:61`) | B: row-state 저장 구조. 오류 분기 검증 필요 |
| 상태/업무 CUD | CommonRepository의 도메인 Extension | PRODUCTIONLotManager · common/production (`B-COMMON/service/common/production/PRODUCTIONLotManager.java:2798`), WORKORDERManager · common/plan (`B-COMMON/service/common/plan/WORKORDERManager.java:597`) | B: 검증·옵션·이력을 포함한 Core 업무 재사용 |
| 조건/집계/화면 조회 | DbContext.selectList(statement, Map) | WORKORDERManager · common/plan (`B-COMMON/service/common/plan/WORKORDERManager.java:1616`), SelectRecipeItemList4Master_THiRAMES.Service.UI_00001_sql.xml (`B-SQL/mssql/storedquery/SelectRecipeItemList4Master_THiRAMES.Service.UI_00001_sql.xml:4`) | B: 검색 조건과 결과 alias 계약 |
| 조회+Entity 변환+CUD | SQL로 목록/대상 파악 후 Entity/Extension으로 저장 | BOMManager · common/masterdata (`B-COMMON/service/common/masterdata/BOMManager.java:60`), RECIPEDEFINITIONManager · common/masterdata (`B-COMMON/service/common/masterdata/RECIPEDEFINITIONManager.java:265`), PRODUCTIONPackingManager · pack/production/logic (`B-PACK/service/pack/production/logic/PRODUCTIONPackingManager.java:120`) | B: 읽기/쓰기 책임 분리. 동일 요청 Context 연결 확인 |
| SQL 직접 쓰기 | DbContext.insert(...) | RECIPEDEFINITIONManager · common/masterdata (`B-COMMON/service/common/masterdata/RECIPEDEFINITIONManager.java:64`), InsertTraceDataParameter4RecipeActive_THiRAMES.Service.Biz_00001_sql.xml (`B-SQL/mssql/storedquery/InsertTraceDataParameter4RecipeActive_THiRAMES.Service.Biz_00001_sql.xml:4`) | A: Core Entity CUD와 이력/범위 동등성은 보장되지 않음 |
| 목록/Batch | create(list,true), upsert(list,...,true) | BOMManager · common/masterdata (`B-COMMON/service/common/masterdata/BOMManager.java:60`), RECIPEITEMManager · common/masterdata (`B-COMMON/service/common/masterdata/RECIPEITEMManager.java:61`) | B: 목록 처리와 이력 영향행 수 |
| 업무 Bulk | LotUpsert.bulkColumnList + ProductionExtension.upsertLotBulk | PRODUCTIONPackingManager · pack/production/logic (`B-PACK/service/pack/production/logic/PRODUCTIONPackingManager.java:120`) | B: 변경 컬럼 명시. 포장 검증은 A |

업무용 프로젝트 Repository/Entity 정의를 찾느라 services를 모두 읽지 않는다. 실제 CommonRepository는 MES-Core, 기본 CUD는 FRAME-CORE로 내려간다. 로컬 CoreRepository subclass 3개는 connector/document/plugin **sample**이다. 생산 CUD 표본은 Repository subclass를 새로 만든 사례가 아니라 **기존 Repository를 호출하는 Manager**다.

## Entity 표본과 키 [B/A]

프로젝트가 사용하는 Recipeitem (`M-CORE/common/entity/Recipeitem.java:12`) / Recipeitemhist (`M-CORE/common/entity/Recipeitemhist.java:12`)를 Entity 계약 참고 대상으로 삼는다. 현재 프로젝트 밖 MES-Core 소스에 위치한다.

- Recipeitem: `CIM_RECIPEITEM`, `RECIPEITEMID + SITEID` 복합키. Manager의 get 키 조합과 일치한다.
- Recipeitemhist: `CIM_RECIPEITEMHIST`, `LASTEVENTSEQ`가 Id이며 insertable=false. 본 Entity의 PK를 Hist PK에 그대로 복제하는 구조가 아니다.
- `SaveRecipeItem`은 메시지에서 Entity를 만들고 Manager는 저장된 Entity와 비교한다. 다른 곳에서는 `new Lot`, Factory.getEntity, DbContext.convertToEntityObject도 사용한다. “모든 Entity 생성은 한 방식만 허용”하는 프로젝트 규칙은 확인되지 않았다.
- TestEntity (`B-WEB/entity/TestEntity.java:13`)는 일부 공통 getter가 null을 반환하는 Z_TEST용 Entity다. 신규 생산 Entity 템플릿으로 추천하지 않는다.
- 신규 필드가 메시지 Map에서 통과하는 것과 실제 `@Column`/SQL 컬럼으로 저장되는 것은 별도 확인 대상이다. SITEID와 entity key, setter의 touched 호출, Hist 필드, mapper 결과를 함께 확인한다.

## saveHist / 삭제 / 영향행 수

| 실제 호출 | 여기서 확인한 의미 | 주의 |
|---|---|---|
| RECIPEITEMManager.delete → upsert(...,DELETE,true) | 논리 삭제+이력 경로 | JavaDoc의 “실제 삭제” 표현보다 RequestType을 우선 |
| PRODUCTWORKORDERRELManager.save → REALDEL 그룹 → realDelete(...,true) | 물리 삭제+이력 경로 | DEL과 REALDEL은 같은 row-state가 아님 |
| BOMManager.deleteBom → REALDELETE,true | 선택 Product/Site 전체 교체를 위한 물리 삭제 | 단건 삭제 표본으로 쓰지 않음 |
| createBom/deleteBom → dbTransactionCheck(count, list.size()*2) | 본 데이터+Hist 반환 count를 묶어 검사 | “2”는 임의 배수/SQL batch 횟수가 아님 |
| MaterialManager.upsertMaterialInterface | 실제 upsert는 saveHist=false 고정, 기대 count는 전달 saveHist 사용 | 인자 이름만 보고 history가 저장된다고 쓰지 않음 |

근거: RECIPEITEMManager · common/masterdata (`B-COMMON/service/common/masterdata/RECIPEITEMManager.java:61`), PRODUCTWORKORDERRELManager · common/masterdata (`B-COMMON/service/common/masterdata/PRODUCTWORKORDERRELManager.java:272`), BOMManager · common/masterdata (`B-COMMON/service/common/masterdata/BOMManager.java:60`), MATERIALManager · common/material (`B-COMMON/service/common/material/MATERIALManager.java:7322`). 직접 `deleteBiz` 문자열 사용은 프로젝트 Java에 없지만 `delete`와 `RequestType.DELETE`로 연결된다. CoreRepository (`F-CORE/abstracts/business/CoreRepository.java:171`)에서 이 연결을 대조했다. 이력 테이블 존재/trigger/실제 반환행 수는 DB 검증하지 않았다.

## Bulk는 “List를 인자로 받는다”와 다르다

PRODUCTIONPackingManager · pack/production/logic (`B-PACK/service/pack/production/logic/PRODUCTIONPackingManager.java:120`)의 upsertLotWithInBox는 저장 Lot을 재조회하고 기존 INBOX/OUTBOX/PALLETID와 공정 node를 확인한 후 INBOX를 설정한다. `new LotUpsert(); setBulkColumnList(List.of(INBOX)); upsertLotBulk(UPDATE, lotList, options)`를 사용한다.

재사용 가치는 **저장할 컬럼을 명시하고 Core Bulk 경로로 넘기는 방식**이다. 다른 필드를 추가로 setter 호출해도 bulkColumnList에 없으면 동일 저장 효과를 가정하면 안 된다. 반대로 모든 필드를 넣는 변경도 금지된 일반 규칙은 아니지만 업무 이력/동시 갱신 영향을 검토해야 한다. 조회 결과가 null인 분기에서 lot.getLotid()를 호출하는 코드가 있으므로 예외 처리까지 무비판적으로 복사하지 않는다.

보관 SQL에는 `SP_BULK...` 이름도 많다. 해당 파일의 존재나 함수명만으로 현재 Java Bulk 호출이 그 SP를 실행한다고 결론내리지 않는다. 이번 대표 Bulk는 실제 Java → Extension 호출을 근거로 선정했다.

## Transaction과 lock의 증거 경계

- 보통 Rule/Manager는 DbContext/CommonRepository를 사용하고 직접 commit하지 않는다. [전체 Java 호출 검색+대표 흐름]
- **예외:** LoginController (`B-WEB/api/LoginController.java:74`)는 실패 시 Context.commit 후 예외를 던진다. 실패 횟수 지속 의도를 가진 특정 인증 경로이며 일반 SAVE 표본이 아니다.
- 직접 `getSeparatedTransaction()`은 web-ui/test의 TesterEvent·TesterLoop·TesterPivot에만 확인했다. 업무 Rule의 독립 transaction 표본은 없다.
- 프로젝트 Java에서 직접 `select4Update`/`selectWithLock` 호출은 찾지 못했다. 이 사실은 Core 내부 lock 부재/동시성 안전을 뜻하지 않는다.
- `get → create/update`, BOM 교체, ID 발급, mixed list 상태 변경의 동시성은 runtime/DB 격리 수준까지 검증하지 않았다. Java의 “먼저 조회했다”만으로 경쟁 방지를 주장하지 않는다.
- 파일과 Kafka는 DB rollback으로 함께 되돌아간다고 볼 근거가 없다. [integration-and-web-boundaries.md](integration-and-web-boundaries.md)

## SQL 탐색/로딩 경계 [A, 매우 중요]

현재 프로젝트의 mapper 보관 위치는 **services/src/main/resources/sql-back**뿐이다.

| DBMS | 경로 | XML 개수 | XML 내부 select statement 수 |
|---|---|---:|---:|
| MSSQL | sql-back/mssql/{api,core,custom,modeler,storedquery} | 945 | 1,035 |
| Oracle | sql-back/oracle/mes/... | 948 | 1,047 |
| PostgreSQL | sql-back/postgresql/mes/... | 943 | 1,034 |

web-ui/resources/sql에는 .gitkeep만 있다. 현재 cmos.json에는 mapper prefix override가 없다. 인접 Framework의 기본 prefix는 `sql`, custom은 `custom`이며 실제 탐색은 prefix+DBMS다. **기본 설정의 sql/mssql와 sql-back/mssql는 다르다.** 따라서 sql-back을 수정하는 것만으로 운영 Query가 바뀐다고 저장하면 안 된다. 실제 제공자는 resolved MES-Core JAR, 외부 resource, 배포 인자가 될 수 있으나 이번에는 확정하지 못했다. Configuration · mapper prefix (`F-API/configuration/Configuration.java:26`) DataBaseContext.initializeMapperXML (`F-IIA/context/DataBaseContext.java:173`) cmos.json (`B-RES/config/cmos.json:1`)

SQL을 새로 만들 때: (1) 호출 statement ID 확인 → (2) 활성 mapper provider 확인 → (3) 해당 DBMS XML 확인 → (4) namespace/id 중복 검사 → (5) 입력 조건/결과 alias/컬럼 순서 대조. sql-back의 이름을 임의 변경하거나 활성 폴더로 이동하는 것은 이번 분석 범위가 아니다.

## SQL 표본과 비정상 가정 방지

1. **단순 조회:** SelectRecipeItemList4Master_THiRAMES.Service.UI_00001_sql.xml (`B-SQL/mssql/storedquery/SelectRecipeItemList4Master_THiRAMES.Service.UI_00001_sql.xml:4`). SITEID 필터, ID/이름 LIKE, ISUSABLE 선택 조건을 볼 수 있다. MSSQL COLLATE/문자열 결합은 PostgreSQL에 그대로 복사하지 않는다.
2. **복잡 조회:** SelectProductOrderListForWo_THiRAMES.Service.Biz_00001_sql.xml (`B-SQL/mssql/storedquery/SelectProductOrderListForWo_THiRAMES.Service.Biz_00001_sql.xml:4`) / SelectProductOrderListForWo_THiRAMES.Service.Biz_00001_sql.xml (`B-SQL/postgresql/mes/storedquery/SelectProductOrderListForWo_THiRAMES.Service.Biz_00001_sql.xml:4`). 일자 생성 → 지시/계획 join → 마지막 PLANDATE/PLANQTY를 Java pivot과 결합한다. DBMS별 날짜 생성 방식이 다르다. 결과 컬럼 순서도 Java 계약이다.
3. **직접 INSERT:** InsertTraceDataParameter4RecipeActive_THiRAMES.Service.Biz_00001_sql.xml (`B-SQL/mssql/storedquery/InsertTraceDataParameter4RecipeActive_THiRAMES.Service.Biz_00001_sql.xml:4`). 태그는 `<select>`인데 SQL 본문은 INSERT다. 태그/파일명만으로 read-only라 분류하면 안 된다. 해당 MSSQL 보관본은 Manager가 넣는 SITEID를 WHERE에서 사용하지 않고 전체 후보를 NOT EXISTS로 처리한다. 사이트 범위를 제한하는 표본으로 쓰지 않는다.
4. **ID 충돌:** MSSQL/PostgreSQL의 `SelectOrderDateListForWo` Biz/UI 두 파일은 모두 `com.thirautech.cmos.mes.SelectOrderDateListForWo-00001`를 선언한다. CLASSID가 다른 파일명이어도 mapper ID는 충돌할 수 있다. 현재 로딩 장애 재현은 아니다.

전체 2,836 XML의 well-formed 파싱은 통과했다. MyBatis parser/SQL 문법/DB 실행 검증은 아니다. DBMS별 ID 집합도 같지 않다(동일 `<namespace>.<id>` 기준 MSSQL 대비 Oracle missing 5/extra 18, PostgreSQL missing 5/extra 4). 이 숫자는 현재 보관본의 비교값이며 모든 DBMS 기능 동등성은 미검증이다.

## Verification

원본 근거: `B/.scratch/knowledge-map-review/persistence-and-query-patterns.md` (2026-09-09). 원본 문서의 정적 검사 PASS는 실제 배포 JAR·설정·DB·HTTP·브로커·동시성 검증이 아니다. medium confidence와 project 범위를 유지한다. 다른 프로젝트에 적용하려면 같은 호출·설정 계약을 먼저 대조한다.
