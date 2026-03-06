const Map<String, String> _errorCodeToMessage = {
  'ENV_MISSING': '환경 설정이 비어 있습니다. API 주소와 토큰을 확인해 주세요.',
  'VALIDATION_ERROR': '입력 내용을 다시 확인해 주세요.',
  'DEMO_LOGIN_INVALID': '아이디와 비밀번호를 입력해 주세요.',
  'DEMO_LOGIN_FAILED': '데모 계정 정보가 올바르지 않습니다.',
  'UNAUTHORIZED': '인증 정보가 유효하지 않습니다. 다시 로그인해 주세요.',
  'FORBIDDEN': '현재 요청 권한이 없습니다.',
  'IDEMPOTENCY_KEY_REUSED': '중복 요청이 감지되었습니다. 잠시 후 다시 시도해 주세요.',
  'CASE_NOT_FOUND': '민원 케이스를 찾을 수 없습니다.',
  'CASE_STATE_CONFLICT': '현재 단계와 맞지 않는 요청입니다. 다시 확인해 주세요.',
  'ROUTE_OPTION_NOT_FOUND': '선택한 경로 정보를 찾을 수 없습니다.',
  'INSTITUTION_GATEWAY_ERROR': '기관 연동이 지연되고 있습니다. 잠시 후 다시 시도해 주세요.',
  'LLM_UNAVAILABLE': 'AI 응답이 지연되고 있습니다. 잠시 후 다시 시도해 주세요.',
  'SERVICE_UNAVAILABLE': '서비스 응답이 지연되고 있습니다. 잠시 후 다시 시도해 주세요.',
  'INTERNAL_ERROR': '서버 처리 중 문제가 발생했습니다. 잠시 후 다시 시도해 주세요.',
  'NETWORK_ERROR':
      '네트워크 연결이 원활하지 않습니다. 실기기에서는 localhost 대신 PC LAN IP를 사용해 주세요.',
  'NETWORK_TIMEOUT': '서버 응답이 지연되고 있습니다. 잠시 후 다시 시도해 주세요.',
  'SSL_ERROR': '보안 연결(SSL)에 실패했습니다. 네트워크 환경을 확인해 주세요.',
  'HTTP_CLIENT_ERROR': '요청 전송 중 문제가 발생했습니다. 잠시 후 다시 시도해 주세요.',
  'INVALID_REQUEST': '요청 형식이 올바르지 않습니다. 설정값을 확인해 주세요.',
  'INVALID_URL': 'API 주소 형식이 올바르지 않습니다. 실행 옵션을 확인해 주세요.',
  'RESPONSE_PARSE_ERROR': '서버 응답 형식을 해석하지 못했습니다. 잠시 후 다시 시도해 주세요.',
  'UNKNOWN_ERROR': '요청 처리 중 문제가 발생했습니다. 다시 시도해 주세요.',
};

const Map<int, String> _statusFallbackMessage = {
  400: '요청 형식이 올바르지 않습니다. 입력 내용을 확인해 주세요.',
  401: '인증 정보가 유효하지 않습니다. 다시 로그인해 주세요.',
  403: '현재 요청 권한이 없습니다.',
  404: '요청한 리소스를 찾을 수 없습니다.',
  409: '현재 단계와 맞지 않는 요청입니다. 다시 확인해 주세요.',
  500: '서버 처리 중 문제가 발생했습니다. 잠시 후 다시 시도해 주세요.',
  503: '서비스 응답이 지연되고 있습니다. 잠시 후 다시 시도해 주세요.',
};

String toKoreanErrorMessage(Object error) {
  if (error is ApiClientErrorLike) {
    final code = error.code;
    if (code != null && _errorCodeToMessage.containsKey(code)) {
      return _errorCodeToMessage[code]!;
    }
    final status = error.status;
    if (status != null && _statusFallbackMessage.containsKey(status)) {
      return _statusFallbackMessage[status]!;
    }
    final message = error.message;
    if (message != null && message.trim().isNotEmpty) {
      return message;
    }
  }

  return _errorCodeToMessage['UNKNOWN_ERROR']!;
}

abstract class ApiClientErrorLike {
  String? get code;

  int? get status;

  String? get message;
}
