---
id: MEM-20260908-registapiauth-widget-command-objectid
type: project
scope: project
project: RegistApiAuth
domain: API authorization registration
tags: [CIM_MENU, CIM_MENUOBJECT, CIM_WIDGET, GRIDPROPERTY, SEARCHFILTER, PROCESSTRAN, COMMAND, QUERYID, OBJECTID, VIEWID]
status: active
confidence: high
created: 2026-09-08
updated: 2026-09-08
last_seen: 2026-09-08
occurrences: 1
source_agent: Codex
---

# RegistApiAuth 위젯·command·objectid 연결 규칙

## Context

`RegistApiAuth`는 `CIM_MENU`, `CIM_MENUOBJECT`, `CIM_WIDGET`와 화면 HTML/JS를 함께 분석해 `CIM_APIAUTHMAP` 후보를 만든다. 메뉴 식별자와 화면 소스, 위젯 메타데이터의 연결이 어긋나면 READ는 일부 남고 SAVE/objectid 매핑만 누락되므로, 위젯 단위의 모든 API 발생 지점을 보존해야 한다.

## Symptom

`CIM_WIDGET.GRIDPROPERTY`의 첫 번째 `actionId`만 보거나 `WIDGETID`를 `MENUID`와 직접 연결하면, 같은 화면의 후속 위젯·버튼 command·검색필터 조회가 빠진다. 특히 `VIEWID=WUIXX004.html`인데 `WIDGETID=WUIXX0041`처럼 숫자 접미사가 붙는 구조를 잘못 해석하면 위젯을 찾지 못한다.

## Root Cause

- 화면의 기준 키는 `CIM_MENU.SITEID + MENUCLASSID + MENUID + VIEWID`이며, 파일 매칭은 `VIEWID`의 `.html` 경로를 기준으로 한다. `MENUID`는 위젯 파일/ID 검색 키가 아니다.
- 한 화면에는 `VIEWID` basename 뒤에 숫자 접미사가 붙은 여러 `CIM_WIDGET.WIDGETID`가 존재할 수 있다. 소스에서 발견한 위젯 인덱스와 DB의 numeric suffix를 합쳐 모든 위젯을 순회해야 한다.
- `CIM_MENUOBJECT.OBJECTNAME`은 허용 여부를 결정하는 필터가 아니다. object와 연결된 command가 있으면 `ADDROW`, `ROWDELETE`, `Btn_WOConfirm` 등 이름과 관계없이 대상이다.

## Wrong Approach

- `WIDGETID`를 `MENUID` 또는 잘린 prefix로 조회해 하나의 위젯만 선택하는 것.
- `GRIDPROPERTY`의 첫 `actionId`만 읽거나 `SEARCHFILTER`를 생략하는 것.
- READ/조회 command를 SAVE command로 오인해 READ row에 objectid를 넣는 것.
- `OBJECTNAME`을 기준으로 버튼을 제외하거나, 소스에 objectid가 없다는 이유로 SAVE 후보를 버리는 것.

## Correct Approach

1. `CIM_MENU.VIEWID`를 `view/<...>.html` 및 실제 `webRoot/view` 파일에 매칭한다. 같은 basename의 JS와 HTML의 `<script src>`도 함께 분석한다.
2. 해당 화면 basename에 숫자 suffix가 붙은 모든 `CIM_WIDGET`을 수집한다. `SITEID`와 설정된 `PRODUCT`도 키에 포함한다.
3. 각 위젯의 `GRIDPROPERTY` JSON을 재귀 순회해 모든 `actionId`를 찾는다.
   - slash 없는 조회 action은 READ로 해석한다.
   - `saveAction/readAction` 형태의 slash action은 양쪽을 모두 만든다. 예를 들어 `MD_UserSave_Cryto/MES$RuleMultiInquiryByCrypto$...$CDS_UserList_100$00001`은 `MD_UserSave_Cryto` SAVE 1건과 `RuleMultiInquiryByCrypto` + `CDS_UserList_100` READ 1건이다.
   - 조회 row는 `OBJECTID=NULL`, `QUERYID`는 버전 suffix가 아닌 query 단위로 저장한다. SAVE row는 `QUERYID=NULL`이고 command와 objectid를 저장한다.
