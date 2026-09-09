---
id: MEM-20260909-2nd-battery-integration-and-web-boundaries
type: project
scope: project
project: 2nd-battery
domain: integration-web
tags: [cmos, eis, mcs, kafka, upload, authentication, transaction]
status: active
confidence: medium
created: 2026-09-09
updated: 2026-09-09
last_seen: 2026-09-09
occurrences: 1
source_agent: codex
---

# 2nd-battery · Integration & Web Boundaries

목적: 외부 입력/응답과 DB transaction의 경계를 표본으로 보존한다. A=고유 protocol/업무, B=적용 조건이 있는 패턴. 현재 외부 요청/발송/파일 업로드 테스트는 실행하지 않았다.

## EIS 보고 Rule [A payload / B 어댑터 구조]

[LotStartReport](<E:/0.Project/mes-package/2nd-battery/services/src/main/java/com/thirautech/cmos/mes/packages/business/common/eis/LotStartReport.java:53>)는 Equipment header를 읽고 SITEID를 DbContext에서 설정한다. CARRIERLIST/LOTLIST 자식에 SITEID/EQUIPMENTID와 BATCHID/RECIPEID/SENDTIME을 넣는다. reply APPLICATIONID를 MES로 바꾸고 WEBDATA를 echo하며 Kafka message key에 COMMAND-TID를 설정한다.

[EISManager · common/eis](<E:/0.Project/mes-package/2nd-battery/core/common-services/src/main/java/com/thirautech/cmos/mes/packages/service/common/eis/EISManager.java:808>)는 CARRIERLIST가 있으면 Carrier에 연결된 Lot을 조회해 전달 LOTLIST를 대체한다. 이어서 common PRODUCTIONLotManager.processTrackInLotByEIS를 호출한다. UI의 processTrackInLot 경로와 입력/분기가 같다고 가정하면 안 된다.

**재사용:** 통신 payload 정리와 내부 업무 진입을 나누는 방식. **복사 제한:** carrier 우선순위, SITEID 공급원, reply command/application, message key, 장비 protocol 필드. key가 설정되었다는 이유만으로 멱등성/중복 처리가 구현되었다고 주장하지 않는다.

## MCS 전송/우회 [A]

[TransportJobRequest](<E:/0.Project/mes-package/2nd-battery/services/src/main/java/com/thirautech/cmos/mes/packages/business/electrode/mcs/TransportJobRequest.java:47>)는 EQPID/UNITID/CARRIERTYPE/CARRIEREMPTYSTATE/SENDTIME을 확인하고 IMCSManager.requestCarrierTransportJob으로 넘긴다. [MCSManager · electrode/mcs](<E:/0.Project/mes-package/2nd-battery/core/electrode-services/src/main/java/com/thirautech/cmos/mes/packages/service/electrode/mcs/MCSManager.java:1921>)는 reply MessageData의 APPLICATIONID가 EIS이면 MCS 우회 payload를 만들고 MCS로 전송한 다음 EIS용 payload를 다시 만들어 EIS로 전송한다. 다른 분기에는 REELSHAFT 등 CarrierType별 처리가 있다.

호출은 Manager process 중의 `getDbContext().sendKafka(...)`다. 인접 [DbContext](<E:/0.Project/cmos-frame/core/src/main/java/com/thirautech/cmos/mes/core/common/business/DbContext.java:300>)는 ConnectorFactory의 sender.send로 직접 연결한다. PROJECT에 after-commit outbox를 붙인 표본으로 해석할 근거는 없다. Kafka publish와 DB commit의 원자성, 재시도/중복/응답 확인은 별도 검증 대상이다.

현재 [kafka.json](<E:/0.Project/mes-package/2nd-battery/web-ui/src/main/resources/config/kafka.json:1>)는 주석을 제외하면 비어 있다. 전송 코드가 존재하지만 해당 checkout 설정으로 MCS/EIS target이 실행 가능하다는 증거는 없다. target명·topic·소비자 설정을 다른 프로젝트로 일반화하지 않는다.

[ConnectRepository (sample)](<E:/0.Project/mes-package/2nd-battery/services/src/main/java/com/thirautech/cmos/mes/packages/sample/connector/ConnectRepository.java:44>)는 connector API 입문용 sample이다. 실패 응답을 예외로 올리지 않고 기본 응답 객체를 반환하는 코드이므로 생산 integration error handling 표준으로 복사하면 안 된다. 전체 메시지 logging 방식 역시 외부 요청에 그대로 적용하지 않는다.

## 파일 + DB 저장 [B 패턴, 실행 연결 조건부]

[MesUploadController](<E:/0.Project/mes-package/2nd-battery/web-ui/src/main/java/com/thirautech/cmos/web/api/MesUploadController.java:17>) → [BaseHttpController](<E:/0.Project/mes-package/2nd-battery/web-ui/src/main/java/com/thirautech/cmos/web/api/BaseHttpController.java:35>) uploadFiles → 실제 파일 → MES-Core AttachmentManager.createAttachment → DATADIC.UPLOAD.

