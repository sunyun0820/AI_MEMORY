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
updated: 2026-09-09
last_seen: 2026-09-09
occurrences: 1
source_agent: codex
---

# 2nd-battery · Extension Patterns & Invariants

각 항목의 Core Knowledge는 프로젝트 사용 지식이다. **코드가 직접 강제하는 조건**, **호출자가 지켜야 하지만 완전히 검사되지 않는 전제**, **복사하면 안 되는 관찰된 코드**를 구분한다. A=프로젝트 전용, B=조건부 재사용 패턴. 모든 검증은 정적이며 운영 불변성을 주장하지 않는다.

## 1. Block 인터페이스와 구현 선택 [B]

- **Core Knowledge:** core의 모든 Manager 인터페이스/구현은 BlockController/BlockModule 쌍이다. 공정별 동명 인터페이스는 별개의 FQCN이고 공통 Manager로 위임한다.
- **Applicability:** 이 배터리 서비스 블록 구조를 사용하는 확장/모듈 교체 작업.
- **Avoid:** 같은 이름의 common 인터페이스로 import를 잘못 바꾸지 않는다. “Factory는 단일 구현체만 허용하므로 Block도 복수 구현 불가”라고 일반화하지 않는다.
- **Verification:** [IRECIPEITEMManager](<E:/0.Project/mes-package/2nd-battery/core/common-services/src/main/java/com/thirautech/cmos/mes/packages/interfaces/common/masterdata/IRECIPEITEMManager.java:9>), [PRODUCTIONLotManager · cell/production/assembly](<E:/0.Project/mes-package/2nd-battery/core/cell-services/src/main/java/com/thirautech/cmos/mes/packages/service/cell/production/assembly/PRODUCTIONLotManager.java:73>), [PRODUCTIONLotManager · cell/production/formation](<E:/0.Project/mes-package/2nd-battery/core/cell-services/src/main/java/com/thirautech/cmos/mes/packages/service/cell/production/formation/PRODUCTIONLotManager.java:22>), [PRODUCTIONLotManager · electrode/production/mixing](<E:/0.Project/mes-package/2nd-battery/core/electrode-services/src/main/java/com/thirautech/cmos/mes/packages/service/electrode/production/mixing/PRODUCTIONLotManager.java:40>) 및 전체 62쌍 선언 확인. 인접 [ClassInfo.getBlockModuleClass](<E:/0.Project/cmos-frame/iia/src/main/java/com/thirautech/cmos/framework/iia/classes/entity/ClassInfo.java:345>)는 후보가 여러 개면 version 내림차순으로 선택한다. 동일 version 동률 선택/배포 JAR 동작은 미검증. 새 override의 활성화는 실제 버전과 block config를 다시 확인한다. `block.json` 본문 예시는 모두 주석이다.

## 2. messageValidation은 값 전체 검증과 같지 않다 [B]

- **Core Knowledge:** 프로젝트는 `webDataMessage(...)` 후 process의 `entity.mandatory(...)`를 반복 사용한다. 전자는 key 존재, 후자는 업무 입력값을 확인하는 역할로 나뉜다. `webDataCheck`는 빈 값까지 보는 별도 경로다.
- **Applicability:** 신규 Rule, 기존 messageValidation 변경.
- **Avoid:** 키 검사만 남기고 process 검증을 제거하지 않는다. “검증은 messageValidation에서 전부 끝난다”는 가정도 틀리다. 빈 WEBDATA와 빈 DATALIST 하위 목록을 같은 것으로 취급하지 않는다.
- **Verification:** [SaveRecipeItem](<E:/0.Project/mes-package/2nd-battery/services/src/main/java/com/thirautech/cmos/mes/packages/business/common/masterdata/SaveRecipeItem.java:13>), [TrackInLot_Assembly](<E:/0.Project/mes-package/2nd-battery/services/src/main/java/com/thirautech/cmos/mes/packages/business/cell/production/assembly/TrackInLot_Assembly.java:43>), [RequestInspection](<E:/0.Project/mes-package/2nd-battery/services/src/main/java/com/thirautech/cmos/mes/packages/business/common/quality/RequestInspection.java:15>) + 연결 계약 [CoreRule](<E:/0.Project/cmos-frame/core/src/main/java/com/thirautech/cmos/mes/core/abstracts/business/CoreRule.java:188>). 메시지 파싱 runtime은 미실행.

