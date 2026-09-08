# AI_MEMORY

Codex, Cursor, Claude Code, Gemini/Antigravity 등 여러 개발 에이전트가 **공용 장기 메모리, 전역 Skill, 공용 Rule, 전역 지침, 반복 작업 Tool**을 한 저장소에서 공유하기 위한 개인 Agent Runtime 저장소입니다.

## 목표

1. 과거 작업의 중요한 규칙, 실수, 장애 원인, 해결 패턴, 설계 제약을 다음 작업에서 다시 활용합니다.
2. 반복적이고 기계적인 작업은 검증된 Tool로 실행하여 작업 속도를 높이고 Agent의 불필요한 추론/토큰 사용을 줄입니다.
3. 여러 PC와 여러 Agent에서 최대한 동일한 작업 환경을 `git clone + setup.ps1`로 재현합니다.
4. DB/Git/엔지니어링 같은 공통 안전 규칙은 Agent별로 복붙하지 않고 AI_MEMORY 한 곳에서 관리합니다.

## 핵심 구조

```text
AI_MEMORY/
├─ README.md
├─ INDEX.md
├─ TOOL_INDEX.md
├─ MEMORY_POLICY.md
├─ setup.ps1
├─ doctor.ps1
│
├─ instructions/
│  └─ GLOBAL_AGENT_INSTRUCTIONS.md
│
├─ rules/
│  ├─ README.md
│  ├─ db-safety.md
│  ├─ git-safety.md
│  ├─ engineering-principles.md
│  └─ RULES.md
│
├─ skills/
│  ├─ README.md
│  └─ agent-memory/
│     └─ SKILL.md
│
├─ memory/
│  ├─ rules/
│  ├─ lessons/
│  ├─ incidents/
│  ├─ projects/
│  └─ archive/
│
├─ tools/
│  ├─ README.md
│  ├─ common/
│  ├─ filesystem/
│  ├─ git/
│  ├─ java/
│  ├─ dotnet/
│  ├─ database/
│  ├─ build/
│  └─ web/
│
├─ templates/
│  ├─ MEMORY_TEMPLATE.md
│  └─ TOOL_TEMPLATE.md
│
└─ scripts/
   ├─ search-memory.ps1
   ├─ rebuild-index.ps1
   ├─ search-tools.ps1
   └─ rebuild-tool-index.ps1
```

## 역할 구분

```text
instructions = AI_MEMORY 자체의 공통 Agent 동작 지침
rules        = 모든 Agent에 항상 적용할 안전·엔지니어링 규칙
skills       = Agent가 특정 작업을 어떻게 수행할지 정의
memory       = 과거 작업에서 무엇을 배웠는지 저장
tools        = 반복 작업을 실제 스크립트/프로그램으로 실행
```

각 영역을 섞지 않습니다.

- 업무 경험/오류 원인 → `memory/`
- Agent Workflow → `skills/`
- AI_MEMORY Recall/Learn/Tool 사용 원칙 → `instructions/`
- 모든 Agent 공통 안전·행동 규칙 → `rules/`
- 반복 실행 가능한 자동화 → `tools/`

`memory/rules/`는 과거 작업에서 학습한 규칙을 저장하는 Memory 분류이고, 루트의 `rules/`는 모든 Agent에 항상 배포되는 전역 Rule이므로 역할이 다릅니다.

# Shared Rules

공용 Rule의 canonical source는 다음 세 파일입니다.

```text
rules/db-safety.md
rules/git-safety.md
rules/engineering-principles.md
```

`rules/RULES.md`는 위 세 파일을 합친 배포용 aggregator입니다.

```text
canonical rules
      ↓
rules/RULES.md
      ↓
GLOBAL_AGENT_INSTRUCTIONS.md 와 결합
      ↓
Agent별 전역 지침으로 배포
```

`RULES.md`는 직접 수정하지 않습니다. canonical rule 파일을 수정한 뒤 `setup.ps1`을 실행하면 자동으로 재생성됩니다.

# Agent 기본 흐름

```text
사용자 요청
   ↓
공용 Rule 적용
   ↓
비단순 분석/설계/개발 작업인가?
   ↓ YES
관련 Memory Recall
   ↓
필요한 Skill 적용
   ↓
반복/대량/기계적 작업이 있는가?
   ↓ YES
TOOL_INDEX에서 기존 Tool 검색
   ↓
적합한 Tool이 있으면 TOOL.md 확인 후 실행
   ↓
없으면 Agent가 직접 수행
   ↓
결과 판단
   ↓
사용자가 명시적으로 요청한 경우에만 Memory Learn
```

## Memory 원칙

### Recall = 자동

과거 프로젝트 경험이 현재 판단에 도움 될 가능성이 있는 비단순 엔지니어링 작업에서는 관련 Memory를 선택적으로 조회합니다.

대표 대상:

- 시스템/소스/문제 분석
- 기능/API/아키텍처/DB 설계
- 기술 의사결정과 영향 분석
- 구현/디버깅/리팩터링/코드 리뷰
- 마이그레이션
- 빌드/배포
- DB 작업
- 보안 검토
- 반복되는 장애/운영 작업

전체 Memory를 매번 읽지 않습니다.

### Learn = 사용자 명시 요청

작업 완료 자체는 Memory 저장 권한이 아닙니다.

예:

