---
id: MEM-20260908-hyosung-agv-boundaries
type: project
scope: project
project: hyosung
domain: agv-integration-boundaries
tags: [hyosung, agv, rest, callback, service, ui, scope, verification]
status: active
confidence: high
created: 2026-09-08
updated: 2026-09-10
last_seen: 2026-09-08
occurrences: 1
source_agent: codex
---

# Hyosung AGV 예제의 모듈 배치와 검증 경계

## Core Knowledge

2026-09-08 Hyosung `real_edu` 예제는 AGV REST 송신과 콜백 업무를 `service`에, Servlet·웹 매핑을 `ui`에 두었다. Framework/MES-Core는 연결 계약의 분석 근거였다.

## Navigation / Applicability

- `service/example/testoutbound`: 송신 예제.
- `service/example/testcallback`: 콜백 업무.
- `ui`의 `rest.json`, `web.json`, Servlet: 외부 요청·응답 어댑터.
- C-MOS 입력 접근, 응답 스키마 선택과 Dispatcher 우회 시 실행 책임은 [콜백 계약](../cmos-frame/web-callback-input-response-contract.md)을 참조한다. 이 예제의 모듈 배치를 모든 소비 프로젝트의 필수 구조로 일반화하지 않는다.

## Evidence / Authorization Boundary

원본에는 예제·매핑·HTML 문서의 정적 확인과 `TestCallbackServlet`의 Java 17 대상 컴파일 기록이 있다. 실제 MES 기동, DB, 외부 AGV 송수신 성공의 증거는 아니다.

후속 작업의 권한은 해당 사용자 요청과 프로젝트 정책을 따른다. 과거 예제 제작·컴파일·더미 테스트 허용을 DB·외부 호출·운영 반영·Git 변경의 승인으로 재사용하지 않는다.
