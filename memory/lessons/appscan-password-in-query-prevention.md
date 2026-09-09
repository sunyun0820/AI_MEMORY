---
id: MEM-20260909-151502
type: lesson
scope: global
project: ""
domain: security
tags: [appscan, security, password-in-query, http-get, form-method, 2-track-defense]
status: active
confidence: high
created: 2026-09-09
updated: 2026-09-09
last_seen: 2026-09-09
occurrences: 2
source_agent: antigravity
---

# AppScan 조회의 비밀번호 매개변수 취약점 원인과 프론트·서버 2-Track 방어 패턴

## Context

웹 취약점 진단 도구(IBM Security AppScan)에서 BSMES 시스템을 점검하는 중 `조회의 비밀번호 매개변수(Password Parameter in Query String)` 취약점(심각도: 상, CVSS 8.2)이 `/login.html` 및 `/mobile/login.html` 2개 경로에서 검출되었다.

## Symptom

- 진단 보고서에 `GET /login.html?userId1=admin&password1=**CONFIDENTIAL 1**&SAVE-ID=on` 및 `GET /mobile/login.html?...` 요청이 기록되고, 서버가 200 OK로 응답하여 취약점으로 판정됨.
- 실제 정상 로그인은 프론트엔드 AJAX(`POST /login`, JSON Body)로 동작하고 있었음에도 스캐너에서 취약점이 검출됨.

## Root Cause

1. **프론트엔드 HTML `<form>` 명세 누락 및 `<input name="...">` 노출**:
   - `login.html` 내 `<form name="form" id="form">` 태그에 `method`와 `action` 속성이 지정되어 있지 않았음.
   - W3C HTML 표준에 따라 `method`가 없으면 기본값은 **`GET`**, `action`이 없으면 기본 제출 대상은 **현재 URL(`/login.html`)**이 됨.
   - `<input name="password1" type="password">`처럼 `name` 속성이 있으면 네이티브 submit 발생 시 브라우저가 자동으로 URL 쿼리에 `?password1=...`를 붙여 GET 요청을 발생시킴.
   - AppScan은 페이지의 DOM을 크롤링할 때 비밀번호 필드가 포함된 GET 폼을 감지하고, "GET으로 비밀번호를 전송하는 취약한 폼"으로 판단하여 시뮬레이션 GET 공격을 시도함.
2. **백엔드 정적 서빙의 쿼리 무시**:
   - 백엔드(Jetty/웹서버)는 `/login.html`이 정적 리소스이므로 뒤에 붙은 `?password1=...` 쿼리스트링을 무시하고 200 OK로 HTML을 그대로 서빙함.
   - 스캐너는 200 OK 응답을 받아 "비밀번호 파라미터를 GET으로 정상 수신/처리함"으로 확정 판정함.

## Wrong Approach

- **프론트엔드만 수정하는 경우**: HTML `<form method="POST">`로 수정하면 스캐너의 초기 폼 인식은 막을 수 있으나, 악의적 공격자나 쿼리 기반 파라미터 스캔이 직접 URL로 비밀번호를 주입할 때 서버가 200 OK로 응답하면 여전히 잠재적 위험이 남음.
- **백엔드 API 필터(`webFilters`)만 수정하는 경우**: C-MOS 프레임워크 구조상 정적 파일(`/login.html`)은 `ApiHandler`를 건너뛰므로 일반 API Filter에서는 해당 GET 요청이 전혀 가로채지지 않음.

## Correct Approach (2-Track 방어 패턴)

* **Track 1 (프론트엔드 HTML / JS 통제)**:
  - `<form id="form" method="post" action="/login">` 명시 및 submit 이벤트에서 `e.preventDefault()` 적용.
  - 로그인 입력 필드(`userId1`, `password1`)에서 `name` 속성을 완전히 제거하고 `id`만 유지하여, 예기치 않은 네이티브 폼 제출이 일어나더라도 URL 쿼리 파라미터로 조합되지 않도록 원천 차단.
  - `isLoginSubmitting` 플래그 및 제출 버튼 `disabled` 처리를 통해 엔터/버튼 연타 시 중복 요청(Double Submit) 차단.
  - AJAX를 통해 본문(JSON)으로만 전송하고 `entry`, `ssoFail` 등 업무상 필요한 쿼리는 정상 허용 후 즉시 URL 정리(`history.replaceState`).
* **Track 2 (백엔드/웹서버 인입 차단)**:
  - Jetty 핸들러 체인 최우선 순위(`addHandlerBySensitiveQueryBlock`) 또는 리버스 프록시 단계에서 `request.getQueryString()`을 검사.
  - `password`, `pwd`, `passwd` 등 민감 파라미터가 쿼리스트링에 포함된 요청 감지 시 즉시 **HTTP 400 Bad Request** 반환.
  - 로깅 시 비밀번호 원문은 마스킹/제외하고 URI, 파라미터 키 이름(`Param: password`), 클라이언트 IP만 기록.
  - 정상적인 비즈니스 호출(`POST` JSON body의 `WEBDATA`)은 쿼리스트링이 `null`이므로 전혀 영향을 주지 않음.

## Reusable Rule

비밀번호 입력란이 있는 로그인/회원가입 HTML 페이지는 `<form method="POST">` 명시와 함께 input의 `name` 속성을 제거하여 네이티브 쿼리 노출을 막고, 백엔드/프록시 최상단에서 쿼리스트링에 비밀번호 관련 키가 포함된 모든 요청을 HTTP 400으로 조기 차단하는 2-Track 방어 정책을 적용한다.

## Verification

- `JettyServer.java`에 민감 쿼리스트링 차단 핸들러 적용 후 `3.5.3-SNAPSHOT` 빌드 성공.
- **라이브 서버 실증 (2026-09-09, `localhost:22112`)**:
  - `GET /login.html?password=TEST_ONLY` 및 `?password1=TEST_ONLY` → `HTTP 400 Bad Request` 차단 확인.
  - `GET /mobile/login.html?password=TEST_ONLY` 및 `?password1=TEST_ONLY` → `HTTP 400 Bad Request` 차단 확인.
  - `GET /login.html?entry=process/wip&ssoFail=1` → `HTTP 200 OK` 정상 통과 및 기능 유지 확인.
  - 임의 패스워드(`MySecretPassword999!`) 주입 후 전체 로그 전수 조사 결과 패스워드 값 누출 0건 확인.