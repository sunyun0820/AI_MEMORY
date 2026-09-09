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

# 기존 행 재저장 시 파생 수량은 차분으로 맞출 것

## Core Knowledge

기존 자식 행의 수량을 헤더에 증분 반영하는 구조에서는 `delta = newQty - oldQty`를 사용한다. 집계량에는 `+delta`, 그에 대응하는 잔량에는 `-delta`처럼 각 필드의 의미에 맞는 부호를 적용한다. 한쪽이 정상이어도 쌍 필드의 보정이 빠질 수 있다.

## Applicability

자식의 기존 기여분이 이미 집계·잔량에 반영된 UPDATE에 적용한다. INSERT의 기존 기여분은 0이다. 전체 재계산, 절대값 덮어쓰기, 다른 단위·업무 의미의 수량에는 같은 공식을 무조건 적용하지 않는다.

## Avoid / Recurrence Prevention

- 집계만 `-old + new`로 보정하고 잔량에서 new 전체를 다시 빼지 않는다.
- 잔량 차감을 끄는 옵션이 있으면 루프에서 old를 먼저 복구하는 코드도 같은 옵션 경계 안에 있어야 한다. 차분 합계를 최종 반영하는 방식이 경계 확인에 유리하다.
- 같은 수량 재저장, 증가, 감소, 신규 행을 각각 대조하고 Service 검증과 종속 수량도 따로 확인한다.
- 동시 갱신이 가능하면 old 조회와 반영의 트랜잭션·잠금 경계도 확인한다. 차분 계산만으로 동시성까지 해결되지는 않는다.

## Verification

[ETI LOTDEFECT 사고](../incidents/eti-lotdefect-qty-double-deduct.md)의 소스 분석과 사용자 재현 숫자에서 도출했다. 원본에는 2026-09-08 차분 적용 소스 재확인이 기록되어 있으나 수정 후 런타임 재현은 없다.
