---
id: MEM-20260908-152800
type: incident
scope: project
project: eti
domain: lotdefect
tags: [lotdefect, DefectLot, Lot.Qty, defectSum, double-deduct]
status: active
confidence: high
created: 2026-09-08
updated: 2026-09-08
last_seen: 2026-09-08
occurrences: 1
source_agent: cursor-agent
---

# LOTDEFECT DefectLot 재저장 시 Lot.Qty 이중 차감

## Context

`eti/api310`의 `LOTDEFECT.DefectLot`에서 기존 불량행을 수량 변경 없이 재저장하면 `Lot.Defectqty`는 유지되고 `Lot.Qty`만 다시 빠졌다. 2026-08-21 소스 분석으로 원인을 확인했다. `Lot.Qty` 차감은 이 API 한 곳에서만 하며, Service 호출부는 Qty를 다시 빼지 않는다.

## Symptom

초기 Qty=300에 불량 10+100을 신규 등록하면 DefectQty=110, Qty=190으로 정상이다. 이후 Other Defects=100 행만 재저장하면 DefectQty=110은 유지되고 Qty만 90이 된다.

## Root Cause

`SelectLotDefect4Update`가 기존 행을 찾으면 UPDATE 분기를 탄다. UPDATE는 `storedLot.Defectqty`에서만 oldQty를 되돌리고, `defectSum`에는 요청 수량 전체를 넣었다. 이후 `Lot.Qty -= defectSum`이 실행되어 이미 반영된 수량이 다시 빠진다. DefectQty가 유지되는 것은 UPDATE 분기를 탔다는 증거다. 동일 요청 안 중복 차감은 없다.

## Wrong Approach

DefectQty가 정상이면 Qty도 같은 합으로 맞다고 단정하면 안 된다. 두 필드가 같은 `defectSum`을 쓰더라도 UPDATE 보정은 DefectQty에만 있었다.

## Correct Approach

기존 행 재저장은 `변경량 = newQty - oldQty`만 `Lot.Qty`에 반영한다. 100→100은 0, 100→120은 -20, 100→80은 +20. 2026-09-08 소스 재확인 결과 현재 `LOTDEFECT.DefectLot.cs`는 `oldDefectSum`을 모아 `Qty -= (defectSum - oldDefectSum)`으로 차분을 적용한다. 런타임 재검증은 이 세션에서 하지 않았다.

## Reusable Rule

자식 수량 UPDATE가 헤더의 한 필드만 `-old + new`로 맞추고, 쌍이 되는 다른 필드에는 요청 수량 전체를 빼면 재저장 때 그 필드만 이중 반영된다.

## Verification

사용자 재현 숫자와 2026-08-21 `DefectLot` 소스 대조로 원인을 확인했다. 수정 후 런타임 재현은 미실시. 이미 잘못 빠진 Lot.Qty 데이터는 코드 수정만으로 복구되지 않는다.