- **좋은 표본 이유:** HTTP 파일 파라미터와 C-MOS 업무 Entity 연결, 파일 목록 처리, Attachment 메타데이터 저장 실패 시 파일 정리 시도가 드러난다.
- **사용 Core 계약:** HttpData, Factory.getEntity(Attachment), @AutoInjection AttachmentManager, setDatadic.
- **재사용:** filesystem 부수효과와 DB 저장을 한 흐름으로 추적하고 보상 처리를 검토하는 방식.
- **복사 제한:** RELATIONTYPE/RELATIONID, uploadPath, 반환 필드, 파일명/경로 정책. 파일 생성 자체와 최종 DB commit은 다른 완료 지점이다.
- **검증 한계:** catch 안에서 list가 확보된 경우 deleteFiles를 호출한다. 실패한 uploadFiles의 부분 파일, 이후 Dispatcher commit 실패, cleanup 자체 실패까지 완전 보상된다고 증명하지 않았다.
- **활성성:** 현재 `/upload`는 `UploadController`로 매핑된다. 로컬 MesUploadController의 존재를 실제 endpoint 연결 증거로 쓰지 않는다. [web.json](<E:/0.Project/mes-package/2nd-battery/web-ui/src/main/resources/config/web.json:29>)

구형 로컬 [WebUploadController](<E:/0.Project/mes-package/2nd-battery/web-ui/src/main/java/com/thirautech/cmos/web/api/WebUploadController.java:11>)는 super.process()에서 Servlet/request/response를 받아 WebUtil을 사용한다. 둘을 하나의 공통 Base 계약처럼 섞지 않는다. 새 파일 기능은 매핑에서 출발해 실제 선택된 base/handler를 확인한다.

## 로그인 실패 저장 [A]

[LoginController](<E:/0.Project/mes-package/2nd-battery/web-ui/src/main/java/com/thirautech/cmos/web/api/LoginController.java:33>)의 실제 순서: 입력 검증/단방향 암호화 → Site의 Loginpolicy → retry row와 잠금 잔여시간 → LoginImplement.userLogin → 실패면 Context.commit을 시도하고 예외, 성공이면 사용자 정보와 JwtUtil 토큰을 DATADIC.auth에 넣는다.

이는 기존 Framework lifecycle에 **실패 상태를 유지하기 위한 예외적인 commit**을 삽입한 코드다. [LoginController](<E:/0.Project/mes-package/2nd-battery/web-ui/src/main/java/com/thirautech/cmos/web/api/LoginController.java:74>)에서 commit 실패는 log 후 계속 예외 처리한다. “로그인 실패했으니 아무 것도 저장되지 않는다”도, “실패 횟수는 반드시 저장된다”도 현재 코드만으로 확정할 수 없다. transaction 문제를 분석할 때 이 파일을 우선 확인한다.

응답 사용자 정보의 민감 필드 제외 정책, token claim의 출처, LOGINLOCKMINUTES fallback과 계정 잠금 DB 상태는 인접 MES-Core 구현/실제 설정까지 확인해야 한다. 이번 작업에서는 로그인 시도나 token 생성/검증을 하지 않았다.

## 인증/권한과 CORS 구분 [A/B]

[CorsWebApiFilter](<E:/0.Project/mes-package/2nd-battery/web-ui/src/main/java/com/thirautech/cmos/web/api/filters/CorsWebApiFilter.java:14>)는 doStart에서 true를 반환하고 doEnd에서 요청 Origin을 응답 허용 Origin으로 반사하며 credentials=true를 설정한다. 이것은 현재 정책 관찰이며 다른 프로젝트의 보안 기준으로 재사용할 권장은 아니다.

인증/권한 진단은 [web.json](<E:/0.Project/mes-package/2nd-battery/web-ui/src/main/resources/config/web.json:29>) → [SecurityWebFilter](<E:/0.Project/mes-core/core/src/main/java/com/thirautech/cmos/mes/core/web/filter/SecurityWebFilter.java:1>) → LoginImplement/LoginpolicyImplement/그룹·메뉴 데이터 순으로 탐색한다. 토큰 인증, Site/IP 제한, command/SQL 제한, 화면 버튼 노출은 다른 계약이다. UI에서 버튼이 보이지 않는 것을 서버 command 차단과 동일시하지 않는다. 운영 접근 통제 효과는 DB/HTTP 테스트 없이 확정하지 않는다.

## Context

2026-09-09 작성된 2nd-battery Knowledge Map 검토 문서를 사용자 요청에 따라 프로젝트 메모리로 반영했다. 본문의 현재 상태, 확인 및 미실행 표현은 해당 검토일의 정적 조사 기록을 가리킨다. 저장 시 프로젝트 소스를 재분석하지 않았다.

## Verification

- 근거: [원본 검토 문서](<E:/0.Project/mes-package/2nd-battery/.scratch/knowledge-map-review/integration-and-web-boundaries.md:1>).
- 원본 verification.json은 문서 8개 및 링크 321회에 대한 문서 정적 검사 PASS를 기록한다. 이 결과는 기존 검토 기록이며 이번 저장에서 소스 검증을 재수행한 결과가 아니다.
- 본 메모리의 근거는 검토 문서다. 실제 의존 JAR, 배포 설정, DB, 서버, HTTP, 브로커, 파일 업로드 및 동시성 동작은 검증되지 않았다.
- source 및 line 링크는 검토 당시 탐색 단서다. 이후 변경 작업에서는 필요한 범위의 현재 코드와 비교한다. A는 프로젝트 전용, B는 조건부 재사용이며 전역 rule로 승격하지 않는다.
