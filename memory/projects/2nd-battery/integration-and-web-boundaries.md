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
updated: 2026-09-10
last_seen: 2026-09-09
occurrences: 1
source_agent: codex
---

# 2nd-battery EIS·MCS·파일·로그인의 완료 경계

## Core Knowledge / Applicability

2026-09-09 조사본에서 EIS/MCS, 파일 저장, 로그인 실패는 일반 요청 DB transaction과 서로 다른 완료 지점을 가진다. 프로젝트 프로토콜과 예외적 commit을 그대로 다른 서비스의 표준으로 복사하지 않는다. 파일·메서드 위치는 [탐색 지도](source-navigation-map.md)를 따른다.

## EIS 입력·응답

`LotStartReport`는 Equipment header를 읽고 SITEID를 DbContext에서 설정한다. CARRIERLIST/LOTLIST에 SITEID/EQUIPMENTID와 BATCHID/RECIPEID/SENDTIME을 넣고 reply APPLICATIONID=MES, WEBDATA echo, Kafka key=COMMAND-TID를 설정한다.

`EISManager`는 CARRIERLIST가 있으면 Carrier에 연결된 Lot을 조회해 전달 LOTLIST를 대체하고 common `PRODUCTIONLotManager.processTrackInLotByEIS`로 넘긴다. UI processTrackInLot와 입력·분기가 같지 않다. carrier 우선순위·SITEID 공급원·reply/key는 이 프로토콜의 계약이며, message key만으로 멱등성 구현을 주장하지 않는다.

## MCS 전송

`TransportJobRequest`는 EQPID/UNITID/CARRIERTYPE/CARRIEREMPTYSTATE/SENDTIME을 확인해 `IMCSManager.requestCarrierTransportJob`으로 넘긴다. reply APPLICATIONID=EIS 분기에서 MCSManager는 MCS 우회 payload를 전송한 뒤 EIS용 payload를 다시 만들어 전송한다. 다른 분기에는 REELSHAFT 등 CarrierType별 처리가 있다.

Manager 실행 중 `DbContext.sendKafka`를 호출하며 인접 DbContext는 ConnectorFactory의 `sender.send`로 연결됐다. after-commit outbox나 Kafka publish와 DB commit의 원자성·재시도·중복 방지 증거로 해석하지 않는다. 당시 kafka.json은 주석 외 활성 key가 없어 전송 코드의 존재만으로 target/topic 구성이 완성됐다고 판단할 수 없다.

sample `ConnectRepository`는 실패 응답을 예외로 올리지 않고 기본 응답 객체를 반환했다. 생산 error handling이나 전체 메시지 logging의 표준으로 복사하지 않는다.

## 파일과 Attachment

`MesUploadController → BaseHttpController.uploadFiles → 파일 생성 → AttachmentManager.createAttachment → DATADIC.UPLOAD` 순서다. HttpData, Factory.getEntity(Attachment), @AutoInjection AttachmentManager를 이용하는 로컬 표본이다.

catch에서 파일 목록을 확보한 경우 deleteFiles로 정리를 시도한다. uploadFiles의 부분 파일, 이후 Dispatcher commit 실패, cleanup 실패까지 완전 보상된다는 보장은 없다. RELATIONTYPE/RELATIONID·uploadPath·파일명/경로·반환 필드는 프로젝트 계약이다.

web.json의 `/upload`는 **UploadController** 이름으로 매핑됐으므로 로컬 MesUploadController의 존재는 endpoint 연결 증거가 아니다. 구형 WebUploadController는 super.process에서 Servlet/request/response를 받아 WebUtil을 사용하므로 두 base 계약을 섞지 않는다.

## 로그인 실패 commit

`LoginController`: 입력 검증·단방향 암호화 → Site Loginpolicy → retry row·잠금 잔여시간 → LoginImplement.userLogin → 실패 시 Context.commit 시도 후 예외 / 성공 시 사용자 정보·JwtUtil 토큰을 DATADIC.auth에 설정.

실패 상태를 유지하려는 예외적인 commit이며 commit 실패는 로그 후 예외 처리로 이어진다. 로그인 실패=아무 저장 없음, 실패 횟수=반드시 저장됨 중 어느 쪽도 이 흐름만으로 확정하지 않는다. 민감 사용자 필드 제외, claim 출처, LOGINLOCKMINUTES fallback, 잠금 상태는 별도 인증 계약이다.

## CORS·인증·권한

CorsWebApiFilter는 doStart=true, doEnd에서 요청 Origin을 허용 Origin으로 반사하고 credentials=true를 설정했다. 해당 코드 관찰이며 보안 권장 구성으로 일반화하지 않는다.

인증 탐색은 web.json → SecurityWebFilter → LoginImplement/LoginpolicyImplement·그룹/메뉴 계약으로 이어진다. 토큰 인증, Site/IP, command/SQL 권한, 화면 버튼 노출은 서로 다르다. 숨겨진 버튼은 서버 command 차단의 증거가 아니다.

## Evidence / Transfer

2026-09-09 `.scratch/knowledge-map-review/integration-and-web-boundaries.md`의 정적 호출 관찰에 근거한다. 실제 DB·송수신·파일 보상·로그인·token 검증 결과는 아니다.

프로토콜과 구현 선택을 제거해도 남는 원칙은 [요청 실패와 부수효과의 완료 경계](../../lessons/request-failure-does-not-rollback-all-effects.md)에 분리한다. fallback 반환값의 정보 소실은 [별도 교훈](../../lessons/fallback-result-is-not-success-proof.md)을 참조한다.
