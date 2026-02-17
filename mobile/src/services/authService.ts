import { APP_ENV, assertEnvConfigured } from "../config/env";

export function getDevAccessToken(): string {
  assertEnvConfigured();
  return APP_ENV.devJwt;
}
