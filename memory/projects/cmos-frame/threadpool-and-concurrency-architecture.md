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

# C-MOS Framework Thread Pool Architecture & Concurrency Control

## Context
C-MOS Framework 3.5.x 기반 시스템에서 외부 HTTP/API 요청, 스케줄러, 비즈니스 로직을 처리하는 멀티스레드 아키텍처와 실제 프로젝트(`2nd-battery` 등)의 동시성 제어 및 장애 예방 불변조건을 정의한다.

## 3대 쓰레드풀 계층 및 역할 분담
1. **Web Container Pool (Jetty `QueuedThreadPool`)**:
   - **스레드 명칭**: `CMOS-WEB-1`, `CMOS-WEB-2`, ...
   - **설정 파일**: `config/web.json` (`minThreads`, `maxThreads`, `idleTimeout`)
   - **역할**: 외부 클라이언트(웹 브라우저 UI, 설비 EAP/PLC)와의 HTTP/TCP 네트워크 I/O 수신, 인증/보안 필터링, 정적 웹 리소스(HTML/JS) 서빙, 응답 전송.
   - **비즈니스 격리**: 비즈니스 로직을 직접 수행하지 않고 `BaseDispatcher`를 통해 내부 디스패처 풀로 작업을 위임(`addDispatcherSync`)하고 동기 대기한다.
2. **Business Dispatcher Pool (C-MOS `WorkerType.DISPATCHER`)**:
   - **스레드 명칭**: `{workerThreadName}/DISPATCHER-1` (기본값: `CMOS/DISPATCHER-1`)
   - **설정 파일**: `config/cmos.json` (`workerThreadName`, `workerMinThreadCount`, `workerMaxThreadCount`, `workerKeepAliveTime`, `workerTimeOut`)
   - **구현체**: `WorkerContext` 내 `java.util.concurrent.ThreadPoolExecutor` (큐: `SynchronousQueue`)
   - **역할**: 일반 MES 웹/API 요청 및 스케줄러 작업의 **실제 비즈니스 로직(트랜잭션 시작, CoreRule/Controller 실행, MyBatis SQL 실행, 커밋/롤백) 병렬 수행**.
3. **Background Worker & Scheduler Pool**:
   - **`WorkerType.WORKER`**: `Factory.getWorkerFactory().addWorker()` / `joinWorker()`로 호출되는 단일 요청 내 대량 분할 작업 및 백그라운드 비동기 처리용 풀.
   - **Quartz `SimpleThreadPool`**: `config/scheduler.json`의 `org.quartz.threadPool.threadCount`(기본 10개)로 구동되며, 스케줄 트리거 감시 전용 풀. (실제 비즈니스 잡 실행 시 `DISPATCHER` 풀을 호출)

## Project Application Invariants (실제 프로젝트 동작 불변조건)
- **무설정 자동 동시 병렬 처리**:
  - 실제 프로젝트(`2nd-battery` 등)에서 별도 커스텀 스레드풀 코드를 작성하지 않고 `cmos.json`/`web.json`의 스레드 설정을 생략하더라도, 프레임워크 기본값(최소 0, 최대 400개, `SynchronousQueue`)에 의해 **외부 동시 요청이 최대 400개까지 자동으로 병렬 처리**된다.
- **설정값 상속 메커니즘**:
  - `web.json`에 `minThreads`, `maxThreads`, `idleTimeout`이 생략되면 `WebDataConfig`는 `cmos.json`의 `workerMinThreadCount`(0), `workerMaxThreadCount`(400), `workerTimeOut`(0)을 자동으로 상속받아 Jetty 풀을 초기화한다.

## Critical Pitfalls & 장애 예방 규칙
1. **DB 커넥션 풀(DBCP)과의 비율 불일치 (Hang 위험)**:
   - `workerMaxThreadCount` 기본값은 400개이나, DB 커넥션 풀(DBCP) 최대 크기는 보통 20~50개 수준이다.
   - 동시 요청 폭증 시 400개의 `DISPATCHER` 스레드가 동시에 트랜잭션을 시도하면 DB Connection 대기 타임아웃이 발생하여 서버 전체가 락(Hang)에 빠진다.
   - **규칙**: `workerMaxThreadCount`는 반드시 DB 커넥션 풀의 `maxActive / maximumPoolSize`와 비례하게(통상 1~2배 수준, 예: 50~100) 하향 조정해야 한다.
2. **RejectionHandler의 Unbounded Thread 생성 위험 (OOM 방지)**:
   - `WorkerContext.getRejectionHandler()`는 스레드 수가 `workerMaxThreadCount`에 도달했을 때 요청을 거부하거나 대기시키지 않고 `new Thread(r).start()`로 새 OS 스레드를 무제한 생성한다.
   - 유입량이 처리 한도를 초과하면 `java.lang.OutOfMemoryError: unable to create new native thread`로 JVM이 다운될 수 있으므로, 웹 서버(`web.json` maxThreads) 레벨에서 적절한 유입 상한을 설정해야 한다.
3. **설정값 '0' 입력 시 서버 기동 실패**:
   - `web.json`의 `maxThreads` 또는 `scheduler.json`의 `threadCount`에 0을 명시하면 컨테이너 검증 오류(`IllegalArgumentException`, `SchedulerConfigException`)로 애플리케이션 기동이 중단된다.

## Reusable Rule
C-MOS 기반 프로젝트의 동시 처리 튜닝 시 소스 코드를 수정하지 말고 `cmos.json`의 `workerMaxThreadCount`를 DB 커넥션 풀 수치에 맞추어 조정하고, Jetty(`web.json`)와 C-MOS 엔진(`cmos.json`) 스레드풀의 역할 분담을 인지하여 네트워크 병목과 비즈니스 병목을 구분하여 분석한다.