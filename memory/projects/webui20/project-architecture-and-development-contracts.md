---
id: MEM-20260910-webui20-project-contracts
type: project
scope: project
project: WEBUI20
domain: frontend-architecture
tags: [WEBUI20, WEB20_MES, THiRA-MES, vue3, vite, pinia, element-plus, auigrid, page-config, file-routing]
status: active
confidence: high
created: 2026-09-10
updated: 2026-09-10
last_seen: 2026-09-10
occurrences: 1
source_agent: cursor
---

# WEBUI20 화면·라우팅·pageConfig 개발 계약

## Core Knowledge

WEBUI20(`WEB20_MES` 저장소 폴더명)은 레거시 THiRA MES 화면을 Vue 3로 이행하는 UI다. Vite, Pinia, 파일 기반 Vue Router, Element Plus, AUIGrid를 사용하며, 업무 화면의 공통 위젯 속성·라벨·actionId는 서버의 pageConfig와 결합된다.

새 화면은 독립 UI를 새로 만드는 방식이 아니라 `TU*` 공통 컴포넌트와 화면별 callback을 조립하는 방식으로 구현한다. 핵심 식별자 계약은 `파일 PAGEID = fetchPageConfig의 PAGE_ID = 컴포넌트 page-id = 서버 PAGE_ID`이며, 각 `ele-id`는 서버 `ELE_ID`와 일치해야 한다.

## Source Navigation

- `src/main.js`: 앱 부트스트랩과 전역 플러그인 등록.
- `src/pages/mes/{MD|PM|QM|SM|PP|RP|EM}/`: 파일 경로가 업무 화면 라우트가 되는 영역.
- `src/pages/mes/common/`: 부모 화면이 import하는 공통 팝업/내부 화면. 파일 라우트 스캔에서 제외된다.
- `src/components/`: 입력·조회·저장·그리드·팝업·검색 폼을 제공하는 `TU*` 공통 컴포넌트와 composable.
- `src/layouts/`, `src/router/`: 인증/기본 레이아웃, 메뉴·탭, 파일 라우트와 백엔드 메뉴 연결.
- `src/api/`: Biz/Service/HTTP 계층과 MES 요청·응답 변환.
- `src/store/`: app, user, language, tabs, popup Pinia store.
- `src/configs/settings.js`, mode별 `.env*`: 제품·사이트·API 런타임 설정.
- `MIGRATION_RULES.md`: 레거시 Vue3 이행 시 공통 컴포넌트 우선 원칙.

## Screen Composition Contract

일반 업무 화면은 다음 패턴을 따른다.

1. `TUCollapse`와 `TUCard`/`TUQueryForm`으로 조회 조건을 구성하고 `TUInput`, `TUBasicSelect`, `TUDatePicker`, `TUFindButton`, `TUClearButton`을 배치한다.
2. 그리드 영역은 `TUAuiGrid`와 필요 시 `TUSplitter`를 사용하며, 추가·삭제·저장은 `TUAddButton`, `TUSoftDeleteButton`, `TUUpsertButton` 등 공통 버튼으로 구성한다.
3. `queryForm`과 필터/grid ref registry를 만들고 `pageConfigDataProvide`, `queryForm`, `filterComponents`, `gridComponents`, `callback`을 `provide`한다. 편집 화면은 필요 시 `buttonController`도 제공한다.
4. `onMounted`에서 `BizFactory.createBiz(siteSetting.DEFAULT_PRODUCT_ID)`로 얻은 Biz의 `fetchPageConfig(['PAGEID'])` 결과를 `pageConfigDataProvide`에 설정한다.
5. 화면 고유 동작은 제공된 callback으로 확장한다. 조회 파라미터는 주로 `beforeRetrieveCallback`이 객체로 반환하고, `false`는 작업 중단을 뜻한다. 저장 검증·후처리는 `beforeSaveCallback`과 `afterSaveCallback`을 사용한다.

`TUInput` 등 필터 컴포넌트는 주입된 `queryForm[eleId]`와 결합되므로 queryForm key와 `ele-id`를 맞춘다. `TUFindButton`은 연결된 grid의 `retrieve()`를 호출하고, `TUUpsertButton`은 그리드의 `_ROW_STATE`(`A`, `U`, `D`)가 있는 대상 행을 저장 흐름으로 넘긴다.

