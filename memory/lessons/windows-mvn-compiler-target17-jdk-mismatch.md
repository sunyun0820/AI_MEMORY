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

원본 기록에서는 PATH의 Java가 21인데 JAVA_HOME은 Java 8이어서 Java 17 타깃 빌드가 실패했다. 세션 JAVA_HOME을 설치된 JDK 21로 바꾼 뒤 `cmos-frame`, `busan_\service` 및 로컬에서 추가 확인한 `cmos-starter`(`plugin-jetty`, `plugin-web-starter`)의 `mvn compile` 성공(`BUILD SUCCESS`)이 기록되어 있다. 이번 Refine에서는 현재 JDK 설치나 빌드를 재검증하지 않았으므로 특정 경로·버전을 현 환경의 정답으로 고정하지 않는다.

### 과거 환경 및 추가 검증 기록

- 당시 PATH의 런타임은 OpenJDK 21 (`Temurin-21.0.4+7`)이었지만 JAVA_HOME은 `C:\Program Files\Java\jdk1.8.0_202`로 설정되어 있었다. 컴파일 오류는 `Fatal error compiling: invalid target release: 17 -> [Help 1]`였다.
- 해당 세션의 JAVA_HOME을 `C:\Program Files\Eclipse Adoptium\jdk-21.0.4.7-hotspot`으로 변경해 해결했다. 이 경로는 과거 환경의 증거이며 현재 설치 경로나 모든 프로젝트의 권장 JDK를 뜻하지 않는다.
- 2026-09-09 로컬 기록은 `cmos-starter`의 `plugin-jetty`, `plugin-web-starter`에도 같은 원인과 해결이 적용됐음을 추가한다. `occurrences: 2`는 이 기존 추가 기록을 보존한 값이며 병합을 새로운 장애 발생으로 세지 않는다.
- 이번 병합에서는 JDK 설치, 컴파일, 테스트를 재실행하지 않았다. 원격의 toolchain·별도 javac 진단 지침과 로컬의 추가 성공 사례를 함께 보존했다.
