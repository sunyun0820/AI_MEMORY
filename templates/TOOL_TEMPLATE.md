---
name: tool-name
category: common
description: 이 Tool이 수행하는 한 가지 목적을 한 줄로 작성한다.
platforms:
  - windows
runtime:
  - powershell
safety: read-only
idempotent: true
tags:
  - example
---

# tool-name

## Use When

- 이 Tool을 사용해야 하는 명확한 상황을 작성합니다.
- 반복/대량/기계적인 작업 조건을 우선 기술합니다.

## Do Not Use When

- 이 Tool이 적합하지 않은 상황을 작성합니다.
- 더 단순한 기본 명령이 적합하다면 명시합니다.

## Command

```powershell
.\tool-name.ps1 -Root "<project-root>"
```

## Inputs

- `Root`: 입력 설명

가변 경로/값은 인자로 받으며 사용자 PC의 절대경로를 하드코딩하지 않습니다.

## Output

기본 출력은 짧고 구조적으로 유지합니다.

```text
STATUS=SUCCESS
RESULTS=0
```

출력이 크면 결과를 파일에 기록하고 stdout에는 요약과 파일 경로만 반환합니다.

## Exit Codes

- `0`: 정상 성공
- `1`: 실행은 정상이나 결과 없음
- `2`: 잘못된 입력/파라미터
- `3`: 실행 환경 또는 Dependency 문제
- `4`: 부분 성공
- `5+`: Tool 전용 오류가 있다면 아래에 정의

## Safety

현재 `safety` 등급이 실제 동작과 일치하는지 설명합니다.

- `read-only`: 조회만 수행
- `write-local`: 로컬 파일 생성/수정
- `destructive`: 삭제/reset/대량 변경
- `external`: DB/API/배포/Git push/메일 등 외부 상태 변경

`destructive` 또는 `external` Tool의 존재 자체를 실행 권한으로 간주하지 않습니다.

## Dependencies

필요한 Runtime/외부 명령/패키지를 작성합니다.

없다면:

```text
None
```

## Examples

대표적인 정상 사용 예시를 1~2개만 작성합니다.

## Notes

Agent가 실행 전에 반드시 알아야 하는 제약사항이 있을 때만 작성합니다.
