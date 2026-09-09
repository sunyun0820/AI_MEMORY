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
occurrences: 2
source_agent: codex
---

# C-MOS 3.5.2 매뉴얼의 API·소비 프로젝트 계약

## Core Knowledge

매뉴얼의 공개 API 예제는 현재 인터페이스에서, 실행·패키징 설명은 실제 소비 UI 프로젝트에서 확인한다. 버전 번호가 같아도 작업 소스의 초기화 순서가 과거 문서와 다를 수 있다.

## API Contracts

- Business: `getEventByName`, `getEventByUrl`을 사용하며 `getEvent(String)`은 deprecated다.
- Connector: `getConnector(Connector.Type)`; target sender는 `getSender(Connector.Type, String)` 또는 connector의 `getSender(String)`.
- Context Factory: `getGuId()`, `getRequestId()`, `makeTid()`, `getContext()`; 인접 API 이름으로 `getTid()`를 만들어 쓰지 않는다.
- Factory 단일 구현체 조건은 [architecture](architecture.md), 초기화의 현재 `Database → Context → Entry` 의존성은 [runtime-lifecycle](runtime-lifecycle.md)이 기준이다. 과거 3.5.2 문서의 `Database → Entry → Context` 순서를 현재 예제에 복사하지 않는다.

## Consumer Project Boundary

원본에서 확인한 교육용 UI는 `com.thirautech.cmos.web.WebServer.main`에서 `Factory.initialize(args)`를 호출하며 설정 원본은 `src/main/resources/config`다. 당시 POM은 프레임워크 3.5.2·plugin-web-starter를 사용하고 install 시 의존 JAR을 target/libs, config/webapp/wwwroot/스크립트를 target에 복사했다. 이 경로는 소비 프로젝트별 POM 확인 없이 전체 C-MOS 배포 표준으로 확대하지 않는다.

원본 매뉴얼의 DB 지원 설명 범위는 MSSQL·Oracle·PostgreSQL이다. 현재 배포·지원 정책이 달라졌는지는 매뉴얼 갱신 시 별도로 확인한다.

## Verification

원본은 WebServer, 세 Factory 인터페이스, UI POM/config를 정적 확인한 기록이다. 2026-09-08 Refine에서는 현재 framework의 Factory·인터페이스 계약을 재대조했으며 교육용 UI 패키징 실행은 하지 않았다. Maven·DB·HTTP·운영 배포 검증 기록으로 사용하지 않는다. DOCX 제작 절차는 [별도 lesson](../../lessons/source-grounded-docx-manual-validation.md)을 참조한다.
