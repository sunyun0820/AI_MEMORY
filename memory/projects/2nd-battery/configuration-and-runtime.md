---
id: MEM-20260909-2nd-battery-configuration-and-runtime
type: project
scope: project
project: 2nd-battery
domain: configuration-runtime
tags: [cmos, java, maven, deployment, mapper-provider, ui]
status: active
confidence: medium
created: 2026-09-09
updated: 2026-09-10
last_seen: 2026-09-09
occurrences: 1
source_agent: codex
---

# 2nd-battery 기동·패키징·설정과 웹 매핑 경계

## Core Knowledge / Applicability

2026-09-09 조사본은 `web-ui`의 `WebServer.main → Factory.initialize(args)`로 기동하며 별도의 프로젝트 main 업무 초기화는 없었다. 실행 폴더의 classpath와 외부 config/wwwroot/libs 배치가 함께 맞아야 한다.

아래 설정은 해당 시점의 정적 관찰이다. 파일의 존재·샘플 값은 실행 활성화나 운영 적합성의 증거가 아니다. 경로 약칭과 상세 위치는 [탐색 지도](source-navigation-map.md)를 참조한다.

## 실행 설정

| 파일 / 위치 | 기록된 연결 | 진단 경계 |
|---|---|---|
| `B-WEB/WebServer.java`, `B-RES/start.bat`·`start.sh` | Factory 기동, 작업 디렉터리 기준 classpath `./;./libs/*;./*`(Linux 구분자는 `:`) | 실행 위치와 외부 파일 배치를 확인 |
| `B-RES/config/cmos.json` | system/node, Dispatcher/Processor, daemonFactoryInitialize=true, dev=true | dev를 운영 기본으로 복제하지 않음 |
| `B-RES/config/web.json` | MesWebDispatcher, filters, mappings, port/resourceBase, uploadPath, multipart, cache | 실제 URL별 실행 경로를 확인 |
| `B-RES/config/mybatis.xml` | cmos-dev 환경, Hikari, STATEMENT cache scope, BATCH executor, timeout | 접속정보는 메모리·산출물에 복사하지 않음 |
| `block.json`, `kafka.json`, `scheduler.json` | block 예시는 전체 주석, kafka/scheduler는 주석 외 활성 key 없음 | override·브로커·스케줄러 가동 증거가 아님 |

## Maven 단계와 배포

- web-ui의 dependency copy는 **package** 단계에서 libs를 만든다. config/wwwroot/start script 등의 외부 resource copy는 **install** 단계다.
- web-ui JAR은 config/wwwroot/webapp·스크립트 등을 제외하므로 package 결과만 완전한 실행 배치로 보지 않는다.
- web-ui POM의 install-file은 `wwwroot/WEB-INF/lib/oraclepki.jar`를 `com.oracle.database.jdbc:ojdbc11:23.5.0.24.07` 좌표에 설치하도록 기록돼 있다. 파일과 좌표의 의도 확인 없이 이 설정을 재사용하지 않는다. install은 로컬 Maven 저장소도 변경한다.
- web-ui surefire는 skip=true였다. main 소스의 `test/Tester*`는 자동 회귀테스트 통과 증거가 아니며 Factory/DB를 사용할 수 있다.
- core/child의 3.5.2·Java17과 services/web-ui의 3.5.1·Java11 불일치, parent/reactor 구조는 [모듈·artifact 경계](project-architecture.md)에 둔다.

## 활성 SQL provider

mapper 보관 위치 `sql-back`과 기본 로더의 `sql/{dbms}`는 다르다. web-ui의 sql에는 `.gitkeep`만 있었고 cmos.json에는 prefix override가 없었다. SQL을 바꿔도 결과가 그대로라면 classpath·배포 리소스·dependency JAR의 mapper·prefix override·namespace/id부터 확인한다. 상세 정적 근거와 중복 ID 사례는 [영속·SQL 계약](persistence-and-query-patterns.md)을 따른다.

## 웹 매핑

- web.json에는 `/login→LoginController`, `/favorite→FavoriteController`, `/logusermenu→LogUsermenuController`, 비밀번호 변경/초기화, `/ssoLogin→SsoLoginController`가 있었다.
- 업/다운로드는 webMapping의 **UploadController/DownloadController** 이름으로 지정됐다. 로컬 `WebUploadController`, `MesUploadController`의 존재만으로 `/upload`가 이들을 실행한다고 단정하지 않는다.
- servletMapping의 업/다운로드 항목은 주석이었다. `/custom`은 `com.thirautech.cmos.web.custom.ClassNameMethodController#execute`를 지정했지만 조사본의 로컬 클래스와 연결되지 않았다. 클래스의 존재와 매핑, 의존 JAR 공급 여부를 따로 확인한다.
- 프로젝트 CORS와 MES AccessWebFilter/SecurityWebFilter가 연결된다. 빈 allow 배열의 의미는 filter 계약에 따르며, 토큰·Site/IP·command/SQL 검사를 하나의 보장으로 합치지 않는다. 구체 경계는 [웹·연동 계약](integration-and-web-boundaries.md)을 참조한다.

## UI 배포물과 개발 원본

조사한 web-ui는 Maven 호스트로, Vue 개발용 package.json과 src/pages 트리가 없고 wwwroot/assets에 해시 JS/source map이 있었다. `sourcesContent`의 `PM_CL_002.vue:LotProcess`, `BOM.vue:paramData2Helper`로 요청 계약을 관찰했지만 이를 이 checkout에서 수정·재빌드 가능한 Vue 개발 원본으로 취급하지 않는다. 정확한 map 파일은 [탐색 지도](source-navigation-map.md)에 둔다.

## Evidence

2026-09-09 `.scratch/knowledge-map-review/configuration-and-runtime.md`, POM·대표 호출의 정적 확인 기록에 근거한다. 실제 기동·Maven 실행·DB/브로커·HTTP·운영 설정 적합성을 검증했다는 뜻은 아니다.
