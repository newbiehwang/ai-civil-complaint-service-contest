# AI Civil Complaint Service (Scenario A)

Spring Boot backend scaffold and interface-first contract for Scenario A (층간소음).

## What is included
- OpenAPI contract: `docs/contracts/openapi-scenario-a.yaml`
- Interface spec: `docs/contracts/scenario-a-interface-spec.md`
- Figma handoff doc: `docs/figma/figma-api-handoff.md`
- Spring API scaffold with in-memory workflow/state machine
- Frontend mock request/response payloads: `frontend/mocks/**`

## Quick start
1. Run tests
```bash
gradle test
```

2. Run server
```bash
gradle bootRun
```

3. API base URL
```text
http://localhost:8080/api/v1
```

## Main endpoints
- `POST /cases`
- `GET /cases/{caseId}`
- `POST /cases/{caseId}/intake/messages`
- `POST /cases/{caseId}/decomposition`
- `POST /cases/{caseId}/routing/recommendation`
- `POST /cases/{caseId}/routing/decision`
- `POST /cases/{caseId}/evidence`
- `GET /cases/{caseId}/evidence/checklist`
- `POST /cases/{caseId}/submission`
- `POST /cases/{caseId}/supplement-response`
- `GET /cases/{caseId}/timeline`

## Notes
- Current backend persistence is in-memory for rapid prototype iteration.
- Security is open (`permitAll`) for development; replace with real JWT validation later.
- State transition conflicts are returned as `409 CASE_STATE_CONFLICT`.
