---
id: MEM-20260909-171501
type: lesson
scope: global
project: mes-core
domain: security
tags: [jwt, alg-none, signature-validation, security-web-filter, authentication-bypass, login-boundary]
status: active
confidence: high
created: 2026-09-09
updated: 2026-09-09
last_seen: 2026-09-09
occurrences: 1
source_agent: antigravity
---

# JWT alg=none 및 서명 누락 위조 토큰의 선제 차단과 로그인 엔드포인트 토큰 검증 경계

## Core Knowledge

인증 필터(`SecurityWebFilter`)는 토큰 검증 대상 URL(`validTokenUrlMethodMapList`: `/api`, `/usermenu` 등)이 아닌 공개/로그인 엔드포인트(`/login`)라도, 요청 헤더에 `Authorization`이 포함되어 있다면 `alg: none`이거나 서명부(3번째 파트)가 누락된 위조 JWT를 컨트롤러 진입 전 즉시 `HTTP 401 Unauthorized`로 선제 차단해야 한다.

반면, 만료 토큰(expired)이나 정상 서명 형식(`HS256` 등)의 토큰은 브라우저(localStorage)에 남은 이전 토큰을 헤더에 달고 재로그인을 시도하는 클라이언트 관례를 지원하기 위해 필터를 통과시켜 로그인 비즈니스 로직(자격 증명 검증)에 위임한다.

## Applicability

- **적용 대상**: JWT 기반 인증 필터(`SecurityWebFilter`) 및 로그인/공개 엔드포인트 경계
- **적용 조건**: 토큰 검증 비대상 URL이지만 클라이언트가 Authorization 헤더를 붙여 요청할 수 있는 환경
- **예외/주의**: 만료 토큰까지 공개 엔드포인트에서 일괄 차단하면 재로그인 자체가 불가능해질 수 있으므로, **"서명 누락 / `alg: none` 위조 토큰만 선별 차단"**하는 정책 경계를 유지해야 한다.

## Avoid / Recurrence Prevention

- **비인가 경로에 대한 오판 방지**: "`/login`은 로그인 전 엔드포인트이므로 인증 필터(`SecurityWebFilter`)의 영향을 전혀 받지 않는다"고 가정하지 말 것.
- **과도한 검증으로 인한 기능 장애 방지**: 로그인 화면 진입 시 만료된 토큰의 유효성 전체(만료 시간 검증 등)를 검사하면 사용자가 로그아웃/만료 후 다시 로그인하는 정상 시나리오가 401에 막혀 무한 루프에 빠질 수 있으므로, 만료 검증과 서명 위조 검증을 분리할 것.

## Root Cause & Mechanism

1. **CVE/취약점 배경**: JWT의 `alg: none` 취약점은 공격자가 헤더에 `{"alg":"none"}`을 설정하고 서명부를 비워 서버가 서명 검증을 건너뛰고 페이로드(권한, 사용자 ID)를 신뢰하게 만드는 고전적 인증 우회 공격이다.
2. **C-MOS 필터 분기 설계 (`SecurityWebFilter.java`)**:
   ```java
   if (!validUrl(request)) {
       // 토큰 검증 대상이 아닌 URL이라도 서명 없는 위조 토큰은 거부
       return rejectUnsignedToken(request);
   }
   ```
3. **위조 판정 기준 (`rejectUnsignedToken`)**:
   - Authorization 헤더의 JWT가 3개 파트로 분리되지 않거나, 3번째 파트(서명부)가 비어있는 경우
   - 1번째 파트(Header Base64) 디코딩 결과 `alg` 필드가 없거나 대소문자 무관 `"none"`인 경우
   - 위 조건 충족 시 비즈니스 로직 이전에 `WebUtility.sendUnAuth(..., "unsigned Authentication Token")`로 401 JSON 응답 반환.

## Verification

- **라이브 서버 실증 (2026-09-09, `http://localhost:22112/login`)**:
  1. `alg: none` 토큰(서명부 없음)으로 `POST /login` 요청 시:
     - 응답: `HTTP 401 Unauthorized` (`{"MESSAGE":"Unauthorized","CODE":401,"ISSUCCESS":false}`)
     - 서버 로그: `[ACCESS DENIED][URL:/login] ... [unsigned Authentication Token]` 즉시 차단 확인.
  2. `alg: HS256` 서명부 포함 토큰으로 동일 요청 시:
     - 응답: `SecurityWebFilter` 통과 후 `AbstractLoginController`에서 자격 증명 검증 수행 → `HTTP 200 OK`, `ISSUCCESS: false` (`[MES-0120] Login is denied by login policy`) 반환 확인.
