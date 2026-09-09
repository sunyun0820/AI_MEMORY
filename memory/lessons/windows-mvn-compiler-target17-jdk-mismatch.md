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
updated: 2026-09-09
last_seen: 2026-09-09
occurrences: 2
source_agent: antigravity
---

# Maven 타깃 버전 오류는 실제 Maven·컴파일러 JDK를 확인할 것

## Core Knowledge

`invalid target release: 17`은 사용 중인 컴파일러가 요청한 타깃을 지원하지 않을 때 발생할 수 있다. `java -version`이 최신이어도 Maven이 JAVA_HOME의 다른 JDK를 사용하면 빌드는 실패한다.

## Applicability / Correct Approach

Windows의 여러 JDK 설치 환경에서 Maven 타깃 오류가 나면 같은 실행 세션의 `mvn -v`, `java -version`, `JAVA_HOME`을 비교한다. POM의 source/target/release와 toolchains·fork/executable 설정도 확인한다. toolchain이나 별도 javac을 쓰면 Maven 실행 JVM과 컴파일러 JDK가 다를 수 있다.

프로젝트가 지원하는 설치된 JDK를 확인한 뒤 해당 세션의 JAVA_HOME을 조정하고 `mvn -v`로 재확인한다. 과거 설치 경로를 복사하거나 전역 환경을 불필요하게 바꾸지 않는다. 컴파일 성공을 테스트 통과로 보고하지 않는다.

## Verification

원본에서 PATH는 Java 21, JAVA_HOME은 Java 8이어서 Java 17 타깃 빌드가 실패했고, 해당 세션을 프로젝트가 지원하는 설치 JDK 21로 바꾼 뒤 cmos-frame·busan service가 컴파일됐다고 기록했다. 2026-09-09 cmos-starter의 plugin-jetty·plugin-web-starter에서도 같은 원인/해결을 추가 확인한 기록이 있다.

occurrences=2는 이 두 기록을 유지한 값이다. 반복 정제·병합을 새로운 발생으로 세지 않으며, 특정 과거 설치 경로를 현재 환경의 정답으로 보존하지 않는다. 이번 Refine에서 JDK 설치·Maven 컴파일·테스트는 재실행하지 않았다.
