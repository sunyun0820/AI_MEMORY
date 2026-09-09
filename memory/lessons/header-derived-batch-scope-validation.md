---
id: MEM-20260910-refine-batch-scope
type: lesson
scope: global
project: ""
domain: batch-input-validation
tags: [batch, header-detail, first-item, scope, invariant, mixed-input]
status: active
confidence: medium
created: 2026-09-10
updated: 2026-09-10
last_seen: 2026-09-09
occurrences: 1
source_agent: Codex
---

# 첫 항목으로 처리 범위를 정하는 API는 목록 전체의 전제를 검증할 것

## Core Knowledge

첫 header나 첫 행의 소유자·테넌트·그룹·상태로 목록 전체의 조회·삭제·분기를 정하면, 뒤의 모든 항목도 그 범위에 속한다는 전제가 생긴다. 첫 항목 검사나 한 필드의 일치만으로 전체 목록의 동질성이 보장되지 않는다.

## Applicability / Recurrence Prevention

- 첫 원소에서 공통 범위를 정해 자식 목록에 값을 넣거나 기존 집합을 교체하는 API에 적용한다.
- 범위를 결정하는 필드와 업무 분기 조건을 식별하고, 전체 항목을 검사할지 명시적으로 그룹별 처리할지 계약을 정한다. 원래 이질적 항목을 독립 처리하는 API에 단일 범위를 강제하지 않는다.
- header에서 상속할 필드와 자식의 개별 값을 구분한다. 자식 값 덮어쓰기를 입력 정합성 검증으로 해석하지 않는다.
- 빈 목록, 여러 header, 혼합 범위·상태를 구분한다. 빈 목록의 no-op·오류·전체 삭제 의미는 API 계약을 따르며 추정하지 않는다.

## Evidence

2026-09-09 [2nd-battery 확장 조건](../projects/2nd-battery/extension-patterns-and-invariants.md)에 기록된 첫 Equipment 기반 Lot 목록, 첫 Product/Site 기반 BOM 교체, 첫 Lot Batch/상태 기반 Track-In에서 공통 전제를 추출했다. 정적 관찰의 일반화이며 새 런타임 장애나 검증 성공을 추가한 것이 아니다.

완전한 목표 목록과 patch를 구분하는 별도 문제는 [관계 목록 차집합](relation-data-sync-must-use-diff-bulk.md)을 참조한다.
