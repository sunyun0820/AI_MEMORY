---
id: MEM-20260909-2nd-battery-runtime-and-business-flow
type: project
scope: project
project: 2nd-battery
domain: business-flow
tags: [cmos, request, rule, manager, track-in, bom, iqc]
status: active
confidence: medium
created: 2026-09-09
updated: 2026-09-10
last_seen: 2026-09-09
occurrences: 1
source_agent: codex
---

# 2nd-battery 조회·저장·Track-In·BOM·품질 업무 흐름

## Core Knowledge / Applicability

2026-09-09 기록된 요청 흐름은 웹 설정이 고른 Dispatcher에서 `CoreRule.messageValidation/process`와 Manager로 연결된다. 단순 공통 조회는 프로젝트 Manager를 거치지 않을 수도 있다. 아래는 정적 호출 연결이며 실행 JAR·DB 결과까지 보장하지 않는다.

`LoginController`와 로컬 `BaseController`도 CoreRule이다. Controller라는 이름을 HTTP MVC나 CoreController 계약으로 해석하지 않는다. 로컬 `CoreController + @EventMethodMapping` 표본 `TesterController`는 test용이다. 일반 요청 수명주기는 [C-MOS lifecycle](../cmos-frame/runtime-lifecycle.md), 파일·심볼 위치는 [탐색 지도](source-navigation-map.md)를 따른다.

## 공통 READ

`dashboard-app.js → POST /api(COMMAND=RuleMultiInquiry) → MES-CORE RuleMultiInquiry → FRAME-CORE RuleMultiRepository → 해당 ID의 활성 mapper → DATADIC`.

UI는 SITEID/USERID/APPLICATIONID/LANGUAGE와 WEBDATA의 CLASSID/QUERYID/VERSION·검색 조건을 만든다. 표본은 QUERYID=`SelectRealTimeEquipmentState`, VERSION=`00001`, 보관 SQL의 namespace/id는 `com.thirautech.cmos.mes.SelectRealTimeEquipmentState-00001`이다.

단순 화면 조회에는 별도 Rule/Manager 없이 이 경로를 검토할 수 있지만 query ID·입력·응답 이름·권한을 함께 맞춘다. 이 SQL의 Batch join은 SITEID를 함께 묶지 않아 사이트 분리 표준이 아니다. 보관본이 sql-back에 있으므로 실제 mapper 공급 여부는 [SQL 로딩 경계](persistence-and-query-patterns.md)를 따른다.

## Manager 가공 READ

`SelectProductOrderListForWo → IWORKORDERManager → WORKORDERManager.selectProductOrderListForWo → DbContext.selectList → PivotUtility → setDatadic("SelectProductOrderListForWo",0,dt)`.

Rule이 WEBDATA별 날짜·제품·지시 조건을 추출하고 Manager가 날짜 문자열과 DATEDIFF를 계산한다. 고정 statement는 `com.thirautech.cmos.mes.SelectProductOrderListForWo-00001`이며 SQL 마지막 두 컬럼 `PLANDATE/PLANQTY`가 pivot 축/값이다.

- 컬럼 순서·alias·응답 데이터셋 이름은 함께 변경해야 하는 계약이다.
- Manager는 `dt != null` 뒤 `dt.get(0)`을 사용하므로 0건 안전성의 표본이 아니다.
- 여러 WEBDATA를 순회해도 응답 키/인덱스가 고정이다. 다중 데이터셋 확장에 그대로 복사하지 않는다.
- Manager는 WORKORDERTYPE을 넣지만 보관 SQL은 PRODUCTORDERTYPE을 읽었다. 구조를 재사용할 때 조건명·0건·날짜 경계를 확인한다.

## 행 상태 SAVE

`SaveRecipeItem → IRECIPEITEMManager.save → RECIPEITEMManager.create/update/delete → CommonRepository → CoreRepository/DB/Hist → 요청 commit 호출`.

