# Global Skills

이 폴더는 Codex, Cursor, Claude Code, Antigravity에서 공통으로 사용할 **전역 Skill 원본 저장소**입니다.

## 기본 구조

각 Skill은 `skills/` 바로 아래에 독립 폴더로 둡니다.

```text
skills/
├─ skill-a/
│  └─ SKILL.md
├─ skill-b/
│  └─ SKILL.md
└─ skill-c/
   └─ SKILL.md
```

`setup.ps1`은 `skills/*/SKILL.md` 패턴을 자동으로 탐색합니다.

따라서 새 Skill을 추가할 때 setup 스크립트를 수정할 필요가 없습니다.

## 전역 연결 방식

탐색된 각 Skill 폴더는 Junction으로 다음 위치에 연결됩니다.

```text
Codex + Cursor
~\.agents\skills\<skill-name>

Claude Code
~\.claude\skills\<skill-name>

Antigravity
~\.gemini\config\skills\<skill-name>
```

실제 원본은 항상 이 Repository의 `skills/<skill-name>`입니다.

## 운영 원칙

- Agent별로 동일 Skill을 복사해서 관리하지 않습니다.
- Skill 원본은 이 Repository 한 곳에서만 수정합니다.
- Skill 폴더명은 짧고 역할이 명확한 이름을 사용합니다.
- 한 Skill은 하나의 명확한 책임을 갖도록 유지합니다.
- 프로젝트 전용 규칙은 무조건 전역 Skill로 만들지 않습니다.
- 장기 경험 데이터는 `skills/`가 아니라 `memory/`에 저장합니다.

## 새 Skill 추가 후

Repository를 받은 각 PC에서 다음만 실행하면 됩니다.

```powershell
git pull
.\setup.ps1
```

추가된 Skill이 자동으로 탐색되고 지원 Agent의 전역 Skill 경로에 연결됩니다.