## 3. DATALIST와 첫 header 전제 [B 구조 / A 필드]

- **Core Knowledge:** `getWebdataList(Lot.class,0,LOTLIST,...)`는 WEBDATA[0].DATALIST.LOTLIST를 읽는다. Rule이 첫 Equipment의 SITEID/EQUIPMENTID를 자식에 넣는다.
- **Applicability:** Lot/Carrier/검사 요청의 header-detail 확장.
- **Avoid:** LOTLIST를 WEBDATA의 직접 필드로 평탄화하지 않는다. header를 여러 개 받아도 모두 처리한다고 가정하지 않는다. 혼합 Site/설비 목록을 묶으려면 계약부터 바꿔야 한다.
- **Verification:** [TrackInLot_Assembly](<E:/0.Project/mes-package/2nd-battery/services/src/main/java/com/thirautech/cmos/mes/packages/business/cell/production/assembly/TrackInLot_Assembly.java:43>), [LotStartReport](<E:/0.Project/mes-package/2nd-battery/services/src/main/java/com/thirautech/cmos/mes/packages/business/common/eis/LotStartReport.java:53>), [CoreRule](<E:/0.Project/cmos-frame/core/src/main/java/com/thirautech/cmos/mes/core/abstracts/business/CoreRule.java:118>), [PM_CL_002-NJaZFJa6.js.map](<E:/0.Project/mes-package/2nd-battery/web-ui/src/main/resources/wwwroot/assets/PM_CL_002-NJaZFJa6.js.map:1>). 품질은 별도 INSPREQLOTLIST를 사용하므로 자식명을 그대로 복사하지 않는다.

## 4. 저장 의미는 각 Manager별로 다르다 [A/B]

- **Core Knowledge:** RecipeItem.save는 ADD→UPDATE→DEL 그룹, ProductWorkOrderRel.save는 ADD→UPDATE→REALDEL 그룹, BOM.save는 전체 교체다.
- **Applicability:** 신규 SAVE/삭제 버튼, 공통 grid save helper 변경.
- **Avoid:** 모든 SAVE가 upsert 한 종류이거나 모든 D가 물리 삭제라는 가정을 피한다. UI row-state와 RequestType은 별도 변환 단계다.
- **Verification:** [RECIPEITEMManager · common/masterdata](<E:/0.Project/mes-package/2nd-battery/core/common-services/src/main/java/com/thirautech/cmos/mes/packages/service/common/masterdata/RECIPEITEMManager.java:61>), [PRODUCTWORKORDERRELManager · common/masterdata](<E:/0.Project/mes-package/2nd-battery/core/common-services/src/main/java/com/thirautech/cmos/mes/packages/service/common/masterdata/PRODUCTWORKORDERRELManager.java:53>), [BOMManager · common/masterdata](<E:/0.Project/mes-package/2nd-battery/core/common-services/src/main/java/com/thirautech/cmos/mes/packages/service/common/masterdata/BOMManager.java:60>). [PRODUCTWORKORDERRELManager · common/masterdata](<E:/0.Project/mes-package/2nd-battery/core/common-services/src/main/java/com/thirautech/cmos/mes/packages/service/common/masterdata/PRODUCTWORKORDERRELManager.java:272>)의 실제 메서드만 물리삭제 좁은 표본으로 추천한다. 전체 Manager를 검증된 upsert 템플릿으로 채택하지 않는다.

## 5. BOM은 Product/Site 단위 전체 스냅샷 [A]

