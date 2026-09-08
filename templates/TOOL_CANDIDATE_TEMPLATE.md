### TC-XXXX — 후보 이름

- `dedup_key`: `stable-purpose-or-target-key`
- `kind`: `new-tool | improvement`
- `target`: `새 Tool이면 예정 이름 또는 역할 / improvement면 기존 Tool·Script 경로`
- `status`: `candidate`
- `occurrences`: 1
- `first_seen`: `YYYY-MM-DD`
- `last_seen`: `YYYY-MM-DD`
- `projects`: `project-a`
- `verification`: `needs-validation | source-confirmed | runtime-confirmed`
- `expected_gain`: `token=low|medium|high, time=low|medium|high, error=low|medium|high`
- `implementation_difficulty`: `low | medium | high`
- `recommendation`: `low | medium | high`
- `problem`: 반복 작업 또는 기존 Tool/Script 문제를 한두 문장으로 작성합니다.
- `input`: 새 Tool 후보일 때 핵심 입력을 간단히 작성합니다. improvement면 필요 없을 경우 생략합니다.
- `output`: 새 Tool 후보일 때 핵심 출력을 간단히 작성합니다. improvement면 필요 없을 경우 생략합니다.
- `evidence`: 어떤 세션/프로젝트/소스에서 왜 후보가 되었는지 비밀정보 없이 짧게 작성합니다.
- `proposed_direction`: 구현 방향이 명확할 때만 짧게 작성합니다.

중복 후보를 발견하면 새 항목을 만들지 말고 기존 항목의 `occurrences`, `last_seen`, `projects`, `evidence`를 갱신합니다.
