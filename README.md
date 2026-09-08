# AI_MEMORY

Codex, Cursor, Claude Code, Gemini/Antigravity 등 여러 개발 Agent가 **공용 장기 메모리, 전역 Skill, 공용 Rule, 전역 지침, 반복 작업 Tool**을 한 저장소에서 공유하기 위한 개인 Agent Runtime 저장소입니다.

## 목표

1. 과거 작업의 중요한 규칙, 실수, 장애 원인, 해결 패턴, 설계 제약을 다음 작업에서 재사용합니다.
2. 반복적이고 기계적인 작업은 검증된 Tool로 실행하여 속도와 토큰 사용량을 줄입니다.
3. 여러 PC와 여러 Agent에서 최대한 동일한 환경을 `git clone + setup.ps1`로 재현합니다.
4. DB/Git/엔지니어링 같은 공통 안전 규칙은 Agent별로 복붙하지 않고 AI_MEMORY 한 곳에서 관리합니다.
5. 전역 Skill도 AI_MEMORY를 canonical source로 삼고 여러 Agent에 동일하게 배포합니다.

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
│        ├─ db-safety.mdc
│        ├─ git-safety.mdc
│        └─ engineering-principles.mdc
│
├─ skills/
│  ├─ agent-memory/
│  └─ <shared-skill>/
│
├─ memory/
├─ tools/
├─ templates/
└─ scripts/
   └─ import-global-skills.ps1
```

## 역할 구분

```text
instructions = AI_MEMORY 자체의 공통 Agent 동작 지침
rules        = 모든 Agent에 항상 적용할 안전·엔지니어링 규칙 원본
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

## Agent별 배포

```text
canonical rules
      │
      ├─ Codex / Claude / Gemini 계열
      │      ↓
      │   RULES.md + GLOBAL_AGENT_INSTRUCTIONS.md
      │
      └─ Cursor
             ↓
          local plugin
             ├─ db-safety.mdc
             ├─ git-safety.mdc
             └─ engineering-principles.mdc
```

Cursor에서는 `agent-memory` Skill이 Memory Recall/Learn/Backfill 동작을 담당하고, 공용 안전 Rule 3개는 local plugin의 독립된 `alwaysApply` Rule 3개로 배포합니다.

따라서 Cursor `Customize → Plugins`에는 **Ai Memory 플러그인 1개**가 보이는 것이 정상이고, `Customize → Rules`에는 AI_MEMORY가 제공하는 **Rule 3개**가 별도로 보여야 정상입니다.

# Shared Skills

공용 Skill의 canonical source는 항상 다음입니다.

```text
AI_MEMORY/skills/<skill-name>/
```

Agent별 설치 디렉터리는 배포 대상일 뿐 원본으로 취급하지 않습니다.

새 전역 Skill을 다른 Agent 또는 패키지 관리 도구로 먼저 설치한 경우에는 다음 스크립트를 반복해서 사용할 수 있습니다.

```powershell
.\scripts\import-global-skills.ps1
```

기본 검색 대상은 현재 존재하는 다음 전역 Skill 경로입니다.

```text
~/.agents/skills
~/.gemini/config/skills
~/.gemini/skills
~/.claude/skills
~/.cursor/skills
```

동작 원칙:

1. 각 경로에서 `SKILL.md`가 있는 활성 Skill만 찾습니다.
2. `AI_MEMORY/skills/<name>`에 이미 있으면 다시 가져오지 않습니다.
3. AI_MEMORY에 없는 Skill만 디렉터리 전체를 임시 위치로 복사합니다.
4. 모든 파일의 SHA-256 fingerprint가 원본과 같은지 검증한 뒤 canonical 디렉터리로 확정합니다.
5. `~/.agents/skills`에서 가져온 Skill은 검증 성공 후 원본 디렉터리를 AI_MEMORY canonical Skill을 가리키는 junction으로 바꿉니다.
6. Gemini/Antigravity/Claude/Cursor의 다른 source root는 import source로만 사용하며 import 스크립트가 직접 삭제하지 않습니다. 이후 `setup.ps1`이 Agent별 배포 형식으로 동기화합니다.
7. AI_MEMORY 안의 기존 Skill을 자동 덮어쓰지 않습니다. 이름은 같지만 내용이 다르면 경고하고 둘 다 보존합니다.

변경 없이 어떤 Skill이 import 대상인지 먼저 보고 싶으면:

```powershell
.\scripts\import-global-skills.ps1 -WhatIf
```

`~/.agents/skills`의 실제 디렉터리를 junction으로 바꾸지 않고 원본을 그대로 유지하려면:

```powershell
.\scripts\import-global-skills.ps1 -KeepAgentsSource
```

특정 경로만 검사할 수도 있습니다.

```powershell
.\scripts\import-global-skills.ps1 -SourceRoot "$HOME\.agents\skills"
```

Import 후에는 새로 생긴 `skills/*`를 검토하고 Git에 반영한 다음 아래를 실행합니다.