4. 각 위젯의 `SEARCHFILTER` JSON도 재귀 순회해 모든 `dropDown`을 READ로 등록한다. 예를 들어 `THiRA.MES.Modeler$RuleMultiInquiry$THiRA.MES.Modeler$CBO_CommonCodeList$00001?...`은 command `RuleMultiInquiry`, queryId `CBO_CommonCodeList`로 등록한다. URL query parameter는 권한 키의 queryId가 아니다.
5. 각 위젯의 `PROCESSTRAN` JSON에서 모든 map의 `dataField`와 `dropDown`을 읽는다. `dropDown`의 쉼표 구분 항목을 각각 처리하고, `#R/#C/#D/#U` 요청 타입을 반영한다. `dataField`가 있으면 widget index를 붙인 objectid를 사용한다.
6. 화면 HTML/JS의 `ngsWidget.ajax`·`ngsUtil.ajax`, raw `COMMAND`/`QUERYID` 객체와 helper 호출도 분석한다.
   - READ는 queryId 권한이 핵심이므로 objectid를 연결하지 않는다.
   - SAVE는 click/on/addEventListener/onclick 및 delegated event의 대상 DOM id를 enclosing event 범위에서 찾아 objectid로 연결한다. 함수 호출로 위임된 경우 호출 관계를 따라 같은 objectid를 전파한다.
7. SAVE objectid는 `CIM_MENUOBJECT`의 `(SITEID, MENUCLASSID, MENUID, OBJECTID)`와 대조한다. 소스 command가 있으면 `OBJECTNAME` 값은 검사하지 않는다.
   - 메타데이터에 object가 없더라도 후보를 버리지 않고 등록 가능한 형태로 남긴다. 후보 comments에는 `CIM_MENUOBJECT 등록 필요`를 남기고, 위젯 저장 command의 경우 결정적인 `upsertBtn{widgetIndex}` 같은 fallback objectid를 사용한다.
   - 소스 이벤트 범위에서 objectid 자체를 찾지 못한 `NO_MENU_OBJECT_MATCH`도 누락시키지 말고 해당 사유를 comments/diagnostics에 보존한 등록 후보로 취급한다.
8. command 또는 queryId가 조건식·템플릿·helper 매개변수에서 유한한 여러 값으로 조합되면 가능한 결과를 모두 별도 row로 등록한다. 같은 objectid에 command가 2~3개 나오면 모두 SAVE row로 만든다. comments에는 각각 `DYNAMIC_COMMAND`, `DYNAMIC_QUERYID`를 기록하고 둘 다 동적이면 두 사유를 함께 기록한다.
9. `webRoot/index.html`, `index.js`와 공통 framework 조회는 메뉴 키 없이 `AUTHTYPE=SYSTEM`, `TYPE=READ`로 등록한다. SYSTEM row에는 `MENUCLASSID`, `MENUID`, `OBJECTID`를 넣지 않는다.

## Reusable Rule

위젯 권한 수집은 `VIEWID → VIEW basename + numeric widget suffix → CIM_WIDGET의 GRIDPROPERTY/SEARCHFILTER/PROCESSTRAN + 화면 이벤트` 순서로 전부 수행한다. READ는 command/queryId 단위, SAVE는 command/objectid 단위로 만들며, objectid는 이벤트 DOM id와 `CIM_MENUOBJECT`를 연결하되 `OBJECTNAME`으로 제외하지 않는다.

## Verification

현재 `RegistApiAuth` README와 `GenerationEngine`/`NgsSourceAdapter` 구현을 대조했고, `RegistrarSelfTest`에서 slash action의 양쪽 분해, 다중 위젯, GRIDPROPERTY SAVE/READ, SEARCHFILTER READ, 동적 command/queryId, metadata 없는 SAVE fallback, SYSTEM index READ를 포함한 21개 assertion이 통과했다.
