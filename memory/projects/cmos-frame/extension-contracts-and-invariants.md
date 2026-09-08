---
id: MEM-20260908-frame-contracts
type: project
scope: project
project: cmos-frame
domain: extension-contracts-and-invariants
tags: [framework, cmos, contracts, core-rule, core-entity, core-repository, soft-delete, hist]
status: active
confidence: high
created: 2026-09-08
updated: 2026-09-08
last_seen: 2026-09-08
occurrences: 1
source_agent: antigravity
---

# C-MOS Framework Extension Contracts & Invariants

## Context
프로젝트(PROJECT) 개발자가 `FRAME-CORE` 및 `MES-CORE`를 상속하여 비즈니스 로직, 엔티티, 영속 계층을 구현할 때 반드시 준수해야 하는 상속 계약, 생명주기 제어 및 데이터 불변조건을 정의한다.

## 5대 핵심 상속 체인
1. **Controller**: `InterfaceController` (API) -> `AbstractController` (API) -> `BaseController` (IIA) -> `CoreController` (FRAME-CORE) -> `PROJECT`
2. **Manager**: `InterfaceManager` (API) -> `AbstractManager` (API) -> `BaseManager` (IIA) -> `CoreManager` (FRAME-CORE) -> `PROJECT`
3. **Repository**: `InterfaceRepository` (API) -> `AbstractRepository` (API) -> `BaseRepository` (IIA) -> `CoreRepository` (FRAME-CORE) -> `PROJECT`
4. **Entity**: `InterfaceEntity` (API) -> `AbstractEntity` (API) -> `BaseEntity` (IIA) -> `CoreEntity` (FRAME-CORE) -> `PROJECT`
5. **Rule/Event**: `InterfaceEvent` (API) -> `AbstractEvent` (API) -> `BaseEvent` (IIA) -> `CoreRule` (FRAME-CORE) -> `PROJECT`

## CoreRule 실행 계약
- `CoreRule`은 상위 `BaseEvent`의 `validation()`과 `execute()`를 `final`로 재정의하여 직접 오버라이드할 수 없도록 제한한다.
- 대신 다음 두 추상 메서드의 구현을 강제한다:
  - `public abstract void messageValidation()`: 파라미터 유효성 검증 (`webDataCheck` 등 활용)
  - `public abstract void process()`: 실제 비즈니스 트랜잭션 수행

## CoreEntity 공통 필드 및 컬럼 관리
- **공통 14개 필드 규약 (`CORE_COLUMN_LIST`)**:
  `ACTIVITY`, `PREVACTIVITY`, `CUSTOMACTIVITY`, `PREVCUSTOMACTIVITY`, `ISUSABLE`, `DESCRIPTION`, `REASONCODE`, `COMMENTS`, `CREATOR`, `CREATETIME`, `MODIFIER`, `MODIFYTIME`, `LASTEVENTTIME`, `TID`
- `getAllColumnsExceptCore()`: 도메인 고유 필드만 추출할 때 공통 14개 필드를 제거하여 반환한다.
- **Touched Columns 관리와 엔티티 재사용 제어**:
  - 엔티티 내부의 변경 필드 집합(`touchedColumns`, `touchedColumnNames`)을 추적한다.
  - `CoreRepository.selectBiz()`, `select4Update()` 등은 기본 검색 조건으로 `ISUSABLE = 'USABLE'`을 설정한 뒤 조회를 수행한다. 만약 호출자가 원래 `ISUSABLE`을 검색 조건으로 지정하지 않았다면, 조회 후 `touchedColumns`에서 `ISUSABLE`을 다시 제거하여 원복한다. 이는 조회에 사용된 동일 엔티티 인스턴스를 후속 로직에서 재사용할 때 원치 않는 조건 누수나 오염을 방지하기 위함이다.

## Repository CUD 및 Hist 저장 규칙
- **논리 삭제(Soft Delete) vs 물리 삭제**:
  - `deleteBiz()`: 엔티티의 `ISUSABLE`을 `UNUSABLE`로 변경하고 `RequestType.UPDATE`를 수행하여 DB 행을 보존하는 논리 삭제를 수행한다.
  - `unDelete()`: `ISUSABLE`을 다시 `USABLE`로 변경하고 `RequestType.UPDATE`를 수행한다.
  - `realDelete()`: `RequestType.REALDELETE`를 전달하여 DB 물리 `DELETE`를 수행한다.
- **이력(Hist) 자동 저장 조건**:
  - `upsertEntityWithFullColumn` 및 배치 연산에서 `saveHist == true`이고 본 테이블 연산의 영향 행 수가 1 이상(`count > 0`)일 때 `CoreEntityUtility.getEntityHist(entity)`를 생성하여 이력 테이블에 INSERT한다.

## Reusable Rule
신규 업무 로직 개발 시 Spring MVC 컨트롤러 대신 `CoreRule`을 상속하여 검증(`messageValidation`)과 실행(`process`)을 분리하고, 삭제 작업 시 시스템 요구사항에 따라 `deleteBiz`(논리삭제, 기본 권장)와 `realDelete`(물리삭제)를 명확히 구분하여 호출한다.
