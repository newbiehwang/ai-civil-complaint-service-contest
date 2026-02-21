# mobile_flutter

Flutter port of the mobile demo flow.

## Run

```bash
cd mobile_flutter
flutter create .
flutter pub get
flutter run
```

If Flutter SDK is not installed yet:

```bash
brew install --cask flutter
```

## Included demo scope

- Start flow (Frame 1 ~ 4 style sequence)
- Chatbot conversation screen
- Mini interfaces:
  - ListPicker
  - OptionList (date/time)
  - SummaryCard
  - PathChooser
  - NoiseDiaryBuilder
  - DraftViewer
  - DraftConfirm
  - StatusFeed

Core UI flow is demo-local, and intake turns can be wired to the backend API.

## Backend wiring (Flutter)

`ChatbotDemoScreen` now supports live backend intake wiring:
- `POST /api/v1/cases` (first user message)
- `POST /api/v1/cases/{caseId}/intake/messages` (follow-up turns)
- `POST /api/v1/auth/demo-login` (start flow Gov24 demo login)

If backend env is missing, the app automatically falls back to demo-local flow.

### Run with API env

```bash
cd mobile_flutter
flutter run \
  --dart-define=API_BASE_URL=http://<LAN_IP>:8080 \
  --dart-define=DEV_JWT=<YOUR_DEV_JWT>
```

or use an env file:

```bash
cd mobile_flutter
cp .env.example .env
# edit .env values
flutter run --dart-define-from-file=.env
```

macOS 전용 env를 따로 쓰려면:

```bash
cd mobile_flutter
cp .env.macos.example .env.macos
# edit .env.macos values
flutter run -d macos --dart-define-from-file=.env.macos
```

Notes:
- On real iPhone, do not use `localhost`; use your PC LAN IP.
- On macOS app, `API_BASE_URL_MACOS`, `DEV_JWT_MACOS`를 우선 사용합니다.
- Legacy keys `EXPO_PUBLIC_API_BASE_URL` and `EXPO_PUBLIC_DEV_JWT` are also accepted.
- Demo login credential: `demo / 1234`
