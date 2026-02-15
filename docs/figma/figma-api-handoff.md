# Figma API Handoff (Scenario A)

## 목적
Figma 프로토타입의 모든 화면 액션을 API `operationId`와 1:1 매핑하기 위한 문서.

## 공통
- Base URL: `http://localhost:8080/api/v1`
- Header: `Authorization: Bearer <token>`
- Optional Header: `X-Trace-Id`, `Idempotency-Key`
- 원본 계약: `docs/contracts/openapi-civil-complaint.yaml`

## 화면 매핑
1. 시작 화면 (민원 생성)
- Operation: `createCase`
- Endpoint: `POST /cases`
- Request example: `frontend/mocks/requests/create-case.json`
- Response example: `frontend/mocks/responses/create-case-response.json`
- Error states: validation error, unauthorized

2. 대화형 접수 화면
- Operation: `appendIntakeMessage`
- Endpoint: `POST /cases/{caseId}/intake/messages`
- Request example: `frontend/mocks/requests/intake-message.json`
- Response example: `frontend/mocks/responses/intake-update-response.json`
- Error states: case not found, validation error

3. 경로 추천 화면
- Operation: `decomposeCase`, `recommendRoute`
- Endpoint: `POST /cases/{caseId}/decomposition`, `POST /cases/{caseId}/routing/recommendation`
- Response example: `frontend/mocks/responses/routing-recommendation-response.json`
- Error states: state conflict

4. 경로 확정 화면
- Operation: `confirmRouteDecision`
- Endpoint: `POST /cases/{caseId}/routing/decision`
- Request example: `frontend/mocks/requests/route-decision.json`
- Error states: route option not found, state conflict

5. 증거 업로드 화면
- Operation: `registerEvidence`, `getEvidenceChecklist`
- Endpoint: `POST /cases/{caseId}/evidence`, `GET /cases/{caseId}/evidence/checklist`
- Request examples:
  - `frontend/mocks/requests/register-evidence-audio.json`
  - `frontend/mocks/requests/register-evidence-log.json`
- Response examples:
  - `frontend/mocks/responses/evidence-checklist-insufficient.json`
  - `frontend/mocks/responses/evidence-checklist-sufficient.json`

6. 제출 확인 화면
- Operation: `submitCase`
- Endpoint: `POST /cases/{caseId}/submission`
- Optional Header: `Idempotency-Key` (재시도 시 동일 키 사용)
- Request example: `frontend/mocks/requests/submit-case.json`
- Response example: `frontend/mocks/responses/submission-response.json`
- 참고: 제출 직후 `submissionStatus=QUEUED`가 반환되며, 완료 상태는 `getCase`/`getTimeline` 폴링으로 반영

7. 진행상태 타임라인 화면
- Operation: `getTimeline`
- Endpoint: `GET /cases/{caseId}/timeline`
- Response example: `frontend/mocks/responses/timeline-response.json`

## Figma 컴포넌트 상태 가이드
- 버튼 상태: default/loading/disabled/error
- 화면 상태: empty/loading/success/error
- 에러 메시지 규약: `code`별 사용자 친화 문구 매핑
- 상태 배지: `CaseStatus` enum과 1:1 대응
