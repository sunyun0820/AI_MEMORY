---
id: MEM-20260909-171501
type: lesson
scope: project
project: mes-core
domain: security
tags: [jwt, alg-none, signature-validation, security-web-filter, authentication-bypass, login-boundary]
status: active
confidence: high
created: 2026-09-09
updated: 2026-09-10
last_seen: 2026-09-09
occurrences: 1
source_agent: antigravity
---

# mes-core 공개 로그인 경로의 제한적 토큰 검사와 호환 경계

## Core Knowledge

2026-09-09 조사한 SecurityWebFilter의 validUrl 비대상 경로는 rejectUnsignedToken으로 제한적인 형식 검사를 한다. 이는 이전 토큰을 붙여 /login·/loginwidget을 호출하는 해당 클라이언트의 재로그인 호환 분기이며 일반 JWT 인증 정책이 아니다. 이 분기를 통과했다는 사실은 토큰 서명이나 사용자 인증 성공을 뜻하지 않는다.

## Source Contract

조사본의 doStart는 ignore method 처리 → validUrl 분기 → 보호 URL의 WebUtil.getAuthentication 및 Site/IP·command/SQL 권한 검사 순서다.

validUrl=false 분기의 rejectUnsignedToken은:

- Authorization이 비어 있으면 통과시킨다.
- Bearer 접두사를 정리하고 점으로 나눈 결과가 **3개 미만**이거나 세 번째 부분이 비어 있으면 거부한다. 정확히 3부분인지 검사하는 구현은 아니다.
- header 디코딩/JSON 변환 실패, alg 누락·빈값·대소문자 무관 none이면 거부한다.
- 그 외에는 true를 반환한다. 여기서는 실제 서명 일치, 허용 알고리즘 목록, 만료·issuer·audience를 검증하지 않는다. alg=HS256처럼 보이고 세 번째 부분이 존재하는 것은 정상 서명의 증거가 아니다.

## Applicability / Recurrence Prevention

위 날짜에 기록된 클라이언트·인증 필터의 공개 로그인 계약을 유지·변경할 때 참고한다. 보호 URL까지 이 제한 검사를 대신 적용하거나 미검증 claim을 사용자 신원·권한으로 신뢰하지 않는다. 공개 경로에서 토큰을 완전히 검사할지 무시할지는 그 경로의 실제 인증 계약에 따라 별도로 결정한다.

“만료 토큰은 항상 허용해야 한다”, “공개 URL은 무조건 이 검사로 충분하다”로 일반화하지 않는다. 다른 URL 설정, ignore method, 토큰 없이 오는 요청과 실제 로그인 자격 증명 검증까지 구분한다.

## Verification

2026-09-09 cmos frame/core/.../web/filter/SecurityWebFilter.java의 doStart, rejectUnsignedToken, isNoneOrMissingAlg를 정적으로 확인한 기록이다. 원본 로컬 시험은 none 토큰의 401과 서명부가 있는 입력의 로그인 로직 진입 후 ISSUCCESS=false 응답을 기록한다. 후자는 로그인 성공이나 암호학적 서명 검증 증거가 아니다. 정적 확인과 당시 로컬 시험 결과를 모든 경로의 인증 검증으로 확대하지 않는다.
