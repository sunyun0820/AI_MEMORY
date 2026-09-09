---
id: MEM-YYYYMMDD-HHMMSS
type: lesson
scope: project
project: ""
domain: ""
tags: []
status: active
confidence: medium
created: YYYY-MM-DD
updated: YYYY-MM-DD
last_seen: YYYY-MM-DD
occurrences: 1
source_agent: ""
---

# 제목

## Core Knowledge

미래 작업에서 재사용할 핵심 지식을 1~3문장으로 압축합니다. 단순 구현 완료/변경 파일 요약은 적지 않습니다.

## Applicability

이 기억을 언제 적용해야 하는지, 적용 범위와 필요한 조건을 짧게 적습니다.

- 적용 대상:
- 적용 조건:
- 예외/주의:

특정 프로젝트/제품/버전에서만 확인된 지식이면 그 경계를 명확히 적습니다. 현재 Source가 없는 상태는 적용 경계가 아닙니다.

## Avoid / Recurrence Prevention

과거의 실수, 오판, 위험한 접근을 반복하지 않기 위해 무엇을 피하거나 먼저 확인해야 하는지 적습니다. 해당 사항이 없으면 삭제 가능합니다.

## Evidence

이 지식이 어떤 경험/근거에서 나왔는지 필요한 만큼만 적습니다.

가능한 근거 예:

- 현재 작업에서 이미 확인한 코드/설정/테스트/로그
- 공식 문서
- 사용자/팀의 명시적 지시
- 반복된 동일 사례
- 기존 Memory에 기록된 검증 결과

**Memory 저장을 위해 별도 프로젝트 Source를 다시 확보하거나 감사하지 않습니다.** Source가 현재 없다는 사실은 Evidence 부족으로 기록하지 않습니다.

---

아래 섹션은 Incident/복잡한 Lesson처럼 원인과 해결 과정 자체가 미래에 가치가 있을 때만 추가합니다. 필요 없으면 삭제합니다.

## Context

어떤 작업/상황에서 발생했는지 2~5문장 이내로 작성합니다.

## Symptom

겉으로 드러난 오류/현상을 짧게 작성합니다.

## Root Cause

확인된 실제 원인을 작성합니다. 당시 작업에서 추정만 된 내용이면 확정 지식처럼 저장하지 않습니다.

## Wrong Approach

Agent 또는 사람이 잘못 접근한 부분이 재발 방지에 의미가 있을 때만 작성합니다.

## Correct Approach

다음에 같은 유형을 만났을 때 재사용할 수 있는 해결 또는 검증 순서를 작성합니다.

## Reusable Rule

특정 사례에서 다른 모듈/프로젝트에도 적용 가능한 패턴이 있다면 한두 문장으로 일반화합니다.

- 프로젝트 전용 구현 방법을 일반 원칙으로 승격하지 않습니다.
- 일반 원칙과 프로젝트 구현 방법을 분리합니다.
- 일반화할 근거가 없으면 프로젝트 범위를 넘겨 확장하지 않습니다.
- 일반화 판단을 위해 별도 Source Audit을 수행하지 않습니다.
