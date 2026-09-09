---
id: MEM-20260909-2nd-battery-source-navigation-map
type: project
scope: project
project: 2nd-battery
domain: source-navigation
tags: [cmos, navigation, source-map, rule, manager]
status: active
confidence: medium
created: 2026-09-09
updated: 2026-09-10
last_seen: 2026-09-09
occurrences: 1
source_agent: codex
---

# 2nd-battery 업무별 소스 탐색 지도

## Scope / Core Knowledge

2026-09-09 기록된 경로·심볼을 업무 질문으로 묶은 지도다. 프로젝트 `core`는 배터리 서비스 계층이고, 같은 PRODUCTIONLotManager 이름이 여러 패키지에 있으므로 **Rule import의 FQCN**에서 출발한다. 이 지도는 해당 날짜의 탐색 단서이며 전체 구현이나 실행 artifact의 동일성을 보장하지 않는다.

| 질문 | 먼저 읽을 메모리 |
|---|---|
| 모듈 소유권·상속/위임·버전 불일치 | [구조](project-architecture.md) |
| 조회·저장·Track-In·BOM·IQC 흐름 | [업무 흐름](runtime-and-business-flow.md) |
| Block 선택·목록 전제·상태·반례 | [확장 불변조건](extension-patterns-and-invariants.md) |
| Entity·삭제·Hist·Bulk·SQL provider | [영속 계약](persistence-and-query-patterns.md) |
| EIS/MCS·파일·로그인·CORS | [연동 경계](integration-and-web-boundaries.md) |
| 실행 폴더·POM 단계·웹 매핑·UI 배포물 | [설정·배포](configuration-and-runtime.md) |

## 경로 약칭

B는 배터리 checkout 루트, F는 Framework의 api/iia/core 모듈을 포함하는 루트, M은 MES-Core의 core 모듈 상위 루트다. `cmos frame` 통합 배치에서는 F가 `framework`, M이 저장소 루트에 대응한다. 이 약칭은 머신의 고정 절대 경로가 아니다.

| 약칭 | 상대 경로 접두사 |
|---|---|
| B-COMMON | `B/core/common-services/src/main/java/com/thirautech/cmos/mes/packages/` |
| B-CELL | `B/core/cell-services/src/main/java/com/thirautech/cmos/mes/packages/` |
| B-ELECTRODE | `B/core/electrode-services/src/main/java/com/thirautech/cmos/mes/packages/` |
| B-PACK | `B/core/pack-services/src/main/java/com/thirautech/cmos/mes/packages/` |
| B-RULE | `B/services/src/main/java/com/thirautech/cmos/mes/packages/business/` |
| B-SQL | `B/services/src/main/resources/sql-back/` |
| B-WEB | `B/web-ui/src/main/java/com/thirautech/cmos/web/` |
| B-RES | `B/web-ui/src/main/resources/` |
| F-API | `F/api/src/main/java/com/thirautech/cmos/framework/api/` |
| F-IIA | `F/iia/src/main/java/com/thirautech/cmos/framework/iia/` |
| F-CORE | `F/core/src/main/java/com/thirautech/cmos/mes/core/` |
| M-CORE | `M/core/src/main/java/com/thirautech/cmos/mes/core/` |

## Rule → Manager 진입점

아래 경로는 각 약칭 뒤에 붙인다. Manager 인터페이스는 공정별 구현 모듈이 아닌 B-COMMON의 `interfaces/`에 모여 있다.

| 질문 / Rule(B-RULE) | Manager 위치와 핵심 심볼 |
|---|---|
| `common/masterdata/SaveRecipeItem.java` | `B-COMMON/interfaces/common/masterdata/IRECIPEITEMManager.java` → `B-COMMON/service/common/masterdata/RECIPEITEMManager.java`: save/create/update/delete |
| `common/masterdata/SaveProductWorkOrderRel.java` | `B-COMMON/service/common/masterdata/PRODUCTWORKORDERRELManager.java`: save, realDelete(당시 272행), create의 UPDATE+CREATE 반례 |
| `common/masterdata/SaveBom.java` | `B-COMMON/service/common/masterdata/BOMManager.java`: saveBom/deleteBom/generateBomId |
| `common/plan/SelectProductOrderListForWo.java` | `B-COMMON/service/common/plan/WORKORDERManager.java`: selectProductOrderListForWo(1616행), pivot·조건명·0건 경계 |
| `cell/production/assembly/TrackInLot_Assembly.java` | `B-CELL/service/cell/production/assembly/PRODUCTIONLotManager.java`: processTrackInAssemblyLot → common 위임 |
| formation / mixing 공정 확장 | `B-CELL/service/cell/production/formation/PRODUCTIONLotManager.java`, `B-ELECTRODE/service/electrode/production/mixing/PRODUCTIONLotManager.java` |
| Lot 시작·취소·ID | `B-COMMON/service/common/production/PRODUCTIONLotManager.java`: 생성(183행), ID(750행), Track-In 진입(1877행)·검증(1997행)·실행(2798행), 취소(3893행) |
| `common/plan/ConfirmWorkOrder.java` | 위 WORKORDERManager의 confirm(597행) → PlanExtension |
| `pack/plan/SelectPackingProductOrderList.java` | `B-PACK/service/pack/plan/DELIVERYORDERManager.java`: processCancelActiveDeliveryOrder, 상태 전이 site 인자 반례(229행) |
| `common/masterdata/ActiveRecipeDefinition.java` | `B-COMMON/service/common/masterdata/RECIPEDEFINITIONManager.java`: 활성화(64행), 버전·복사(265행) |
| `common/quality/RequestInspection.java` | `B-COMMON/service/common/quality/QUALITYManager.java`: IQC(110행), detail→header 생성(10538행); `B-COMMON/service/common/material/MATERIALManagerQuality.java` |
| Bulk·포장 | `B-PACK/service/pack/production/logic/PRODUCTIONPackingManager.java`: upsertLotWithInBox(120행)·LotUpsert.bulkColumnList |
| Hist count·계획 0건 반례 | `B-COMMON/service/common/material/MATERIALManager.java`: upsertMaterialInterface(7322행); `B-COMMON/service/common/plan/PRODUCTORDERManager.java`(239행) |
| `common/eis/LotStartReport.java` | `B-COMMON/service/common/eis/EISManager.java`(808행) → common processTrackInLotByEIS |
| `electrode/mcs/TransportJobRequest.java` | `B-ELECTRODE/service/electrode/mcs/MCSManager.java`: requestCarrierTransportJob(1921행) |

