---
id: MEM-20260909-151501
type: project
scope: project
project: cmos-starter
domain: web-server
tags: [cmos-starter, plugin-jetty, jetty, handler-chain, security, query-string, web-filters]
status: active
confidence: medium
created: 2026-09-09
updated: 2026-09-10
last_seen: 2026-09-09
occurrences: 2
source_agent: antigravity
---

# C-MOS Jetty 정적 리소스와 민감 query 차단의 경계

## Core Knowledge

2026-09-09 plugin-jetty 조사본에서 `ApiHandler`는 resourceBase의 정적 리소스이면 API 처리를 건너뛰었다. API용 webFilters 설정만으로 정적 요청까지 차단된다고 가정하지 않는다.

## Handler Contract

`JettyServer.start`의 등록 순서는 `HttpMethodBlock → SensitiveQueryBlock → Etag(캐시 설정 조건부) → NotAccessUri → Api → WebAppContext`였다.

`SensitiveQueryBlock`은 `request.getQueryString`을 `&`/`;`로 나눠 원래 키와 UTF-8로 한 번 디코딩한 키를 검사한다. 일치하면 HTTP 400과 handled를 설정하고 원문 값 대신 URI·일치 키·IP를 기록한다. body는 읽지 않는다. `/login.html`, `/mobile/login.html`, `/login`이 같은 앞단 검사를 거치도록 배치한 구성이다.

## Applicability / Recurrence Prevention

- 이 조사본의 구조이며 모든 C-MOS 버전의 정적 요청 처리 규칙으로 일반화하지 않는다.
- 등록 순서·handled 표시만으로 모든 후속 핸들러·접근 로그·프록시의 동작을 보장하지 않는다. 실제 handled 검사와 기록 지점을 구분한다.
- query가 붙은 POST, 업무상 같은 키, 중복 키·디코딩 처리를 따로 검토한다. body를 읽지 않는다는 사실은 부작용 없음이나 암호화·전송 보호의 증거가 아니다.
- 값 비기록 표본을 브라우저·모든 로그·프록시의 무노출 보장으로 확대하지 않는다.
- 당시 의존성/보안 수정은 `3.5.3-SNAPSHOT`으로 기록됐다. 소스·artifact·실행 JAR의 동일성과 과거 브랜치 선택을 구분한다.

## Evidence

2026-09-09 `plugin/plugin-jetty/src/main/java/com/thirautech/cmos/jetty/JettyServer.java`의 등록·차단 분기와 `handler/ApiHandler.java`의 정적 리소스 우회를 확인한 기록이다.

원본에는 plugin 빌드·install, 정적 로그인/API 민감 query의 400, 시험값의 조사 로그 미검출이 기록돼 있다. 이 표본을 전체 배포·보안 진단 통과로 확대하지 않는다. 화면 쪽 전송 계약은 [BSMES 로그인 사례](../../lessons/appscan-password-in-query-prevention.md)를 참조한다.
