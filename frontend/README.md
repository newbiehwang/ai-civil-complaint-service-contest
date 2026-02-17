# Frontend Workspace

React + Vite + Storybook 기반의 프론트엔드 작업 공간입니다.

## Run

```bash
cd frontend
npm install
npm run dev
```

## Storybook

```bash
cd frontend
npm run storybook
```

## Build

```bash
cd frontend
npm run build
npm run build-storybook
```

## Figma Token Sync

1. Figma(Tokens Studio)에서 토큰 JSON 내보내기
2. `design-tokens/figma.tokens.json` 업데이트
3. `npm run tokens:build` 실행
4. 생성된 `src/styles/generated/tokens.css`가 앱/스토리북에 자동 반영

## Contract-first Notes

- `src/api-contract.ts`에 OpenAPI 계약 상태/에러 코드를 상수 타입으로 반영
- 화면 상태 배지(`StatusBadge`)는 `CaseStatus` enum과 1:1로 매핑
