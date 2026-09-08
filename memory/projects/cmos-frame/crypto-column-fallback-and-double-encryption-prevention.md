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

# cmos-frame DB 컬럼 암호화 복호화 실패 폴백 및 이중 암호화 방지 패턴

## Context

`cmos-frame` 프레임워크의 `EncryptionContext`, `CryptoColumnUtility` 및 이를 사용하는 MES 서비스(`UserSave_Cryto` 등)에서 `crypto-columns.json`에 정의된 DB 컬럼의 암호화/복호화(`*ByCrypto`) 처리 중 발생한 평문 데이터 유실 및 이중 암호화 방지 작업이다.

## Symptom

1. DB에 기존 평문 데이터(레거시 데이터)나 다른 체계의 데이터가 들어있는 상태에서 `decrypt`를 호출하면 복호화 오류로 `null`이 반환되어 화면 및 조회 결과의 컬럼 데이터가 유실됨.
2. 비복호화 상태의 DB 원본 데이터(암호문)를 엔티티로 읽어와 일부 필드만 변경한 뒤 `updateByCrypto`를 호출하면, 이미 암호화된 문자열이 다시 암호화되는 이중 암호화(`AES(AES(value))`)가 발생함.

## Root Cause

1. `EncryptionContext.java`의 `decrypt(String src)` 메서드가 예외 발생 시 `logger.error(e); return null;`로 구현되어 있어, 평문 데이터가 들어오면 `null`로 반환됨.
2. `CryptoColumnUtility.encryptEntity`는 필드 값이 이미 암호문인지 판별하지 않고 무조건 `Factory.getEncryptionFactory().encrypt(plain)`를 호출함.

## Wrong Approach

- 이중 암호화를 막기 위해 프레임워크 코어 전체에 `{ENC}` 같은 Prefix를 부여하거나 암복호화 엔진 인터페이스(`InterfaceEncryptionFactory`)를 변경하려 하면, 기존 운영 DB 데이터 마이그레이션이 불가피해지거나 "코어 프레임워크 수정 금지" 프로젝트 원칙에 위배됨.

## Correct Approach

1. **복호화 엔진 폴백 처리**: `EncryptionContext.decrypt(String src)`에서 예외 발생 시 `null` 대신 원본 문자열 `src`를 그대로 반환하도록 수정 (평문 입력 시 평문 그대로 유지).
2. **서비스 레이어 이중 암호화 방어**: DB 원본 암호문 데이터가 유입될 수 있는 서비스 업데이트 로직(예: `UserSave_Cryto.updateUser`)의 최상단에서 `CryptoColumnUtility.decryptEntity(user);`를 선제 호출함.
   - 입력값이 평문이면 복호화 실패로 평문 유지.
   - 입력값이 암호문이면 정상 복호화되어 평문으로 변환.
   - 결과적으로 100% 평문 상태가 보장된 후 `updateByCrypto`를 호출하여 안전하게 1회만 암호화됨.

## Reusable Rule

`cmos-frame` 기반 서비스에서 DB 원형 데이터가 `updateByCrypto`로 전달될 수 있는 경우, 서비스 메서드 시작 시 `CryptoColumnUtility.decryptEntity(entity)`를 선행 호출하여 데이터를 평문화한 뒤 업데이트를 진행한다.

## Verification

- `EncryptionContext.java` 복호화 폴백 수정 후 `cmos-frame`의 `framework-iia` Maven 컴파일 성공.
- `UserSave_Cryto.java`에 `decryptEntity` 선호출 적용 후 `busan_\service` Maven 컴파일 성공 (`BUILD SUCCESS`).
