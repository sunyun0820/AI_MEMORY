# AI_MEMORY

Codex, Cursor, Claude Code, Antigravity 등 여러 개발 에이전트가 **하나의 공용 장기 메모리, 전역 Skill, 전역 지침**을 공유하기 위한 저장소입니다.

핵심 목표는 두 가지입니다.

1. 과거 작업의 중요한 규칙, 실수, 장애 원인, 해결 패턴, 설계 제약을 다음 작업에서 자동으로 다시 활용합니다.
2. 여러 PC와 여러 Agent에서 최대한 동일한 작업 방식을 `git clone + setup.ps1`로 재현합니다.

## 핵심 동작

```text
사용자 요청
   ↓
비단순 분석/설계/개발 작업인가?
   ↓ YES
agent-memory Recall 자동 실행
   ↓
관련 Memory만 선택적으로 조회
   ↓
분석 / 설계 / 구현 / 디버깅 / 리뷰 수행
   ↓
작업 완료
   ↓
자동 저장하지 않음
```

Memory 저장/갱신은 사용자가 명시적으로 요청할 때만 수행합니다.

예:

```text
"이거 기억해"
"이번 내용 메모리에 남겨"
"기존 메모리 업데이트해"
"이 실수 학습해"
```

즉 운영 원칙은 다음과 같습니다.

> **Recall = 자동 / Learn = 사용자 명시 호출**

## 저장소 구조

```text
AI_MEMORY/
├─ README.md
├─ INDEX.md
├─ MEMORY_POLICY.md
├─ setup.ps1
│
├─ memory/
│  ├─ rules/
│  ├─ lessons/
│  ├─ incidents/
│  ├─ projects/
│  └─ archive/
│
├─ skills/
│  ├─ README.md
│  └─ agent-memory/
│     └─ SKILL.md
│
├─ instructions/
│  └─ GLOBAL_AGENT_INSTRUCTIONS.md
│
├─ templates/
│  └─ MEMORY_TEMPLATE.md
│
└─ scripts/
   ├─ search-memory.ps1
   └─ rebuild-index.ps1
```

### 역할 구분

- `memory/` : 에이전트가 과거 작업에서 **무엇을 배웠는지** 저장
- `skills/` : 에이전트가 **어떻게 동작할지** 정의
- `instructions/` : 각 Agent가 **언제 Skill을 자동 적용할지** 정의하는 전역 지침의 단일 원본

## 최초 설치

```powershell
git clone https://github.com/sunyun0820/AI_MEMORY.git E:\AI_MEMORY
cd E:\AI_MEMORY
Set-ExecutionPolicy -Scope Process Bypass
.\setup.ps1
```

저장소 위치는 `E:\AI_MEMORY`로 고정되지 않습니다. `setup.ps1`이 현재 Repository 위치를 자동으로 사용합니다.

## setup.ps1이 하는 일

### 1. 공용 Memory 경로 등록

현재 Repository 경로를 사용자 환경변수로 등록합니다.

```text
AI_MEMORY_HOME=<현재 Repository 경로>
```

이미 올바른 값이면 그대로 둡니다.

### 2. 설치된 Agent 감지

`setup.ps1`은 이 PC에 실제로 설치되어 있거나 사용 흔적이 확인되는 Agent만 구성합니다.

```text
=== Agent Detection ===
[OK]   Codex 발견
[OK]   Cursor 발견
[SKIP] Claude Code 설치 흔적 없음
[SKIP] Antigravity 설치 흔적 없음
```

`[SKIP]`된 Agent에 대해서는:

- 전역 Skill Junction을 만들지 않습니다.
- 전역 지침을 만들지 않습니다.
- `.claude`, `.cursor`, `.gemini` 같은 Agent 설정 폴더도 새로 만들지 않습니다.

즉, 설치되지 않은 Agent는 **아무 변경 없이 그대로 건너뜁니다.**

단순히 Agent 루트 폴더가 존재한다는 이유만으로 설치된 것으로 판단하지 않습니다. 이전 버전의 AI_MEMORY setup이 만들어 놓은 폴더를 실제 설치로 오인하지 않도록, 실행 명령 또는 실제 설정/앱 데이터 같은 더 구체적인 흔적을 사용합니다.

현재 주요 감지 기준은 다음과 같습니다.

- Codex: `codex` 명령 또는 `~/.codex/config.toml`
- Cursor: `agent` 명령 또는 Cursor 실행 파일
- Claude Code: `claude` 명령 또는 `~/.claude/settings.json`
- Antigravity: `agy` 명령 또는 Antigravity 전용 앱/설정 데이터

Codex와 Cursor 중 하나라도 설치되어 있으면 둘이 공통으로 사용하는 `~/.agents/skills` 경로를 구성합니다.

### 3. 전역 Skill 자동 연결

`skills/*/SKILL.md`를 자동 탐색합니다.

탐색된 Skill은 **설치된 Agent에만** Junction으로 연결합니다.

