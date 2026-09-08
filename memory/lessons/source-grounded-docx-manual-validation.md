---
id: MEM-20260908-155843
type: lesson
scope: global
project: ""
domain: docx-generation
tags: [docx, ooxml, toc, numbering, pagination, visual-qa]
status: active
confidence: high
created: 2026-09-08
updated: 2026-09-08
last_seen: 2026-09-08
occurrences: 1
source_agent: codex
---

# 소스 기반 DOCX 매뉴얼은 API 정합성과 OOXML 레이아웃을 함께 검증할 것

## Context

소스 기반 개발자 매뉴얼을 DOCX로 생성하면서 코드 예제는 정적 API 검사에 통과했지만, 목차 위치, 목록 번호, 표와 코드 블록의 페이지 분할은 렌더링 후에야 드러나는 문제가 있었다.

## Symptom

- 추정한 `getTid()`와 2개 인자의 `getConnector(...)` 예제가 현재 인터페이스에 없었다.
- 정적 목차 도구가 표지 앞 문서 시작 위치에 목차를 삽입하고 기존 `[[TOC]]` 표식을 남겼다.
- 글머리표가 숫자 목록으로 보이거나 다음 번호 목록이 앞 목록의 번호를 이어갔다.
- 표 행과 코드 블록이 페이지 경계에서 분리되어 한두 단어만 다음 페이지에 남았다.
- 표준 렌더러는 Windows 환경에서 LibreOffice 실행 파일을 찾지 못해 실패했다.

## Root Cause

- 메서드명을 인접 API에서 추정하고 실제 인터페이스 선언을 마지막 단계까지 확인하지 않았다.
- 정적 목차 스크립트는 목차를 항상 문서 시작에 삽입하도록 구현되어 있으며 사용자 정의 표식 위치를 처리하지 않는다.
- OOXML numbering에 새 `w:abstractNum`을 기존 `w:num` 뒤에 추가했고, 다시 시작해야 할 여러 숫자 목록이 같은 `w:numId`를 공유했다.
- 표 행에 `w:cantSplit`이 없었다.
- 렌더러가 LibreOffice에만 의존하고 Microsoft Word 변환 경로를 제공하지 않았다.

## Wrong Approach

- 오래된 문서나 이름이 비슷한 메서드만 보고 코드 예제를 확정한다.
- DOCX 내부 텍스트 검사만 통과하면 레이아웃도 정상이라고 본다.
- 번호 목록 하나를 문서 전체에서 재사용하거나 OOXML 요소 순서를 고려하지 않고 numbering XML 끝에 추가한다.

## Correct Approach

1. 모든 공개 코드 예제의 클래스와 메서드 서명을 현재 인터페이스 소스에서 확인하고 deprecated API도 구분한다.
2. 목차 생성 후 표지와 목차의 실제 순서, placeholder 잔존 여부, 링크와 bookmark를 검사한다.
3. 새 `w:abstractNum`은 첫 `w:num` 앞에 삽입하고, 번호를 다시 시작해야 하는 목록마다 별도의 `w:numId`를 만든다.
4. 페이지 중간 분할을 허용하지 않을 표의 각 행에 `w:cantSplit`을 적용한다.
5. DOCX를 PDF와 페이지 이미지로 렌더링해 모든 페이지를 확인한다. Windows에서 LibreOffice가 없으면 숨김 Word COM으로 PDF를 만들고 Poppler 실행 파일로 래스터화하는 대체 경로를 사용한다.
6. 구조 검사, 금지 패턴 검사, 최종 파일 hash 비교와 렌더링 검사를 분리해 수행한다.

## Reusable Rule

개발자 매뉴얼의 완성 조건은 내용 생성이 아니라 현재 소스와의 API 정합성, DOCX 구조 검사, 실제 렌더링 전 페이지 검토가 모두 끝난 상태다.

## Verification

- 잘못된 Factory 예제를 현재 인터페이스와 대조해 `getGuId()` 및 `getConnector(Connector.Type)` 형태로 수정했다.
- 목차를 지정 위치로 이동하고 placeholder를 제거한 뒤 bookmark와 hyperlink를 검사했다.
- numbering XML 순서와 목록별 `numId`를 수정한 뒤 번호 표시가 정상임을 렌더링으로 확인했다.
- 모든 표 행에 `w:cantSplit`을 적용하고 26페이지 전체를 이미지로 확인했다.
- Word COM PDF 변환과 Poppler 래스터화를 실제로 수행해 LibreOffice 부재 시 대체 경로를 확인했다.
