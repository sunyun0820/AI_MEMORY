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

# C-MOS Framework Persistence & Transaction Architecture

## Context
프레임워크의 데이터베이스 접근 계층(JPA/MyBatis 혼용)과 트랜잭션 수명주기 및 트랜잭션 분기(`Basic` vs `Separated`)의 실제 구현 계약을 정리한다.

## Transaction Model (`BaseTransaction`)
- **Connection & Session 매핑**: `BaseTransaction`은 `SqlSession`과 `java.sql.Connection`을 함께 보유하며 격리 수준(기본값 `TRANSACTION_READ_COMMITTED`)과 타임아웃을 관리한다.
- **TransactionType 분기**:
  - `Basic("T")`:
    - 일반 요청 트랜잭션.
    - `BaseDispatcher`의 요청 수명주기에 종속되며, 정상 완료 시 일괄 commit, 예외 발생 시 일괄 rollback, finally에서 close된다.
  - `Separated("S")`:
    - 메인 Transaction과 별도 Connection/Session을 사용하며 현재 소스에서 독립 작업에 사용된다.
    - 현재 소스에서 확인된 실제 사용처:
      1. 진입/통신 이력 로깅 (`EntryLoggingRepository`, `ConnectorLoggingRepository`)
      2. 스키마 메타데이터 캐싱 (`ClassCache`)
      3. 독립 DB 현재 시각 조회 (`TimeUtility.dbNow`)
    - *주의*: 검증 범위를 넘어서는 추가적인 격리 수준이나 절대적 동작 보장을 임의로 단정하지 않는다.
- **자원 해제 불변조건**: 트랜잭션이 close된 이후 commit 또는 rollback을 호출하면 `UnsupportedOperationException("Closed Transaction")`이 발생한다.

## Persistence Architecture
- **JPA & MyBatis 혼용 구조**:
  - `InterfaceJPA` (`JpaRepository`): Spring Data JPA가 아니며 자체 구현체다. 엔티티 어노테이션 기반으로 단건/목록 조회(`select`, `selectWithLock`), CUD(`insert`, `update`, `delete`), Batch 연산을 동적으로 수행한다.
  - `InterfaceMybatis` (`MybatisRepository`): 복잡한 업무 쿼리를 위한 MyBatis XML 매퍼 연동을 제공한다.
- **SQL 생성 및 Dialect**:
  - `FRAME-IIA`의 `SqlMaker` 계열(`SelectSqlMaker`, `InsertSqlMaker`, `UpdateSqlMaker`, `DeleteSqlMaker`, `SelectWithLockSqlMaker`)을 통해 DBMS에 맞는 SQL을 생성한다.
  - 지원 DBMS Dialect: `MSSqlDialect`, `OracleDialect`, `PostgreSqlDialect`
- **Connection Pool**: HikariCP, Tomcat DBCP, Vibur DBCP, Oracle UCP를 환경설정에 따라 지원한다.

## Reusable Rule
DB 작업 시 단순 CRUD 및 이력 저장은 `CoreRepository`의 JPA 계열 메서드를 활용하고, 다중 테이블 조인이나 도메인 특화 쿼리는 MyBatis 매퍼를 활용한다. 메인 업무 트랜잭션과 분리되어 즉시 저장되어야 하는 작업(로깅 등)은 `SeparatedTransaction`을 통해 수행한다.
