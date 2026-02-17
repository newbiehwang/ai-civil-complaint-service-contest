# Design Tokens

Figma에서 관리하는 토큰을 `figma.tokens.json`으로 내보내고 아래 명령으로 앱/스토리북 스타일 변수로 동기화합니다.

```bash
npm run tokens:build
```

출력물:
- `src/styles/generated/tokens.css`: 런타임 CSS 변수
- `design-tokens/build/tokens.json`: 가공된 토큰 JSON

권장 워크플로:
1. Figma 토큰 수정
2. `figma.tokens.json` 갱신
3. `npm run tokens:build`
4. 컴포넌트 스타일/스토리 확인
