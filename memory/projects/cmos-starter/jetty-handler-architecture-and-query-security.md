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
updated: 2026-09-09
last_seen: 2026-09-09
occurrences: 2
source_agent: antigravity
---

# C-MOS Jetty 정적 리소스와 민감 query 차단의 경계

## Core Knowledge

원본 plugin-jetty 조사에서 ApiHandler는 resourceBase에 존재하는 정적 리소스를 확인하면 API 처리를 건너뛰었다. 따라서 API용 webFilters 설정만으로 해당 정적 요청이 차단된다고 가정하면 안 된다. 실제 전체 요청 보안 제어 위치는 배포 핸들러·프록시 흐름을 확인해 정한다.

## Handler Contract

2026-09-09 pull 이후 JettyServer.start의 등록 순서:

HttpMethodBlock → SensitiveQueryBlock → Etag(캐시 설정 조건부) → NotAccessUri → Api → WebAppContext.

민감 query 차단은 request.getQueryString의 파라미터 키를 검사하여 HTTP 400과 handled 표시를 설정하고, 원문 값 대신 URI·일치 키·IP를 기록하는 방식이었다. /login.html·/mobile/login.html의 정적 파일과 /login API가 같은 앞단 검사를 거치는 의도로 추가됐다.

## Applicability / Recurrence Prevention

- 이 구조는 해당 plugin-jetty 조사본의 계약이다. 모든 C-MOS 버전에서 webFilters가 정적 리소스에 절대 실행되지 않는다는 일반 규칙은 아니다.
- handled 표시와 등록 순서만으로 모든 후속 핸들러·접근 로그·앞단 프록시의 동작까지 보장하지 않는다. 실제 핸들러의 handled 검사와 로그 지점을 확인한다.
- query 검사만 한다는 것은 body를 읽지 않는다는 뜻이다. query가 붙은 POST, 업무상 같은 키, 디코딩·중복 키 처리까지 부작용이 0%라는 뜻은 아니다.
- body 사용을 별도 애플리케이션 암호화나 전송 보호의 증거로 해석하지 않는다. 비밀번호·인증 토큰을 모두 같은 전송 필드로 통일하는 규칙도 아니다.
- 값 비기록 표본을 전체 로그·브라우저·프록시의 무노출 보장으로 확대하지 않는다.
- 당시 web-ui 의존성/보안 수정은 3.5.3-SNAPSHOT으로 기록됐다. 브랜치·artifact·실행 JAR을 현재 작업마다 확인하고, 과거 브랜치 이름을 강제 checkout 명령이나 현재 사용자 승인으로 쓰지 않는다.

## Verification

원본에는 2026-09-09 plugin 빌드·install 성공, 정적 로그인/API의 민감 query 400, 시험값의 조사 로그 미검출이 기록돼 있다. pull 이후 D:/thira/cmos frame/plugin/plugin-jetty/src/main/java/com/thirautech/cmos/jetty에서 JettyServer.java:158, :357의 등록·차단 분기와 handler/ApiHandler.java:82의 정적 리소스 우회를 정적으로 재확인했다. 민감 키 검사는 &/; 분리, 원래 키 및 UTF-8 1회 디코딩 키를 대상으로 하며 body를 읽지 않는다. 소스 부재 제한은 해소됐지만 실제 서버·HTTP·로그·배포 테스트는 이번에 재실행하지 않았다. 화면 구현 확인은 [BSMES 로그인 사례](../../lessons/appscan-password-in-query-prevention.md)를 참조한다.