```powershell
.\setup.ps1
.\doctor.ps1
```

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
명시 요청 시 현재 지식은 Learn/Remember
또는
명시 요청 시 세션 전체 회고는 Backfill
```

## Memory 원칙

### Recall = 자동

과거 프로젝트 경험이 현재 판단에 도움 될 가능성이 있는 비단순 엔지니어링 작업에서는 관련 Memory를 선택적으로 조회합니다. 전체 Memory를 매번 읽지 않습니다.

### Learn / Remember = 사용자 명시 요청

작업 도중 지금 막 확인된 중요한 지식 하나 또는 몇 개를 저장/갱신하는 모드입니다.

작업 완료 자체는 Memory 저장 권한이 아닙니다. `기억해`, `메모리에 남겨`, `저장해`, `업데이트해`처럼 사용자가 명시적으로 요청한 경우에만 저장/갱신합니다.

### Backfill = 사용자 명시 요청

완료되었거나 충분히 진행된 현재 세션을 전체적으로 회고해서 실시간 Learn/Remember에서 놓친 재사용 지식을 복구하는 모드입니다.

실수/시행착오, 재발 방지 규칙, 프로젝트 로직/제약, 설계 결정과 폐기안, 검증/디버깅 절차, 재사용 작업 순서, 지속적 위험, Tool 후보까지 확인합니다. 모든 내용을 저장하지 않고 `MEMORY_POLICY.md` 기준으로 가치 있는 내용만 중복/충돌 확인 후 저장합니다.

Tool 후보는 Backfill에서 발굴/보고만 하며 자동 구현하지 않습니다.

권장 호출:

```text
agent_memory recall
agent_memory remember
agent_memory backfill
```

`agent-memory`처럼 하이픈으로 적어도 됩니다. 자세한 사용법은 `skills/agent-memory/README.md`와 `skills/agent-memory/references/backfill.md`를 참고합니다.

세부 저장 기준은 `MEMORY_POLICY.md`를 따릅니다.

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

1. canonical shared rules 3개 검증
2. `rules/RULES.md` 재생성
3. Cursor용 `.mdc` Rule 3개 재생성
4. `AI_MEMORY_HOME` 등록
5. 설치된 Agent 감지
6. `AI_MEMORY/skills/*`의 모든 canonical Skill 연결/복사
7. Agent별 전역 지침/Rule 배포
8. 구버전 Cursor junction 또는 통합 `ai-memory.mdc`를 AI_MEMORY 소유인 경우에만 안전하게 정리

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

Cursor 전역 Rule은 local plugin으로 배포합니다.

```text
~/.cursor/plugins/local/ai-memory/
├─ .cursor-plugin/
│  └─ plugin.json
└─ rules/
   ├─ db-safety.mdc
   ├─ git-safety.mdc
   └─ engineering-principles.mdc
```

`setup.ps1`은 이 경로를 junction으로 두지 않고 실제 파일로 복사합니다. Rule 변경 또는 `git pull` 후에는 `setup.ps1`을 다시 실행하면 됩니다.

```powershell
git pull
.\setup.ps1
.\doctor.ps1
```

그 후 Cursor가 실행 중이면 `Developer: Reload Window`를 실행합니다.

## Cursor 확인 기준

정상 상태:

```text
Customize → Plugins
└─ Ai Memory (Local)            1개

Customize → Rules
├─ DB Safety 계열               1개
├─ Git Safety 계열              1개
└─ Engineering Principles 계열  1개
```

기존에 `Customize → Rules`에 사용자가 직접 만든 동일 내용의 User Rule 3개가 있다면, AI_MEMORY의 plugin Rule 3개가 정상 표시되고 `doctor.ps1`이 PASS한 뒤 삭제해야 중복 적용을 피할 수 있습니다.

### Cursor plugin이 보이지 않을 때

1. `Settings → Agents → Include Third-Party Plugins, Skills, and Other Configs`가 ON인지 확인
2. `~/.cursor/plugins/local/ai-memory/.cursor-plugin/plugin.json`이 실제 파일인지 확인
3. `Developer: Reload Window` 실행
4. Teams/Enterprise 계정이면 조직 정책에서 Local Plugin Imports가 허용되는지 확인

# Doctor

```powershell
.\doctor.ps1
```

Doctor는 다음을 검사합니다.

- 필수 Repository 구조
- `AI_MEMORY_HOME`
- canonical Shared Rule 3개 존재 및 내용
- `rules/RULES.md` 동기화 상태
- Cursor adapter Rule 3개 동기화 상태
- Cursor local plugin이 junction이 아닌 실제 폴더인지
- Cursor plugin manifest와 설치된 Rule 3개가 AI_MEMORY 원본과 일치하는지
- 구버전 통합 `ai-memory.mdc`가 제거되었는지
- Agent 감지 및 canonical Skill 배포 상태
- Codex/Claude/Gemini managed block 동기화 상태

Doctor는 Cursor UI 내부의 조직 정책까지 판정하지는 못합니다.

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

새로운 전역 Skill을 외부 도구로 설치한 뒤 AI_MEMORY 중앙관리 대상으로 편입하려면:

```powershell
.\scripts\import-global-skills.ps1
```

# Git 운영

Memory, Skill, Tool, 공용 Rule, 전역 지침은 Git으로 동기화하고 변경 이력을 관리합니다. Git 작업은 `rules/git-safety.md`를 따릅니다.

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
