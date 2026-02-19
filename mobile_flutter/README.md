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

All logic is demo-local (no backend wiring yet).