```text
"이거 기억해"
"이번 해결 방법 메모리에 남겨"
"기존 메모리 업데이트해"
"이 실수 학습해"
```

처럼 사용자가 명시했을 때만 저장/갱신합니다.

세부 기준은 [`MEMORY_POLICY.md`](./MEMORY_POLICY.md)를 따릅니다.

# Tool 원칙

반복적·대량·결정적·기계적인 작업에서는 AI가 동일 절차를 매번 다시 수행하기 전에 [`TOOL_INDEX.md`](./TOOL_INDEX.md)를 확인합니다.

```text
TOOL_INDEX.md
   ↓
적합한 Tool 후보 선택
   ↓
선택한 Tool의 TOOL.md만 읽기
   ↓
입력 및 safety 확인
   ↓
Tool 실행
   ↓
요약 결과만 Agent가 분석
```

전체 `tools/` 디렉터리를 컨텍스트에 넣지 않습니다.

## Safety 등급

- `read-only`: 조회만 수행
- `write-local`: 로컬 파일 생성/수정
- `destructive`: 삭제/reset/대량 변경 등 영향이 큰 로컬 작업
- `external`: DB 쓰기, 배포, Git push, API 변경, 메일 등 외부 상태 변경

Tool이 존재한다는 사실 자체는 `destructive` 또는 `external` 작업의 실행 권한을 의미하지 않습니다.

# 최초 설치

```powershell
git clone https://github.com/sunyun0820/AI_MEMORY.git E:\AI_MEMORY
cd E:\AI_MEMORY
Set-ExecutionPolicy -Scope Process Bypass
.\setup.ps1
.\doctor.ps1
```

Repository 위치는 `E:\AI_MEMORY`로 고정되지 않습니다. `setup.ps1`이 현재 Repository 위치를 자동으로 사용합니다.

## setup.ps1 동작

1. 현재 Repository를 `AI_MEMORY_HOME` 사용자 환경변수에 등록합니다.
2. canonical shared rules 3개를 읽어 `rules/RULES.md`를 재생성합니다.
3. 설치된 Agent를 감지합니다.
4. 공용 Skill을 지원되는 Agent 위치에 junction으로 연결합니다.
5. `GLOBAL_AGENT_INSTRUCTIONS.md + RULES.md`를 하나의 AI_MEMORY managed block으로 배포합니다.
6. 기존 Agent별 사용자 지침은 삭제하지 않습니다.

### 전역 배포 위치

```text
Codex       → ~/.codex/AGENTS.md
Cursor      → ~/.cursor/rules/ai-memory.mdc
Claude Code → ~/.claude/CLAUDE.md
Gemini CLI  → ~/.gemini/GEMINI.md
Antigravity → ~/.gemini/GEMINI.md
```

Cursor/Codex/Claude/Gemini에 기존 사용자 지침이 있으면 그대로 유지하고 다음 관리 블록만 추가 또는 갱신합니다.

```text
<!-- AI_MEMORY_MANAGED_START -->
...
<!-- AI_MEMORY_MANAGED_END -->
```

### 전역 Skill

`skills/*/SKILL.md`를 자동 탐색하고 설치된 Agent에 연결합니다.

```text
Codex + Cursor → ~/.agents/skills/<skill-name>
Claude Code    → ~/.claude/skills/<skill-name>
Antigravity    → ~/.gemini/config/skills/<skill-name>
```

Skill 원본은 이 Repository의 `skills/` 한 곳에서 관리합니다.

# Doctor

```powershell
.\doctor.ps1
```

Doctor는 다음을 검사합니다.

- 필수 Repository 구조
- `AI_MEMORY_HOME`
- Shared Rule 3개 존재/비어있지 않음
- `rules/RULES.md`가 canonical source와 정확히 일치하는지
- Agent 감지
- Skill junction 대상
- Agent별 global instruction managed block 존재 여부
- **Agent별 managed block 내용이 현재 AI_MEMORY 원본과 정확히 일치하는지**

즉 파일만 존재한다고 PASS 처리하지 않고, stale rule/instruction도 FAIL로 판정합니다.

# 다른 PC에서 사용

새 PC:

```powershell
git clone https://github.com/sunyun0820/AI_MEMORY.git
cd AI_MEMORY
.\setup.ps1
.\doctor.ps1
```

기존 PC 업데이트:

```powershell
git pull
.\setup.ps1
.\doctor.ps1
```

나중에 새로운 Agent를 설치했다면 `setup.ps1`만 다시 실행하면 새로 감지된 Agent에 공용 설정이 추가됩니다.

# Git 운영

Memory, Skill, Tool, 공용 Rule, 전역 지침은 Git을 통해 동기화하고 변경 이력을 관리합니다.

AI가 Memory를 작성했다고 해서 commit/push까지 자동 수행하는 것을 기본 동작으로 두지는 않습니다. Git 작업은 `rules/git-safety.md`를 따릅니다.

# 현재 단계

현재 구조는 의도적으로 단순하게 유지합니다.

```text
Markdown
+ Git
+ Shared Memory
+ Shared Global Skills
+ Shared Global Rules
+ Shared Global Instructions
+ Shared Agent Tools
```

Memory/Tool 규모가 충분히 커져 Markdown 색인과 텍스트 검색이 비효율적이 되는 시점에 SQLite FTS 또는 Vector Search 같은 검색 계층을 추가할 수 있습니다.
