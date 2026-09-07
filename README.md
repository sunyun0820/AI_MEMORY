# AI_MEMORY

Codex, Cursor, Claude Code, Antigravity 같은 여러 개발 에이전트가 **하나의 공용 장기 메모리**를 함께 사용하기 위한 저장소입니다.

목표는 대화나 로그를 무작정 쌓는 것이 아니라, 반복해서 가치가 있는 **규칙, 실수, 장애 원인, 해결 패턴, 프로젝트 지식**만 압축해 보존하고 다음 작업에서 필요한 기억만 다시 꺼내 쓰는 것입니다.

## 핵심 구조

```text
개발 작업 시작
      ↓
agent-memory가 관련 기억 검색
      ↓
현재 작업과 관련된 소수의 기억만 적용
      ↓
개발 / 디버깅 / 테스트
      ↓
작업 완료
      ↓
재사용 가치가 있는 경험인지 판단
      ↓
신규 Memory 생성 또는 기존 Memory 갱신
```

전체 Memory를 매번 컨텍스트에 넣지 않습니다. 필요한 것만 검색해서 사용하는 것이 이 저장소의 핵심 원칙입니다.

## 저장소 구조

```text
AI_MEMORY/
├─ README.md
├─ INDEX.md
├─ MEMORY_POLICY.md
├─ setup.ps1
│
├─ memory/
│  ├─ rules/          # 반복적으로 지켜야 하는 검증된 규칙
│  ├─ lessons/        # 재사용 가능한 문제 해결 경험
│  ├─ incidents/      # 실제 장애/오류와 원인/해결
│  ├─ projects/       # 특정 프로젝트에서만 유효한 지식
│  └─ archive/        # 더 이상 active하지 않은 기억
│
├─ skills/
│  └─ agent-memory/
│     ├─ SKILL.md
│     ├─ scripts/
│     └─ references/
│
├─ templates/
│  └─ MEMORY_TEMPLATE.md
│
├─ scripts/
│  ├─ search-memory.ps1
│  └─ rebuild-index.ps1
│
└─ instructions/
   └─ GLOBAL_INSTRUCTION_SNIPPET.md
```

## 최초 설치

### 1. Repository Clone

예시:

```powershell
git clone https://github.com/sunyun0820/AI_MEMORY.git E:\AI_MEMORY
cd E:\AI_MEMORY
```

저장소 위치는 반드시 `E:\AI_MEMORY`일 필요는 없습니다. `setup.ps1`이 **현재 저장소가 있는 실제 경로**를 자동으로 등록합니다.

### 2. setup.ps1 실행

PowerShell 실행 정책 때문에 막히는 경우 현재 세션에서만 허용합니다.

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\setup.ps1
```

`setup.ps1`은 다음 작업만 수행합니다.

1. 현재 Repository 경로를 사용자 환경변수 `AI_MEMORY_HOME`으로 등록합니다.
2. 공용 원본 스킬 `skills\agent-memory`를 각 Agent의 전역 Skill 위치에 Junction으로 연결합니다.
3. 이미 같은 설정이 존재하면 그대로 두므로 여러 번 실행해도 됩니다.
4. 기존 경로에 실제 파일/폴더가 있으면 삭제하거나 덮어쓰지 않고 경고 후 건너뜁니다.

## setup.ps1 실행 결과

예를 들어 Repository가 `E:\AI_MEMORY`에 있다면:

```text
AI_MEMORY_HOME=E:\AI_MEMORY
```

공용 Skill 원본은 하나입니다.

```text
E:\AI_MEMORY\skills\agent-memory
```

그리고 Agent별 전역 Skill 위치가 이 원본을 가리킵니다.

```text
~\.agents\skills\agent-memory
    └─ Junction → E:\AI_MEMORY\skills\agent-memory
       (Codex + Cursor)

~\.claude\skills\agent-memory
    └─ Junction → E:\AI_MEMORY\skills\agent-memory
       (Claude Code)

~\.gemini\config\skills\agent-memory
    └─ Junction → E:\AI_MEMORY\skills\agent-memory
       (Antigravity)
```

따라서 Agent별로 Skill을 복사해서 관리하지 않습니다.

```text
                     AI_MEMORY
                         │
                skills/agent-memory
                         │
              ┌──────────┼──────────┐
              │          │          │
        Codex/Cursor    Claude   Antigravity
