---
id: MEM-20260908-154901
type: project
scope: project
project: cmos-frame
domain: crypto
tags: [encryption, decryption, double-encryption, crypto-column, user-save]
status: active
confidence: high
created: 2026-09-08
updated: 2026-09-08
last_seen: 2026-09-08
occurrences: 1
source_agent: antigravity
---

# C-MOS 컬럼 복호화 폴백과 이중 암호화 방어의 한계

## Core Knowledge

현재 `EncryptionContext.decrypt(src)`는 복호화 예외 시 null 대신 원문을 반환한다. 이는 레거시 입력이 조회 결과에서 null로 바뀌는 것을 줄이는 호환 처리이며, 반환값이 평문이라는 보장은 아니다. `CryptoColumnUtility.encryptEntity`는 암호문 여부를 판별하지 않고 대상 문자열을 다시 암호화한다.

## Applicability / Known Approach

busan `UserSave_Cryto.updateUser`는 `decryptEntity(user)`를 선행한 뒤 `updateByCrypto`를 호출한다. 현재 키·알고리즘으로 정상 복호화되는 DB 원문이 들어오는 경우 기존 암호문을 다시 암호화하는 문제를 줄인다.

다른 키·체계의 암호문이나 손상된 암호문은 복호화 실패 후 그대로 남아 재암호화될 수 있다. 실패 시 원문 반환만으로 평문/암호문 구분이나 “항상 한 번만 암호화”를 주장하지 않는다.

## Avoid / Recurrence Prevention

- 서비스 입력의 출처·암호화 상태와 읽기/쓰기 경계를 먼저 확인한다. 임의 문자열에 decrypt를 반복 호출하는 것을 보편적 정규화 방법으로 삼지 않는다.
- 평문, 현재 체계의 정상 암호문, 잘못된 키·손상된 암호문, null/빈값, 재저장을 구분해 검증한다.
- Prefix 도입·암호화 인터페이스 변경은 기존 데이터 형식과 소비자에 미치는 영향을 평가할 별도 설계다. 당시 변경 범위 선택을 영구적인 “코어 수정 금지” 규칙으로 승격하지 않는다.
- [폴백 반환값과 성공 판정 구분](../../lessons/fallback-result-is-not-success-proof.md)을 참조한다.

## Verification

2026-09-08 현재 `framework/iia/.../EncryptionContext.java`의 예외 분기, `framework/core/.../CryptoColumnUtility.java`의 encrypt/decryptEntity, `busan/service/.../UserSave_Cryto.java`의 선행 복호화를 정적 대조했다. 원본의 framework-iia/service 컴파일 성공은 과거 증거이며 평문 보장이나 암호학적 안전성 검증이 아니다. 이번에는 DB·런타임 테스트를 수행하지 않았다.