- **Core Knowledge:** 첫 행 기준 기존 BOM을 모두 삭제하고 DEL 아닌 목록에 PRODUCTDEFINITIONID.순번 형태 BOMID를 다시 부여한다. UI가 전체 grid를 전송한다.
- **Applicability:** BOM 화면 저장/삭제, 데이터 마이그레이션, 부분 수정 API.
- **Avoid:** 변경 행만 보내면 나머지 행이 보존된다는 가정을 금지한다. 단일 Product/Site 전제는 코드 전체에서 완전히 검사된 불변조건이 아니다. mixed scope/빈 목록/전체 삭제/재정렬 시 ID 변경을 명시적으로 검증한다.
- **Verification:** [BOMManager · common/masterdata](<E:/0.Project/mes-package/2nd-battery/core/common-services/src/main/java/com/thirautech/cmos/mes/packages/service/common/masterdata/BOMManager.java:60>)의 saveBom/deleteBom/generateBomId, [BOM-aAsZ1en0.js.map](<E:/0.Project/mes-package/2nd-battery/web-ui/src/main/resources/wwwroot/assets/BOM-aAsZ1en0.js.map:1>) 원본 내용의 getGridData. DB 결과는 미검증.

## 6. Lot Track-In은 상태 컬럼 변경보다 넓다 [A 정책 / B 조합]

- **Core Knowledge:** 현재 Lot 재조회, 같은 node, WAITFORRULE, 허용 Lot 상태, 설비-공정/배치 일치, Recipe/SQC 처리 뒤 Core startLot/trackInLot을 호출한다.
- **Applicability:** 수동 생산 시작, 설비 보고 시작, 공정별 변경.
- **Avoid:** 공정 wrapper만 보고 “검증 없음”으로 결론내리지 않는다. common 정책을 바꾸면 assembly/formation/mixing 등의 호출자를 함께 확인한다. 불변조건으로 강제된 것은 해당 메서드의 검사 범위뿐이다. 동일 Batch/Site/상태가 모두 보장된다고 확장하지 않는다.
- **Verification:** [PRODUCTIONLotManager · common/production](<E:/0.Project/mes-package/2nd-battery/core/common-services/src/main/java/com/thirautech/cmos/mes/packages/service/common/production/PRODUCTIONLotManager.java:1877>), [PRODUCTIONLotManager · common/production](<E:/0.Project/mes-package/2nd-battery/core/common-services/src/main/java/com/thirautech/cmos/mes/packages/service/common/production/PRODUCTIONLotManager.java:1997>), [PRODUCTIONLotManager · common/production](<E:/0.Project/mes-package/2nd-battery/core/common-services/src/main/java/com/thirautech/cmos/mes/packages/service/common/production/PRODUCTIONLotManager.java:2798>), [PRODUCTIONLotManager · cell/production/assembly](<E:/0.Project/mes-package/2nd-battery/core/cell-services/src/main/java/com/thirautech/cmos/mes/packages/service/cell/production/assembly/PRODUCTIONLotManager.java:73>), [PRODUCTIONLotManager · cell/production/formation](<E:/0.Project/mes-package/2nd-battery/core/cell-services/src/main/java/com/thirautech/cmos/mes/packages/service/cell/production/formation/PRODUCTIONLotManager.java:22>). DB 내부 lock/옵션 후속 동작은 선택된 인접 Core 연결만 확인.

## 7. 상태 전이는 Core 정의와 저장 업무를 함께 본다 [B]

- **Core Knowledge:** WorkOrder confirm은 Created 대상 재조회 → checkStateTransition(model,current,target,site) → common-data → PlanExtension.changeWorkOrderState로 진행한다.
- **Applicability:** 확정/확정취소/종료/종료취소.
- **Avoid:** 상태 문자열 setter만 추가하지 않는다. UI가 넘긴 state를 DB 현재 state 대신 신뢰하지 않는다. 상태 모델의 DB 설정까지 검증했다고 주장하지 않는다.
- **Verification:** [WORKORDERManager · common/plan](<E:/0.Project/mes-package/2nd-battery/core/common-services/src/main/java/com/thirautech/cmos/mes/packages/service/common/plan/WORKORDERManager.java:597>), [CoreManager](<E:/0.Project/cmos-frame/core/src/main/java/com/thirautech/cmos/mes/core/abstracts/business/CoreManager.java:22>). 다른 경로인 [DELIVERYORDERManager · pack/plan](<E:/0.Project/mes-package/2nd-battery/core/pack-services/src/main/java/com/thirautech/cmos/mes/packages/service/pack/plan/DELIVERYORDERManager.java:229>)의 checkStateTransition 네 번째 인자는 SITEID 자리에 getState()를 전달한다. 이 코드는 상태 전이 표본에서 제외한다(정적 인자 불일치, 운영 재현 없음).

