import type { ApiError } from "../types/api";

const ERROR_CODE_TO_MESSAGE: Record<string, string> = {
  VALIDATION_ERROR: "입력 내용을 다시 확인해 주세요.",
  UNAUTHORIZED: "인증 정보가 유효하지 않습니다. 개발용 토큰을 확인해 주세요.",
  FORBIDDEN: "현재 요청에 대한 권한이 없습니다.",
  IDEMPOTENCY_KEY_REUSED: "중복 요청이 감지되었습니다. 잠시 후 다시 시도해 주세요.",
  CASE_NOT_FOUND: "민원 케이스를 찾을 수 없습니다.",
  CASE_STATE_CONFLICT: "현재 단계에서는 이 요청을 처리할 수 없습니다.",
  ROUTE_OPTION_NOT_FOUND: "선택한 경로 정보를 찾을 수 없습니다.",
  INSTITUTION_GATEWAY_ERROR: "기관 연동이 지연되고 있습니다. 잠시 후 다시 시도해 주세요.",
  INTERNAL_ERROR: "서버 처리 중 문제가 발생했습니다. 잠시 후 다시 시도해 주세요.",
  NETWORK_ERROR:
    "네트워크 연결이 원활하지 않습니다. Expo Go에서는 localhost 대신 PC의 LAN IP를 mobile/.env에 설정해 주세요.",
  UNKNOWN_ERROR: "요청 처리 중 문제가 발생했습니다. 다시 시도해 주세요.",
};

type ApiClientLikeError = {
  code?: string;
  message?: string;
  status?: number;
};

const STATUS_FALLBACK_MESSAGE: Record<number, string> = {
  400: "요청 형식이 올바르지 않습니다. 입력 내용을 확인해 주세요.",
  401: ERROR_CODE_TO_MESSAGE.UNAUTHORIZED,
  403: ERROR_CODE_TO_MESSAGE.FORBIDDEN,
  404: "요청한 리소스를 찾을 수 없습니다.",
  409: "현재 단계와 맞지 않는 요청입니다. 다시 확인해 주세요.",
  500: ERROR_CODE_TO_MESSAGE.INTERNAL_ERROR,
  503: ERROR_CODE_TO_MESSAGE.INSTITUTION_GATEWAY_ERROR,
};

export function toKoreanErrorMessage(error: unknown): string {
  if (!error) {
    return ERROR_CODE_TO_MESSAGE.UNKNOWN_ERROR;
  }

  if (typeof error === "object" && error !== null) {
    const maybeApiClientError = error as ApiClientLikeError;
    if (maybeApiClientError.code && ERROR_CODE_TO_MESSAGE[maybeApiClientError.code]) {
      return ERROR_CODE_TO_MESSAGE[maybeApiClientError.code];
    }

    if (typeof maybeApiClientError.status === "number" && STATUS_FALLBACK_MESSAGE[maybeApiClientError.status]) {
      return STATUS_FALLBACK_MESSAGE[maybeApiClientError.status];
    }

    if (typeof maybeApiClientError.message === "string" && maybeApiClientError.message.trim().length > 0) {
      if (maybeApiClientError.message.includes("[mobile env]")) {
        return "앱 환경 설정이 비어 있습니다. mobile/.env 값을 확인해 주세요.";
      }
      return maybeApiClientError.message;
    }

    const maybeApiError = error as ApiError;
    if (typeof maybeApiError.code === "string" && ERROR_CODE_TO_MESSAGE[maybeApiError.code]) {
      return ERROR_CODE_TO_MESSAGE[maybeApiError.code];
    }
  }

  return ERROR_CODE_TO_MESSAGE.UNKNOWN_ERROR;
}
