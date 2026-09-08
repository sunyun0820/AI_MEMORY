---
id: MEM-20260908-frame-lifecycle
type: project
scope: project
project: cmos-frame
domain: runtime-lifecycle
tags: [framework, cmos, lifecycle, factory-init, dispatcher, request-flow]
status: active
confidence: high
created: 2026-09-08
updated: 2026-09-08
last_seen: 2026-09-08
occurrences: 1
source_agent: antigravity
---

# C-MOS 초기화와 요청 수명주기

## Bootstrap Contract

현재 `Factory.initialize(args)` 순서는 Environment → Logger → Document → Configuration → 다국어 설정 → Encryption → Database → Context → Entry → Business → Property → Worker → Connector → Scheduler → Plugin이며 설정이 켜지면 Daemon을 초기화한다.

EntryFactory에서 Processor.initialize가 실행되고 권한 캐시 reload가 SeparatedTransaction을 만들 수 있다. transaction ID 발급에 ContextFactory가 필요하므로 **Database → Context → Entry** 의존성을 유지한다. getter의 null 검사는 반환할 자기 Factory 필드를 대상으로 한다.

현재 destroy 순서는 Plugin → Scheduler → Worker → Connector → Property → Business → Entry → Context → Database → Encryption → Configuration → Document → Logger → Daemon이다. 초기화의 정확한 역순이라고 단순화하지 않는다. Entry가 Context보다 먼저 종료되는 의존 경계는 유지된다.

## Request Contract

BaseDispatcher.executeInternal의 정상 메시지 처리 흐름:

1. 메시지 파싱. 파싱 실패는 message error 응답을 만들고 Context 생성 전에 반환한다.
2. preStart(request) → Context 생성(start) → preExecute(context).
3. getEvent로 Event 또는 Controller 메서드를 찾는다.
4. Event는 preInvoke → validation → execute → postInvoke를 수행한다. CoreRule은 validation/execute를 messageValidation/process에 연결한다. Controller 경로는 preInvoke → 매핑 메서드 호출 → postInvoke다.
5. 정상 흐름에서 commit(context) 후 성공 응답을 설정한다. try 내부 예외는 rollback 및 실패 응답 설정으로 이어진다.
6. finally에서 postExecute → close → postClose를 각각 try/catch로 호출한다.

## Applicability / Recurrence Prevention

- command 실행 전 검사는 preExecute 경계를 확인한다.
- postExecute는 commit/rollback 뒤에 호출된다. 후처리 실패까지 앞선 업무 commit을 되돌린다고 가정하지 않는다.
- 위 순서는 일반 executeInternal 경로다. Worker timeout 등 바깥 실행 경계는 별도로 확인한다.
- commit 호출과 실제 DB 성공 보장은 다르다. [트랜잭션의 예외 처리 한계](persistence-and-transaction.md)를 따른다.
- 구체적인 시작 오류는 [권한 캐시 bootstrap 사고](../../incidents/mes-core-api-auth-bootstrap-order.md)에 보존한다.

## Verification

2026-09-08 현재 `framework/api/.../Factory.java`와 `framework/iia/.../BaseDispatcher.java`의 분기·호출 순서를 정적 대조했다. 서버 시작·요청 호출·DB 검증은 이번 정제에서 수행하지 않았다.
