---
id: MEM-20260908-152802
type: project
scope: project
project: eti
domain: lotdefect
tags: [lotdefect, service, MaterialLot, validation]
status: active
confidence: medium
created: 2026-09-08
updated: 2026-09-08
last_seen: 2026-09-08
occurrences: 1
source_agent: cursor-agent
---

# eti LOTDEFECT 수량 관련 잔여 경계

## Context

`Lot.Qty` 이중 차감의 직접 원인은 `LOTDEFECT.DefectLot`였다. Service는 Lot.Qty를 다시 빼지 않는다. 다만 같은 재저장 경로에 차분과 다른 검증/차감이 남아 있다. 런타임 재현은 하지 않았고, 2026-08-21 Service 소스 읽기로만 확인했다.

## Symptom

API Qty 버그와 별개로, 기존 불량 수량을 키우는 재저장이 Service에서 막히거나 CONVERTED Lot의 MaterialLot 수량이 요청 전체만큼 다시 빠질 수 있다.

## Root Cause

`PRODUCTIONLotManager.MakeLotList_Defect`는 `item.Qty < 요청 불량 합`으로만 검증한다. 차분을 보지 않는다. `SaveLotDefect`의 CONVERTED 분기는 `materiallot.Qty -= 요청수량 전체`를 적용한다.

## Correct Approach

수량 변경 재저장을 손볼 때는 API `DefectLot`뿐 아니라 Service 검증과 CONVERTED MaterialLot 차감이 차분 기준인지 같이 본다. `CancelDefectLot`는 삭제 시 기존 수량을 되돌리므로 이 Qty 재저장 버그의 원인이 아니다.

## Reusable Rule

eti 불량 재저장은 API Qty, Service 검증, CONVERTED MaterialLot를 따로 대조한다.

## Verification

`mes_service` `PRODUCTIONLotManager.DefectLot.cs`와 `ManagerExtenstions.Production.Lotdefect.cs` 소스 확인. 재현 테스트 없음.
