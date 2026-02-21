# Chat Turn Contract (LLM-style)

`POST /api/v1/chat/turn`

단일 턴 요청/응답으로 대화형 UI를 구동하기 위한 백엔드 계약입니다.
앱은 이 API 응답의 `assistantMessage`, `uiHint`, `statePatch`, `nextAction`만 해석하면 됩니다.

## Request

```json
{
  "userMessage": "윗집 소음이 너무 시끄러워요",
  "context": {
    "caseId": "optional-uuid",
    "scenarioType": "SCENARIO_A",
    "housingType": "APARTMENT",
    "consentAccepted": true
  },
  "uiCapabilities": ["LIST_PICKER", "OPTION_LIST", "SUMMARY_CARD"]
}
```

- `context.caseId`가 없으면 백엔드가 새 케이스를 생성합니다.
- `context.caseId`가 있으면 해당 케이스에 메시지를 누적합니다.

## Response

```json
{
  "sessionId": "6a4fcbca-1111-2222-3333-999999999999",
  "assistantMessage": "거주 형태를 선택해 주세요.",
  "uiHint": {
    "type": "LIST_PICKER",
    "selectionMode": "SINGLE",
    "title": null,
    "subtitle": null,
    "options": [
      { "id": "residence-apartment", "label": "아파트" },
      { "id": "residence-villa", "label": "빌라" },
      { "id": "residence-officetel", "label": "오피스텔" }
    ],
    "meta": {}
  },
  "statePatch": {
    "caseId": "6a4fcbca-1111-2222-3333-999999999999",
    "status": "RECEIVED",
    "riskLevel": "LOW",
    "currentActionRequired": "INTAKE_REQUIRED",
    "requiredSlots": [
      "noiseNow",
      "safety",
      "residence",
      "management",
      "noiseType",
      "frequency",
      "timeBand",
      "sourceCertainty"
    ],
    "filledSlots": {
      "noiseNow": "지금 진행 중"
    },
    "riskSignalDetected": false
  },
  "nextAction": "INTAKE_REQUIRED"
}
```

## UI Hint Types

- `NONE`
- `LIST_PICKER`
- `OPTION_LIST`
- `SUMMARY_CARD`
- `PATH_CHOOSER`
- `STATUS_FEED`

## Selection Mode

- `NONE`
- `SINGLE`
- `MULTIPLE`

## Notes

- 인증은 기존 API와 동일하게 `Authorization: Bearer <token>`을 사용합니다.
- 현재 구현은 기존 `createCase + appendIntakeMessage` 상태머신을 래핑합니다.
- `status=CLASSIFIED` 시 `uiHint.type=PATH_CHOOSER` 힌트를 반환해 라우팅 단계 진입을 유도합니다.
