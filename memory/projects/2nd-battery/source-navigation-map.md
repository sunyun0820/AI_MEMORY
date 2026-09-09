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
updated: 2026-09-09
last_seen: 2026-09-09
occurrences: 1
source_agent: codex
---

# 2nd-battery · Source Navigation Map

이 지도는 2026-09-09 원본 검토 문서의 탐색 단서다. pull 이후 core 4개 서비스 모듈·services·web-ui의 참조 경로와 대표 소스를 재확인했다. 아래 줄 번호는 원본 위치이며 전체 구현·실행 JAR의 동일성까지 검증한 지도는 아니다.

## Source Path Aliases

원본 조사 경로: B=E:/0.Project/mes-package/2nd-battery, F=E:/0.Project/cmos-frame, M=E:/0.Project/mes-core. 현재 대응 경로는 B=D:/thira/package/2nd(core 4개 서비스 모듈·services·web-ui 확보), F=D:/thira/cmos frame/framework, M=D:/thira/cmos frame이다. B/core/common-services·cell-services·electrode-services·pack-services의 소스와 POM도 현재 경로에서 확인했다. 아래 약칭은 원본 경로의 압축 표기이며 확보된 모듈만 현재 루트로 대응시킨다. 파일·심볼은 FQCN으로 다시 확인한다.

| 약칭 | 원본 경로 접두사 |
|---|---|
| B-COMMON | B/core/common-services/src/main/java/com/thirautech/cmos/mes/packages/ |
| B-CELL | B/core/cell-services/src/main/java/com/thirautech/cmos/mes/packages/ |
| B-ELECTRODE | B/core/electrode-services/src/main/java/com/thirautech/cmos/mes/packages/ |
| B-PACK | B/core/pack-services/src/main/java/com/thirautech/cmos/mes/packages/ |
| B-RULE | B/services/src/main/java/com/thirautech/cmos/mes/packages/business/ |
| B-SQL | B/services/src/main/resources/sql-back/ |
| B-WEB | B/web-ui/src/main/java/com/thirautech/cmos/web/ |
| B-RES | B/web-ui/src/main/resources/ |
| F-API | F/api/src/main/java/com/thirautech/cmos/framework/api/ |
| F-IIA | F/iia/src/main/java/com/thirautech/cmos/framework/iia/ |
| F-CORE | F/core/src/main/java/com/thirautech/cmos/mes/core/ |
| M-CORE | M/core/src/main/java/com/thirautech/cmos/mes/core/ |
| B | 원본 배터리 checkout 루트 |

**첫 판단:** 이 프로젝트의 `core`는 배터리 PROJECT 계층이다. `core/common-services`에는 공통 구현뿐 아니라 cell/electrode/pack 인터페이스도 들어 있다. 동일한 PRODUCTIONLotManager 이름 대신 **Rule import의 FQCN**을 출발점으로 삼는다.

범례: A=Project-specific, B=적용 조건이 있는 재사용 패턴. 아래 경로·줄 번호는 원본 checkout에서 기록한 파일/심볼 위치다. 인접 Framework/MES-Core 소스는 resolved 의존성 동일성 미검증. Framework 내부 탐색은 [Framework Memory · source-navigation-map.md](../cmos-frame/source-navigation-map.md)를 사용한다.

