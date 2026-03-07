# AI 기반 층간소음 민원 케이스 오케스트레이션 서비스

층간소음 민원을 대화형으로 접수하고, 상태머신 기반으로 경로 추천/서류 생성/제출/진행 추적까지 연결하는 프로토타입입니다.

## 서비스 특징
- 대화형 민원 접수:
  - 자유 입력 + 미니 인터페이스(`ListPicker`, `MultiForm`, `OptionList`, `SummaryCard`, `PathChooser`, `StatusFeed`)를 혼합해 정보 수집.
- 케이스 오케스트레이션:
  - 백엔드 상태머신이 단계 전이를 강제해 잘못된 순서 제출을 방지.
- LLM + 규칙 기반 하이브리드:
  - LLM(Claude)로 응답/가이드 생성.
  - 실패 시 폴백 로직으로 흐름을 유지.
- 이웃사이센터 소음측정 신청 흐름:
  - 신청 정보 수집, 선택 첨부, 초안 검토, 동의, 최종 제출 단계 포함.
- 문서/제출 파이프라인:
  - 측정 신청 문서(HWPX) 작성 로직 포함.
  - 메일 발송은 설정 기반으로 활성화 가능.
- 모바일 실사용 데모:
  - Flutter 기반 iOS/macOS/Android 실행.
  - 로그인 세션/민원 목록/상담 화면을 포함.

## 현재 데모 구현 범위
- 공통
  - 정부24 스타일 시작 화면 + 데모 로그인.
  - 케이스 생성/조회/대화 턴(`POST /api/v1/chat/turn`) 기반 흐름.
- Intake 단계
  - 일반 대화에서 접수 의사 확인 후 구조화 수집 단계 진입.
  - 기본 정보/소음 패턴/시작 시점 수집.
- 경로 선택
  - `PathChooser` 기반 추천 경로 제시 및 선택.
- 이웃사이센터 측정 신청 흐름(데모)
  - 신청 정보 입력(프로필 불러오기/직접 입력)
  - 참고자료 선택 첨부(선택사항)
  - 신청서/발생일지 초안 검토
  - 동의 단계
  - 제출 후 상태 피드 표시
- 상태 추적
  - `StatusFeed` UI로 단계 진행 상황 표시.

## 리포지토리 구성
- 백엔드(Spring Boot): `/Users/hwangshincheol/conductor/workspaces/ai-civil-complaint-service-contest/wellington/src/main/java`
- 모바일(Flutter): `/Users/hwangshincheol/conductor/workspaces/ai-civil-complaint-service-contest/wellington/mobile_flutter`
- 계약/문서:
  - `/Users/hwangshincheol/conductor/workspaces/ai-civil-complaint-service-contest/wellington/docs/contracts/openapi-civil-complaint.yaml`
  - `/Users/hwangshincheol/conductor/workspaces/ai-civil-complaint-service-contest/wellington/docs/contracts/scenario-a-interface-spec.md`

## 백엔드 실행
1. Postgres 실행
```bash
docker compose up -d postgres
```

2. 테스트
```bash
./gradlew test
```

3. 서버 실행
```bash
./gradlew bootRun
```

4. API 기본 주소
```text
http://localhost:8080/api/v1
```

## Flutter 실행
1. 의존성 설치
```bash
cd mobile_flutter
flutter pub get
```

2. 실행(권장: .env 사용)
```bash
flutter run --dart-define-from-file=.env
```

3. macOS 실행
```bash
flutter run -d macos --dart-define-from-file=.env.macos
```

## 주요 환경변수
- DB/JWT
  - `DB_URL`, `DB_USERNAME`, `DB_PASSWORD`, `JWT_SECRET`
- LLM
  - `AI_CHAT_USE_LLM`
  - `AI_CHAT_PROVIDER=claude`
  - `CLAUDE_API_KEY`, `CLAUDE_MODEL`, `CLAUDE_TIMEOUT_MS`
- 이웃사이센터 측정 문서/메일
  - `NEIGHBOR_CENTER_MEASUREMENT_TEMPLATE_PATH`
  - `NEIGHBOR_CENTER_MEASUREMENT_OUTPUT_DIR`
  - `NEIGHBOR_CENTER_MEASUREMENT_RECIPIENT_EMAIL`
  - `NEIGHBOR_CENTER_MEASUREMENT_MAIL_ENABLED`
  - `NEIGHBOR_CENTER_MEASUREMENT_MAIL_FROM`
  - `NEIGHBOR_CENTER_MEASUREMENT_MAIL_SUBJECT`

## 주요 API
- `POST /api/v1/auth/demo-login`
- `POST /api/v1/chat/turn`
- `POST /api/v1/cases`
- `GET /api/v1/cases/{caseId}`
- `POST /api/v1/cases/{caseId}/submission`
- `GET /api/v1/cases/{caseId}/timeline`

## 참고
- 이 레포는 공모전 프로토타입입니다.
- 기관 실연계(MCP/기관 API)는 데모/설정 기반 동작을 포함하며, 운영 전환 시 인증·보안·법적 검토가 필요합니다.
