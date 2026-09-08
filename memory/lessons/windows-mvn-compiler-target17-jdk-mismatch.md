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

# Maven 타깃 버전 오류는 실제 Maven·컴파일러 JDK를 확인할 것

## Core Knowledge

`invalid target release: 17`은 사용 중인 컴파일러가 요청한 타깃을 지원하지 않을 때 발생할 수 있다. `java -version`이 최신이어도 Maven이 JAVA_HOME의 다른 JDK를 사용하면 빌드는 실패한다.

## Applicability / Correct Approach

Windows의 여러 JDK 설치 환경에서 Maven 타깃 오류가 나면 같은 실행 세션의 `mvn -v`, `java -version`, `JAVA_HOME`을 비교한다. POM의 source/target/release와 toolchains·fork/executable 설정도 확인한다. toolchain이나 별도 javac을 쓰면 Maven 실행 JVM과 컴파일러 JDK가 다를 수 있다.

프로젝트가 지원하는 설치된 JDK를 확인한 뒤 해당 세션의 JAVA_HOME을 조정하고 `mvn -v`로 재확인한다. 과거 설치 경로를 복사하거나 전역 환경을 불필요하게 바꾸지 않는다. 컴파일 성공을 테스트 통과로 보고하지 않는다.

## Verification

원본 기록에서는 PATH의 Java가 21인데 JAVA_HOME은 Java 8이어서 Java 17 타깃 빌드가 실패했다. 세션 JAVA_HOME을 설치된 JDK 21로 바꾼 뒤 cmos-frame과 busan service 컴파일이 성공했다고 기록되어 있다. 이번 Refine에서는 현재 JDK 설치나 빌드를 재검증하지 않았으므로 특정 경로·버전을 현 환경의 정답으로 고정하지 않는다.