## 8. Recipe 활성화/버전은 연결 데이터도 변경한다 [A]

- **Core Knowledge:** saveRecipe는 동일 계열 최대 버전인지 검사하고 기존 active 일부를 hold, 선택 항목 active, ProcessDataParameter/TraceDataParameter INSERT를 수행한다. 새 버전은 Recipeparameter/Mbom 복사를 동반한다.
- **Applicability:** ActiveRecipeDefinition, 버전 추가, 복사 기능.
- **Avoid:** STATE만 수정하면 활성화 완료라고 보지 않는다. holdRecipe는 첫 active만 처리하므로 DB에 active가 오직 하나라는 사실을 이 코드만으로 입증하지 않는다. Recipe 작업이 항상 해당 SITEID만 쓴다는 주장도 [InsertTraceDataParameter4RecipeActive_THiRAMES.Service.Biz_00001_sql.xml](<E:/0.Project/mes-package/2nd-battery/services/src/main/resources/sql-back/mssql/storedquery/InsertTraceDataParameter4RecipeActive_THiRAMES.Service.Biz_00001_sql.xml:4>) 때문에 부적절하다.
- **Verification:** [RECIPEDEFINITIONManager · common/masterdata](<E:/0.Project/mes-package/2nd-battery/core/common-services/src/main/java/com/thirautech/cmos/mes/packages/service/common/masterdata/RECIPEDEFINITIONManager.java:64>), [RECIPEDEFINITIONManager · common/masterdata](<E:/0.Project/mes-package/2nd-battery/core/common-services/src/main/java/com/thirautech/cmos/mes/packages/service/common/masterdata/RECIPEDEFINITIONManager.java:265>), [InsertTraceDataParameter4RecipeActive_THiRAMES.Service.Biz_00001_sql.xml](<E:/0.Project/mes-package/2nd-battery/services/src/main/resources/sql-back/mssql/storedquery/InsertTraceDataParameter4RecipeActive_THiRAMES.Service.Biz_00001_sql.xml:4>). SQL provider/실행 범위는 미검증.

## 9. 품질 Header/Detail 저장은 자재/구매까지 연결된다 [A]

- **Core Knowledge:** IQC 검사요청은 활성 검사정의와 대상 자재 검증 후 검사요청/대상을 생성하고 구매 품목 및 자재 검사 관계를 갱신한다.
- **Applicability:** RequestInspection/검사 취소/상태 변경.
- **Avoid:** QMS 테이블만 수정하면 완료라는 가정, 이름이 일반적인 RequestInspection이 모든 INSPTYPE을 처리한다는 가정. 현재 default 분기는 작업하지 않는다.
- **Verification:** [RequestInspection](<E:/0.Project/mes-package/2nd-battery/services/src/main/java/com/thirautech/cmos/mes/packages/business/common/quality/RequestInspection.java:15>), [QUALITYManager · common/quality](<E:/0.Project/mes-package/2nd-battery/core/common-services/src/main/java/com/thirautech/cmos/mes/packages/service/common/quality/QUALITYManager.java:110>), [MATERIALManagerQuality · common/material](<E:/0.Project/mes-package/2nd-battery/core/common-services/src/main/java/com/thirautech/cmos/mes/packages/service/common/material/MATERIALManagerQuality.java:24>). 실제 create는 [QUALITYManager · common/quality](<E:/0.Project/mes-package/2nd-battery/core/common-services/src/main/java/com/thirautech/cmos/mes/packages/service/common/quality/QUALITYManager.java:10538>)에서 detail→header다. 이 순서의 DB FK 적합성은 미검증이다.

