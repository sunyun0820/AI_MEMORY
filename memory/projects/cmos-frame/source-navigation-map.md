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

# C-MOS Framework Source Navigation Map

## Context
향후 AI Agent가 C-MOS Framework 및 MES-CORE 기반 작업 시 불필요한 전체 파일 검색과 토큰 소모를 방지하고, 분석 목적에 맞는 핵심 클래스로 즉시 이동할 수 있도록 저장소 상대경로 기반의 탐색 지도를 제공한다.

## Source Navigation Matrix

| 탐색 목적 / 질문 | 모듈 | 상대 경로 / 클래스 | 핵심 메서드 및 심볼 |
|---|---|---|---|
| **부트스트랩 / 팩토리 초기화 순서** | `FRAME-API` | `api/src/main/java/.../api/Factory.java` | `initialize()`, `destroy()`, `getAndInitialize()` |
| **클래스패스 스캔 / 패키지 필터** | `FRAME-API` | `api/src/main/java/.../api/Environment.java` | `PACKAGE_PREFIX_SET`, `putClassSet()`, `isTraceClass()` |
| **요청 수명주기 / 커밋·롤백 제어** | `FRAME-IIA` | `iia/src/main/java/.../iia/abstracts/entry/BaseDispatcher.java` | `executeInternal()`, `start()`, `commit()`, `rollback()` |
| **요청 전/후처리 훅 (Processor)** | `FRAME-IIA` | `iia/src/main/java/.../iia/abstracts/entry/BaseProcessor.java` | `setStartTime()`, `setEndTime()` |
| **트랜잭션(Basic / Separated) 분기** | `FRAME-IIA` | `iia/src/main/java/.../iia/abstracts/context/BaseTransaction.java` | `TransactionType`, `initialize()`, `decreseCounter()` |
| **비즈니스 Rule (검증 / 실행 2단계)** | `FRAME-CORE` | `core/src/main/java/.../mes/core/abstracts/business/CoreRule.java` | `validation()`(final), `messageValidation()`, `process()` |
| **엔티티 공통 14개 필드 규약** | `FRAME-CORE` | `core/src/main/java/.../mes/core/abstracts/business/CoreEntity.java` | `CORE_COLUMN_LIST`, `getAllColumnsExceptCore()` |
| **CRUD / 논리삭제 / Hist 자동 저장** | `FRAME-CORE` | `core/src/main/java/.../mes/core/abstracts/business/CoreRepository.java` | `deleteBiz()`, `realDelete()`, `upsertEntityWithFullColumn()`, `selectBiz()` |
| **Service(Manager) 공통 / 상태전이** | `FRAME-CORE` | `core/src/main/java/.../mes/core/abstracts/business/CoreManager.java` | `getDbContext()`, `setCommonData()`, `checkStateTransition()` |
| **Controller 응답 / DataDic 처리** | `FRAME-CORE` | `core/src/main/java/.../mes/core/abstracts/business/CoreController.java` | `setDatadic()`, `getRequestData()`, `getReplytData()` |
| **웹 인증 / 세션 / 보안 필터** | `MES-CORE` | `core/src/main/java/.../mes/core/web/filter/` | `SecurityWebFilter`, `LoginSessionWebFilter`, `AccessWebFilter` |
| **로그인 / 토큰 발급 컨트롤러** | `MES-CORE` | `core/src/main/java/.../mes/core/web/login/LoginController.java` | `LoginTokenUtility`, `AzureOpenIdLoginController` |
| **MyBatis XML 매퍼 위치** | `MES-CORE` | `core/src/main/resources/sql/` | `mssql/api/`, `mssql/core/`, `oracle/`, `postgresql/` |

## Quick Search Keywords for Grep / Find
- 요청 진입점: `BaseDispatcher`, `WebDispatcher`, `InterfaceProcessor`
- 비즈니스 로직: `CoreRule`, `CoreController`, `CoreManager`, `BusinessUtility`, `DbContext`
- 영속성/DB: `CoreRepository`, `BaseTransaction`, `JpaRepository`, `MybatisRepository`, `SqlMaker`
- 엔티티/도메인: `CoreEntity`, `CORE_COLUMN_LIST`, `touchedColumns`, `IsUsable`
- 상태/옵션셋: `LotState`, `EquipmentState` (`common/state/`), `TrackIn`, `TrackOut` (`common/optionset/`)
