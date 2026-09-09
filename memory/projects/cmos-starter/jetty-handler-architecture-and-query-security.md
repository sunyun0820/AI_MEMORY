---
id: MEM-20260909-151501
type: project
scope: project
project: cmos-starter
domain: web-server
tags: [cmos-starter, plugin-jetty, jetty, handler-chain, security, query-string, web-filters]
status: active
confidence: high
created: 2026-09-09
updated: 2026-09-09
last_seen: 2026-09-09
occurrences: 1
source_agent: antigravity
---

# C-MOS Starter plugin-jetty 핸들러 체인 구조와 쿼리스트링 보안 제약

## Context

`cmos-starter`의 `plugin-jetty`는 C-MOS 웹 애플리케이션의 내장 웹 서버(Jetty 11) 생명주기와 HTTP 요청 처리를 담당하는 핵심 모듈이다. 보안 취약점 진단(AppScan "조회의 비밀번호 매개변수") 조치 과정에서 정적 리소스와 API 핸들러의 실행 분기 및 쿼리스트링 보안 제약 구조가 확인되었다.

## Invariant & Module Boundaries

### 1. HandlerCollection 등록 순서와 실행 흐름
`JettyServer.java`의 `start()` 메소드에서 `HandlerCollection handlers`에 등록되는 순서는 다음과 같다:

1. `addHandlerBySensitiveQueryBlock(handlers)`: 모든 HTTP 요청의 쿼리스트링 민감 파라미터 사전 검사 (보안 최우선 핸들러)
2. `addHandlerByEtag(handlers, context)`: ETag 및 캐시 헤더 처리
3. `addHandlerByNotAccessUri(handlers)`: `userNotAccessUris`에 정의된 비인가 URI 차단
4. `addHandlerByApi(handlers, server, context)`: `ApiHandler` (C-MOS API 라우팅 및 `webFilters` 실행)
5. `addHandlerByWeb(handlers, context)`: `WebAppContext` (정적 HTML, CSS, JS 파일 서빙)

### 2. 정적 리소스 서빙과 webFilters의 실행 경계
`ApiHandler.java`는 요청 처리 시작 시 `context.getResource(url)`을 검사한다:
`java
Resource resource = context.getResource(url);
if (resource != null && resource.exists()) {
    isResource = true;
    return;
}
`
- **중요 경계**: `/login.html`, `/mobile/login.html` 등 `resourceBase`(`wwwroot`)에 존재하는 정적 파일 요청은 `ApiHandler`에서 즉시 탈출(return)하여 5번 `WebAppContext`의 Jetty `DefaultServlet`으로 직행한다.
- **불변조건**: `web.json`에 등록된 `webFilters`(`CorsWebApiFilter`, `RequestSchemaWebFilter`, `SecurityWebFilter` 등)는 **정적 웹콘텐츠 요청 시 절대 실행되지 않으며, 오직 API 요청에만 적용된다**.
- 따라서 정적 HTML 요청을 포함한 전체 서버 차원의 HTTP 보안 제어는 반드시 `addHandlerByApi` 이전의 Jetty Handler 레벨에서 처리해야 한다.

### 3. 쿼리스트링 민감 정보 보안 정책 (Password in Query String)
- **제약**: 비밀번호, 인증 토큰 등 민감 정보는 URL 쿼리스트링에 위치해서는 안 되며, 반드시 암호화된 요청 본문(Body)으로 전송되어야 한다.
- **정상 웹데이터와의 격리**: 정상 로그인(`POST /login`) 및 비즈니스 API 호출은 본문 JSON의 `WEBDATA` 배열을 사용하며, 요청 URL 뒤에 `?` 쿼리스트링이 없으므로 `request.getQueryString()`은 `null`이다.
- **차단 메커니즘**: `addHandlerBySensitiveQueryBlock`은 `request.getQueryString()`만 검사하므로 본문 스트림이나 정상 API 동작에 0%의 부작용을 보장하면서, 주소창에 파라미터를 노출하는 `password1`, `password`, `pwd`, `passwd` 등의 쿼리 파라미터를 HTTP 400으로 즉시 차단한다.
- **로그 유출 방지**: 보안 위반 차단 로그 기록 시 URI, 파라미터명, IP만 로깅하고 비밀번호 원문 값은 절대 로그에 남기지 않는다.

### 4. 브랜치 및 의존성 불변조건
- `web-ui`의 `pom.xml`은 `plugin-web-starter:3.5.3-SNAPSHOT` 및 `plugin-jetty:3.5.3-SNAPSHOT`을 참조한다.
- `cmos-starter` 저장소(`sf/solution/c-mos/plugin.git`)는 로컬 체크아웃 기본값이 `ver3.5.2`일 수 있으나, 활성 보안 수정 브랜치는 `origin/3.5.3-SNAPSHOT`이다. 작업 및 빌드 시 반드시 `3.5.3-SNAPSHOT` 브랜치를 기준으로 진행해야 한다.

## Verification

- `plugin-jetty`에 `addHandlerBySensitiveQueryBlock`, `findSensitiveQueryParam`, `isSensitiveParamName` 구현 후 `mvn clean compile` 및 `mvn install` 성공 (`3.5.3-SNAPSHOT`).
- `password1=...`, `pwd=...`, URL-인코딩된 `%70%61%73%73%77%6f%72%64%31=...` 쿼리 매개변수 차단 및 정상 쿼리 통과 검증 완료.