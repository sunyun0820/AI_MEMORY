---
id: MEM-20260908-cmos-callback-contract
type: project
scope: project
project: cmos-frame
domain: web-callback-input-response-contract
tags: [framework, cmos, callback, apiMapping, servletMapping, abstract-event, core-rule, message-data]
status: active
confidence: high
created: 2026-09-08
updated: 2026-09-09
last_seen: 2026-09-08
occurrences: 1
source_agent: codex
---

# C-MOS 외부 JSON 콜백의 입력·응답·실행 경계

## Core Knowledge

CoreRule.getWebData는 WEBDATA 접근 helper이며 모든 수신 JSON의 허용 스키마는 아니다. 파싱된 object는 getRequestData().getMap 또는 상속된 getMessageMap으로 접근할 수 있다. 다만 필드 접근 가능성과 실제 endpoint가 외부 요청을 받아 처리하는 것은 별도 계약이다.

## Applicability / Adapter Selection

- 기존 apiMapping/CoreRule을 재사용하려면 메시지 파서, URL 매핑, preStart/preExecute와 인증·스키마 필터가 외부 payload를 허용하는지 먼저 확인한다. 문법적으로 유효한 JSON object라는 사실만으로 충분하지 않다.
- 원본에서 확인한 표준 Dispatcher는 MessageData 응답을 생성·직렬화한다. getWebData 대신 원문 map을 읽는 변경이 외부의 code/result/message/data 같은 응답 스키마까지 바꾸지는 않는다.
- 외부가 표준 응답을 허용하면 기존 CoreRule 경로를 검토한다. 임의 응답을 요구하면 servletMapping 또는 별도로 검증된 Dispatcher/어댑터 확장 경로가 필요하다. Servlet이 유일한 해결책이라는 규칙은 아니다.
- Servlet으로 우회하면 기존 Dispatcher의 Context 생성·인증·commit/rollback·close 책임을 자동 상속한다고 가정하지 않는다. Manager 호출에 필요한 실행 환경을 명시적으로 확인한다.
- CoreRule은 messageValidation/process·MES DbContext 관례를 사용한다. generic AbstractEvent의 직접 apiMapping 지원은 실제 웹 로더와 매핑 타입을 확인해야 하며, 클래스 상속만으로 연결 가능성을 확정하지 않는다.

## Verification

원본은 AbstractEvent/AbstractController/CoreRule, BaseDispatcher, MES Dispatcher와 MessageData의 입력 접근 및 응답 직렬화를 정적으로 대조한 기록이다. 2026-09-09 현재 AbstractEvent가 AbstractController를 상속하고 getMessageMap을 사용할 수 있음, CoreRule의 getRequestData/getWebData helper를 다시 확인했다. 실제 callback·Servlet·서버·DB 검증은 수행하지 않았다. [Hyosung 사례](../hyosung/agv-integration-boundaries.md)는 별도의 프로젝트 배치 예다.
