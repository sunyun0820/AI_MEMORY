---
id: MEM-20260909-frame-threadpool
type: project
scope: project
project: cmos-frame
domain: concurrency-and-threading
tags: [framework, cmos, threadpool, jetty, worker-context, dispatcher, concurrency, dbcp]
status: active
confidence: high
created: 2026-09-09
updated: 2026-09-09
last_seen: 2026-09-09
occurrences: 1
source_agent: antigravity
---

# C-MOS 스레드풀 상한·거부 처리·작업 종료의 경계

## Core Knowledge

현재 WorkerContext는 WorkerType마다 SynchronousQueue와 ThreadPoolExecutor를 만든다. **getRejectionHandler가 new Thread(r).start()를 실행하므로 workerMaxThreadCount는 프로세스 전체 작업 스레드의 엄격한 상한이 아니다.** 설정값 400을 외부 요청 400개 처리 보장으로 읽거나 max만 낮추면 과부하가 해결된다고 가정하지 않는다.

## Pool / Dispatch Boundaries

- 일반 BaseDispatcher.execute는 WorkerFactory.addDispatcherSync로 executeInternal을 DISPATCHER에 위임하고 동기 대기한다.
- WorkerType.WORKER와 DISPATCHER는 별도 executor다. 한 풀의 수치를 모든 백그라운드 작업의 합계로 해석하지 않는다.
- Quartz의 AbstractJob.execute → DispatcherConcurrentJob.executeJob → dispatcher.execute는 실제 Job 실행 경로다. Quartz 풀을 단순 트리거 감시 전용이라고 설명하지 않는다.
- 원본은 Jetty 웹 풀 → 내부 Dispatcher 구성을 기록한다. 정적 리소스·직접 Servlet 등 모든 HTTP 경로가 같은 업무 위임 경로를 탄다는 보장은 아니다.

## Configuration / Failure Boundaries

현재 Configuration의 기본 worker 값은 min=0, max=400, keepAlive=60초, timeout=0이다. WorkerContext는 양수 설정을 반영하며, addWorkerSync의 timeout=0은 future.get() 무기한 대기 경로다.

WebDataConfig는 min/max를 worker 설정에서 초기화하고 idleTimeout은 workerTimeOut×1000으로 만든다. 이름이 비슷해도 웹 idle timeout과 업무 future timeout은 의미·단위가 다르다. 실제 Jetty 생성자·버전·배포 설정은 별도로 확인한다.

- 거부 시 별도 스레드를 만드는 경로에는 동일한 제한이 없다. 웹 풀 상한만으로 Scheduler/WORKER 등 모든 유입이 제한된다고 가정하지 않는다.
- addWorkerSync는 대기 실패를 예외로 바꾸지만 future.cancel을 호출하지 않는다. 요청 timeout이 작업 중지·DB rollback 완료를 뜻하지 않는다.
- destroyWorker는 awaitTermination을 호출하지만 해당 메서드에는 executor.shutdown이 없다. 종료 로그만으로 작업 수락 중지·스레드 종료를 확정하지 않는다.
- workerCount 감소가 finally가 아니므로 작업 예외 후 수치가 남을 수 있다. 이 수치를 실제 스레드 수나 정확한 진행 작업 수로 단정하지 않는다.
- DB 풀 크기·점유 시간·요청당 연결 수·CPU/I/O·거부 정책·실측 부하를 함께 확인한다. “DB 풀의 1~2배로 반드시 조정”, “소스 수정 없이 설정만 변경”이라는 고정 처방은 근거가 부족하다.

## Verification

2026-09-09 현재 framework/iia/.../context/WorkerContext.java, scheduler/AbstractJob.java·DispatcherConcurrentJob.java, framework/api/.../configuration/Configuration.java, framework/core/.../web/data/WebDataConfig.java를 정적 확인했다. BaseDispatcher의 동기 위임도 대조했다. Jetty/Quartz 라이브 기동·부하·DB·메모리 고갈 시험 및 2nd-battery resolved JAR의 동일성은 확인하지 않았다.
