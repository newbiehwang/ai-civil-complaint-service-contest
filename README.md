# AI Civil Complaint Service (Scenario A)

Spring Boot backend scaffold and interface-first contract for Scenario A (층간소음).

## What is included
- OpenAPI contract: `docs/contracts/openapi-civil-complaint.yaml`
- Interface spec: `docs/contracts/scenario-a-interface-spec.md`
- Figma handoff doc: `docs/figma/figma-api-handoff.md`
- Spring API scaffold with JPA + Flyway persistence (Case/Evidence/Timeline)
- Frontend mock request/response payloads: `frontend/mocks/**`
- Frontend app scaffold (React + Vite + Storybook + design-token pipeline): `frontend/**`

## Quick start
1. Start Postgres
```bash
docker compose up -d postgres
```

2. Run tests
```bash
gradle test
```

3. Run server
```bash
gradle bootRun
```

4. API base URL
```text
http://localhost:8080/api/v1
```

## Frontend quick start
1. Install dependencies
```bash
cd frontend
npm install
```

2. Run app
```bash
npm run dev
```

3. Run Storybook
```bash
npm run storybook
```

4. Sync Figma tokens into CSS variables
```bash
npm run tokens:build
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
- Runtime DB defaults:
  - `DB_URL=jdbc:postgresql://localhost:5433/complaint`
  - `DB_USERNAME=complaint`
  - `DB_PASSWORD=complaint`
  - `JWT_SECRET` (HS256, 32+ chars)
  - `AI_FOLLOWUP_USE_LLM=false` (기본: 룰 기반 follow-up)
  - `OPENAI_API_KEY` (선택, `AI_FOLLOWUP_USE_LLM=true`일 때 사용)
  - `OPENAI_MODEL=gpt-4o-mini` (선택)
- `INSTITUTION_GATEWAY_FAIL_DIRECT_API=false` (set `true` to simulate `INSTITUTION_GATEWAY_ERROR` on `DIRECT_API` submit)
- Mock institution submission worker delay:
  - `MOCK_SUBMISSION_DELAY_MS=1500` (default)
- Tests run on in-memory H2 (PostgreSQL mode) via `src/test/resources/application.yml`.
- Security enforces Bearer JWT on `/api/v1/**`.
- State transition conflicts are returned as `409 CASE_STATE_CONFLICT`.
- Evidence is optional; submission can proceed without attachments after route confirmation.
- `Idempotency-Key` is supported for `POST /cases` and `POST /cases/{caseId}/submission`.
