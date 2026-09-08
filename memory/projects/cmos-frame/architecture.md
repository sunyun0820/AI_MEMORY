---
id: MEM-20260908-frame-architecture
type: project
scope: project
project: cmos-frame
domain: architecture
tags: [framework, cmos, architecture, modules, classpath-scan, ioc, factory]
status: active
confidence: high
created: 2026-09-08
updated: 2026-09-08
last_seen: 2026-09-08
occurrences: 1
source_agent: antigravity
---

# C-MOS Framework 모듈 경계와 자동 탐색 계약

## Core Knowledge

확인한 C-MOS 3.5.x 스택은 자체 Factory·Dispatcher·Repository로 동작한다. Spring Boot의 자동 구성·Spring Data JPA 계약을 전제로 해석하지 않는다. 같은 core 이름과 패키지가 서로 다른 모듈에 걸쳐 있으므로 디렉터리와 POM을 함께 확인한다.

## Module Boundaries

`cmos frame` checkout 기준:

| 역할 | 실제 디렉터리 | 핵심 경계 |
|---|---|---|
| FRAME-API / framework-api | `framework/api` | 인터페이스·Abstract·어노테이션·Factory·Environment |
| FRAME-IIA / framework-iia | `framework/iia` | API 계약 구현, Base 계층·Factory·DB/SQL 인프라 |
| FRAME-CORE / c-mos-core | `framework/core` | CoreRule·CoreEntity·CoreRepository·DbContext 등 MES 기반 계약 |
| MES-CORE / mes-core | `core` | 공통 업무 모델러, 웹 인증 필터와 API 권한 |
| PROJECT | 예: busan의 service/UI | 공통 Core 계약을 사용하는 고객사 로직·구성 |

## Applicability / Recurrence Prevention

- `Environment.PACKAGE_PREFIX_SET`는 `com.thirautech`이며 `putClassSet`에서 prefix로 자동 탐색 수집을 제한한다. 자동 탐색을 기대하는 클래스의 패키지를 확인한다.
- `Factory.getAndInitialize(cls)`는 해당 Factory 인터페이스의 탐색 결과가 없거나 둘 이상이면 Not Found / Too Many Class로 실패한다. 이 단일 구현 조건을 모든 업무 인터페이스에 확대하지 않는다.
- 모듈 이름만 보고 `core`와 `framework/core`를 혼동하지 않는다. 상세 경로는 [탐색 지도](source-navigation-map.md), 실행 순서는 [수명주기](runtime-lifecycle.md)를 참조한다.

## Verification

2026-09-08 현재 checkout의 모듈 경로, `framework/api/.../Factory.java`의 getAndInitialize 및 `Environment.java`의 prefix/putClassSet을 정적 확인했다. Spring 미사용은 이 조사 대상 스택의 구조 설명이며 모든 향후 소비 프로젝트의 의존성까지 금지하거나 보장하는 규칙은 아니다.
