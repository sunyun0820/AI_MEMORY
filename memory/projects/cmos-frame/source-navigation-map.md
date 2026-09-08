---
id: MEM-20260908-frame-nav
type: project
scope: project
project: cmos-frame
domain: source-navigation
tags: [framework, cmos, navigation, file-map, cheat-sheet, search-guide]
status: active
confidence: high
created: 2026-09-08
updated: 2026-09-08
last_seen: 2026-09-08
occurrences: 1
source_agent: antigravity
---

# C-MOS Source Navigation Map

## Scope

현재 `cmos frame` checkout 루트 기준이다. `framework/core`는 FRAME-CORE이고 최상위 `core`는 MES-CORE다. 아래 java 경로의 `...`는 `src/main/java/com/thirautech/cmos`를 줄인 표기이며 그대로 열 수 있는 리터럴 경로가 아니다.

| 질문 | 모듈 상대 경로 | 핵심 심볼 |
|---|---|---|
| Factory 초기화·구현 선택 | `framework/api/.../framework/api/Factory.java` | initialize, destroy, getAndInitialize |
| 클래스 탐색·패키지 필터 | `framework/api/.../framework/api/Environment.java` | PACKAGE_PREFIX_SET, putClassSet |
| 공개 Factory API | `framework/api/.../framework/api/interfaces/factory/` | InterfaceBusinessFactory, InterfaceConnectorFactory, InterfaceContextFactory |
| 요청·commit/rollback | `framework/iia/.../framework/iia/abstracts/entry/BaseDispatcher.java` | executeInternal, preExecute, commit, rollback |
| Processor 기본 구현 | `framework/iia/.../framework/iia/abstracts/entry/BaseProcessor.java` | setStartTime, setEndTime |
| 트랜잭션·실패 처리 | `framework/iia/.../framework/iia/abstracts/context/BaseTransaction.java` | initialize, commit, rollback, close, decreseCounter |
| 독립 트랜잭션·ID 의존성 | `framework/iia/.../framework/iia/materialze/context/SeparatedTransaction.java` | makeTransactionId |
| 업무 검증·실행 | `framework/core/.../mes/core/abstracts/business/CoreRule.java` | messageValidation, process |
| 공통 컬럼·touched | `framework/core/.../mes/core/abstracts/business/CoreEntity.java` | CORE_COLUMN_LIST, getAllColumnsExceptCore |
| CRUD·논리삭제·Hist | `framework/core/.../mes/core/abstracts/business/CoreRepository.java` | selectBiz, deleteBiz, realDelete, upsertEntityWithFullColumn |
| Service·상태전이 | `framework/core/.../mes/core/abstracts/business/CoreManager.java` | getDbContext, setCommonData, checkStateTransition |
| Controller 응답 | `framework/core/.../mes/core/abstracts/business/CoreController.java` | setDatadic, getRequestData, getReplytData |
| 웹 인증 필터 | `core/.../mes/core/web/filter/` | SecurityWebFilter, LoginSessionWebFilter, AccessWebFilter |
| 로그인·SSO | `core/.../mes/core/web/login/`, `web/sso/` | LoginController, AzureOpenIdLoginController |
| API 권한·캐시 | `core/.../mes/core/common/authorization/` | ApiAuthorizationProcessor, ApiAuthorizationManager, AuthorizationCacheManager, AuthorizationSnapshot |
| MyBatis XML | `core/src/main/resources/sql/` | mssql, oracle, postgresql |

## Verification

2026-09-08 로컬 소스 경로를 기준으로 framework 접두사 누락과 두 core 모듈의 경계를 정리했다. 버전·checkout이 바뀌면 `rg --files`로 실제 위치를 다시 찾는다. 실행 계약은 [architecture](architecture.md), [lifecycle](runtime-lifecycle.md), [persistence](persistence-and-transaction.md), [extension](extension-contracts-and-invariants.md)에 분리한다.