줄 번호는 위 날짜의 보조 단서다. 실제 탐색은 경로·메서드·FQCN을 우선한다. Track-In 취소를 시작 순서의 단순 역실행으로 가정하지 않는다.

## Framework / MES 연결

| 역할 | 상대 경로·심볼 |
|---|---|
| 공통 READ | `M-CORE/common/business/rulemultiinquiry/RuleMultiInquiry.java`, `F-CORE/common/business/rulemultiinquiry/AbstractRuleMultiRepository.java` |
| Entity·Hist | `M-CORE/common/entity/Recipeitem.java`, `Recipeitemhist.java` |
| Repository·업무 옵션 | `M-CORE/common/business/CommonRepository.java`, `extension/ProductionExtension.java`의 trackInLot 연결 |
| 업무 기반 | `F-CORE/abstracts/business/CoreRule.java`, `CoreManager.java`, `CoreRepository.java` |
| Block 후보 선택 | `F-IIA/classes/entity/ClassInfo.java`: getBlockModuleClass |
| mapper prefix·로딩 | `F-API/configuration/Configuration.java`, `F-IIA/context/DataBaseContext.java`: initializeMapperXML |
| 요청·외부 전송 | `F-IIA/abstracts/entry/BaseDispatcher.java`, `F-CORE/common/business/DbContext.java`: sendKafka |
| 웹 인증 | `M-CORE/web/filter/SecurityWebFilter.java`, LoginImplement/LoginpolicyImplement |

Framework 전체 경로는 [C-MOS 탐색 지도](../cmos-frame/source-navigation-map.md)를 참조한다. 인접 소스는 프로젝트 resolved 의존성과 같다는 증거가 아니다.

## SQL / UI / 웹 파일

- B-SQL의 `SelectRecipeItemList4Master_THiRAMES.Service.UI_00001_sql.xml`: `mssql/storedquery`, 기준정보 조회.
- `SelectProductOrderListForWo_THiRAMES.Service.Biz_00001_sql.xml`: `mssql/storedquery`, `postgresql/mes/storedquery`, 날짜/pivot 계약.
- `InsertTraceDataParameter4RecipeActive_THiRAMES.Service.Biz_00001_sql.xml`: `mssql/storedquery`, select 태그 안 INSERT·SITEID 필터 반례.
- `SelectOrderDateListForWo`의 Biz/UI 파일: MSSQL/PostgreSQL에서 같은 namespace/id 충돌. 파일 CLASSID를 runtime ID로 해석하지 않는다.
- `B-RES/wwwroot/mes/dashboard-app.js`: RuleMultiInquiry 요청. 대응 보관 SQL은 `B-SQL/mssql/storedquery/SelectRealTimeEquipmentState_THiRAMES.Service.UI_00001_sql.xml`.
- `B-RES/wwwroot/assets/PM_CL_002-NJaZFJa6.js.map`: sourcesContent의 `src/pages/mes/PM/PM_CL_002.vue`, LotProcess(약 1657행).
- `B-RES/wwwroot/assets/BOM-aAsZ1en0.js.map`: sourcesContent의 `BOM.vue:paramData2Helper`, 전체 grid 전송. 두 map 모두 개발 원본 checkout 자체가 아니다.
- `B-WEB/WebServer.java`, `B-RES/start.bat`, `start.sh`, `config/{cmos,web,mybatis,block,kafka,scheduler}`: 기동·설정. POM은 `B/core/pom.xml`, 각 child, `B/services/pom.xml`, `B/web-ui/pom.xml`을 구분한다.
- `B-WEB/api/LoginController.java`, `BaseHttpController.java`, `MesUploadController.java`, `WebUploadController.java`, `filters/CorsWebApiFilter.java`: 매핑 대상·base·완료 경계. `/upload`의 설정 이름은 UploadController다.
- `B-WEB/test/TesterController.java`, `entity/TestEntity.java`, `B/services/src/main/java/com/thirautech/cmos/mes/packages/sample/connector/ConnectRepository.java`: 생산 표준으로 삼지 않을 test/sample.

## 탐색 순서 / Evidence

업무 소유 모듈 → Rule process/import → 공정·common Manager/Extension/statement ID → 입력·상태·이력·외부 효과 순으로 좁힌다. SQL·실행 문제면 수정 전에 실제 artifact와 mapper/config 로딩 경로부터 확인한다.

근거는 2026-09-09 `.scratch/knowledge-map-review/source-navigation-map.md` 및 당시 대표 POM·Rule·Manager 위임/CUD 확인 기록이다. 파일 존재 확인이나 정적 검사 PASS를 전체 의미·SQL 실행·배포 JAR 동일성·DB·HTTP·동시성 검증으로 확대하지 않는다.
