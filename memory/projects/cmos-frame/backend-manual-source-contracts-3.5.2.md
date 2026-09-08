---
id: MEM-20260908-155842
type: project
scope: project
project: cmos-frame
domain: developer-documentation
tags: [manual, backend, framework-3.5.2, factory, api, maven-install]
status: active
confidence: high
created: 2026-09-08
updated: 2026-09-08
last_seen: 2026-09-08
occurrences: 1
source_agent: codex
---

# C-MOS Framework 3.5.2 백엔드 매뉴얼의 현재 소스 계약

## Context

C-MOS Framework 3.5.2를 사용하는 개발자용 백엔드 매뉴얼을 작성하면서 `cmos-frame`, `mes-core`, 교육용 UI 프로젝트의 현재 소스를 기준으로 진입점, 초기화 순서, 호출 API, 환경 설정과 배포 방식을 확인했다. 기존 Word/PPT/HTML 자료는 참고 자료일 뿐이며, 충돌할 때는 현재 소스와 설정을 우선한다.

## Symptom

과거 문서나 인접 API의 형태를 따라 예제를 추정하면 컴파일되지 않는 메서드 호출, 폐기 예정 API, 실제 패키징과 다른 배포 절차가 매뉴얼에 들어갈 수 있다.

## Root Cause

프레임워크의 공개 API와 교육용 UI 프로젝트의 빌드 설정은 버전별로 달라질 수 있다. 특히 Factory 계열 메서드는 이름이 유사해도 실제 인터페이스의 인자와 반환 계약이 서로 다르다.

## Correct Approach

1. 백엔드 실행 진입점은 UI 프로젝트의 `com.thirautech.cmos.web.WebServer.main`이며 `Factory.initialize(args)`를 호출한다.
2. `Factory.initialize`의 현재 순서는 Environment, Logger, Document, Configuration, 다국어 설정, Encryption, Database, Entry, Context, Business, Property, Worker, Connector, Scheduler, Plugin이며, 설정에 따라 Daemon이 뒤따른다.
3. `Factory.getAndInitialize`는 구현 클래스가 없거나 둘 이상이면 실패하므로 Factory 인터페이스당 구체 구현은 정확히 하나여야 한다.
4. 현재 Business API는 `getEventByName`과 `getEventByUrl`을 사용하며 `getEvent(String)`은 deprecated다.
5. Connector API는 `getConnector(Connector.Type)`이고, target별 sender는 `getSender(Connector.Type, String)` 또는 connector의 `getSender(String)`로 얻는다.
6. Context Factory에는 `getGuId()`, `getRequestId()`, `makeTid()`, `getContext()`가 있고 `getTid()`는 없다.
7. 교육용 UI의 설정 원본은 `src/main/resources/config`이며 `cmos.json`, `web.json`, `mybatis.xml` 등 실제 파일을 설명 기준으로 삼는다.
8. UI POM은 프레임워크 버전 3.5.2와 `plugin-web-starter`를 사용한다. `mvn install` 시 의존 JAR은 `target/libs`에 복사되고, config/webapp/wwwroot/스크립트 등의 리소스는 `target`으로 복사된다.
9. 개발자 매뉴얼의 공식 DB 지원 범위는 MSSQL, Oracle, PostgreSQL로 한정한다.

## Reusable Rule

C-MOS 매뉴얼의 코드 예제와 지원 범위는 오래된 문서나 메서드명 추정이 아니라 현재 버전의 인터페이스, 구현 소스, 소비 프로젝트 POM과 설정 파일을 함께 대조해 확정한다.

## Verification

- `WebServer.java`, `Factory.java`, `InterfaceBusinessFactory.java`, `InterfaceConnectorFactory.java`, `InterfaceContextFactory.java`를 정적 확인했다.
- 교육용 UI의 `pom.xml`과 `src/main/resources/config`를 정적 확인했다.
- 완성 매뉴얼의 정적 구조 및 코드 패턴을 검사했지만 Maven 실행, DB 접속, HTTP 호출과 운영 배포는 수행하지 않았다.
