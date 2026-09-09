---
id: MEM-20260908-cmos-callback-contract
type: project
scope: project
project: cmos-frame
domain: web-callback-input-response-contract
tags: [framework, cmos, callback, apiMapping, servletMapping, abstract-event, core-rule, message-data]
status: active
confidence: high
created: 2026-09-08
updated: 2026-09-08
last_seen: 2026-09-08
occurrences: 1
source_agent: codex
---

# C-MOS 외부 JSON 콜백의 입력·응답 경계

## Context

C-MOS 기반 프로젝트에서 외부 시스템의 CMOS 봉투가 아닌 JSON 콜백을 기존 API 경로로 받을 수 있는지와 전용 Servlet이 필요한 조건을 검토했다. `AbstractEvent`/`CoreRule`의 업무 실행과 `BaseDispatcher`/`Dispatcher`의 메시지 변환을 현재 소스에서 대조했다.

## Symptom

외부 콜백 JSON을 `CoreRule`로 처리하려 하면 `getWebData()`가 기대하는 `WEBDATA` 구조와 맞지 않아 Servlet이 입력 수신에 필수인 것처럼 보였다. 반대로 외부 응답이 `code/result/message/data`로 고정된 경우에는 표준 API 응답을 그대로 사용할 수 없다.

## Root Cause

`CoreRule`의 `getWebData()`는 MES `MessageData.WEBDATA` helper일 뿐 입력 JSON 전체의 허용 스키마를 정의하지 않는다. `AbstractController#getMessageMap()` 또는 `CoreRule#getRequestData().getMap()`으로 파싱된 JSON object의 원문 map을 읽을 수 있다. 하지만 표준 Dispatcher는 `MessageData` 응답을 만들고 `toMessageString()`으로 직렬화하므로, `apiMapping`의 이벤트만으로 외부의 임의 응답 스키마를 대체할 수 없다.

## Wrong Approach

처음에는 `CoreRule` 경로가 CMOS 요청 형식만 받을 수 있다고 넓게 판단했다. 실제 제약은 입력 필드가 아니라 표준 Dispatcher가 생성하는 응답 계약이며, `getWebData()`를 원문 콜백의 유일한 접근 방식으로 보면 안 된다.

## Correct Approach

1. 외부 JSON이 문법적으로 유효한 object인지 확인한다.
2. 외부가 CMOS 표준 응답을 허용하면 `apiMapping`에 `CoreRule` 또는 generic `AbstractEvent`를 연결한다.
3. Rule/Event에서는 `getWebData()` 대신 `getRequestData().getMap()` 또는 `getMessageMap()`을 사용해 원문 필드를 읽고 Manager를 호출한다.
4. 외부가 `{"code":200,"result":true,"message":"","data":{}}`처럼 특정 응답을 요구하면 `servletMapping` 어댑터에서 원문 수신·검증·응답 직렬화를 직접 제어한다.
5. MES Manager, 표준 트랜잭션, `messageValidation/process` 관례가 필요하면 `AbstractEvent`보다 `CoreRule`을 우선한다. generic `AbstractEvent` 직접 `apiMapping`이 가능한지는 웹 모듈 로더의 실제 구현으로 smoke test한다.

## Reusable Rule

외부 콜백 연동에서 Servlet 선택 기준은 수신 JSON의 모양이 아니라 외부가 요구하는 응답 계약이다. 입력만 유연하게 처리할 때는 기존 API Dispatcher와 `CoreRule`/`AbstractEvent`를 재사용하고, 응답 스키마까지 고정일 때만 `servletMapping` 어댑터를 둔다.

## Verification

`AbstractEvent`, `AbstractController`, `CoreRule`, `BaseDispatcher`, MES `Dispatcher`, `MessageData` 소스를 대조했다. C-MOS 표준 응답의 `MessageData` 생성·직렬화와 Rule/Event 실행 순서를 코드로 확인했으며, 실제 MES 기동이나 외부 callback runtime은 수행하지 않았다.
