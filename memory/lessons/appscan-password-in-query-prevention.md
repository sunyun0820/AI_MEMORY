---
id: MEM-20260909-151502
type: lesson
scope: project
project: busan
domain: security
tags: [appscan, security, password-in-query, http-get, form-method, 2-track-defense]
status: active
confidence: medium
created: 2026-09-09
updated: 2026-09-10
last_seen: 2026-09-09
occurrences: 2
source_agent: antigravity
---

# BSMES 로그인 폼의 query 노출 조치와 검증 범위

## Core Knowledge

2026-09-09 BSMES AppScan 대응은 AJAX 로그인뿐 아니라 HTML form의 네이티브 제출과 정적 파일 서빙 경로를 함께 다뤘다. input의 `name` 제거와 특정 query 키의 HTTP 400 차단은 해당 화면·Jetty 구성의 선택이며 모든 로그인 폼의 공용 구현 규칙이 아니다.

## Recorded Contract

- `/login.html`, `/mobile/login.html`의 기존 form은 method/action이 없고 `userId1`, `password1` 입력에 name이 있었다.
- 조치 후 `method=post`, `action=/login`, submit의 `preventDefault`, `isLoginSubmitting` 중복 제출 제어를 사용했다. JS가 id로 값을 읽어 `simpleAjax` POST를 보내므로 입력 name을 제거했다.
- desktop은 `ssoFail` 표시 후 URL 정리와 로그인 성공 시 `entry` 처리를 유지했다.
- 정적 리소스보다 앞선 민감 query 검사 위치·디코딩 계약은 [Jetty 메모리](../projects/cmos-starter/jetty-handler-architecture-and-query-security.md)에 둔다.

## Applicability / Recurrence Prevention

- 네이티브 POST·FormData·serialize가 name에 의존하는 폼에서 name 제거를 복사하면 값 전달을 깨뜨릴 수 있다. 실제 값 수집·전송 계약을 먼저 확인한다.
- HTTP 400이나 `history.replaceState`는 이미 전송·기록된 값을 브라우저·프록시·기존 로그에서 지우지 않는다.
- query 검사와 JSON body 처리는 별개다. query가 붙은 POST나 업무상 같은 키에 대한 부작용까지 없다고 단정하지 않는다.

## Evidence

2026-09-09 `web-ui/src/main/resources/wwwroot`의 desktop/mobile `login.html`, `login.js`에서 위 form·JS 계약을 정적으로 확인한 기록이 있다.

같은 날짜의 로컬 시험 기록은 desktop/mobile 민감 query의 400, entry/ssoFail의 200, 시험값의 조사 로그 미검출을 보고한다. 당시 표본 결과이며 AppScan 재진단 전체 통과나 모든 경로·로그의 비노출 증거는 아니다. 정적 확인을 브라우저 제출·배포 JAR 동일성 검증과 혼동하지 않는다.
