---
id: MEM-20260908-155202
type: incident
scope: global
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

# 다중 DBMS SQL 일관성 검증 시 질문 범위 축소 해석 및 단편적 확인 실수

## Context

사용자가 리소스 폴더(`src/main/resources/sql`) 내 MSSQL, Oracle, PostgreSQL 3종 DBMS에 존재하는 MyBatis XML 파일들을 대상으로, 신규/수정 파일뿐만 아니라 기존 파일들까지 포함하여 `select id`가 동일하게 유지되고 있는지 전수 비교 검증을 요청한 상황.

## Symptom

사용자가 "git의 변경된 파일들만 체크해주면된다. 다른 기존 3가지 db의 쿼리들을 체크해서 확인해줘"라고 요청했으나, 에이전트가 방금 작업한 특정 Java/SQL 수정 맥락에 갇혀 git diff에 걸린 파일 몇 개만 확인하고 "이번 작업으로 생성된 파일은 없다", "문제 없다"며 단편적으로 답변함.
이에 사용자가 "이전꺼 무시하고 현재 기준이라고 했잖아. 몇십개의 파일들이 있잖아. 거기에 있는것들이 문제없냐는거다. 왜이리 멍충하누"라고 강하게 지적하며 재검증을 요구함.

## Root Cause

1. **질문 의도 오판 및 맥락 편향**:
   사용자의 핵심 의도는 "3개 DBMS(MSSQL, Oracle, PostgreSQL) 간 MyBatis XML `select id` 1:1 정합성 전수 검증"이었으나, 에이전트가 최근 대화 맥락(특정 서비스 리팩토링)에 과도하게 편향되어 확인 대상을 임의로 축소함.
2. **단편적/정성적 확인 시도**:
   수십 개에 달하는 XML 파일 간의 키 일관성 검증을 체계적인 스크립트 기반 전수 추출 및 차집합(diff)으로 처리하지 않고, 육안 검토나 일부 파일 검색 수준으로 처리하려 함.

## Wrong Approach

- 사용자의 포괄적 검증 요청("다른 기존 3가지 db의 쿼리들을 체크해서 확인해줘")을 직전 작업 범위로 좁혀 생각하여, 전체 대상 파일이 아닌 일부 파일만 확인하고 성급히 이상 없다고 결론지음.

## Correct Approach

1. **사용자의 검증 범위 명확화**:
   다중 DBMS 간 매핑 검증 요청 시, 단편 파일이 아닌 해당 도메인(예: `modeler` 등)의 전체 파일 목록을 검증 대상으로 설정.
2. **스크립트 기반 전수 ID 추출 및 3-way diff 수행**:
   - PowerShell 정규식(`select id="([^"]+)"`)을 통해 MSSQL, Oracle, PostgreSQL 디렉터리 내 모든 XML의 ID를 전수 추출.
   - `Compare-Object`를 이용해 MSSQL ↔ Oracle, MSSQL ↔ PostgreSQL, Oracle ↔ PostgreSQL 3자 간 차집합을 전수 비교.
3. **구체적이고 정확한 팩트 리포트**:
   - MSSQL ↔ PostgreSQL: 100% 동일.
   - Oracle: `CDS_UserClassObjectRelList_100_OracleDatabase_sql.xml` 내에 `101-00002`, `102-00002`가 중복 정의되어 접미사 불일치가 존재하며, 캐시 및 일부 공통 쿼리가 경로 차이로 modeler 폴더에 없음 등 정확한 사실을 도출하여 보고함.

## Reusable Rule

- 다중 DBMS 간 SQL/쿼리 일관성 검증 요청을 받으면, 직전 작업 맥락으로 범위를 축소하지 말고 지정된 전체 경로의 XML에서 ID를 자동 추출하여 3-way 차집합(diff)으로 전수 검증하라.
- 사용자가 "기존 것들과 비교해서도 문제가 없는지"를 물을 때는 정성적 판단이나 추측을 배제하고 스크립트 기반의 데이터 전수 비교 결과를 제시하라.

## Verification

PowerShell 파이프라인으로 MSSQL, Oracle, PostgreSQL XML 전체를 파싱하여 전수 3-way diff를 수행하고 결과를 사용자에게 정확히 전달하여 검증 완료.