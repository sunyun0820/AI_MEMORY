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
updated: 2026-09-08
last_seen: 2026-09-08
occurrences: 1
source_agent: codex
---

# Hyosung AGV 연동 작업 경계와 검증 범위

## Context

Hyosung AGV REST 송신 및 외부 JSON 콜백 예제를 `real_edu` 프로젝트에 구성하고 사용법을 정리했다. 프로젝트 요청에서 실제 수정 허용 범위와 분석 전용 프레임워크 범위를 명시적으로 분리했다.

## Verified Boundary

- 수정 허용: `C:\Users\<project-user>\Desktop\real_edu\service`, `C:\Users\<project-user>\Desktop\real_edu\ui`
- 분석 전용: `E:\0.Project\cmos-frame`, `E:\0.Project\mes-core`의 프레임워크·코어 소스
- AGV API 예제 Java는 service `example/testoutbound`, 콜백 수신 Java는 service `example/testcallback`, Servlet/웹 매핑은 ui에 둔다.
- 기존 사용자 변경으로 보이는 `ui/.factorypath`, `ui/pom.xml`은 관련 작업에서 임의로 되돌리거나 커밋하지 않는다.

## Verification Boundary

- 허용된 정적/격리 검증: Java 컴파일, 설정 매핑 확인, 문서 구조 확인, 로컬 더미 대상 기준 테스트
- 별도 승인 없이 하지 않는 것: DB 접속/쿼리, 실제 외부 AGV 호출, MES 운영 반영, Git commit/push
- 실제 MES 기동 및 외부 callback 송수신은 정적 검증과 구분해 보고한다. 실행하지 않았으면 통과했다고 표현하지 않는다.

## Reusable Rule

Hyosung AGV 연동 작업은 service/ui에만 최소 변경하고 프레임워크·코어는 소스 근거 분석만 수행한다. 설정·컴파일·문서 검증과 실제 MES/외부 연동 검증을 분리해 결과를 보고한다.

## Verification

이번 작업에서 Test 송신/콜백 예제, ui `rest.json`/`web.json`, 신규 HTML 매뉴얼을 정적으로 확인했고 `TestCallbackServlet`의 Java 17 대상 컴파일을 확인했다. DB와 실제 외부 시스템에는 접속하지 않았다.
