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

# C-MOS Framework Architecture & Module Boundaries

## Context
C-MOS Framework 3.5.x 스택은 Spring Boot나 Spring Framework를 사용하지 않는 순수 Java 기반 자체 프레임워크다. 향후 AI Agent가 불필요한 전체 소스 탐색 및 오추측을 하지 않도록 핵심 모듈 경계와 컴포넌트 탐색 규칙을 정립한다.

## Architecture & Module Chain
Canonical Naming 체계:
1. **FRAME-API** (`framework-api`): 순수 계약 계층
   - 패키지: `com.thirautech.cmos.framework.api`
   - 인터페이스, Abstract 기본 클래스, 어노테이션, `Factory`, `Environment` 포함. 외부 의존성은 slf4j, javax.persistence, mybatis 수준으로 최소화됨.
2. **FRAME-IIA** (`framework-iia`): 기반 인프라/구현 계층
   - 패키지: `com.thirautech.cmos.framework.iia`
   - `FRAME-API` 의존. Base 구현체(`BaseController`, `BaseManager`, `BaseRepository`, `BaseDispatcher`, `BaseTransaction`), DB 커넥션 풀 및 드라이버, 14개 서브 팩토리 구체 클래스, SQL Maker, 파서, 커넥터 구현체 포함.
3. **FRAME-CORE** (`c-mos-core`): MES 도메인 공통 기반
   - 패키지: `com.thirautech.cmos.mes.core.*`, `com.thirautech.cmos.core.*`
   - `FRAME-IIA` 의존. `CoreController`, `CoreManager`, `CoreRepository`, `CoreEntity`, `CoreRule`, `DbContext`, 공통 상태(State) 및 옵션셋(OptionSet), 기본 Web Servlet Dispatcher 포함.
4. **MES-CORE** (`mes-core`): MES 공통 비즈니스 코어
   - 패키지: `com.thirautech.cmos.mes.core.*`
   - `FRAME-CORE` 의존. 상위 비즈니스 모델러(CDS, DAS, PMS, POS, PPS, QMS, RDS), 웹 보안/인증 필터, SSO, 파일 업/다운로드, 바코드 유틸리티 포함.
5. **PROJECT**: 실제 구축 프로젝트
   - `MES-CORE` 및 `FRAME-CORE`의 Core 클래스를 상속받아 고객사별 사이트 로직 구현.

## Verified Invariants
- **Spring 미사용**: Spring Web, Spring Data, Spring Security 등을 사용하지 않으며 자체 Dispatcher, JPA Repository 구현체, 자체 서블릿 필터를 사용한다.
- **클래스패스 스캔 범위**: `Environment.PACKAGE_PREFIX_SET = Set.of("com.thirautech")`로 선언되어 있어, `Environment.putClassSet` 시 패키지 prefix가 `com.thirautech`인 클래스만 스캔 대상(`classSet`)에 수집된다. 프레임워크 자동 탐색 대상은 이 하위 패키지에 위치해야 한다.
- **Factory 단일 구현체 계약**: `Factory.getAndInitialize(cls)`는 대상 인터페이스 구현체가 `0`개이거나 `2개 이상`이면 `UnsupportedOperationException`("Not Found" 또는 "Too Many Class")을 발생시킨다. 인터페이스당 구체 구현 클래스는 스캔 범위 내에 정확히 1개여야 한다.

## Reusable Rule
C-MOS 관련 소스를 분석하거나 구현할 때 Spring 의존적 가정(어노테이션 기반 자동 구성 등)을 배제하고, `FRAME-API` -> `FRAME-IIA` -> `FRAME-CORE` -> `MES-CORE` -> `PROJECT` 계층 순서 및 `com.thirautech` 패키지 규칙에 맞추어 설계한다.
