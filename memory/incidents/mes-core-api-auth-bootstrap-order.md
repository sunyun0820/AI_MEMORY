---
id: MEM-20260908-mescore-api-auth-bootstrap
type: incident
scope: project
project: mes-core
domain: bootstrap-and-authorization-cache
tags: [java, factory, initialization-order, separated-transaction, cache-reload]
status: active
confidence: high
created: 2026-09-08
updated: 2026-09-08
last_seen: 2026-09-08
occurrences: 1
source_agent: Codex
---

# API 권한 캐시 초기화 중 Factory 의존성 오류

## Core Knowledge

Processor 초기화가 권한 캐시를 읽으면서 기존 Factory 초기화 순서의 숨은 의존성을 드러냈다. 현재 필요한 순서는 `DataBaseFactory → ContextFactory → EntryFactory`다. 전체 수명주기는 [runtime-lifecycle](../projects/cmos-frame/runtime-lifecycle.md)을 참조한다.

## Symptom / Root Cause

- `DataBaseFactory Not Initialilze`: `getDataBaseFactory()`가 반환할 `dataBaseFactory` 대신 `entryFactory`의 null 여부를 검사했다.
- 이를 고친 뒤 `ContextFactory Not Initialilze`: `EntryFactory`의 Processor 초기화 중 생성한 `SeparatedTransaction`이 transaction ID 발급에 아직 초기화되지 않은 `ContextFactory`를 요구했다.
- 이후 `USERCLASSID is required`: 별개의 캐시 입력 정합성 오류다. 초기화 순서를 바꾸는 것으로 잘못된 권한 행이 해결되지는 않는다.

## Applicability / Recurrence Prevention

C-MOS Processor.initialize에서 DB 조회나 ID 발급을 추가할 때 적용한다. getter는 자기 필드를 검사하고, 초기화 중 호출하는 의존 Factory를 먼저 준비하며 종료 시 Entry를 Context보다 먼저 닫는다. 잘못된 권한 행은 조용히 제외하지 않는다. reload 오류 처리의 정확한 보장 범위는 [권한 캐시 계약](../projects/mes-core/api-authorization-runtime-and-cache.md)을 따른다.

## Verification

2026-09-08 Refine에서 현재 `framework/api/.../Factory.java`, `framework/iia/.../SeparatedTransaction.java`, `core/.../AuthorizationSnapshot.java`를 정적 대조했다. 두 단계 시작 오류와 snapshot/SAVE/SYSTEM/endpoint 테스트 통과는 원본 기록의 과거 증거이며 이번에 서버·테스트·DB를 실행한 결과가 아니다.
