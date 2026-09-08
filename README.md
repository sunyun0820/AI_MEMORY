# AI_MEMORY

Codex, Cursor, Claude Code, Gemini/Antigravity 등 여러 개발 에이전트가 **공용 장기 메모리, 전역 Skill, 공용 Rule, 전역 지침, 반복 작업 Tool**을 한 저장소에서 공유하기 위한 개인 Agent Runtime 저장소입니다.

## 목표

1. 과거 작업의 중요한 규칙, 실수, 장애 원인, 해결 패턴, 설계 제약을 다음 작업에서 재사용합니다.
2. 반복적이고 기계적인 작업은 검증된 Tool로 실행하여 속도와 토큰 사용량을 줄입니다.
3. 여러 PC와 여러 Agent에서 최대한 동일한 환경을 `git clone + setup.ps1`로 재현합니다.
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
├─ adapters/
│  └─ cursor-plugin/
│     ├─ .cursor-plugin/
│     │  └─ plugin.json
│     └─ rules/
│        └─ ai-memory.mdc
│
├─ skills/
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
├─ templates/
└─ scripts/
```

## 역할 구분

```text
instructions = AI_MEMORY 자체의 공통 Agent 동작 지침
rules        = 모든 Agent에 항상 적용할 안전·엔지니어링 규칙
adapters     = Agent별 전역 설정 형식/배포 방식 차이를 흡수
skills       = Agent가 특정 작업을 어떻게 수행할지 정의
memory       = 과거 작업에서 무엇을 배웠는지 저장
tools        = 반복 작업을 실제 스크립트/프로그램으로 실행
```

`memory/rules/`는 과거 작업에서 학습한 규칙을 저장하는 Memory 분류이고, 루트의 `rules/`는 모든 Agent에 항상 배포되는 전역 Rule입니다.

# Shared Rules

공용 Rule의 canonical source는 다음 세 파일입니다.

```text
rules/db-safety.md
rules/git-safety.md
rules/engineering-principles.md
```

`rules/RULES.md`는 위 세 파일을 합친 배포용 aggregator이며 직접 수정하지 않습니다.

```text
canonical rules
      ↓
rules/RULES.md
      ↓
GLOBAL_AGENT_INSTRUCTIONS.md 와 결합
      ↓
Agent별 전역 지침/adapter로 배포
```

Rule을 수정한 뒤 `setup.ps1`을 실행하면 aggregator와 Agent별 배포본이 갱신됩니다.

# Agent 기본 흐름

```text
사용자 요청
   ↓
공용 Rule 적용
   ↓
비단순 엔지니어링 작업이면 관련 Memory Recall
   ↓
필요한 Skill 적용
   ↓
반복/대량/결정적 작업이면 TOOL_INDEX 검색
   ↓
적합한 Tool 실행
   ↓
결과 판단
   ↓
