---
id: MEM-20260908-mescore-api-auth-runtime
type: project
scope: project
project: mes-core
domain: api-authorization
tags: [java, authorization, processor, cache, snapshot, system-auth, endpoint]
status: active
confidence: high
created: 2026-09-08
updated: 2026-09-08
last_seen: 2026-09-08
occurrences: 1
source_agent: Codex
---

# mes-core API 권한 검사와 캐시 교체의 실행 경계

## Core Knowledge

ApiAuthorizationProcessor는 BaseDispatcher의 preExecute에서 command 매칭 전에 검사한다. `processorClassList` 등록과 `apiAuthorizationEnabled` 설정을 함께 확인한다. disabled 또는 옵션 누락이면 no-op이며, 활성화 시 기본적으로 모든 endpoint를 검사하고 `apiAuthorizationExcludedEndpoints`의 exact/trailing `/**` 패턴만 제외한다.

## Mapping Contract

- MENU의 command 키는 SITEID + MENUCLASSID + MENUID + COMMAND다. READ 매핑은 QUERYID를 더하며 query version과 OBJECTID를 권한 키로 사용하지 않는다.
- `resolveMappingType`는 모든 요청 query가 exact READ 매핑이면 READ를 우선한다. 그렇지 않고 명시적 SAVE 매핑이 있으면 SAVE로 분류한다. SAVE가 없는 READ command는 READ 검증으로 넘어가 빈/미등록 query를 거부한다.
- 따라서 같은 command에 READ와 SAVE가 함께 등록되어 있으면 exact READ 실패가 곧바로 거부를 뜻하지 않는다. SAVE 분류 후 메뉴·등록 object 권한을 검사한다. 실제 동작과 분류 계약을 함께 검토한다.
- READ로 분류된 batch는 모든 QUERYID 매핑과 메뉴 권한이 필요하다. SAVE는 등록된 command의 OBJECTID와 메뉴·객체 권한을 사용한다. SAVE payload의 QUERYID 존재 자체를 조회 권한으로 해석하지 않는다.
- SYSTEM은 등록된 SYSTEM 매핑과 인증된 SITEID + USERID를 전제로 한다. menuClass/menu/object와 관리자 판별을 요구하지 않으며 토큰 검증은 앞단 인증 필터 책임이다. SYSTEM 등록을 관리자 전용 API 표식으로 오해하지 않는다.

## Cache / Failure Boundary

manager/cache는 singleton이며 데이터는 공유 AtomicReference<AuthorizationSnapshot>으로 교체한다. reload는 SeparatedTransaction에서 매핑·사용자 그룹·메뉴·객체 권한을 읽어 새 snapshot을 검증한 뒤 commit 호출, snapshot.set 순서로 진행한다.

조회·구성 오류가 snapshot.set 전에 전파되면 rollback을 시도하고 이전 snapshot을 유지한다. 다만 현재 BaseTransaction.commit/rollback이 내부 DB 예외를 삼키므로 “commit 호출 후 교체”가 “DB 성공 확인 후 교체”를 보장하지 않는다. 원자 참조 교체도 여러 DB 조회의 단일 시점 일관성이나 요청의 여러 cache getter가 같은 버전을 읽는다는 보장은 아니다. 상세는 [트랜잭션 메모리](../cmos-frame/persistence-and-transaction.md)를 참조한다.

## Configuration / DDL Boundary

CIM_APIAUTHMAP.AUTHTYPE은 MENU/SYSTEM이며 기본값 MENU다. SYSTEM 형태를 위해 MENUCLASSID/MENUID를 nullable로 두고 유형별 unique/shape check를 둔 설계다. 프로젝트 DDL에 DBMS별 COLLATE를 넣지 않는 원본 지침을 유지한다. DDL 파일과 실제 적용 DB 상태는 구분한다.

검사 대상 allowlist를 별도로 복제하거나 개별 요청·클래스별 캐시를 추가하기 전에 기존 Processor·manager·snapshot 경계로 해결 가능한지 확인한다.

## Verification

2026-09-08 현재 ApiAuthorizationManager, AuthorizationSnapshot, AuthorizationCacheManager와 BaseDispatcher/BaseTransaction을 정적 대조했다. 설정/DDL 대조와 snapshot·SAVE/SYSTEM·endpoint 자체 테스트 통과는 원본 기록의 과거 검증이며 이번에는 재실행하지 않았다. 실제 HTTP/JWT 종단 간 검증은 원본에서도 미실시였다.
