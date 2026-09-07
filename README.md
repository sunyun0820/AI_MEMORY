# AI_MEMORY

여러 개발 에이전트가 **하나의 공용 장기 메모리와 전역 Skill 원본**을 함께 사용하기 위한 저장소입니다.

대상은 Codex, Cursor, Claude Code, Antigravity 등이며, 목표는 다음 두 가지입니다.

1. 반복해서 가치가 있는 오류 원인, 해결 패턴, 프로젝트 규칙을 공용 Memory로 축적합니다.
2. 여러 Agent에서 공통으로 사용할 Skill을 이 Repository 한 곳에서 관리합니다.

---

## 핵심 개념

```text
AI_MEMORY
   │
   ├─ memory/   → Agent가 과거 작업에서 배운 지식과 경험
   │
   └─ skills/   → Agent가 어떻게 작업할지 정의하는 공용 전역 Skill 원본
```

**Memory와 Skill은 역할이 다릅니다.**

- `memory/` : 무엇을 배웠는가
- `skills/` : 어떻게 일할 것인가

Agent별로 Memory나 Skill을 복사해서 관리하지 않고, 가능한 한 이 Repository를 단일 원본으로 사용합니다.

---

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
├─ skills/            # 공용 전역 Skill 원본
│  ├─ README.md
│  └─ <skill-name>/
│     └─ SKILL.md
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

`skills/` 아래의 **직접 하위 폴더 중 `SKILL.md`가 존재하는 폴더만 전역 Skill로 인식**합니다.

새로운 Skill을 추가하더라도 `setup.ps1`을 수정할 필요가 없습니다.

---

## 최초 설치

### 1. Repository Clone

예시:

```powershell
git clone https://github.com/sunyun0820/AI_MEMORY.git E:\AI_MEMORY
cd E:\AI_MEMORY
```

Repository 위치는 반드시 `E:\AI_MEMORY`일 필요가 없습니다.

`setup.ps1`이 자신이 위치한 Repository의 실제 경로를 자동으로 사용합니다.

### 2. setup.ps1 실행

PowerShell 실행 정책 때문에 막히는 경우 현재 세션에서만 허용합니다.

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\setup.ps1
```

---

## setup.ps1이 하는 일

### 1. AI_MEMORY_HOME 등록

현재 Repository 경로를 사용자 환경변수로 등록합니다.

```text
AI_MEMORY_HOME=<현재 AI_MEMORY Repository 경로>
```

이미 같은 값이 등록되어 있으면 변경하지 않습니다.

다른 경로가 등록되어 있으면 현재 Repository 경로로 갱신합니다.

현재 PowerShell 세션의 `$env:AI_MEMORY_HOME`에도 즉시 반영합니다.

### 2. 전역 Skill 자동 탐색

다음 조건을 만족하는 폴더를 자동으로 찾습니다.

```text
skills/<skill-name>/SKILL.md
```

예:

```text
skills/
├─ agent-memory/
│  └─ SKILL.md
├─ code-review/
│  └─ SKILL.md
└─ root-cause-analysis/
   └─ SKILL.md
```

이 경우 `setup.ps1`은 3개의 전역 Skill을 자동으로 인식합니다.

### 3. Agent 전역 Skill 경로에 Junction 생성

현재 구성은 다음 경로를 사용합니다.

```text
Codex + Cursor
~\.agents\skills\<skill-name>

Claude Code
~\.claude\skills\<skill-name>

Antigravity
~\.gemini\config\skills\<skill-name>
```

실제 Skill 파일을 복사하지 않고 Junction으로 연결합니다.

예를 들어 Repository가 `E:\AI_MEMORY`에 있고 `agent-memory` Skill이 있다면:

```text
~\.agents\skills\agent-memory
    └─ Junction → E:\AI_MEMORY\skills\agent-memory

~\.claude\skills\agent-memory
    └─ Junction → E:\AI_MEMORY\skills\agent-memory

~\.gemini\config\skills\agent-memory
    └─ Junction → E:\AI_MEMORY\skills\agent-memory
```

따라서 Skill 원본은 항상 다음 한 곳에만 존재합니다.

```text
AI_MEMORY\skills\<skill-name>
```

### 4. 재실행 가능

`setup.ps1`은 여러 번 실행해도 됩니다.

- 이미 올바르게 연결된 Junction → 그대로 유지
- 다른 위치를 가리키는 Link → 덮어쓰지 않고 경고
- 실제 파일/폴더가 이미 존재 → 삭제하지 않고 경고

이전 초기 버전의 setup 스크립트가 생성했던 아래 Junction은 AI_MEMORY의 `agent-memory` 원본을 가리키는 경우에만 안전하게 정리합니다.

```text
~\.codex\skills\agent-memory
~\.cursor\skills\agent-memory
```

사용자가 직접 만든 실제 폴더는 삭제하지 않습니다.

---

## 새 전역 Skill 추가 방식

향후 Skill을 추가할 때는 Repository에 폴더만 추가합니다.

```text
skills/
└─ my-new-skill/
   └─ SKILL.md
