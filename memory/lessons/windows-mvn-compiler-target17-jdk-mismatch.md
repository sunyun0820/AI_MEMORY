---
id: MEM-20260908-154902
type: lesson
scope: global
project: ""
domain: build
tags: [maven, java, build, windows, jdk17, jdk21, environment]
status: active
confidence: high
created: 2026-09-08
updated: 2026-09-08
last_seen: 2026-09-08
occurrences: 1
source_agent: antigravity
---

# Windows 환경 Maven 컴파일 시 JAVA_HOME Java 8 지정으로 인한 Java 17 타깃 빌드 실패

## Context

Windows 개발 환경에서 `cmos-frame` 및 `busan_\service` 프로젝트를 Maven(`mvn compile`)으로 빌드할 때 발생한 컴파일러 타깃 버전 불일치 문제이다.

## Symptom

`mvn compile` 실행 시 아래와 같은 오류와 함께 빌드가 실패함:
`Fatal error compiling: invalid target release: 17 -> [Help 1]`

## Root Cause

`java -version` 실행 시 시스템 기본 런타임은 OpenJDK 21 (`Temurin-21.0.4+7`)로 인식되지만, 환경 변수 `$env:JAVA_HOME`이 `C:\Program Files\Java\jdk1.8.0_202` (Java 8)로 고정되어 있어 `maven-compiler-plugin`이 Java 8 `javac`을 호출하여 Java 17 소스/타깃 옵션을 처리하지 못함.

## Correct Approach

Maven 빌드 명령 실행 전 현재 세션의 `JAVA_HOME`을 설치된 JDK 21 경로로 지정한 후 빌드를 수행한다:
```powershell
$env:JAVA_HOME="C:\Program Files\Eclipse Adoptium\jdk-21.0.4.7-hotspot"; mvn compile -DskipTests
```

## Reusable Rule

Windows 환경에서 Maven 빌드 시 `invalid target release: 17` 에러가 발생하면, `$env:JAVA_HOME`이 레거시 Java 8을 가리키고 있는지 확인하고 JDK 17/21 경로(`Eclipse Adoptium` 등)로 명시적으로 지정하여 실행한다.

## Verification

`$env:JAVA_HOME="C:\Program Files\Eclipse Adoptium\jdk-21.0.4.7-hotspot"` 설정 후 `cmos-frame` 및 `busan_\service`에서 `mvn compile` 성공 (`BUILD SUCCESS`).
