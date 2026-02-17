# Scenario A Interface Spec (Frontend-Figma / Backend-Spring)

## 1) Goal
Define a stable API and state contract before UI implementation so:
- Figma screens map directly to backend endpoints.
- Spring Boot implementation can proceed without rework from UI changes.
- Frontend and backend can develop in parallel with mock data.

## 2) Scope (Phase 1 vertical slice)
Included flow:
1. Create case
2. Intake chat and slot extraction
3. Decompose + route recommendation
4. Route decision
5. Evidence registration + checklist
6. Submission trigger
7. Timeline tracking

Out of scope for this slice:
- Real institution API integrations (use mock worker)
- Advanced document generation templates
- Full admin console

## 3) Contract Artifacts
- OpenAPI: `docs/contracts/openapi-civil-complaint.yaml`
- Error model: section 6 below
- State machine: section 5 below

## 4) Global API Rules
- Base path: `/api/v1`
- Auth: `Authorization: Bearer <JWT>`
- Trace header: `X-Trace-Id` (optional, recommended)
- Idempotency: `Idempotency-Key` for create/submit style requests
- Time format: ISO-8601 UTC (`2026-02-15T09:30:00Z`)
- ID format: UUID for entity IDs

## 5) State Machine Contract
Allowed state transitions for scenario A:
- `RECEIVED -> CLASSIFIED`
- `CLASSIFIED -> ROUTE_CONFIRMED`
- `ROUTE_CONFIRMED -> EVIDENCE_COLLECTING`
- `EVIDENCE_COLLECTING -> FORMAL_SUBMISSION_READY`
- `FORMAL_SUBMISSION_READY -> INSTITUTION_PROCESSING`
- `INSTITUTION_PROCESSING -> SUPPLEMENT_REQUIRED`
- `SUPPLEMENT_REQUIRED -> INSTITUTION_PROCESSING`
- `INSTITUTION_PROCESSING -> COMPLETED`
- `COMPLETED -> CLOSED`

Exceptional states:
- `MEDIATION_IN_PROGRESS`, `MEDIATION_SUCCESS`, `MEDIATION_FAILED`

Backend must reject invalid transitions with `409 CASE_STATE_CONFLICT`.

## 6) Error Contract
Unified error payload:
```json
{
  "timestamp": "2026-02-15T09:30:00Z",
  "traceId": "f78f1b8a4d6e4f3b",
  "code": "CASE_STATE_CONFLICT",
  "message": "Cannot submit before route confirmation.",
  "details": ["currentState=CLASSIFIED", "requiredState=FORMAL_SUBMISSION_READY"]
}
```

Required error codes (minimum set):
- `VALIDATION_ERROR` (400)
- `UNAUTHORIZED` (401)
- `CASE_NOT_FOUND` (404)
- `CASE_STATE_CONFLICT` (409)
- `ROUTE_OPTION_NOT_FOUND` (404)
- `EVIDENCE_INSUFFICIENT` (409)
- `INSTITUTION_GATEWAY_ERROR` (502/503)

## 7) Figma Screen to API Mapping
1. Screen: Start Complaint
- `POST /api/v1/cases`
- Output: `caseId`, initial `status=RECEIVED`

2. Screen: Intake Chat
- `POST /api/v1/cases/{caseId}/intake/messages`
- Output: filled slots, risk signal, next follow-up question
- Optional UI hint: `followUpInterface` (`OPTIONS`/`DATE`) with `selectionMode` (`SINGLE`/`MULTIPLE`) and up to 4 options

3. Screen: Route Recommendation
- `POST /api/v1/cases/{caseId}/decomposition`
- `POST /api/v1/cases/{caseId}/routing/recommendation`
- Output: ranked routing options with reasons

4. Screen: Route Confirmation
- `POST /api/v1/cases/{caseId}/routing/decision`
- Output: case state update to `ROUTE_CONFIRMED`

5. Screen: Evidence Upload
- File upload to object storage (client flow)
- `POST /api/v1/cases/{caseId}/evidence` to register metadata
- `GET /api/v1/cases/{caseId}/evidence/checklist` for sufficiency

6. Screen: Submit
- `POST /api/v1/cases/{caseId}/submission`
- Output: `submissionId`, `submissionStatus`

7. Screen: Timeline
- `GET /api/v1/cases/{caseId}/timeline`
- Output: ordered events for status UI

## 8) Spring Boot Implementation Notes
Suggested packages:
- `com.example.complaint.api` (controllers)
- `com.example.complaint.application` (use-cases)
- `com.example.complaint.domain` (state machine, entities)
- `com.example.complaint.infrastructure` (db, storage, external connectors)

Implementation order:
1. Generate DTO/controller interfaces from OpenAPI
2. Implement in-memory or Postgres persistence for `Case`, `TimelineEvent`, `Evidence`
3. Implement state transition guard in domain service
4. Add mock submission worker for institution processing
5. Add integration tests for transition and error codes

## 9) Frontend-Figma Handoff Rules
- Every Figma screen must specify:
  - API endpoint(s)
  - request payload example
  - success and error response examples
  - loading/empty/error states
- Every button action in prototype must map to one API operationId.
- Use contract enums directly in frontend constants (no free-text status labels).

## 10) Immediate Next Tasks
1. Freeze this v0.1 contract and align team terminology.
2. Scaffold Spring Boot project with OpenAPI-first controller interfaces.
3. Create frontend mock client from OpenAPI and wire Figma prototype behavior.