```text
Codex + Cursor
~\.agents\skills\<skill-name>

Claude Code
~\.claude\skills\<skill-name>

Antigravity
~\.gemini\config\skills\<skill-name>
```

따라서 Skill 원본은 `AI_MEMORY\skills\` 한 곳에서만 관리합니다.

### 4. 공용 전역 지침 배포

전역 지침의 유일한 원본은 다음 파일입니다.

```text
instructions/GLOBAL_AGENT_INSTRUCTIONS.md
```

`setup.ps1`이 **설치된 Agent에만** 반영합니다.

```text
Codex       → ~/.codex/AGENTS.md
Cursor      → ~/.cursor/rules/ai-memory.mdc
Claude Code → ~/.claude/CLAUDE.md
Antigravity → ~/.gemini/GEMINI.md
```

Codex, Claude Code, Antigravity의 기존 전역 지침은 삭제하지 않습니다. `AI_MEMORY_MANAGED_START/END` 블록만 추가하거나 갱신합니다.

Cursor는 `ai-memory.mdc`라는 AI_MEMORY 전용 Rule 파일을 별도로 관리합니다. 동일 이름의 사용자 파일이 존재하고 AI_MEMORY 관리 마커가 없다면 덮어쓰지 않습니다.

## 자동 Recall 대상

과거 프로젝트 경험이 현재 판단에 도움 될 가능성이 있는 **비단순 엔지니어링 작업**은 기본적으로 Recall 대상입니다.

예:

- 시스템/소스/문제 분석
- 기능 설계
- API 설계
- 아키텍처 설계
- 데이터 모델/DB 설계
- 기술 의사결정 및 영향 분석
- 구현
- 디버깅
- 리팩터링
- 코드 리뷰
- 마이그레이션
- 빌드/배포
- 보안 검토
- 반복되는 장애/운영 작업

다음과 같은 단순 질문에서는 일반적으로 Recall을 생략합니다.

```text
Java int를 String으로 변환하는 법
특정 git 명령어 하나 확인
단순 문법 질문
```

사용자가 Recall을 먼저 호출할 필요는 없습니다.

## Learn 사용 방식

작업 완료 자체는 Memory 저장 권한이 아닙니다.

사용자가 명시적으로 요청해야 합니다.

```text
"이거 기억해"
"이번 해결 방법 저장해"
"이 규칙 앞으로 기억해"
"기존 메모리 업데이트해"
```

그때 `agent-memory`가 다음을 수행합니다.

```text
저장 가치 판단
   ↓
기존 Memory 검색
   ↓
중복 있음 → 기존 MD 갱신
중복 없음 → 신규 MD 생성
   ↓
INDEX 재생성
```

## Memory 종류

- `rule` : 반복적으로 따라야 하는 검증된 규칙
- `lesson` : 재사용 가능한 문제 해결/설계 경험
- `incident` : 실제 장애와 검증된 원인/해결
- `project` : 특정 프로젝트에서만 유효한 구조/제약/지식

세부 저장 정책은 [`MEMORY_POLICY.md`](./MEMORY_POLICY.md)를 따릅니다.

## Memory 검색 원칙

전체 Memory를 매번 읽지 않습니다.

```text
현재 작업 분석
   ↓
Global / Project Rule 확인
   ↓
INDEX 검색
   ↓
관련 Lesson / Incident 검색
   ↓
가장 관련성 높은 소수의 Memory만 읽기
   ↓
현재 코드/설정과 일치하는지 검증 후 사용
```

현재 소스 코드, 테스트, 설정, 공식 문서, 명시적인 프로젝트 지침이 오래된 Memory와 충돌하면 **현재 증거가 우선**입니다.

## 다른 PC에서 동기화

```powershell
git pull
.\setup.ps1
```

새 PC에서는:

```powershell
git clone https://github.com/sunyun0820/AI_MEMORY.git
cd AI_MEMORY
.\setup.ps1
```

으로 공용 Memory 경로와 **그 PC에 설치된 Agent의** 전역 Skills/전역 지침만 구성합니다.

예를 들어 새 PC에 Codex만 설치되어 있다면 Codex 관련 구성만 적용되고 Cursor, Claude Code, Antigravity는 건너뜁니다.

나중에 해당 PC에 Claude Code를 새로 설치했다면 다시:

```powershell
.\setup.ps1
```

만 실행하면 새로 감지된 Claude Code에도 공용 Skill과 전역 지침이 적용됩니다.

## Git 운영

Memory나 Skill을 변경한 뒤에는 일반 Git 흐름을 사용합니다.

```powershell
git add .
git commit -m "에이전트 공용 메모리 업데이트"
git push
```

Git은 동기화뿐 아니라 잘못된 Memory/Skill 변경을 diff와 rollback으로 관리하기 위한 장치이기도 합니다.

## 현재 단계

현재는 의도적으로 단순하게 유지합니다.

```text
Markdown + Git + Shared Memory + Shared Global Skills + Shared Global Instructions
```

Memory 규모가 커져 단순 검색이 비효율적이 되는 시점에 SQLite FTS 또는 Vector Search를 추가할 수 있습니다.
