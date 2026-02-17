# Mobile Check App (Expo)

`13_Chatbot_Conversation` 점검용 React Native + Expo + TypeScript 앱입니다.

## 포함 내용

- 상단 고정 헤더(`뒤로가기`, `층간소음 상담`)
- AI 메시지 상단 대형 출력
- 타입라이터(점진 출력) 애니메이션
- 입력창 위 미니 인터페이스(시간 선택 칩) 조건부 노출
- 하단 고정 입력창 + 전송 버튼

## 실행

```bash
cd mobile
npm install
npm run start
```

- iOS 시뮬레이터: `npm run ios`
- Android 에뮬레이터: `npm run android`

## 실행 안 될 때

```bash
cd mobile
rm -rf node_modules package-lock.json
npm install
npx expo install react-dom react-native-web @expo/metro-runtime
npm run start
```

- Node 버전은 LTS(권장: 20.x)에서 실행하는 것이 안정적입니다.
