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
- `occurrences`: 4
- `first_seen`: `2026-09-08`
- `last_seen`: `2026-09-08`
- `projects`: `AI_MEMORY`
- `verification`: `source-confirmed`
- `expected_gain`: `token=low, time=medium, error=high`
- `implementation_difficulty`: `low`
- `recommendation`: `high`
- `problem`: INDEX 항목의 Path를 만드는 문자열에서 `$($item.Path)` 앞의 backtick이 변수 확장을 막아 실제 경로 대신 literal 표현이 출력될 수 있습니다.
- `evidence`: 현재 `scripts/rebuild-index.ps1`의 `AppendLine` 문자열이 ``- [...] - `$($item.Path)`...`` 형태이며, AMES 및 C-MOS Backfill에서 실제 경로 대신 `$(@{...}.Path)$extra`가 출력되어 `INDEX.md`를 수동 교정하는 문제가 반복 재현되었습니다.
- `proposed_direction`: 경로 Markdown code 표시는 유지하되 PowerShell 변수 확장이 정상 동작하도록 문자열 구성을 수정하고, 생성된 INDEX에 literal `$(` 표현이 남지 않는 간단한 검증을 추가합니다.

### TC-0002 — 다중 DBMS MyBatis SQL 매핑 정합성 검사기

- `dedup_key`: `verify-multi-db-sql-mapping`
- `kind`: `new-tool`
- `target`: `scripts/verify-sql-mapping.ps1`
- `status`: `candidate`
- `occurrences`: 1
- `first_seen`: `2026-09-08`
- `last_seen`: `2026-09-08`
- `projects`: `mes-core`, `c-mos`
- `verification`: `runtime-confirmed`
- `expected_gain`: `token=high, time=high, error=high`
- `implementation_difficulty`: `low`
- `recommendation`: `high`
- `problem`: MSSQL, Oracle, PostgreSQL 등 여러 DBMS를 동시 지원하는 환경에서 MyBatis XML 내 select/insert/update/delete ID가 DBMS 간 1:1로 일치해야 하나, 수동 비교 시 시간이 오래 걸리고 누락이 빈번하게 발생합니다.
- `input`: SQL 루트 디렉터리 경로 (예: `src/main/resources/sql`), 비교 대상 DBMS 목록 (예: `mssql, oracle, postgresql`)
- `output`: DBMS 간 SQL ID 3-way 차집합 결과 (특정 DBMS에만 존재하는 ID, 접미사 불일치, 중복 정의된 ID 등) 요약 리포트
- `evidence`: 이번 세션에서 수십 개 XML의 `select id`를 PowerShell 파이프라인으로 전수 추출하여 3-way diff를 수행하면서 Oracle의 `101-00002` 접미사 불일치 및 누락 쿼리를 발굴함. 스크립트화할 경우 반복적인 다중 DB SQL 점검 시간과 토큰 낭비를 획기적으로 줄일 수 있음.
- `proposed_direction`: 지정된 SQL 디렉터리에서 XML 태그(`<(select|insert|update|delete)\s+id="([^"]+)"`)를 정규식으로 추출하고, 각 DBMS별 ID Set을 구성하여 3-way diff 및 접미사 패턴을 분석하는 PowerShell 스크립트 작성.

### TC-0003 — internal_nav 정적 목차 삽입 위치 제어

- `dedup_key`: `internal-nav-toc-placement`
- `kind`: `improvement`
- `target`: `documents/scripts/internal_nav.py`
- `status`: `candidate`
- `occurrences`: 1
- `first_seen`: `2026-09-08`
- `last_seen`: `2026-09-08`
- `projects`: `cmos-frame`
- `verification`: `runtime-confirmed`
- `expected_gain`: `token=medium, time=high, error=high`
- `implementation_difficulty`: `medium`
- `recommendation`: `high`
- `problem`: 정적 목차가 항상 문서 시작에 삽입되어 표지보다 앞에 놓이고, 작성자가 둔 `[[TOC]]` placeholder는 남는다. 원하는 위치로 이동하고 중복 목차를 정리하는 후처리 스크립트가 필요했다.
- `evidence`: C-MOS 백엔드 개발자 매뉴얼에서 도구 실행 후 생성 목차를 placeholder 위치로 이동하고 placeholder를 제거하는 별도 `normalize_nav.py`를 작성해 해결했다. 현재 소스의 `body.insert(0, toc_heading)` 계열 구현도 시작 위치 고정을 확인시킨다.
- `proposed_direction`: 선택적 placeholder 문자열 또는 목차 heading 뒤 삽입 위치를 인자로 받고, 기존 placeholder를 치환하며, 포함할 heading level을 선택할 수 있게 한다. 기본 동작은 기존 호환성을 유지한다.

### TC-0004 — render_docx Windows Word COM 대체 렌더링

- `dedup_key`: `render-docx-windows-word-com-fallback`
- `kind`: `improvement`
- `target`: `documents/render_docx.py`
- `status`: `candidate`
- `occurrences`: 1
- `first_seen`: `2026-09-08`
- `last_seen`: `2026-09-08`
- `projects`: `cmos-frame`
- `verification`: `runtime-confirmed`
- `expected_gain`: `token=medium, time=high, error=high`
- `implementation_difficulty`: `medium`
- `recommendation`: `high`
- `problem`: Windows에서 LibreOffice 실행 파일이 없으면 DOCX 렌더링이 즉시 실패한다. Microsoft Word가 설치되어 있어도 대체 변환 경로가 없어 시각 QA가 중단된다.
- `evidence`: C-MOS 백엔드 개발자 매뉴얼 작업에서 LibreOffice 탐색 실패 후 숨김 Word COM으로 PDF를 만들고 Poppler의 `pdftoppm.exe`로 26페이지를 렌더링해 전 페이지 QA를 완료했다.
- `proposed_direction`: Windows에서 LibreOffice를 찾지 못할 때 Word COM의 PDF 내보내기를 선택적 fallback으로 제공하고, wrapper 탐색이 실패하면 번들 Poppler 실행 파일을 직접 탐색한다. Word 프로세스 종료와 임시 파일 정리를 보장한다.

## 신규 항목 템플릿

새 항목은 `templates/TOOL_CANDIDATE_TEMPLATE.md` 형식을 사용합니다.