팝업은 `src/pages/mes/common/`에 두고 부모에서 `usePopup`/`useFilterPopup`과 `TUPopup`으로 연다. 팝업 내부 화면도 동일한 pageConfig/provide/callback 계약을 따른다.

새 업무 화면의 대표 참고점은 `src/pages/mes/MD/CODE.vue`, 공통 조회 팝업의 대표 참고점은 `src/pages/mes/common/POPUP_MATERIAL.vue`다. 샘플이나 미이행 화면보다 현재 `TU*`/`TUAuiGrid` 기반 화면을 우선한다.

## Routing and Menu Contract

라우터는 `unplugin-vue-router`가 `src/pages`에서 생성하고 Hash history를 사용한다. 업무 파일 `src/pages/mes/MD/CODE.vue`의 경로는 `/mes/MD/CODE`이며, 백엔드 메뉴의 레거시 `VIEWID` `/view/ngs/mes/MD/CODE.html`도 이 경로로 변환되어야 메뉴명·menuid·탭과 연결된다.

따라서 신규 업무 화면은 도메인 폴더와 PAGEID에 맞는 파일 경로를 만들고, 백엔드 메뉴 `VIEWID`도 같은 최종 경로를 가리키게 해야 한다. `common`, 페이지 내부 `components`, 페이지 `utils`는 라우트 생성 대상이 아니다.

## Backend Communication Contract

기본 호출 계층은 `화면/TU 컴포넌트 → BizFactory/MesBiz → MesService → BaseService → HttpService(axios)`다. 일반 MES 호출은 REST resource 모델이 아니라 `/api`로 POST하는 command 봉투이며, `MesService.createMesParameter`가 actionId를 해석해 `COMMAND`, `SITEID`, `USERID`, `LANGUAGE`, `APPLICATIONID`, `MENUID`, `MENUCLASSID`, `CONTEXTNAME`, `WEBDATA`를 조립한다.

조회 흐름은 `TUFindButton → TUAuiGrid.retrieve() → beforeRetrieveCallback → requestGridData/createMesParameter → 응답 parse → grid binding`이다. 저장 흐름은 공통 저장 버튼이 변경 행을 수집하고 화면 callback 검증 후 actionId로 요청하는 방식이다. 응답은 `MesService.parseMesResult`를 통해 화면용 배열 또는 `errCode: 'E'` 오류 형태로 정규화된다.

로그인·메뉴·다국어·페이지 설정은 `/login`, `/usermenu`, `/langlist`, `/getuipage` 같은 특수 경로를 사용한다. 화면 요청의 사이트·사용자·언어·메뉴 문맥은 브라우저 스토리지 값과 결합되므로 임의의 별도 요청 형식을 만들지 않는다.

## Applicability / Recurrence Prevention

- WEBUI20에서 업무 화면, 팝업, 조회/저장 기능을 추가하거나 이행할 때 적용한다.
- 공통 컴포넌트가 제공하는 기능을 화면에서 재구현하거나 공통 props/emits 계약을 화면 편의에 맞춰 변경하지 않는다.
- 파일명만 추가하고 끝내지 않는다. PAGEID/page-id/ele-id/pageConfig 및 메뉴 VIEWID 연결을 함께 확인한다.
- API를 화면에서 임의로 직접 직렬화하지 않고 기존 Biz/Service의 MES command 봉투와 응답 파서를 사용한다.
- 전역 자동 임포트가 설정되어 있으므로 import 유무만으로 미정의 심볼이라 단정하지 말고 `vite.config.js`의 AutoImport 대상도 확인한다.
- 이 기억은 2026-09-10 확인한 WEBUI20 구조에 한정되며, 실제 작업에서는 현재 `MIGRATION_RULES.md`, 공통 컴포넌트 인터페이스와 대상 화면 소스를 최종 기준으로 삼는다.

## Evidence

2026-09-10 현재 작업에서 `package.json`, `vite.config.js`, 앱/라우터/레이아웃/store/API 계층, `TU*` 컴포넌트와 `CODE.vue`, `PM_PP_001.vue`, `POPUP_MATERIAL.vue`, 로그인 화면을 대조해 확인했다. `MIGRATION_RULES.md`의 공통 컴포넌트 우선 지침도 함께 반영했다.