```

그 후:

```powershell
git pull
.\setup.ps1
```

을 실행하면 모든 지원 Agent의 전역 Skill 위치에 자동으로 연결됩니다.

즉, **새 Skill을 추가할 때마다 setup.ps1을 수정하지 않습니다.**

세부 구조 규칙은 [`skills/README.md`](./skills/README.md)를 참고합니다.

---

## 환경변수 확인

새 PowerShell에서:

```powershell
$env:AI_MEMORY_HOME
```

Repository 경로가 출력되면 정상입니다.

---

## Memory 종류

### Rule

앞으로 반복적으로 지켜야 하는 **검증된 규칙**입니다.

예:

```text
READ ONLY 데이터베이스에서는 SELECT 외 작업을 수행하지 않는다.
```

### Lesson

문제를 해결하면서 얻은 **재사용 가능한 해결 패턴**입니다.

예:

```text
Maven cannot find symbol 발생 시 dependency를 추측해서 추가하기 전에
실제 클래스 위치와 module dependency부터 확인한다.
```

### Incident

실제로 발생했던 **장애/오류 사례, Root Cause, 해결 방법**입니다.

### Project

특정 Repository나 프로젝트에서만 유효한 구조, 관례, 제약조건입니다.

Global Memory와 분리하여 다른 프로젝트에 잘못 적용되는 것을 막습니다.

---

## Memory 사용 원칙

전체 Memory를 매 작업마다 읽지 않습니다.

```text
현재 작업 분석
    ↓
관련 Rule / Project Memory 검색
    ↓
핵심 키워드로 Lesson / Incident 검색
    ↓
관련성이 높은 Memory만 선택
    ↓
현재 코드와 맞는지 검증
    ↓
작업 수행
```

작업이 끝났다고 무조건 Memory를 만들지도 않습니다.

다음과 같은 경우를 장기 기억 후보로 봅니다.

- 원인 파악이 어려웠던 오류의 Root Cause가 검증됨
- Agent가 의미 있는 잘못된 가정을 함
- Agent가 불필요하거나 위험한 수정을 시도함
- 반복 가능한 디버깅/빌드/배포/DB 해결 순서를 발견함
- 프로젝트의 중요한 불변조건 또는 금지사항을 발견함
- 같은 문제가 다시 발생할 가능성이 높음
- 기존 Memory가 잘못되었거나 불완전함이 확인됨

저장하지 않는 항목:

- 단순 성공 기록
- 흔한 프로그래밍 문법
- 일회성 세션 정보
- 전체 대화
- 전체 로그
- 검증되지 않은 추측
- 비밀번호, API Key, Token, Private Key 등 비밀정보

세부 정책은 [`MEMORY_POLICY.md`](./MEMORY_POLICY.md)를 따릅니다.

---

## Memory 검색

```powershell
.\scripts\search-memory.ps1 "maven", "dependency"
```

`AI_MEMORY_HOME`이 존재하면 해당 경로를 사용합니다.

환경변수가 없어도 스크립트 자신의 위치를 기준으로 Repository Root를 자동 계산합니다.

---

## INDEX.md 재생성

```powershell
.\scripts\rebuild-index.ps1
```

`INDEX.md`는 Agent가 Memory 전체를 읽지 않고 관련 기억을 빠르게 찾기 위한 색인입니다.

이 스크립트 역시 특정 드라이브 경로에 의존하지 않습니다.

---

## Git 사용

다른 PC에서 최신 상태를 받을 때:

```powershell
git pull
.\setup.ps1
```

새로운 Memory 또는 Skill 변경사항을 공유할 때:

```powershell
git add .
git commit -m "에이전트 공용 메모리 업데이트"
git push
```

Git은 동기화뿐 아니라 Agent가 잘못 수정했을 때 diff 확인과 rollback을 가능하게 합니다.

---

## 중요한 원칙

1. 현재 코드와 실제 테스트 결과가 Memory보다 우선합니다.
2. 전체 Memory를 매번 컨텍스트에 넣지 않습니다.
3. 검증되지 않은 내용을 Rule로 만들지 않습니다.
4. 비밀정보는 Memory에 저장하지 않습니다.
5. 동일 유형은 신규 파일보다 기존 Memory 갱신을 우선합니다.
6. 프로젝트 한정 지식과 Global Rule을 구분합니다.
7. Agent별 Memory를 따로 만들지 않습니다.
8. Agent별 Skill 복사본을 만들지 않고 `skills/`를 원본으로 사용합니다.
9. 새 Skill 추가 시 setup 스크립트를 수정하지 않습니다.

---

## 현재 단계

현재는 의도적으로 단순하게 시작합니다.

```text
Markdown + Git + Shared Memory + Shared Global Skills
```

Memory가 충분히 커져 Markdown 검색만으로 비효율적이 되는 시점에 SQLite FTS, Vector Search 등의 검색 계층을 추가할 수 있습니다.
