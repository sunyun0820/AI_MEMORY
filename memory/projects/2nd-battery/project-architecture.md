---
id: MEM-20260909-2nd-battery-project-architecture
type: project
scope: project
project: 2nd-battery
domain: architecture
tags: [cmos, battery, modules, ownership, block-manager]
status: active
confidence: medium
created: 2026-09-09
updated: 2026-09-10
last_seen: 2026-09-09
occurrences: 1
source_agent: codex
---

# 2nd-battery 모듈 소유권과 공정 Manager 위임 구조

## Core Knowledge / Applicability

2026-09-09 기록된 2nd-battery는 웹 호스트, 요청 Rule, 공통 업무, 공정별 서비스 블록을 나눈 C-MOS 소비 프로젝트다. 이 프로젝트의 `core`는 FRAME-CORE나 MES-CORE가 아니라 배터리 PROJECT 서비스 계층이다.

| 모듈 | 소유하는 책임 |
|---|---|
| `web-ui` | Factory 기동, 웹 설정, 로그인·파일 어댑터, 배포 UI |
| `services` | UI/설비/MCS 요청의 CoreRule, 요청 변환과 Manager 호출, SQL 보관본 |
| `core/common-services` | common 업무 구현과 common/cell/electrode/pack의 Manager 인터페이스 |
| `core/cell-services` | assembly/formation 및 formation logic 구현 |
| `core/electrode-services` | mixing/plate, MCS와 MCS 기준정보 구현 |
| `core/pack-services` | modules/packing, 포장 logic, 출하·납품 구현 |

`common-services`는 인터페이스만 있는 모듈이 아니다. POM 주석이나 동일한 `core` 이름만으로 소유권을 판단하지 않는다.

## Framework 소비 경계

- FRAME-API: `Factory.initialize`, `@AutoInjection`, `@BlockController`, `@BlockModule`, 인터페이스 계약.
- FRAME-IIA: 주입·Context·Connector 구현과 utility.
- FRAME-CORE: `CoreRule`, `CoreManager`, `DbContext`, `getWebdataList`, `setDatadic`, `RequestType`.
- MES-CORE: `Lot`, `Recipeitem`, `Batch`, `Inspreq` 등의 Entity, `CommonRepository`, 업무 Extension, IdPattern/OptionSet, 상태·오류 상수, 인증.
- PROJECT: 공정별 블록·업무 순서, 하위 목록 바인딩, 화면 SQL/응답 이름, 웹 어댑터.

같은 `com.thirautech.cmos.mes.core` 패키지도 소유 모듈이 다르다. `CoreRule/DbContext`는 FRAME-CORE, `CommonRepository/Recipeitem/ProductionExtension`는 MES-CORE다. 이 스택을 Spring MVC/DI나 Spring Data JPA 계약으로 해석하지 않는다. Framework 경계는 [C-MOS 구조](../cmos-frame/architecture.md)를 참조한다.

## 위임과 확장 위치

`TrackInLot_Assembly → interfaces.cell.production.assembly.IPRODUCTIONLotManager → service.cell.production.assembly.PRODUCTIONLotManager → interfaces.common.production.IPRODUCTIONLotManager → service.common.production.PRODUCTIONLotManager`로 연결된다.

assembly·formation·mixing의 공정 Manager는 공통 Manager의 subclass가 아니라 `CoreManager`를 직접 상속하는 별도 구현체다. 단순 클래스명 대신 Rule import의 FQCN을 따른다. 공정 정책은 해당 wrapper, 여러 공정에 공통인 정책은 common Manager, 기존 MES 업무의 이력·옵션은 Extension 경계에서 검토한다.

조사본에는 업무 전체를 강제하는 별도 BaseRule/BaseManager가 없었고 로컬 BaseController/BaseHttpController는 웹 어댑터 계열이었다. 로컬 CoreRepository subclass는 connector/document/plugin sample이므로 생산 저장의 대표 경로는 기존 Repository를 호출하는 Manager다. Factory의 단일 구현 조건을 Block의 구현 선택 규칙으로 확대하지 않는다.

## 빌드와 실제 소비 artifact

| POM 범위 | 기록된 버전 / Java | 주의 |
|---|---|---|
| `core`와 4개 child | 3.5.2 / 17 | child가 aggregator를 parent로 선언하지 않고 각자 설정을 가짐 |
| `services`, `web-ui` | 3.5.1 / 11 | services는 배터리 모듈 3.5.1을 지정 |
| 당시 인접 Framework/MES-Core | 3.5.3-SNAPSHOT | 프로젝트 resolved JAR과 같은 구현이라는 증거가 아님 |

`web-ui`는 services와 plugin-web-starter를 의존하고, core/services/web-ui를 모두 묶는 상위 reactor POM은 없었다. 따라서 core를 빌드했다고 services/web-ui가 그 결과를 소비한다고 가정하지 않는다. 실제 artifact와 JDK 연결을 확인하며, package/install 차이는 [설정·배포](configuration-and-runtime.md)를 따른다.

## Evidence

2026-09-09 원본 `.scratch/knowledge-map-review/project-architecture.md`와 메모리에 기록된 POM·대표 상속/위임 정적 확인을 근거로 한다. 이 날짜의 구조 지식이며 빌드·배포 JAR 동일성·런타임 성공 검증은 아니다. 상세 경로는 [탐색 지도](source-navigation-map.md), 실행 흐름은 [업무 흐름](runtime-and-business-flow.md)에 둔다.
