# Tool Candidate Backlog

> Backfill과 실사용 중 발견한 **미구현 Tool 후보** 및 **기존 Tool/Script 개선사항**을 누적하는 공용 backlog입니다.
>
> 실제 사용 가능한 Tool 목록은 `TOOL_INDEX.md`가 canonical source입니다. 이 파일의 항목은 후보일 뿐이며 자동 구현/실행 권한을 의미하지 않습니다.

## 운영 규칙

- Backfill에서 가치 있는 Tool 후보 또는 기존 Tool/Script 개선사항을 발견했을 때만 갱신합니다.
- 후보가 없으면 이 파일을 수정하지 않습니다.
- 이름이 아니라 **목적 + 대상 + 입력/출력 + 문제 형태**를 기준으로 기존 항목과 중복 여부를 판단합니다.
- 동일하거나 사실상 같은 후보라면 새 항목을 만들지 않고 기존 항목의 `occurrences`, `last_seen`, `projects`, `evidence`를 보완합니다.
- 기존 Tool/Script의 버그, 경로 문제, 출력 문제, 기능 부족은 `kind: improvement`로 분류합니다. 새 Tool 후보로 중복 등록하지 않습니다.
- 아직 실제 문제가 검증되지 않았다면 `verification: needs-validation`로 유지합니다.
- 후보가 구현되었다고 자동으로 판단하지 않습니다. 실제 Tool/Script 변경과 검증이 끝난 뒤에만 `status`를 갱신합니다.
- Backfill은 이 backlog를 갱신할 수 있지만 후보를 구현하거나 `TOOL_INDEX.md`에 등록하지 않습니다.
- 비밀번호, Token, API Key, Private Key 등 비밀정보는 evidence에 기록하지 않습니다.

## 상태

- `candidate`: 검토/우선순위 결정 전
- `planned`: 구현하기로 결정됨
- `implemented`: 구현 및 검증 완료
- `rejected`: 구현하지 않기로 결정
- `reopened`: 구현 후 동일 문제가 다시 확인됨

## 후보

### TC-0001 — rebuild-index 경로 렌더링 수정

- `dedup_key`: `rebuild-index-path-rendering`
- `kind`: `improvement`
- `target`: `scripts/rebuild-index.ps1`
- `status`: `candidate`
- `occurrences`: 1
- `first_seen`: `2026-09-08`
- `last_seen`: `2026-09-08`
- `projects`: `AI_MEMORY`
- `verification`: `source-confirmed`
- `expected_gain`: `token=low, time=medium, error=high`
- `implementation_difficulty`: `low`
- `recommendation`: `high`
- `problem`: INDEX 항목의 Path를 만드는 문자열에서 `$($item.Path)` 앞의 backtick이 변수 확장을 막아 실제 경로 대신 literal 표현이 출력될 수 있습니다.
- `evidence`: 현재 `scripts/rebuild-index.ps1`의 `AppendLine` 문자열이 ``- [...] - `$($item.Path)`...`` 형태이며, Backfill 과정에서 INDEX를 수동 교정한 사례가 보고되었습니다.
- `proposed_direction`: 경로 Markdown code 표시는 유지하되 PowerShell 변수 확장이 정상 동작하도록 문자열 구성을 수정하고, 생성된 INDEX에 literal `$(` 표현이 남지 않는 간단한 검증을 추가합니다.

## 신규 항목 템플릿

새 항목은 `templates/TOOL_CANDIDATE_TEMPLATE.md` 형식을 사용합니다.
