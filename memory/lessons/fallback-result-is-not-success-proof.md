---
id: MEM-20260908-refine-fallback-success
type: lesson
scope: global
project: ""
domain: failure-semantics
tags: [fallback, error-handling, encryption, transaction, verification]
status: active
confidence: high
created: 2026-09-08
updated: 2026-09-08
last_seen: 2026-09-08
occurrences: 1
source_agent: Codex
---

# 실패를 숨기는 반환값을 성공 증거로 사용하지 말 것

## Core Knowledge

하위 호출이 예외를 원문·기본값·정상 반환으로 바꾸면 상위 호출의 성공 판정에 필요한 정보가 사라질 수 있다. “값이 반환됐다”와 “원한 작업이 성공했다”를 구분하고 실제 실패 전달 계약을 읽는다.

## Applicability / Recurrence Prevention

복호화·파싱의 호환 폴백, I/O wrapper, commit 같은 부수효과 API를 조합할 때 적용한다. 폴백 자체를 금지하는 규칙은 아니다.

- 원문 반환을 성공한 변환 결과로 간주하지 않는다. 입력의 출처와 상태를 확인하고 정상·유효하지 않은 입력의 결과를 분리해 검증한다.
- 정상 반환·성공처럼 보이는 로그만으로 저장이나 commit을 확정하지 않는다. 예외가 전파되는지, 성공 상태가 별도로 제공되는지 확인한다.
- 실패 정보가 필요한 다음 단계(재암호화·캐시 공개 등)에서 그 정보를 얻을 수 없다면 보장 범위를 문서에 명시한다. 계약 변경은 소비자·호환성 영향을 평가할 별도 작업이다.

## Verification

2026-09-08 소스 대조에서 C-MOS decrypt가 실패 시 원문을 반환하고 BaseTransaction.commit/rollback이 내부 예외를 삼키는 두 구현을 확인했다. 전자는 평문 보장, 후자는 DB 성공 확인으로 일반화할 수 없다. 구체 경계는 [암호화 메모리](../projects/cmos-frame/crypto-column-fallback-and-double-encryption-prevention.md)와 [트랜잭션 메모리](../projects/cmos-frame/persistence-and-transaction.md)에 둔다. 실패 주입·DB 검증을 수행했다는 뜻은 아니다.
