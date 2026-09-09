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
updated: 2026-09-10
last_seen: 2026-09-08
occurrences: 1
source_agent: cursor-agent
---

# eti LOTDEFECT의 API·Service·MaterialLot 수량 경계

## Core Knowledge

2026-08-21 ETI 소스 관찰에서 `Lot.Qty` 이중 차감의 직접 원인은 `LOTDEFECT.DefectLot`였으며 Service는 Lot.Qty를 다시 빼지 않았다. 같은 재저장 흐름의 Service 수량 검증과 CONVERTED MaterialLot 차감은 별도 경계이므로 API의 차분 수정만으로 모두 해결됐다고 판단하지 않는다.

## Recorded Behavior / Applicability

- `PRODUCTIONLotManager.MakeLotList_Defect`는 `item.Qty < 요청 불량 합`으로 검사하며 변경 차분을 사용하지 않았다.
- `SaveLotDefect`의 CONVERTED 분기는 `materiallot.Qty -= 요청수량 전체`를 적용했다.
- 따라서 기존 불량 수량 증가가 Service에서 거부되거나 MaterialLot가 재차 차감될 가능성이 있다. 이는 위 정적 관찰에서 도출한 영향이며 런타임 재현된 장애로 기록하지 않는다.
- `CancelDefectLot`는 삭제 시 기존 수량을 되돌리는 경로로, 해당 Lot.Qty 재저장 사고의 원인은 아니었다.

## Avoid / Recurrence Prevention

ETI 불량 재저장을 수정할 때 API Qty, Service의 허용 수량 검사, CONVERTED MaterialLot를 각각 대조한다. API 차분 수정의 과거 근거는 [이중 차감 사고](../../incidents/eti-lotdefect-qty-double-deduct.md), 차분의 일반 적용 조건은 [수량 갱신 교훈](../../lessons/paired-qty-update-must-use-delta.md)을 참조한다.

## Evidence

2026-08-21 `mes_service`의 `PRODUCTIONLotManager.DefectLot.cs`, `ManagerExtenstions.Production.Lotdefect.cs`를 읽은 기록이다. Service·MaterialLot 영향의 재현 테스트는 기록되지 않았다. 이 시점의 관찰을 이후 버전에서도 미해결인 장애로 단정하지 않는다.
