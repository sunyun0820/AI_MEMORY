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
updated: 2026-09-09
last_seen: 2026-09-08
occurrences: 1
source_agent: codex
---

# Hyosung AGV 예제의 모듈 배치와 검증 경계

## Core Knowledge

원본 real_edu 사례는 AGV REST 송신과 콜백 업무를 service에, Servlet·웹 매핑을 ui에 두고 Framework/MES-Core는 분석 근거로만 사용했다. 이는 해당 요청에서 승인된 작업 범위이며 이후 작업의 자동 수정·실행 권한이 아니다.

## Navigation / Applicability

- service의 example/testoutbound: 송신 예제.
- service의 example/testcallback: 콜백 업무.
- ui의 rest.json/web.json 및 Servlet: 외부 요청·응답 어댑터.
- 원본 checkout은 사용자 Desktop의 real_edu, 인접 cmos-frame/mes-core는 별도 E: 경로였다. 다른 머신에서는 실제 저장소와 매핑부터 확인한다.
- 기존 사용자 변경을 구분해 보존한다. 당시 .factorypath/POM의 변경 상태를 현재도 남은 변경이라고 저장하지 않는다.
- C-MOS 콜백의 입력·응답 선택 조건은 [프레임워크 메모리](../cmos-frame/web-callback-input-response-contract.md)를 참조한다.

## Verification / Authorization Boundary

원본에는 예제·매핑·HTML 문서 정적 확인과 TestCallbackServlet의 Java 17 대상 컴파일 기록이 있다. 실제 MES 기동, DB, 외부 AGV 송수신은 검증하지 않았다.

현재 작업의 허용 범위는 최신 사용자 지시와 프로젝트 정책으로 정한다. 메모리에 적힌 과거 컴파일·더미 테스트 허용을 DB·실제 외부 호출·운영 반영·Git 변경의 승인으로 확대하지 않는다. 이번 Refine은 원본 기록의 범위를 정리했으며 예제 실행이나 외부 연동 검증은 하지 않았다.
