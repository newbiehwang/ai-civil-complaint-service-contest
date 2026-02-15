# AI Civil Complaint Service (Scenario A)

Spring Boot backend scaffold and interface-first contract for Scenario A (층간소음).

## What is included
- OpenAPI contract: `docs/contracts/openapi-civil-complaint.yaml`
- Interface spec: `docs/contracts/scenario-a-interface-spec.md`
- Figma handoff doc: `docs/figma/figma-api-handoff.md`
- Spring API scaffold with JPA + Flyway persistence (Case/Evidence/Timeline)
- Frontend mock request/response payloads: `frontend/mocks/**`

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
- Tests run on in-memory H2 (PostgreSQL mode) via `src/test/resources/application.yml`.
- Security is open (`permitAll`) for development; replace with real JWT validation later.
- State transition conflicts are returned as `409 CASE_STATE_CONFLICT`.
