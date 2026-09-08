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

# 소스 기반 DOCX 매뉴얼은 API와 렌더링을 함께 검증할 것

## Core Knowledge

개발자 매뉴얼은 현재 공개 인터페이스와 코드 예제의 정합성, DOCX 구조, 실제 페이지 렌더링을 각각 확인해야 한다. 텍스트·XML 검사 통과만으로 목차·목록·페이지 분할까지 정상임을 보장할 수 없다.

## Applicability / Recurrence Prevention

- 인접 API 이름으로 서명을 추정하지 않는다. 현재 인터페이스의 인자·반환형·deprecated 여부와 소비 프로젝트 설정을 확인한다.
- 목차 도구가 사용자 표식을 처리하는지 확인하고 표지/목차 순서, 남은 placeholder, bookmark와 링크를 검사한다. 도구의 과거 동작을 모든 버전에 일반화하지 않는다.
- OOXML numbering의 `w:abstractNum`은 `w:num` 앞에 배치한다. 번호 재시작이 필요한 목록에는 별도 `w:numId`와 시작값 설정을 사용하고 렌더링으로 확인한다.
- 분할하면 읽기 어려운 표 행에는 `w:cantSplit`을 적용한다. 페이지보다 큰 행을 강제로 유지하지 말고 내용·표 구조를 조정한다. 코드 블록 분할은 별도로 확인한다.
- 최종 DOCX를 PDF·페이지 이미지로 렌더링해 전체를 확인한다. Windows에서 LibreOffice를 쓸 수 없고 Word가 설치되어 있으면 숨김 Word COM PDF 변환과 Poppler를 대체 경로로 검토한다. 실행 가능 여부와 현재 문서 스킬의 지침을 먼저 확인한다.

## Verification

원본 C-MOS 매뉴얼 작업에서 잘못 추정한 Factory 서명, 목차 위치, numbering과 표 분할을 수정했고, Word COM·Poppler로 26페이지를 확인했다고 기록되어 있다. 이는 당시 검증 증거이며 이번 Refine에서 문서를 재생성·렌더링한 결과가 아니다. 프로젝트 API 계약은 [C-MOS 매뉴얼 메모리](../projects/cmos-frame/backend-manual-source-contracts-3.5.2.md)를 참조한다.
