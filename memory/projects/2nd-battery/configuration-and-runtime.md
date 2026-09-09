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
updated: 2026-09-09
last_seen: 2026-09-09
occurrences: 1
source_agent: codex
---

# 2nd-battery · Configuration & Runtime

분류 A: 이 checkout의 실행/배포 연결 지식. 현재 서버 기동·Maven 실행·DB/브로커 접속은 수행하지 않았다. Framework 내부 lifecycle은 [Framework Memory · runtime-lifecycle.md](<E:/AI/AI_MEMORY/memory/projects/cmos-frame/runtime-lifecycle.md:1>) 참조.

## 시작점과 실제 배포 묶음

[WebServer](<E:/0.Project/mes-package/2nd-battery/web-ui/src/main/java/com/thirautech/cmos/web/WebServer.java:5>) → Factory.initialize(args). [start.bat](<E:/0.Project/mes-package/2nd-battery/web-ui/src/main/resources/start.bat:1>)는 현재 작업 디렉터리 기준 `./;./libs/*;./*` classpath를 사용하고 Linux start.sh는 구분자가 `:`다. 별도의 프로젝트 main 업무 초기화는 없다. 실행 폴더와 config/wwwroot/libs 배치가 관련된다.

| 구성 | 현재 소스에서 확인한 역할 | 수정/진단 시 주의 |
|---|---|---|
| web-ui POM | plugin-web-starter와 services 의존 | 서버는 자체 Factory/starter 경로 |
| cmos.json | system/node, Dispatcher/Processor, daemonFactoryInitialize=true, dev=true | dev 값을 운영 배포 기본으로 복제하지 않음 |
| web.json | port/resourceBase, MesWebDispatcher, filters, mappings, uploadPath, multipart, cache | URL이 어떤 실행 경로인지 먼저 확인 |
| mybatis.xml | cmos-dev 환경, Hikari datasource, STATEMENT cache scope, BATCH executor, timeout 등 | 접속정보를 산출물/메모리에 복사하지 않음 |
| block.json | Block/proxy 설정 예시 | 본문이 전체 주석. 활성 override 설정으로 인용 금지 |
| kafka.json / scheduler.json | 샘플 설정 파일 | 주석을 제외하면 활성 key가 없음. 기능 가동 증거가 아님 |

[cmos.json](<E:/0.Project/mes-package/2nd-battery/web-ui/src/main/resources/config/cmos.json:1>) [web.json](<E:/0.Project/mes-package/2nd-battery/web-ui/src/main/resources/config/web.json:29>) [mybatis.xml](<E:/0.Project/mes-package/2nd-battery/web-ui/src/main/resources/config/mybatis.xml:1>) [block.json](<E:/0.Project/mes-package/2nd-battery/web-ui/src/main/resources/config/block.json:1>)

## POM이 말하는 실제 단계

- core/child는 3.5.2 + Java17, services/web-ui는 3.5.1 + Java11 설정. 상위 root 통합 reactor가 없다. [project-architecture.md](<E:/AI/AI_MEMORY/memory/projects/2nd-battery/project-architecture.md:1>)
- web-ui dependency copy는 **package** 단계에 libs를 만든다.
- web-ui의 config/wwwroot/start script 등 외부 resource copy는 **install** 단계다. package만 실행하면 완성 실행 배치와 같다고 가정하지 않는다.
- web-ui JAR은 config/wwwroot/webapp와 스크립트 등을 제외한다. start.bat는 이 외부 파일들이 실행 위치에 있다는 전제로 읽어야 한다.
- web-ui POM의 install-file은 `wwwroot/WEB-INF/lib/oraclepki.jar`를 `com.oracle.database.jdbc:ojdbc11:23.5.0.24.07` 좌표로 설치하도록 되어 있다. Maven 로컬 저장소를 바꾸는 실행이므로 단순 진단 목적으로 install을 자동 실행하지 않았다. 좌표 의도를 별도로 검토할 가치가 있다.
- web-ui surefire는 skip=true. `src/main/java/.../test/Tester*`는 자동 회귀테스트 성공 증거가 아니다. 일부는 Factory/DB를 사용할 수 있어 실행하지 않았다.

근거 [web-ui/pom.xml](<E:/0.Project/mes-package/2nd-battery/web-ui/pom.xml:1>), [core/common-services/pom.xml](<E:/0.Project/mes-package/2nd-battery/core/common-services/pom.xml:1>), [services/pom.xml](<E:/0.Project/mes-package/2nd-battery/services/pom.xml:1>). 이번 분석은 컴파일 가능성/의존성 해석 성공을 보장하지 않는다.

## SQL runtime provider를 먼저 확정한다

프로젝트 mapper 보관본은 sql-back이고 기본 로더는 sql/{dbms}다. 현재 web-ui/sql은 .gitkeep만 있다. 현재 cmos.json에 prefix override는 없다. 인접 Framework의 Configuration/DataBaseContext/Environment와 대조한 결과이며, 배포 CLI 인자/실제 3.5.1 JAR의 provider는 미확인이다. [persistence-and-query-patterns.md](<E:/AI/AI_MEMORY/memory/projects/2nd-battery/persistence-and-query-patterns.md:1>)

