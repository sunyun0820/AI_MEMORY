# Shared Agent Tools

`tools/`는 반복적이고 기계적인 엔지니어링 작업을 AI가 매번 다시 추론하지 않고, 검증된 스크립트/프로그램으로 빠르게 처리하기 위한 공용 Tool 저장소입니다.

## 핵심 원칙

- **Skill**: AI가 어떻게 판단하고 작업할지 정의합니다.
- **Memory**: 과거 작업에서 무엇을 배웠는지 저장합니다.
- **Tool**: 반복 작업을 실제로 실행합니다.

Tool이 있다고 무조건 사용하지 않습니다. 반복적·대량·결정적·기계적인 작업에서 기존 Tool이 직접 처리보다 효율적일 때 우선 사용합니다.

## 탐색 흐름

```text
사용자 요청
  ↓
반복/대량/기계적 작업 포함?
  ↓ YES
TOOL_INDEX.md 검색
  ↓
적합한 Tool 후보 발견
  ↓
선택한 Tool의 TOOL.md만 읽기
  ↓
입력/안전조건 확인
  ↓
Tool 실행
  ↓
Agent가 결과 해석
```

전체 `tools/`를 매번 읽지 않습니다.

## 기본 구조

```text
tools/
├─ README.md
├─ common/
├─ filesystem/
├─ git/
├─ java/
├─ dotnet/
├─ database/
├─ build/
└─ web/
```

실제 Tool은 폴더 단위로 둡니다.

```text
tools/<category>/<tool-name>/
├─ TOOL.md
└─ <executable-or-script>
```

예:

```text
tools/java/find-class/
├─ TOOL.md
└─ find-class.ps1
```

복잡한 Tool은 필요에 따라 `tests/`, `lib/`, `requirements.txt`, `config.example.json` 등을 추가할 수 있습니다.

## Category

초기 공용 Category는 다음과 같습니다.

- `common`: 여러 기술에 공통으로 쓰는 Tool
- `filesystem`: 파일/폴더 검색, 비교, 정리
- `git`: Git 반복 작업
- `java`: Java/Maven/Gradle 관련 작업
- `dotnet`: .NET/C# 관련 작업
- `database`: DB/Schema/DDL/SQL 관련 작업
- `build`: 빌드/로그/CI 관련 작업
- `web`: 웹 리소스/정적 파일 관련 반복 작업

필요한 Category는 향후 추가할 수 있습니다.

## 한 Tool = 한 책임

Tool 하나가 여러 목적을 동시에 수행하지 않도록 합니다.

좋음:

```text
find-class
compare-folders
schema-diff
```

피해야 함:

```text
find-class-and-fix-maven-and-build-project
```

## TOOL.md 필수 Metadata

모든 Tool은 `TOOL.md` 맨 위에 다음 YAML Front Matter를 가져야 합니다.

```yaml
---
name: find-class
category: java
description: Java 프로젝트에서 특정 클래스의 실제 위치와 소속 모듈을 찾는다.
platforms:
  - windows
runtime:
  - powershell
safety: read-only
idempotent: true
tags:
  - java
  - class
  - dependency
---
```

필수 필드:

- `name`: kebab-case Tool 이름
- `category`: Tool Category
- `description`: 한 줄 목적 설명
- `platforms`: `windows`, `linux`, `macos`, `any` 등 지원 환경
- `runtime`: `powershell`, `python`, `bash`, `dotnet`, `java` 등 실행 환경
- `safety`: 아래 고정 Safety 등급 중 하나
- `idempotent`: 동일 입력 반복 실행의 안전성 여부 (`true`/`false`)
- `tags`: Tool 검색용 키워드

## Safety 등급

### `read-only`

조회만 수행합니다. 프로젝트/외부 시스템을 변경하지 않습니다.

예: 클래스 위치 검색, 폴더 비교, Schema 조회, 로그 분석.

### `write-local`

로컬 파일을 생성하거나 수정합니다.

예: 보고서 생성, 포맷 변환, 생성물 작성.

### `destructive`

삭제, reset, 대량 변경처럼 되돌리기 어렵거나 영향이 큰 로컬 작업입니다.

### `external`

DB 쓰기, 배포, Git push, API 변경 요청, 메일 발송 등 외부 시스템 상태에 영향을 줍니다.

Tool이 존재한다는 사실 자체는 `destructive` 또는 `external` 작업의 실행 권한을 의미하지 않습니다. Agent는 실행 전에 현재 사용자 요청과 영향범위를 확인해야 합니다.

## Tool 선택 우선순위

반복 작업에서는 일반적으로 다음 순서를 선호합니다.

```text
1. 검증된 기존 Tool
2. OS/Shell의 적절한 기본 명령
3. Agent가 직접 처리
4. 새 임시 스크립트 작성
```

기존 Tool보다 `rg`, `git`, `find` 같은 표준 명령이 더 단순하고 효율적이면 표준 명령을 사용해도 됩니다.

## Tool 생성 후보

다음 특성이 강할수록 Tool로 만들 가치가 높습니다.

- 반복 수행됨
- 데이터/파일 양이 많음
- 작업 순서가 일정함
- 결과가 결정적임
- AI 추론 필요성이 낮음
- 직접 Agent 처리보다 Script가 빠름
- 단순 작업인데 컨텍스트/토큰을 많이 소비함

일회성 작업이나 판단 자체가 핵심인 작업은 Tool로 만들지 않습니다.

## 입력 규칙

경로, 프로젝트명, 검색어 등 가변 값은 인자로 받습니다.

다음과 같은 PC/사용자 전용 경로를 하드코딩하지 않습니다.

```text
E:\AI_MEMORY
C:\Users\...
E:\PROJECT
```

AI_MEMORY 경로가 필요하면 `AI_MEMORY_HOME` 또는 Tool 자신의 상대경로를 사용합니다.

## 출력 규칙

Agent가 읽어야 하는 출력은 최대한 작고 구조적으로 유지합니다.

간단한 Tool 예:

```text
STATUS=SUCCESS
MATCHES=3
ERRORS=0
```

복잡한 Tool은 가능하면 JSON 출력 옵션을 제공합니다.

대량 원문 로그 전체를 stdout으로 출력하지 않습니다. 상세 결과가 크면 파일로 저장하고 stdout에는 요약과 결과 파일 경로만 반환합니다.

## 공통 Exit Code

가능한 한 다음 규격을 사용합니다.

- `0`: 정상 성공
- `1`: 실행은 정상이나 결과 없음
- `2`: 잘못된 입력/파라미터
- `3`: 실행 환경 또는 Dependency 문제
- `4`: 부분 성공
- `5+`: Tool 전용 오류

Tool 특성상 다른 Exit Code가 필요하면 `TOOL.md`에 명시합니다.

## 비밀정보

Tool 소스, `TOOL.md`, 예제 설정에는 다음 정보를 저장하지 않습니다.

- Password
- API Key
- Token
- Private Key
- 개인 인증정보

필요한 값은 환경변수, OS Credential Store 또는 안전한 실행 환경에서 받습니다.

## Tool 등록 절차

1. `tools/<category>/<tool-name>/` 생성
2. `templates/TOOL_TEMPLATE.md`를 기준으로 `TOOL.md` 작성
3. 실행파일 작성 및 검증
4. `scripts/rebuild-tool-index.ps1` 실행
5. `TOOL_INDEX.md`에 정상 반영되었는지 확인

검색은 다음처럼 수행합니다.

```powershell
.\scripts\search-tools.ps1 "java", "class"
```
