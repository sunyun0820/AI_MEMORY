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

# C-MOS 확장 계약과 엔티티·이력 경계

## Core Knowledge

업무 이벤트는 CoreRule의 `messageValidation()`과 `process()`를 구현한다. CoreRule이 `validation()`·`execute()`를 final로 연결하므로 이 메서드를 직접 재정의하지 않는다.

## Extension / Entity Boundaries

Controller·Manager·Repository·Entity는 `Interface(API) → Abstract(API) → Base(IIA) → Core(FRAME-CORE) → PROJECT`를 따른다. 이벤트는 InterfaceEvent → AbstractEvent → BaseEvent → CoreRule이다.

CoreEntity의 공통 14개 컬럼은 `ACTIVITY, PREVACTIVITY, CUSTOMACTIVITY, PREVCUSTOMACTIVITY, ISUSABLE, DESCRIPTION, REASONCODE, COMMENTS, CREATOR, CREATETIME, MODIFIER, MODIFYTIME, LASTEVENTTIME, TID`다. `getAllColumnsExceptCore()`는 이 목록을 제외한다.

`CoreRepository.selectBiz/select4Update`는 조회 동안 ISUSABLE을 USABLE로 덮고 정상 반환 경로에서 원래 값을 복구한다. 원래 touched가 아니었다면 touchedColumns와 touchedColumnNames에서도 제거한다. 이는 호출자가 UNUSABLE을 주면 그대로 검색한다는 뜻이 아니다. 복원은 finally가 아니므로 조회 예외 후 같은 조건 엔티티를 재사용할 때 복구됐다고 가정하지 않는다.

## CUD / History Boundaries

- `deleteBiz`: ISUSABLE=UNUSABLE의 UPDATE인 논리 삭제.
- `unDelete`: ISUSABLE=USABLE의 UPDATE.
- `realDelete`: REALDELETE의 물리 DELETE. 호출 이름만 보고 논리 삭제로 오해하지 않는다.
- `upsertEntityWithFullColumn` 및 배치 구현은 saveHist=true이고 본 연산 count/totalCount>0일 때 Hist INSERT를 호출한다. 목록 경로의 총 영향 행 수 조건을 각 행의 성공 여부 검증으로 해석하지 않는다.
- 반환 count에 Hist INSERT 수가 더해질 수 있으므로 업무 행 수와 동일하다고 가정하지 않는다.

## Applicability / Verification

2026-09-08 현재 `framework/core/.../CoreRule.java`, `CoreEntity.java`, `CoreRepository.java`의 final 계약·컬럼 목록·조건 복구·이력 분기를 정적 확인했다. DB·예외 주입 테스트는 수행하지 않았다. 상세 위치는 [탐색 지도](source-navigation-map.md)를 참조한다.