1. messageValidation은 `_ROW_STATE, SITEID, RECIPEITEMID, RECIPEITEMNAME` 키를 검사한다. process가 Entity 변환·mandatory 값 검사·ISDCOL/ISSETUP/ISSQC 기본 N을 처리한다.
2. Manager는 ADD → UPDATE → DEL 그룹 순으로 실행한다. 입력 배열의 작업 순서를 그대로 따르는 계약이 아니다.
3. create는 RECIPEITEMID+SITEID로 기존 행을 찾아 update하거나, 신규에 common-data를 설정해 create(list,true)로 보낸다.
4. update는 존재 검사 뒤 DELETE/UNDELETE/UPDATE로 분기하고 delete는 논리 삭제다. **update의 DELETE 뒤 break는 후속 행 처리를 종료한다.**
5. 이 Rule/Manager에는 직접 commit이 없고 bool=true는 이력 정책이다. commit 호출과 실제 DB 성공은 별개다.

저장 의미·불완전한 upsert 반례·이력 count는 [영속 계약](persistence-and-query-patterns.md)과 [확장 시 주의](extension-patterns-and-invariants.md)를 함께 본다.

## Assembly Track-In

`PM_CL_002.vue:LotProcess START → TrackInLot_Assembly → assembly IPRODUCTIONLotManager 구현 → common PRODUCTIONLotManager → ProductionExtension → LotTracking/OptionSet → Repository·이력`.

source map의 UI는 `DATALIST:{LOTLIST:[{LOTID:...}]}`를 만들고 TrackInLot_Assembly를 선택했다. Rule은 WEBDATA 첫 Equipment를 header로 삼아 DATALIST.LOTLIST에 SITEID/EQUIPMENTID를 넣는다. 공정 Manager는 common Manager로 위임한다.

common 흐름은 현재 Lot 재조회 → 같은 PROCESSNODEID·WAITFORRULE·허용 상태·설비-공정 관계 검사 → 첫 Lot Batch의 FINISHED 여부와 설비 BATCHID 일치 검사 → 공정별 Recipe 검사/갱신·SQC → 실제 Track-In으로 연결된다. 최초 CREATED이면 startLot 후 재조회하고 설비/Recipe·공통 추적값을 설정한다. MES-Core는 tracking history/worktime 옵션을 적용한다.

행 상태만 UPDATE하면 같은 효과를 얻지 못한다. 첫 원소를 사용하는 Batch/Site/상태 분기는 목록 전체의 동질성 검사가 아니다. 같은 node 검사만으로 혼합 Site/Batch/CREATED·ACTIVE 목록까지 거부된다고 확대하지 않는다.

## 전체 교체 BOM

`SaveBom → BOMManager`: DEL 제외·중복 검사 → 첫 행 Product/Site의 기존 BOM 전체 물리 삭제 → 남은 행에 `PRODUCTDEFINITIONID.순번` BOMID 재생성 → INSERT·이력 count 검사.

`BOM.vue:paramData2Helper`는 getGridData() 전체와 삭제행 표시를 전송한다. dirty-row만 보내면 나머지 보존을 기대할 수 없다. 반대로 빈 목록은 Rule에서 return하므로 빈 리스트=전체 삭제도 성립하지 않는다. 단일 Product/Site와 재정렬 시 ID 변경, 전체 삭제는 각각 검증한다.

## IQC 품질 연쇄

`RequestInspection`의 조사본 switch는 IQC만 처리하고 default는 작업하지 않았다. QUALITYManager는 활성 검사정의 → 자재·기존 검사 확인 → 검사요청/대상 생성 → 구매 품목 검사 상태 → MATERIALManagerQuality의 IQC 자재 처리를 연결한다.

저장 순서는 **Inspreqlot 목록 → Inspreq**였다. Header-first 일반론으로 바꾸거나 QMS 테이블만 갱신하면 같은 업무라고 해석하지 않는다. 해당 저장 순서의 DB 제약 적합성은 기록된 정적 연결과 별개다.

## Evidence

2026-09-09 `.scratch/knowledge-map-review/runtime-and-business-flow.md`와 메모리에 기록된 SaveRecipeItem·TrackInLot_Assembly 대표 호출 확인에 근거한다. UI 증거는 source map의 원본 내용이다. 실제 HTTP·서버·DB commit·동시성 검증 기록으로 사용하지 않는다.