| 작업/질문 | 먼저 볼 위치·대표 표본 | 같이 볼 파일/연결 | Framework/Core 계약 | 주의·분류 |
|---|---|---|---|---|
| 전체 소유 경계는? | [project-architecture.md](project-architecture.md) | core/pom.xml (`B/core/pom.xml:1`) / services/pom.xml (`B/services/pom.xml:1`) / web-ui/pom.xml (`B/web-ui/pom.xml:1`) | API→IIA→FRAME-CORE→MES-CORE→PROJECT | core 폴더를 MES-Core로 오인 금지 · A |
| 신규 단순 조회는? | dashboard-app.js (`B-RES/wwwroot/mes/dashboard-app.js:119`), SelectRecipeItemList4Master_THiRAMES.Service.UI_00001_sql.xml (`B-SQL/mssql/storedquery/SelectRecipeItemList4Master_THiRAMES.Service.UI_00001_sql.xml:4`) | RuleMultiInquiry (`M-CORE/common/business/rulemultiinquiry/RuleMultiInquiry.java:9`), AbstractRuleMultiRepository (`F-CORE/common/business/rulemultiinquiry/AbstractRuleMultiRepository.java:35`) | RuleMultiInquiry/DbContext/mapper ID | 새 Rule이 항상 필요한 것은 아님. sql-back 활성성 확인 · B |
| 조회 결과를 업무 가공해야 한다면? | SelectProductOrderListForWo (`B-RULE/common/plan/SelectProductOrderListForWo.java:14`) → WORKORDERManager · common/plan (`B-COMMON/service/common/plan/WORKORDERManager.java:1616`) | SelectProductOrderListForWo_THiRAMES.Service.Biz_00001_sql.xml (`B-SQL/mssql/storedquery/SelectProductOrderListForWo_THiRAMES.Service.Biz_00001_sql.xml:4`) / SelectProductOrderListForWo_THiRAMES.Service.Biz_00001_sql.xml (`B-SQL/postgresql/mes/storedquery/SelectProductOrderListForWo_THiRAMES.Service.Biz_00001_sql.xml:4`) | 날짜 Map→MyBatis→pivot→DATADIC | 0건/조건명/마지막 컬럼 계약 검증 후 사용 · B |
| 신규 기준정보 SAVE는? | SaveRecipeItem (`B-RULE/common/masterdata/SaveRecipeItem.java:13`) → IRECIPEITEMManager (`B-COMMON/interfaces/common/masterdata/IRECIPEITEMManager.java:9`) → RECIPEITEMManager · common/masterdata (`B-COMMON/service/common/masterdata/RECIPEITEMManager.java:61`) | Recipeitem (`M-CORE/common/entity/Recipeitem.java:12`), Recipeitemhist (`M-CORE/common/entity/Recipeitemhist.java:12`) | CoreRule 검증/Manager Block/CommonRepository | DELETE break 포함 전체 복사 금지 · B |
| INSERT / UPDATE 호출 표본은? | RECIPEITEMManager · common/masterdata (`B-COMMON/service/common/masterdata/RECIPEITEMManager.java:61`) create/update | CommonRepository (`M-CORE/common/business/CommonRepository.java:13`), CoreRepository (`F-CORE/abstracts/business/CoreRepository.java:171`) | get 키·common-data·RequestType·Hist | “create”가 기존 행 update도 수행함 · B |
| 논리 삭제는? | RECIPEITEMManager · common/masterdata (`B-COMMON/service/common/masterdata/RECIPEITEMManager.java:61`) delete | CoreRepository (`F-CORE/abstracts/business/CoreRepository.java:171`) DELETE 분기 | upsert(DELETE,true)→deleteBiz | 이름/주석보다 enum/overload 확인 · B |
| 물리 삭제는? | PRODUCTWORKORDERRELManager · common/masterdata (`B-COMMON/service/common/masterdata/PRODUCTWORKORDERRELManager.java:272`) 메서드 | SaveProductWorkOrderRel (`B-RULE/common/masterdata/SaveProductWorkOrderRel.java:1`), PRODUCTWORKORDERRELManager · common/masterdata (`B-COMMON/service/common/masterdata/PRODUCTWORKORDERRELManager.java:53`) save | REALDEL→REALDELETE→realDelete | create 전체는 좋은 upsert 표본이 아님 · B |
| BOM 저장이 기존 데이터를 지운다면? | SaveBom (`B-RULE/common/masterdata/SaveBom.java:13`) → BOMManager · common/masterdata (`B-COMMON/service/common/masterdata/BOMManager.java:60`) | BOM-aAsZ1en0.js.map (`B-RES/wwwroot/assets/BOM-aAsZ1en0.js.map:1`) sourcesContent | 전체 교체 CUD/Hist/count | 첫 Product/Site의 전체 목록 계약 · A |
| 신규 업무 Rule/Event는? | TrackInLot_Assembly (`B-RULE/cell/production/assembly/TrackInLot_Assembly.java:43`) | PRODUCTIONLotManager · cell/production/assembly (`B-CELL/service/cell/production/assembly/PRODUCTIONLotManager.java:73`) → PRODUCTIONLotManager · common/production (`B-COMMON/service/common/production/PRODUCTIONLotManager.java:1877`) | CoreRule→Block Manager→Extension | 단순 process에 SQL 직접 추가하기 전 공통 경로 확인 · B |
| 새 공정 Manager/override는? | PRODUCTIONLotManager · cell/production/assembly (`B-CELL/service/cell/production/assembly/PRODUCTIONLotManager.java:73`), PRODUCTIONLotManager · cell/production/formation (`B-CELL/service/cell/production/formation/PRODUCTIONLotManager.java:22`), PRODUCTIONLotManager · electrode/production/mixing (`B-ELECTRODE/service/electrode/production/mixing/PRODUCTIONLotManager.java:40`) | 해당 interfaces 패키지, block.json (`B-RES/config/block.json:1`) | BlockController/BlockModule/버전 선택 | common Manager 상속이 아니라 위임. ClassInfo.getBlockModuleClass (`F-IIA/classes/entity/ClassInfo.java:345`) · B |
| Entity를 추가/확장하려면? | 실제 사용 Recipeitem (`M-CORE/common/entity/Recipeitem.java:12`) / Recipeitemhist (`M-CORE/common/entity/Recipeitemhist.java:12`) | 사용하는 Rule·Manager·XML | CoreEntity key/Column/touched/Hist | 로컬 TestEntity (`B-WEB/entity/TestEntity.java:13`)는 생산 표준 아님 · B |
| 신규 Repository가 꼭 필요한가? | CommonRepository (`M-CORE/common/business/CommonRepository.java:13`)와 기존 Manager 호출 | CoreRepository (`F-CORE/abstracts/business/CoreRepository.java:171`), 도메인 Extension | 기본 Entity CUD 및 업무 CUD | 프로젝트에 생산 전용 Repo subclass 표본 없음 · B |
| MyBatis SQL을 추가/수정하려면? | [persistence-and-query-patterns.md](persistence-and-query-patterns.md)의 로딩 경계 → 해당 DBMS XML | Configuration · mapper prefix (`F-API/configuration/Configuration.java:26`), DataBaseContext.initializeMapperXML (`F-IIA/context/DataBaseContext.java:173`), 실제 배포 resource | namespace+id/DBMS prefix | sql-back을 수정해도 활성 Query 변경 보장 없음 · A |
| SQL ID를 찾을 수 없다면? | 호출 문자열 / QUERYID+VERSION | AbstractRuleMultiRepository (`F-CORE/common/business/rulemultiinquiry/AbstractRuleMultiRepository.java:35`), SelectRecipeItemList4Master_THiRAMES.Service.UI_00001_sql.xml (`B-SQL/mssql/storedquery/SelectRecipeItemList4Master_THiRAMES.Service.UI_00001_sql.xml:4`) | 후보 ID 해석·mapper 존재 여부 | 파일 CLASSID와 runtime ID가 다를 수 있음 · B |
| 같은 SQL ID로 초기화 충돌이 난다면? | sql-back의 SelectOrderDateListForWo Biz/UI 두 파일 | 활성 mapper provider 전체 | namespace+id 유일성 | MSSQL/PG 보관본에서 중복 확인. 현재 장애 재현 아님 · A |
| 버튼/API command 추가는? | PM_CL_002-NJaZFJa6.js.map (`B-RES/wwwroot/assets/PM_CL_002-NJaZFJa6.js.map:1`) LotProcess 또는 BOM-aAsZ1en0.js.map (`B-RES/wwwroot/assets/BOM-aAsZ1en0.js.map:1`) paramData2Helper | services Rule import→Manager, web.json (`B-RES/config/web.json:29`) | COMMAND dispatch와 URL mapping 별도 | Vue 원본은 map 내 복원 자료. 실제 UI repo 확보 필요 · A/B |
| REST 전용 URL 연결은? | web.json (`B-RES/config/web.json:29`) apiMapping/webMapping/servletMapping | LoginController (`B-WEB/api/LoginController.java:33`), BaseHttpController (`B-WEB/api/BaseHttpController.java:35`) | CoreRule 요청 vs HttpData/Servlet | 모든 Controller가 CoreController는 아님 · B |
| CoreController 메서드 이벤트 예는? | TesterController (`B-WEB/test/TesterController.java:7`) | @EventMapping / @EventMethodMapping | CoreController 계약 | test 예뿐; 생산 대표로 승격하지 않음 · A |
| Lot 상태/Track-In 변경은? | PRODUCTIONLotManager · common/production (`B-COMMON/service/common/production/PRODUCTIONLotManager.java:1877`), PRODUCTIONLotManager · common/production (`B-COMMON/service/common/production/PRODUCTIONLotManager.java:1997`), PRODUCTIONLotManager · common/production (`B-COMMON/service/common/production/PRODUCTIONLotManager.java:2798`) | PRODUCTIONLotManager · cell/production/assembly (`B-CELL/service/cell/production/assembly/PRODUCTIONLotManager.java:73`)/formation/mixing 호출자, ProductionExtension (`M-CORE/common/business/extension/ProductionExtension.java:849`) | Core tracking·이력·worktime | node/Batch/설비/Recipe/SQC 영향. 혼합 목록 주의 · A |
| 시작 취소/후속 공정 오류는? | PRODUCTIONLotManager · common/production (`B-COMMON/service/common/production/PRODUCTIONLotManager.java:3893`) | 공정별 CancelTrackIn Rule/Manager | 저장된 현재 상태와 취소 업무 | 시작 로직을 반대로 실행한다고 동일하지 않음 · A |
| 지시 확정/상태 전이는? | ConfirmWorkOrder (`B-RULE/common/plan/ConfirmWorkOrder.java:1`) → WORKORDERManager · common/plan (`B-COMMON/service/common/plan/WORKORDERManager.java:597`) | Core state/PlanExtension, CoreManager (`F-CORE/abstracts/business/CoreManager.java:22`) | checkStateTransition(model,from,to,site) | DELIVERYORDERManager · pack/plan (`B-PACK/service/pack/plan/DELIVERYORDERManager.java:229`)의 site 인자 오류 반례 · B |
| Batch/Lot 생성/ID는? | PRODUCTIONLotManager · common/production (`B-COMMON/service/common/production/PRODUCTIONLotManager.java:183`), PRODUCTIONLotManager · common/production (`B-COMMON/service/common/production/PRODUCTIONLotManager.java:750`) | Workorder/Productdefinition/Processnode/IdPattern 설정 | CreateLot OptionSet/ID generator | 프로젝트 인자 조합과 DB 기준정보를 함께 확인 · A |
| Recipe 활성화/복사는? | ActiveRecipeDefinition (`B-RULE/common/masterdata/ActiveRecipeDefinition.java:1`), RECIPEDEFINITIONManager · common/masterdata (`B-COMMON/service/common/masterdata/RECIPEDEFINITIONManager.java:64`), RECIPEDEFINITIONManager · common/masterdata (`B-COMMON/service/common/masterdata/RECIPEDEFINITIONManager.java:265`) | Recipeparameter/Mbom, InsertTraceDataParameter4RecipeActive_THiRAMES.Service.Biz_00001_sql.xml (`B-SQL/mssql/storedquery/InsertTraceDataParameter4RecipeActive_THiRAMES.Service.Biz_00001_sql.xml:4`) | Core Extension + MyBatis 혼용 | 버전/기존 Active/파생 파라미터 정합성 · A |
| 검사요청/품질 변경은? | RequestInspection (`B-RULE/common/quality/RequestInspection.java:15`) → QUALITYManager · common/quality (`B-COMMON/service/common/quality/QUALITYManager.java:110`) | QUALITYManager · common/quality (`B-COMMON/service/common/quality/QUALITYManager.java:10538`), MATERIALManagerQuality · common/material (`B-COMMON/service/common/material/MATERIALManagerQuality.java:24`) | Quality/Material Extension | IQC 분기, header-detail·구매·자재 연쇄 · A |
| Bulk/Batch 최적화는? | PRODUCTIONPackingManager · pack/production/logic (`B-PACK/service/pack/production/logic/PRODUCTIONPackingManager.java:120`); 목록 CUD는 BOMManager · common/masterdata (`B-COMMON/service/common/masterdata/BOMManager.java:60`) | LotUpsert 및 ProductionExtension | bulkColumnList/saveHist/count | List·업무 Bulk·SP를 혼동하지 않음 · B |
| 이력 누락/영향행 수 오류는? | 호출 overload → BOMManager · common/masterdata (`B-COMMON/service/common/masterdata/BOMManager.java:60`) / MATERIALManager · common/material (`B-COMMON/service/common/material/MATERIALManager.java:7322`) | Recipeitemhist (`M-CORE/common/entity/Recipeitemhist.java:12`), CoreRepository (`F-CORE/abstracts/business/CoreRepository.java:171`) | 이력 true와 반환 count | Hist=false인데 기대 count=2가 될 수 있는 반례 · B |
| Transaction 문제가 나면? | 해당 Manager→LoginController (`B-WEB/api/LoginController.java:74`) 예외 확인 | BaseDispatcher (`F-IIA/abstracts/entry/BaseDispatcher.java:1`), [Framework Memory · persistence-and-transaction.md](../cmos-frame/persistence-and-transaction.md) | Context commit/rollback·Basic/Separated | 직접 lock 호출 없음≠Core lock 없음. DB 미검증 · B |
| EIS 보고 입력이 UI와 다르다면? | LotStartReport (`B-RULE/common/eis/LotStartReport.java:53`) → EISManager · common/eis (`B-COMMON/service/common/eis/EISManager.java:808`) | common Lot의 ByEIS 경로 | MessageData/DATALIST/Context | CARRIERLIST 우선, SITEID 공급원, reply/key 계약 · A |
| MCS 전송/회신/중복 문제는? | TransportJobRequest (`B-RULE/electrode/mcs/TransportJobRequest.java:47`) → MCSManager · electrode/mcs (`B-ELECTRODE/service/electrode/mcs/MCSManager.java:1921`) | DbContext (`F-CORE/common/business/DbContext.java:300`), kafka.json (`B-RES/config/kafka.json:1`) | Connector target + reply payload | 실행 중 send 호출. Kafka 설정은 현재 주석 · A |
| 파일 업로드는? | 활성 web.json (`B-RES/config/web.json:29`)부터; 로컬 표본 MesUploadController (`B-WEB/api/MesUploadController.java:17`) | BaseHttpController (`B-WEB/api/BaseHttpController.java:35`), MES AttachmentManager | HttpData/filesystem/DB 저장 | /upload는 로컬 MesUploadController 이름으로 매핑되지 않음 · A/B |
| 인증/권한 문제는? | LoginController (`B-WEB/api/LoginController.java:33`), CorsWebApiFilter (`B-WEB/api/filters/CorsWebApiFilter.java:14`), web.json (`B-RES/config/web.json:29`) | MES LoginImplement/LoginpolicyImplement, SecurityWebFilter (`M-CORE/web/filter/SecurityWebFilter.java:1`) | 토큰·URL/Site/Command/SQL 권한 | 로컬 CORS/실패 commit을 범용 표준으로 복제 금지 · A |
| 설정/기동/패키징 문제는? | [configuration-and-runtime.md](configuration-and-runtime.md), WebServer (`B-WEB/WebServer.java:5`), start.bat (`B-RES/start.bat:1`) | 7개 POM, config/cmos/web/mybatis | Factory + starter + 외부 resources | Java17/11·3.5.2/3.5.1·package/install 차이 · A |

