---
id: MEM-20260908-frame-tx
type: project
scope: project
project: cmos-frame
domain: persistence-and-transaction
tags: [framework, cmos, transaction, persistence, jpa, mybatis, basic-tx, separated-tx]
status: active
confidence: high
created: 2026-09-08
updated: 2026-09-08
last_seen: 2026-09-08
occurrences: 1
source_agent: antigravity
---

# C-MOS 영속 계층과 트랜잭션 성공 판정의 경계

## Core Knowledge

BaseTransaction은 MyBatis SqlSession과 JDBC Connection을 함께 보유한다. Basic 요청 트랜잭션은 Context/Dispatcher 흐름에서 관리되고, SeparatedTransaction은 독립 세션·커넥션을 사용한다. 분리 트랜잭션 생성 자체가 자동 commit이나 업무 전체 원자성을 뜻하지 않는다.

## Applicability / Lifecycle

- 정상 업무 흐름의 commit·예외 rollback·finally close 호출은 [Dispatcher 수명주기](runtime-lifecycle.md)를 따른다.
- 독립 작업은 commit/rollback/close 책임을 호출부에서 확인한다. 원본에서 확인한 사용처는 통신·진입 이력, ClassCache, TimeUtility.dbNow이고 현재 API 권한 cache reload도 사용한다.
- SeparatedTransaction 생성 시 ContextFactory로 transaction ID를 발급하므로 ContextFactory가 먼저 초기화돼야 한다.
- BaseTransaction 필드의 초기 격리 수준은 READ_COMMITTED지만 생성·환경 설정으로 전달되는 실제 값을 확인한다. 모든 실행의 격리 수준이 고정됐다고 단정하지 않는다.
- close 이후 commit/rollback은 `Closed Transaction` 예외를 낸다.

## Failure Boundary

현재 BaseTransaction의 commit·rollback은 SqlSession/JDBC 호출 예외를 내부에서 잡아 버리고 로그를 남긴다. 정상 반환이나 commit 로그만으로 DB 성공을 확정할 수 없다. close도 내부 자원 해제 예외를 삼킨다. 호출부의 try/catch만으로 모든 DB 실패를 감지한다고 문서화하지 않는다.

이는 현재 소스의 제약이며 이번 Refine에서 수정하거나 실패 재현한 내용은 아니다. [폴백과 성공 판정 lesson](../../lessons/fallback-result-is-not-success-proof.md)을 함께 참고한다.

## Persistence Boundaries

JpaRepository/InterfaceJPA는 자체 엔티티 어노테이션·SQL 생성 구현이며 Spring Data JPA가 아니다. MybatisRepository/InterfaceMybatis는 XML 매퍼를 연결한다. SQL Maker/Dialect와 설정된 풀 구현이 실제 DB 동작을 결정한다. MSSQL·Oracle·PostgreSQL용 dialect 존재만으로 모든 쿼리의 이식성을 보장하지 않는다.

## Verification

2026-09-08 `framework/iia/.../BaseTransaction.java`, `materialze/context/SeparatedTransaction.java`, `BaseDispatcher.java`, `core/.../AuthorizationCacheManager.java`를 정적 대조했다. DB 접속·commit 실패 주입·런타임 검증은 수행하지 않았다.