이 상태에서 “SQL XML을 고쳤는데 실행 결과가 그대로”라는 질문이 오면 파일 내용보다 **실행 classpath·배포 폴더·dependency JAR의 mapper 리소스·prefix override·동일 namespace/id**부터 확인한다. sql-back을 활성화하는 변경은 검토 없는 해결책이 아니다.

## 웹 매핑은 클래스 존재와 별개다

현재 web.json에는 `/login→LoginController`, `/favorite→FavoriteController`, `/logusermenu→LogUsermenuController`, 비밀번호 변경/초기화, `/ssoLogin→SsoLoginController`가 있다.

파일 업/다운로드는 webMapping의 **UploadController/DownloadController** 이름으로 지정되어 있다. 이 프로젝트에는 `WebUploadController`, `MesUploadController`도 있지만 이름이 유사하다는 이유로 `/upload`의 실행 대상으로 단정하면 안 된다. `/custom` 설정이 가리키는 `com.thirautech.cmos.web.custom.ClassNameMethodController#execute`는 로컬 소스에서 발견되지 않았다. 의존 JAR/비활성 예시 여부를 추가 확인해야 한다.

`servletMapping`의 업로드/다운로드 항목은 주석이다. 파일이 있다고 현재 사용되는 것도, 매핑이 있다고 local class가 있는 것도 아니다. 이 교차 검증을 신규 endpoint 추가 시 재사용한다. [web.json](<E:/0.Project/mes-package/2nd-battery/web-ui/src/main/resources/config/web.json:29>) [MesUploadController](<E:/0.Project/mes-package/2nd-battery/web-ui/src/main/java/com/thirautech/cmos/web/api/MesUploadController.java:17>) [WebUploadController](<E:/0.Project/mes-package/2nd-battery/web-ui/src/main/java/com/thirautech/cmos/web/api/WebUploadController.java:11>)

## UI 소스 경계

현재 `web-ui`는 Maven 호스트이며 Vue 개발용 package.json 및 원본 src/pages 트리가 없다. wwwroot/assets는 해시된 배포 JS와 source map 191개를 포함한다. source map의 sourcesContent에서 Vue 화면의 command/payload를 복원해 확인할 수 있다. 이는 현재 checkout에서 수정·재빌드 가능한 원본 프로젝트가 있다는 뜻이 아니다.

표본: [PM_CL_002-NJaZFJa6.js.map](<E:/0.Project/mes-package/2nd-battery/web-ui/src/main/resources/wwwroot/assets/PM_CL_002-NJaZFJa6.js.map:1>) 내부 `PM_CL_002.vue:LotProcess`, [BOM-aAsZ1en0.js.map](<E:/0.Project/mes-package/2nd-battery/web-ui/src/main/resources/wwwroot/assets/BOM-aAsZ1en0.js.map:1>) 내부 `BOM.vue:paramData2Helper`. 수정 작업에서는 실제 UI 개발 저장소와 배포본 일치 여부를 먼저 확인한다. 해시 JS를 정상 Vue 구현 위치로 기록하지 않는다.

## 보안 연결 요약

프로젝트 CORS + MES AccessWebFilter + MES SecurityWebFilter의 연결이 web.json에 있다. URL token 확인 범위와 Site/IP/Command/SQL allow 설정을 함께 본다. 배열이 비어 있다는 사실만으로 허용/차단 의미를 결정하지 않는다. filter의 구현과 운영 config/사용자 그룹 데이터를 확인해야 한다. [CorsWebApiFilter](<E:/0.Project/mes-package/2nd-battery/web-ui/src/main/java/com/thirautech/cmos/web/api/filters/CorsWebApiFilter.java:14>) [SecurityWebFilter](<E:/0.Project/mes-core/core/src/main/java/com/thirautech/cmos/mes/core/web/filter/SecurityWebFilter.java:1>)

현재 dev 설정·URL 노출·사용자 식별자·인증 데이터가 안전한 운영 구성임은 검증하지 않았다. 실제 credentials/endpoint/키 값은 근거 검토 문서에 싣지 않았다.

## Context

2026-09-09 작성된 2nd-battery Knowledge Map 검토 문서를 사용자 요청에 따라 프로젝트 메모리로 반영했다. 본문의 현재 상태, 확인 및 미실행 표현은 해당 검토일의 정적 조사 기록을 가리킨다. 저장 시 프로젝트 소스를 재분석하지 않았다.

## Verification

- 근거: [원본 검토 문서](<E:/0.Project/mes-package/2nd-battery/.scratch/knowledge-map-review/configuration-and-runtime.md:1>).
- 원본 verification.json은 문서 8개 및 링크 321회에 대한 문서 정적 검사 PASS를 기록한다. 이 결과는 기존 검토 기록이며 이번 저장에서 소스 검증을 재수행한 결과가 아니다.
- 본 메모리의 근거는 검토 문서다. 실제 의존 JAR, 배포 설정, DB, 서버, HTTP, 브로커, 파일 업로드 및 동시성 동작은 검증되지 않았다.
- source 및 line 링크는 검토 당시 탐색 단서다. 이후 변경 작업에서는 필요한 범위의 현재 코드와 비교한다. A는 프로젝트 전용, B는 조건부 재사용이며 전역 rule로 승격하지 않는다.
