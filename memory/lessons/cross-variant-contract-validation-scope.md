---
id: MEM-20260908-refine-variant-contracts
type: lesson
scope: global
project: ""
domain: contract-validation
tags: [scope, manifest, multi-db, mapping, duplicates, evidence]
status: active
confidence: high
created: 2026-09-08
updated: 2026-09-08
last_seen: 2026-09-08
occurrences: 1
source_agent: Codex
---

# 다중 구현 정합성 검사는 대상 목록과 비교 키부터 확정할 것

## Core Knowledge

여러 DBMS·플랫폼에서 같은 계약을 구현하는 파일을 비교할 때는 사용자가 지정한 현재 범위를 대상 목록으로 확정한 뒤 같은 의미의 키를 비교한다. 일부 파일의 일치를 전체 정합성으로 보고하지 않는다.

## Applicability / Procedure

1. 변경 파일만인지 전체 경로인지 최신 요청을 따른다. 경로·변형별 파일 수·처리 실패/제외를 기록한다.
2. MyBatis라면 namespace·statement ID·종류 등 실제 lookup 계약을 기준으로 파싱한다. DBMS 이름이나 버전 suffix는 계약상 무시할 근거가 있을 때만 정규화한다.
3. 파일 배치 차이, 누락 키, 중복 키, 종류 불일치를 따로 비교한다. 집합 차집합만 쓰면 중복 횟수를 잃으므로 원본 행 수와 키별 빈도도 확인한다.
4. XML 정규식 추출을 쓰면 따옴표·공백·줄바꿈·주석 등으로 누락 가능한 범위를 밝히고 파싱 실패를 성공으로 취급하지 않는다.
5. ID 정합성 결과와 SQL 의미·문법·실행·성능 검증을 구분한다. 전수 ID 일치는 런타임 호환성 증거가 아니다.

## Verification

[mes-core 비교 범위 오판 사고](../incidents/multi-db-sql-id-validation-scope-misinterpretation.md)에서 범위 누락 예방 원칙을 도출했다. 나머지는 그 비교 절차를 안전하게 재사용하기 위한 검증 체크리스트이며, 특정 스크립트가 이 검사를 이미 구현했다거나 현재 DBMS 쿼리가 일치한다는 주장이 아니다.
