---
id: MEM-20260910-refine-effect-boundaries
type: lesson
scope: global
project: ""
domain: transaction-side-effects
tags: [transaction, rollback, commit, messaging, filesystem, compensation]
status: active
confidence: medium
created: 2026-09-10
updated: 2026-09-10
last_seen: 2026-09-09
occurrences: 1
source_agent: Codex
---

# 요청 실패와 각 부수효과의 완료·복구 경계를 구분할 것

## Core Knowledge

한 요청이 DB 변경, 메시지 발송, 파일 생성, 별도 commit을 함께 수행해도 모두 같은 트랜잭션에 참여하는 것은 아니다. 예외 응답이나 요청 rollback만으로 앞서 완료된 모든 효과가 되돌아갔다고 판단하지 않는다.

## Applicability / Recurrence Prevention

- 효과별로 실행 순서, 참여 트랜잭션, 완료 판정, 실패·보상 책임을 나눠 추적한다. 같은 Context/Manager 안에서 호출됐다는 사실만으로 원자성을 주장하지 않는다.
- DB commit 전 메시지 발송이나 파일 생성이 있으면 이후 실패 때 남는 효과를 검토한다. message key의 존재는 멱등성, catch의 삭제 호출은 완전 보상 증거가 아니다.
- 실패 상태를 보존하기 위한 명시 commit이나 독립 트랜잭션은 일반 요청 rollback과 구분한다. commit을 시도했다는 것과 저장 성공도 구분한다.
- 부분 생성·발송 직후 실패, 다음 저장/commit 실패, 보상 실패를 각각 검증한다. 원자성 요구가 있다면 관련 자원을 실제로 포괄하는 계약을 확인하고 그 범위에서만 보장을 주장한다.

## Evidence

2026-09-09 [2nd-battery 연동 메모리](../projects/2nd-battery/integration-and-web-boundaries.md)의 MCS 실행 중 전송, 파일 생성 후 Attachment 저장·조건부 cleanup, 로그인 실패 commit에서 도출했다. [C-MOS 트랜잭션 메모리](../projects/cmos-frame/persistence-and-transaction.md)는 독립 세션과 commit 실패 전달의 별도 경계를 기록한다. 이 교훈은 메시지/파일 장애가 실제 재현됐다는 주장이 아니다.

하위 API가 실패 정보를 숨겨 성공 판정을 어렵게 하는 문제는 [폴백 반환값 교훈](fallback-result-is-not-success-proof.md)에 별도로 둔다.
