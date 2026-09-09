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
updated: 2026-09-09
last_seen: 2026-09-09
occurrences: 2
source_agent: antigravity
---

# BSMES 로그인 폼의 query 노출 조치와 검증 범위

## Core Knowledge

원본 BSMES AppScan 기록은 AJAX 로그인 외에 HTML form의 네이티브 제출과 정적 파일 서빙 경로를 함께 조사한 사례다. input의 name 제거·특정 query 키의 HTTP 400 차단은 당시 화면·Jetty 구성에서 선택한 방법이며 모든 로그인 폼의 공용 규칙이 아니다.

## Historical Approach

- 대상은 /login.html과 /mobile/login.html이었다. 기존 form에는 method/action이 없고 userId1·password1 입력에 name이 있었다.
- 당시 조치 기록은 form의 method=post/action=/login 명시, submit의 preventDefault, id로 값을 읽는 AJAX 경로를 유지한 name 제거, 중복 제출 제어를 포함한다.
- 정상 업무 query인 entry/ssoFail 처리와 URL 정리, 정적 리소스보다 앞선 Jetty 민감 query 차단을 함께 확인했다. 서버 측 위치와 한계는 [Jetty 메모리](../projects/cmos-starter/jetty-handler-architecture-and-query-security.md)를 참조한다.

## Applicability / Recurrence Prevention

이 방식은 현재 입력값 수집·전송 계약을 확인한 뒤에만 재사용한다. 네이티브 POST·FormData·serialize가 name에 의존하는 화면에서 name을 무조건 제거하면 값 전달을 깨뜨릴 수 있다.

HTTP 400 반환은 이미 URL에 담겨 전송된 값이 브라우저·앞단 프록시·기존 로그에 남지 않았다는 보장이 아니다. history.replaceState도 앞서 전송되거나 기록된 값을 지우는 수단으로 해석하지 않는다. query 검사와 JSON body 처리는 별개지만 query가 있는 POST나 업무상 같은 키 이름까지 부작용이 없다고 단정하지 않는다.

## Verification

원본에는 2026-09-09 로컬 서버에서 desktop/mobile 민감 query가 400, entry/ssoFail이 200이며 시험값이 조사 로그에서 검출되지 않았다는 기록이 있다. 이는 당시 표본 결과이지 AppScan 재진단 전체 통과나 모든 경로·로그의 비노출 증거가 아니다. 시험 문자열 원문과 일회성 점수는 보존하지 않는다.

2026-09-09 pull 이후 D:/thira/busan/web-ui/src/main/resources/wwwroot의 login.html:53 및 mobile/login.html:56을 재확인했다. 두 form 모두 method=post/action=/login이며 userId1·password1에는 name 속성이 없다. login.js:64 및 mobile/login.js:31에서 submit preventDefault, isLoginSubmitting 제어, id 기반 값 수집과 simpleAjax POST 호출을 확인했다. 따라서 앞선 checkout 불일치는 해소됐다. desktop의 ssoFail 표시 후 URL 정리와 로그인 성공 시 entry 처리도 코드에 있다. 이는 정적 구현 확인이며 실제 브라우저 제출·서버 HTTP·AppScan 재진단·배포 JAR 동일성은 이번에 검증하지 않았다.
