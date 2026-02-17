export type AppEnv = {
  apiBaseUrl: string;
  devJwt: string;
  isConfigured: boolean;
  missing: string[];
};

function normalizeBaseUrl(value: string): string {
  return value.replace(/\/+$/, "");
}

function buildEnv(): AppEnv {
  const missing: string[] = [];

  const apiBaseUrlRaw = process.env.EXPO_PUBLIC_API_BASE_URL?.trim() ?? "";
  const devJwtRaw = process.env.EXPO_PUBLIC_DEV_JWT?.trim() ?? "";

  if (!apiBaseUrlRaw) {
    missing.push("EXPO_PUBLIC_API_BASE_URL");
  }

  if (!devJwtRaw) {
    missing.push("EXPO_PUBLIC_DEV_JWT");
  }

  return {
    apiBaseUrl: apiBaseUrlRaw ? normalizeBaseUrl(apiBaseUrlRaw) : "",
    devJwt: devJwtRaw,
    isConfigured: missing.length === 0,
    missing,
  };
}

export const APP_ENV = buildEnv();

export function assertEnvConfigured(): void {
  if (APP_ENV.isConfigured) {
    return;
  }

  const message =
    `[mobile env] Missing required env vars: ${APP_ENV.missing.join(", ")}. ` +
    `Set them in mobile/.env (see mobile/.env.example).`;

  throw new Error(message);
}