## 5분 탐색 순서

1. 이 질문이 UI 배포물, services Rule, 배터리 core Manager, MES-Core 공통 동작 중 어디에 속하는지 정한다.
2. Rule의 `process()`와 import를 읽어 정확한 인터페이스를 찾는다. 같은 단순 이름의 다른 공정 Manager로 이동하지 않는다.
3. Manager가 위임하는 common Manager/Extension/statement ID까지만 우선 추적한다.
4. 입력 키/첫 header/row-state/상태·이력/외부 효과를 확인한다. 표본 제외 항목은 [extension-patterns-and-invariants.md](extension-patterns-and-invariants.md)에서 대조한다.
5. SQL 또는 실행 문제라면 코드 수정보다 먼저 실제 artifact 버전과 mapper/config 로딩 경로를 확인한다.

이 지도는 전체 파일 목록을 대체하는 작업 질문 중심 색인이다. 없는 생산 Controller/Repository/Entity 유형을 억지로 채우지 않았다.

## Verification

2026-09-09 pull 후 B-RULE/B-SQL/B-WEB/B-RES 참조의 서로 다른 파일 33개가 현재 services·web-ui에 모두 존재함을 확인했다. 이는 파일 존재 확인이며 33개 전체의 의미·줄 번호 동일성 검증은 아니다. 대표 정적 재확인: services/web-ui POM은 3.5.1·Java11, services는 배터리 4개 모듈 3.5.1을 의존한다. web-ui의 dependency copy는 package, 외부 resource copy는 install 단계다. WebServer는 Factory.initialize(args)를 호출한다. SaveRecipeItem은 messageValidation의 키 검사 외 process의 mandatory·기본값 처리 후 IRECIPEITEMManager.save로 위임하며, TrackInLot_Assembly는 공정별 IPRODUCTIONLotManager를 import해 processTrackInAssemblyLot를 호출한다. 추가로 B-COMMON/B-CELL/B-ELECTRODE/B-PACK 참조 파일 18개도 모두 존재함을 확인했다. core 및 4개 child POM의 3.5.2·Java17, assembly/formation/mixing Manager의 CoreManager 직접 상속 및 common 인터페이스로의 위임을 재확인했다. RECIPEITEMManager의 행 상태별 CUD, create의 기존 행 update, update의 DELETE 후 break도 현재 구현에 남아 있다. 이 표본 외 Manager 전체 동작·전체 SQL ID 비교 및 파싱·source map 내용은 이번에 재검증하지 않았다.

원본 근거: `B/.scratch/knowledge-map-review/source-navigation-map.md` (2026-09-09). 원본 문서의 정적 검사 PASS는 실제 배포 JAR·설정·DB·HTTP·브로커·동시성 검증이 아니다. medium confidence와 project 범위를 유지한다. 다른 프로젝트에 적용하려면 같은 호출·설정 계약을 먼저 대조한다.
