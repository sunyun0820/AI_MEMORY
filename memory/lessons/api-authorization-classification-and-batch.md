---
id: MEM-20260908-api-auth-classification
type: lesson
scope: global
project: mes-core
domain: api-authorization
tags: [authorization, read, save, queryid, batch, mapping]
status: active
confidence: high
created: 2026-09-08
updated: 2026-09-08
last_seen: 2026-09-08
occurrences: 1
source_agent: Codex
---

# API 권한 유형은 등록 계약으로 판정하고 batch 전체를 검사할 것

## Core Knowledge

조회와 저장을 같은 진입점에서 받는 API는 payload의 특정 필드 유무만으로 권한 유형을 추정하면 안 된다. 등록된 command/operation 계약으로 유형을 판정하고, 조회로 분류한 batch는 포함된 모든 query의 매핑과 권한을 검사한다.

## Applicability

명시적 권한 매핑을 사용하는 API에 적용한다. READ/SAVE의 키, 혼합 유형 우선순위, query version 취급은 시스템마다 다르므로 아래 사례를 일반 규칙으로 복사하지 않는다.

## Avoid / Recurrence Prevention

- 저장 payload에도 조회 식별자가 들어갈 수 있다. 필드가 존재한다는 이유만으로 READ로 바꾸지 않는다.
- 첫 query만 통과해도 batch 전체를 허용하는 검사를 피한다.
- 미등록·빈 식별자와 한 command에 여러 유형이 등록된 경우의 분류 및 거부 경계를 각각 확인한다.
- 분류 테스트와 실제 인증·권한 검증을 구분한다.

## Verification

mes-core의 `AuthorizationSnapshot.resolveMappingType`와 `ApiAuthorizationManager.authorizeRead`를 2026-09-08 정적 대조했다. 현재 구현의 exact READ 우선·명시적 SAVE fallback 및 키 계약은 [프로젝트 메모리](../projects/mes-core/api-authorization-runtime-and-cache.md)에 모았다. 원본에 자체 테스트 통과 기록이 있으나 이번 Refine에서 재실행하거나 HTTP/JWT 종단 간 검증을 수행하지 않았다.
