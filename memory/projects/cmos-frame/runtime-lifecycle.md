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

# C-MOS Framework Runtime Lifecycle & Request Flow

## Context
프레임워크의 부트스트랩, 팩토리 초기화/종료 순서, 그리고 단일 API 요청이 디스패처를 통과하여 트랜잭션 커밋/롤백 및 자원 해제에 이르는 수명주기 계약을 정의한다.

## Bootstrap & Factory Lifecycle
- **초기화 진입점**: `Server.main` 또는 Web 진입점에서 `Factory.initialize(args)` 호출.
- **Factory 초기화 고정 순서** (`Factory.initialize` 내 순차 실행):
  1. `Environment.initialize(list)`
  2. `LoggerFactory`
  3. `DocumentFactory`
  4. `ConfigurationFactory`
  5. `Environment.setMultipleLanguage()`
  6. `EncryptionFactory`
  7. `DataBaseFactory`
  8. `EntryFactory`
  9. `ContextFactory`
  10. `BusinessFactory`
  11. `PropertyFactory`
  12. `WorkerFactory`
  13. `ConnectorFactory`
  14. `SchedulerFactory`
  15. `PluginFactory`
  16. `DaemonFactory` (설정 `isDaemonFactoryInitialize()`가 true일 때만)
- **종료 순서**: `Factory.destroy()` 호출 시 `Plugin` -> `Scheduler` -> ... -> `Logger` 역순으로 종료되며 `Daemon`은 맨 마지막에 종료된다.

## Request Execution Lifecycle (`BaseDispatcher`)
`BaseDispatcher.executeInternal(request)` 흐름:
1. `request.setMessageDocument()`: 수신 메시지 파싱
2. `preStart(request)`: `PreStartProcessor` 목록 순차 실행
3. `start(request)`: `ContextFactory.startContext(request)` 호출 및 요청 Context 생성
4. `preExecute(context)`: `PreExecuteProcessor` 목록 순차 실행
5. `getEvent(request, context)`: URL 또는 eventName으로 실행 대상 `Event` 또는 Controller 메서드 매핑
6. `Event` 실행:
   - `event.preInvoke()`
   - `event.validation()` (CoreRule에서 `messageValidation()`으로 연결)
   - `event.execute()` (CoreRule에서 `process()`로 연결)
   - `event.postInvoke()`
7. `commit(context)`: 정상 종료 시 Context의 모든 활성 트랜잭션 일괄 커밋
8. `catch (Exception)`: 예외 발생 시 `rollback(context)` 호출 및 `setFail(response, context, e)` 설정
9. `finally`:
   - `postExecute(context)`: `PostExecuteProcessor` 실행
   - `close(context)`: `ContextFactory.closeContext(...)` 호출
   - `postClose(context)`: `PostCloseProcessor` 실행

## Reusable Rule
API 요청 처리 중 발생하는 비즈니스 로직은 `validation()`과 `execute()` 단계에 배치되며, 트랜잭션의 커밋과 롤백, 컨텍스트 해제는 `BaseDispatcher`가 프레임워크 레벨에서 일괄 제어한다.