```

Skill을 수정하면 모든 Agent가 같은 원본을 사용합니다.

## 환경변수 확인

새 PowerShell을 연 뒤:

```powershell
$env:AI_MEMORY_HOME
```

Repository 경로가 출력되면 정상입니다.

현재 PowerShell 세션에서는 `setup.ps1`이 `$env:AI_MEMORY_HOME`도 즉시 설정합니다.

## Memory 종류

### Rule

앞으로 반복적으로 지켜야 하는 **검증된 규칙**입니다.

예:

```text
SBTL_GEN 데이터베이스는 READ ONLY이다.
SELECT 외의 작업을 수행하지 않는다.
```

### Lesson

특정 문제를 해결하면서 얻은 **재사용 가능한 문제 해결 패턴**입니다.

예:

```text
Maven cannot find symbol 발생 시 dependency를 먼저 추측해서 추가하지 않는다.
실제 클래스 위치와 module dependency부터 확인한다.
```

### Incident

실제로 발생했던 **장애/오류 사례와 Root Cause, 해결 방법**입니다.

### Project

특정 Repository나 프로젝트에서만 유효한 구조, 관례, 제약조건입니다.

다른 프로젝트에 잘못 적용되는 것을 막기 위해 Global Memory와 분리합니다.

## 작업 전: Recall

`agent-memory`는 비단순 개발 작업을 시작할 때 다음 순서로 동작합니다.

```text
현재 작업 분석
    ↓
Global Rule 확인
    ↓
현재 Project Memory 확인
    ↓
핵심 키워드 추출
    ↓
INDEX / Memory 검색
    ↓
관련성이 높은 Memory만 선택
    ↓
현재 코드와 맞는지 검증 후 적용
```

Memory Repository 전체를 읽지 않습니다.

보통 현재 작업에 가장 관련성이 높은 소수의 Memory만 사용합니다.

## 작업 후: Learn

작업이 끝났다고 무조건 Memory를 만들지 않습니다.

다음과 같은 경우만 장기 기억 후보입니다.

- 원인 파악이 쉽지 않았던 오류의 Root Cause가 검증됨
- Agent가 의미 있는 잘못된 가정을 함
- Agent가 불필요하거나 위험한 수정을 시도함
- 반복 사용 가능한 디버깅/빌드/배포/DB 해결 순서를 발견함
- 프로젝트의 중요한 불변조건 또는 금지사항을 발견함
- 같은 문제가 다시 발생할 가능성이 높음
- 기존 Memory가 잘못되었거나 불완전한 것으로 확인됨

다음은 저장하지 않습니다.

- 단순 성공 기록
- 흔한 프로그래밍 문법
- 일회성 세션 정보
- 전체 대화 내용
- 전체 로그
- 검증되지 않은 추측
- 비밀번호, API Key, Token, Private Key 같은 비밀정보

세부 정책은 [`MEMORY_POLICY.md`](./MEMORY_POLICY.md)를 따릅니다.

## 중복 Memory 처리

신규 Memory를 만들기 전에 기존 Memory를 검색합니다.

같거나 사실상 동일한 사례가 있다면 새 파일을 계속 만들지 않습니다.

```text
동일 유형 발견
    ↓
기존 Memory 갱신
    ├─ occurrences 증가
    ├─ last_seen 갱신
    ├─ 추가 검증 정보 반영
    └─ 더 나은 해결법이 있으면 개선
```

## Memory 승격

기억의 중요도와 검증 수준이 높아지면 다음처럼 발전할 수 있습니다.

```text
Incident / Lesson
       ↓
반복 발생 + 추가 검증
       ↓
강화된 Lesson
       ↓
중요하고 명확한 불변조건으로 확인
       ↓
Rule
```

단순히 여러 번 발생했다는 이유만으로 Rule로 만들지는 않습니다.

## INDEX.md

`INDEX.md`는 Agent가 Memory 전체를 읽지 않고 필요한 기억을 빠르게 찾기 위한 색인입니다.

Memory가 추가/수정된 후:

```powershell
.\scripts\rebuild-index.ps1
```

으로 갱신할 수 있습니다.

`agent-memory` Skill도 Memory 작성 후 Index 갱신을 수행하도록 설계되어 있습니다.

## Git 사용

이 Repository 자체를 Memory의 변경 이력으로 사용합니다.

```powershell
git pull
```

으로 다른 PC에서 최신 Memory를 받고,

```powershell
git add .
git commit -m "Update agent memory"
git push
```

으로 새로운 Memory를 공유할 수 있습니다.

Git을 사용하는 이유는 단순 동기화뿐 아니라 Agent가 Memory를 잘못 변경했을 때 **diff 확인과 rollback**이 가능하기 때문입니다.

## 중요한 원칙

1. **현재 코드와 테스트 결과가 Memory보다 우선합니다.**
2. 전체 Memory를 매 작업마다 읽지 않습니다.
3. 검증되지 않은 내용을 Rule로 만들지 않습니다.
4. 비밀정보는 절대 Memory에 저장하지 않습니다.
5. 동일 유형은 신규 파일보다 기존 Memory 갱신을 우선합니다.
6. 프로젝트 한정 지식과 Global Rule을 구분합니다.
7. Agent별 Memory를 따로 만들지 않고 하나의 Shared Memory를 사용합니다.

## 현재 단계

현재 버전은 의도적으로 단순하게 구성되어 있습니다.

```text
Markdown + Git + Agent Skill + 선택적 검색
```

Memory가 충분히 커져 Markdown 검색만으로 비효율적이 되는 시점에 SQLite FTS, Vector Search 등의 검색 계층을 추가할 수 있습니다. 처음부터 별도 DB나 서버를 두지 않습니다.