사용자가 명시적으로 요청한 경우에만 Memory Learn
```

## Memory 원칙

### Recall = 자동

과거 프로젝트 경험이 현재 판단에 도움 될 가능성이 있는 비단순 엔지니어링 작업에서는 관련 Memory를 선택적으로 조회합니다.

전체 Memory를 매번 읽지 않습니다.

### Learn = 사용자 명시 요청

작업 완료 자체는 Memory 저장 권한이 아닙니다.

다음처럼 사용자가 명시했을 때만 저장/갱신합니다.

```text
"이거 기억해"
"이번 해결 방법 메모리에 남겨"
"기존 메모리 업데이트해"
"이 실수 학습해"
```

세부 기준은 `MEMORY_POLICY.md`를 따릅니다.

# Tool 원칙

반복적·대량·결정적·기계적인 작업에서는 `TOOL_INDEX.md`를 먼저 확인합니다.

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

Tool의 `safety`는 다음 네 값 중 하나입니다.

- `read-only`
- `write-local`
- `destructive`
- `external`

Tool이 존재한다는 사실 자체는 `destructive` 또는 `external` 작업의 실행 권한을 의미하지 않습니다.

# 설치

```powershell
git clone https://github.com/sunyun0820/AI_MEMORY.git E:\AI_MEMORY
cd E:\AI_MEMORY
Set-ExecutionPolicy -Scope Process Bypass
.\setup.ps1
.\doctor.ps1
```

Repository 위치는 고정되지 않습니다. `setup.ps1`이 현재 Repository 위치를 `AI_MEMORY_HOME`으로 등록합니다.

## setup.ps1 동작

1. `AI_MEMORY_HOME` 등록
2. canonical shared rules 3개 검증
3. `rules/RULES.md` 재생성
4. `GLOBAL_AGENT_INSTRUCTIONS.md + RULES.md` 결합
5. 설치된 Agent 감지
6. 공용 Skill 연결
7. Agent별 전역 지침/adapter 배포
8. 기존 사용자 지침은 가능한 범위에서 보존

## 전역 배포 위치

```text
Codex       → ~/.codex/AGENTS.md
Claude Code → ~/.claude/CLAUDE.md
Gemini CLI  → ~/.gemini/GEMINI.md
Antigravity → ~/.gemini/GEMINI.md
Cursor      → ~/.cursor/plugins/local/ai-memory
```

Codex/Claude/Gemini 계열은 기존 파일 안에 다음 관리 블록만 추가 또는 갱신합니다.

```text
<!-- AI_MEMORY_MANAGED_START -->
...
<!-- AI_MEMORY_MANAGED_END -->
```

# Cursor 배포 방식

Cursor는 일반적인 `~/.cursor/rules/*.mdc`를 모든 프로젝트의 전역 Rule로 안정적으로 로딩하는 방식에 의존하지 않습니다.

AI_MEMORY는 Cursor 전역 Rule을 **local Cursor Plugin**으로 배포합니다.

중요: Cursor 최신 빌드에서는 `~/.cursor/plugins/local/` 바깥을 가리키는 symlink/junction이 로드되지 않는 사례가 있으므로, `setup.ps1`은 plugin을 junction으로 연결하지 않고 다음 위치에 **실제 파일로 복사**합니다.

```text
~/.cursor/plugins/local/ai-memory/
├─ .cursor-plugin/
│  └─ plugin.json
└─ rules/
   └─ ai-memory.mdc
```

원본은 계속 다음 위치에서 관리합니다.

```text
AI_MEMORY/adapters/cursor-plugin/
```

따라서 Rule 변경 또는 `git pull` 후에는 `setup.ps1`을 다시 실행해야 Cursor 배포본이 동기화됩니다.

```powershell
git pull
.\setup.ps1
.\doctor.ps1
```

그 후 Cursor에서 `Developer: Reload Window`를 실행합니다.

### Cursor plugin이 Customize에 보이지 않을 때

다음을 확인합니다.

1. `Settings → Agents → Include Third-Party Plugins, Skills, and Other Configs`가 ON인지 확인
2. `~/.cursor/plugins/local/ai-memory/.cursor-plugin/plugin.json`이 실제 파일인지 확인
3. `Developer: Reload Window` 실행
4. Teams/Enterprise 계정이면 조직 관리자가 **Allow Local Plugin Imports**를 허용했는지 확인
5. 그래도 안 보이면 `Developer: Toggle Developer Tools → Console`에서 `plugin` 관련 오류 확인

조직 정책이 local plugin import를 막고 있으면 파일이 정상이어도 Cursor가 해당 폴더를 무시할 수 있습니다.

# Doctor

```powershell
.\doctor.ps1
```

Doctor는 다음을 검사합니다.

- 필수 Repository 구조
- `AI_MEMORY_HOME`
- Shared Rule 3개 존재/비어있지 않음
- `rules/RULES.md`가 canonical source와 일치하는지
- Cursor adapter 원본이 최신인지
- Agent 감지
- Skill junction 대상
- Codex/Claude/Gemini managed block 내용 일치 여부
- Cursor local plugin이 **junction이 아닌 실제 폴더**인지
- Cursor local plugin의 manifest/rule 복사본이 AI_MEMORY 원본과 일치하는지

Doctor는 Cursor 애플리케이션 내부의 조직 정책까지 판정하지는 못합니다. 파일 검증이 PASS인데 Customize에 plugin이 없다면 Cursor의 local plugin import 설정/조직 정책/클라이언트 로딩 문제를 확인해야 합니다.

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

새 Agent를 설치한 뒤에도 `setup.ps1`을 다시 실행하면 감지된 Agent에 공용 설정이 추가됩니다.

# Git 운영

Memory, Skill, Tool, 공용 Rule, 전역 지침은 Git으로 동기화하고 변경 이력을 관리합니다.

AI가 Memory를 작성했다고 해서 commit/push까지 자동 수행하는 것을 기본 동작으로 두지는 않습니다. Git 작업은 `rules/git-safety.md`를 따릅니다.

# 현재 단계

```text
Markdown
+ Git
+ Shared Memory
+ Shared Global Skills
+ Shared Global Rules
+ Shared Global Instructions
+ Agent Adapters
+ Shared Agent Tools
```

Memory/Tool 규모가 커져 Markdown 색인과 텍스트 검색이 비효율적이 되는 시점에 SQLite FTS 또는 Vector Search 같은 검색 계층을 추가할 수 있습니다.
