---
id: MEM-20260910-webui20-legacy-vue-migration-contracts
type: project
scope: project
project: WEBUI20
domain: legacy-ui-migration
tags: [WEBUI20, legacy-ui, vue3, migration, CIM_MENU, CIM_WIDGET, CIM_UIPAGE, CIM_UICOMPONENT, page-config]
status: active
confidence: high
created: 2026-09-10
updated: 2026-09-10
last_seen: 2026-09-10
occurrences: 1
source_agent: cursor
---

# Legacy → Vue Migration Contract

## Core Knowledge

1. **마이그레이션 관계 그래프**  
   `CIM_MENU.VIEWID → Legacy HTML/JS → 전체 CIM_WIDGET → Vue 화면 → CIM_UIPAGE/UICOMPONENT → actionId → command/query`를 하나의 계약으로 보존한다.

2. **화면 단위와 식별자**  
   `MENUID` 수와 실제 화면 수는 1:1이 아니다. 고유 `VIEWID`를 화면 단위로 삼고 `VIEWID ↔ Vue route ↔ Vue PAGE_ID ↔ fetchPageConfig PAGE_ID ↔ page-id ↔ CIM_UIPAGE.PAGE_ID`를 일치시킨다. runtime `SITEID·PRODUCT`도 함께 검증하며, 각 `ele-id`는 동일 PAGE의 `CIM_UICOMPONENT.ELE_ID`와 일치해야 한다.

3. **메뉴 연결**  
   `VIEWID → Vue route → 사용자 menu/tab` 연결을 확인한다. Vue 파일이나 PAGE 메타데이터만 존재해서는 실행 가능한 화면으로 판단하지 않는다.

4. **Widget 수집과 유효성**  
   Widget은 `MENUID`가 아니라 `VIEWID` basename과 숫자 suffix로 전부 수집한다. DB Widget, Legacy HTML의 실제 DOM, JS 이벤트·호출을 교차 검증하여 사용 Widget과 고아 메타데이터를 구분한다.

5. **Widget 분해**  
   Widget 하나는 여러 UI 2.0 Component로 분해될 수 있다. `SEARCHFILTER`는 Filter, `GRIDPROPERTY`는 Grid, `COLUMNPROPERTY·INDEXCOLUMN`은 Column·key·editor, dropdown은 조회 의존성, `PROCESSTRAN`은 Grid 간 이벤트, 저장 command/object는 Button으로 옮긴다. Widget과 Component를 1:1로 가정하지 않는다.

6. **Component와 Grid 식별자**  
   `Widget suffix ↔ Legacy gridN ↔ Vue ele-id="gridN" ↔ UICOMPONENT.ELE_ID ↔ gridRefN`의 의미를 보존한다. 중간 Grid가 없더라도 번호를 압축하거나 재배치하지 않는다.

7. **Filter·Grid·Column·Dropdown 계약**  
   Filter는 `SEARCHFILTER.dataField ↔ ele-id ↔ queryForm ↔ UICOMPONENT`, Grid는 `GRIDPROPERTY ↔ Vue Grid ↔ GRID_PROPERTY`, Column/key는 `COLUMNPROPERTY·INDEXCOLUMN ↔ COLUMN_PROPERTY`로 대조한다. dropdown은 `SEARCHFILTER·COLUMNPROPERTY·INDEXCOLUMN·PROCESSTRAN` 전체에서 조사하고 각 `action·queryId·version·params` 연결을 검증한다. 숨은 컬럼도 key나 요청 파라미터일 수 있으므로 표시 여부만으로 제거하지 않는다.

8. **READ·SAVE action**  
   Legacy `saveAction/readAction`은 READ를 Grid 조회 action으로, SAVE를 Button action 및 object 연결로 분리한다. actionId는 문자열 전체가 아니라 `command·queryId·version·params`로 비교한다. queryId가 같아도 version이 다르면 동일 action이 아니며, params가 다르다는 이유만으로 서로 다른 조회라고 단정하지 않는다.

9. **PROCESSTRAN**  
   `PROCESSTRAN`은 master-detail 관계로 해석하여 발생 Grid, 대상 Grid, 선택 행 전달, 대상 조회 action과 Framework가 지원하는 이벤트 계약을 함께 보존한다.

10. **저장 Object 추적**  
    저장 기능은 `HTML/JS 이벤트 DOM ID → CIM_MENUOBJECT.OBJECTID → Vue Button ele-id → SAVE actionId`로 추적한다. 이름만으로 제외하거나 DB object와 Vue ID의 단순 문자열 불일치만으로 누락을 판단하지 않는다.

11. **Popup·구현 원칙**  
    Popup/include/child 화면은 부모 호출부터 자체 Vue·PAGE_ID·UICOMPONENT까지 별도 의존 그래프로 추적한다. 유사 화면은 구조 참고용이며 ID 복사 대상이 아니다. 기존 `TU*·Grid·Popup·Biz·Service` 계약을 우선 사용하고 화면별 ID와 업무 callback만 재구성한다.

12. **검증 및 완료 판정**  
    불일치는 `소스 누락·Vue 누락·DB 메타 누락·고아 Widget·잘못된 PAGE_ID·action/column/dropdown 오배치·의도적 차이`로 구분한다. Route/menu, 식별자, 전체 Widget, Component, Grid 번호, Filter/Column/key, READ/SAVE, dropdown, PROCESSTRAN, popup 의존성이 모두 검증되어야 마이그레이션 완료로 판단한다.

## Applicability

- WEBUI20에서 Legacy MES 화면을 Vue 화면과 pageConfig 메타데이터로 이행하거나 그 결과를 검증할 때 적용한다.
- 실제 작업에서는 현재 Legacy 소스, Framework 계약, runtime `SITEID·PRODUCT`와 대상 DB 상태를 최종 기준으로 삼는다.

## Evidence

2026-09-10 작업에서 UI 1.0 HTML/JS와 `CIM_MENU·CIM_WIDGET·CIM_MENUOBJECT`, UI 2.0 Vue와 `CIM_UIPAGE·CIM_UICOMPONENT`, WEBUI20 공통 Framework 계약을 교차 확인해 정리했다.
