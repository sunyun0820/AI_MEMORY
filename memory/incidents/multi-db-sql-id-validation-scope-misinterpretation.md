---
id: MEM-20260908-155202
type: incident
scope: project
project: mes-core
domain: sql-mapping
tags:
  - communication
  - requirements-interpretation
  - multi-db
  - mybatis-sql
  - validation
status: active
confidence: high
created: 2026-09-08
updated: 2026-09-08
last_seen: 2026-09-08
occurrences: 1
source_agent: antigravity
---

# 다중 DBMS SQL 검증 범위를 직전 변경 파일로 축소한 실수

## Core Knowledge

mes-core의 MSSQL·Oracle·PostgreSQL MyBatis XML 비교에서, 사용자가 현재 전체 대상을 확인하도록 정정했는데도 직전 작업의 diff 파일만 확인하여 전체 정합성을 성급하게 보고했다.

## Root Cause / Recurrence Prevention

최근 작업 맥락이 명시된 검증 범위를 덮었다. 일부 파일 검색 결과로 전체 일치 여부를 판단했고, 실제 비교한 경로·파일 수·ID 수를 보고하지 않았다. 검증 시작 전에 현재 요청의 경로와 기준을 목록으로 확정하고, 전체 목록과 처리 결과를 대조한다. 변경 파일만 명시적으로 요청한 경우에는 그 범위를 존중한다.

## Historical Evidence

원본 기록에는 전수 비교 뒤 Oracle `CDS_UserClassObjectRelList_100_OracleDatabase_sql.xml`의 `101-00002`·`102-00002` 중복/접미사 문제와 폴더 배치 차이를 찾았다고 남아 있다. 이는 당시 조사 기록이며 현재도 동일한 결함이 존재한다는 뜻은 아니다. 당시 DBMS 간 일치율을 현재 상태로 재사용하지 않는다.

## Verification

원본은 PowerShell 추출·차집합 비교 결과를 근거로 한다. 이번 Refine에서는 과거 실행 원문 및 전체 XML 재검증을 수행하지 않았다. 비교 절차와 한계는 [다중 구현 계약 비교](../lessons/cross-variant-contract-validation-scope.md)에 일반화했다.
