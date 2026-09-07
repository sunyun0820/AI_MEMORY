---
id: RULE-GLOBAL-001
type: rule
scope: global
status: active
confidence: high
tags: [memory, safety, workflow]
created: 2026-09-07
updated: 2026-09-07
---

# Shared Agent Memory 기본 규칙

1. 메모리는 현재 코드, 테스트 결과, 설정, 공식 문서보다 우선하지 않는다.
2. 작업 전 전체 메모리를 읽지 말고 현재 작업과 관련된 항목만 검색한다.
3. 비밀번호, API Key, Token, Private Key 등 비밀정보를 메모리에 저장하지 않는다.
4. 작업 후 모든 내용을 저장하지 않는다. 재발 가능성과 재사용 가치가 있는 핵심만 저장한다.
5. 신규 메모리를 만들기 전에 중복 검색을 수행한다.
6. 기존 메모리가 틀렸다고 확인되면 새 파일을 추가하기보다 기존 메모리를 수정하거나 archive 처리한다.
7. 메모리 적용으로 변경 범위를 불필요하게 확대하지 않는다.