## 10. ID 생성의 인자 순서는 업무 의미다 [A]

- **Core Knowledge:** Lot ID 입력은 LotCreateType에 따라 batch, materiallot, cut/lane, site/line/product shortname, calendar-year code/day-of-year, workorder type/shift 등으로 달라진다. Core IdPattern 기능을 쓰더라도 프로젝트가 조합을 정한다.
- **Applicability:** 신규 공정/LotID/BoxID 정책.
- **Avoid:** 예제 문자 조합을 C-MOS 공통 ID 규칙으로 승격하지 않는다. 달력/코드/라인/설비 기준정보 의존성을 누락하지 않는다. 발급의 동시성 보장은 별도 Core 계약 확인 사항이다.
- **Verification:** [PRODUCTIONLotManager · common/production](<E:/0.Project/mes-package/2nd-battery/core/common-services/src/main/java/com/thirautech/cmos/mes/packages/service/common/production/PRODUCTIONLotManager.java:750>), [PRODUCTIONLotManager · common/production](<E:/0.Project/mes-package/2nd-battery/core/common-services/src/main/java/com/thirautech/cmos/mes/packages/service/common/production/PRODUCTIONLotManager.java:183>). ID pattern DB 정의와 동시 발급은 미검증.

## 11. 이력 flag / count / Bulk 컬럼은 함께 바뀐다 [B]

- **Core Knowledge:** BOM은 true 이력 CUD와 size×2 count 검사를 결합한다. 포장 Bulk는 LotUpsert.bulkColumnList를 명시한다.
- **Applicability:** 이력 최적화, bulk 전환, 저장 필드 추가.
- **Avoid:** true를 commit 옵션으로 읽지 않는다. Hist 생략만 바꾸고 기대 count를 유지하지 않는다. setter를 추가한 것으로 bulk 저장 필드가 늘어난다고 가정하지 않는다.
- **Verification:** [BOMManager · common/masterdata](<E:/0.Project/mes-package/2nd-battery/core/common-services/src/main/java/com/thirautech/cmos/mes/packages/service/common/masterdata/BOMManager.java:60>), [PRODUCTIONPackingManager · pack/production/logic](<E:/0.Project/mes-package/2nd-battery/core/pack-services/src/main/java/com/thirautech/cmos/mes/packages/service/pack/production/logic/PRODUCTIONPackingManager.java:120>). [MATERIALManager · common/material](<E:/0.Project/mes-package/2nd-battery/core/common-services/src/main/java/com/thirautech/cmos/mes/packages/service/common/material/MATERIALManager.java:7322>)는 실제 false와 인자 기반 기대 count가 다른 반례다.

## 12. 외부 효과/실패 저장의 transaction 경계 [A]

- **Core Knowledge:** 로그인 실패는 명시 commit 뒤 예외. MCS는 Manager 실행 중 sendKafka. 파일은 먼저 쓰고 Attachment 생성 실패 시 파일 정리를 시도한다.
- **Applicability:** 인증 장애, 메시지 중복, 파일 잔존, 롤백 문제.
- **Avoid:** Dispatcher가 exception을 잡으면 모든 효과가 사라진다는 가정을 금지한다. 반대로 MCS 성공/중복방지/파일 보상 완료도 정적 코드만으로 보장하지 않는다.
- **Verification:** [LoginController](<E:/0.Project/mes-package/2nd-battery/web-ui/src/main/java/com/thirautech/cmos/web/api/LoginController.java:74>), [MCSManager · electrode/mcs](<E:/0.Project/mes-package/2nd-battery/core/electrode-services/src/main/java/com/thirautech/cmos/mes/packages/service/electrode/mcs/MCSManager.java:1921>), [MesUploadController](<E:/0.Project/mes-package/2nd-battery/web-ui/src/main/java/com/thirautech/cmos/web/api/MesUploadController.java:17>), [DbContext](<E:/0.Project/cmos-frame/core/src/main/java/com/thirautech/cmos/mes/core/common/business/DbContext.java:300>). 송수신/브로커/실패 주입은 미실행.

## 표본에서 제외하거나 조건을 붙인 코드

