---
id: MEM-20260908-152801
type: lesson
scope: global
project: ""
domain: qty-update
tags: [qty, update, delta, double-apply, defect]
status: active
confidence: high
created: 2026-09-08
updated: 2026-09-08
last_seen: 2026-09-08
occurrences: 1
source_agent: cursor-agent
---

# 기존 행 재저장 시 쌍 수량 필드는 차분으로 맞출 것

## Context

헤더 수량과 자식 불량수량을 같이 갱신하는 API에서, 기존 자식 행을 다시 저장할 때 한쪽 헤더 필드만 정상이고 다른 쪽만 어긋나는 사례가 있었다.

## Symptom

재저장 후 집계 필드 A는 유지되고, 쌍이 되는 잔량 필드 B만 요청 수량만큼 다시 감소한다.

## Root Cause

UPDATE 분기가 A에만 old 값을 되돌린 뒤, 공유 합계에 요청 수량 전체를 넣어 B에도 그대로 적용한다. B에는 old 복구가 없다.

## Correct Approach

1. 기존 행 조회 여부로 INSERT/UPDATE를 가른다.
2. UPDATE면 `delta = newQty - oldQty`를 계산한다.
3. 헤더의 모든 쌍 필드(집계, 잔량 등)에 같은 delta를 적용한다.
4. INSERT면 delta = newQty로 본다.
5. 한쪽 필드가 정상이어도 다른 필드 계산을 따로 대조한다.

루프 안에서 잔량을 old만큼 먼저 되돌리는 방식은, 잔량 반영을 끄는 옵션이 있으면 옵션과 충돌할 수 있다. 차분 합계를 쓰는 편이 안전하다.

## Reusable Rule

기존 수량 행을 재저장할 때는 요청 수량 전체가 아니라 `new - old`만 헤더에 반영한다.

## Verification

`eti` LOTDEFECT `DefectLot`에서 DefectQty는 `-old + new`, Qty는 `-new`여서 재저장 시 Qty만 어긋남을 소스와 재현으로 확인했다.