| 관찰 | 왜 위험한 표본인가 | 근거/검증 |
|---|---|---|
| SelectPackingProductOrderList → processCancelActiveDeliveryOrder | 조회 이름이 업무 변경을 숨김 | [SelectPackingProductOrderList](<E:/0.Project/mes-package/2nd-battery/services/src/main/java/com/thirautech/cmos/mes/packages/business/pack/plan/SelectPackingProductOrderList.java:10>): 직접 호출 확인 |
| RecipeItem.update의 DELETE 분기 break | 다중 행 중 뒤쪽 처리가 종료될 수 있음 | [RECIPEITEMManager · common/masterdata](<E:/0.Project/mes-package/2nd-battery/core/common-services/src/main/java/com/thirautech/cmos/mes/packages/service/common/masterdata/RECIPEITEMManager.java:61>) update 158행 부근: 직접 확인 |
| ProductWorkOrderRel.create의 기존 행 update 후 create 목록에도 추가 | 일반 upsert 표본으로 복사하면 UPDATE+CREATE가 이어짐 | [PRODUCTWORKORDERRELManager · common/masterdata](<E:/0.Project/mes-package/2nd-battery/core/common-services/src/main/java/com/thirautech/cmos/mes/packages/service/common/masterdata/PRODUCTWORKORDERRELManager.java:53>) create 129행 부근: 직접 확인 |
| MaterialInterface upsert false / count는 saveHist 인자 | true 호출 시 기대행 수 불일치 가능 | [MATERIALManager · common/material](<E:/0.Project/mes-package/2nd-battery/core/common-services/src/main/java/com/thirautech/cmos/mes/packages/service/common/material/MATERIALManager.java:7322>): 직접 확인 |
| 계획 조회에서 null만 검사 후 get(0) | 0건 결과를 안전하게 처리하는 표본이 아님 | [WORKORDERManager · common/plan](<E:/0.Project/mes-package/2nd-battery/core/common-services/src/main/java/com/thirautech/cmos/mes/packages/service/common/plan/WORKORDERManager.java:1616>), [PRODUCTORDERManager · common/plan](<E:/0.Project/mes-package/2nd-battery/core/common-services/src/main/java/com/thirautech/cmos/mes/packages/service/common/plan/PRODUCTORDERManager.java:239>): 직접 확인 |
| sql-back의 전체 mapper 활성화 | 중복 ID/DBMS 차이/직접 INSERT까지 유입 | [persistence-and-query-patterns.md](<E:/AI/AI_MEMORY/memory/projects/2nd-battery/persistence-and-query-patterns.md:1>): 전체 XML 정적 조사 |

위 항목은 이번에 고친 결함 목록이 아니라 미래 Agent의 오판 방지 지식이다. 수정, DB 재현, 운영 영향 확정은 수행하지 않았다.

## Context

2026-09-09 작성된 2nd-battery Knowledge Map 검토 문서를 사용자 요청에 따라 프로젝트 메모리로 반영했다. 본문의 현재 상태, 확인 및 미실행 표현은 해당 검토일의 정적 조사 기록을 가리킨다. 저장 시 프로젝트 소스를 재분석하지 않았다.

## Verification

- 근거: [원본 검토 문서](<E:/0.Project/mes-package/2nd-battery/.scratch/knowledge-map-review/extension-patterns-and-invariants.md:1>).
- 원본 verification.json은 문서 8개 및 링크 321회에 대한 문서 정적 검사 PASS를 기록한다. 이 결과는 기존 검토 기록이며 이번 저장에서 소스 검증을 재수행한 결과가 아니다.
- 본 메모리의 근거는 검토 문서다. 실제 의존 JAR, 배포 설정, DB, 서버, HTTP, 브로커, 파일 업로드 및 동시성 동작은 검증되지 않았다.
- source 및 line 링크는 검토 당시 탐색 단서다. 이후 변경 작업에서는 필요한 범위의 현재 코드와 비교한다. A는 프로젝트 전용, B는 조건부 재사용이며 전역 rule로 승격하지 않는다.
