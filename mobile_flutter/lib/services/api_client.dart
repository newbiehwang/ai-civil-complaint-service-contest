import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../config/app_env.dart';
import 'auth_session.dart';
import 'error_map.dart';

class ApiClientError implements Exception, ApiClientErrorLike {
  ApiClientError({
    required this.code,
    required this.message,
    this.status,
    this.traceId,
    this.details = const <String>[],
  });

  @override
  final String code;

  @override
  final String message;

  @override
  final int? status;
  final String? traceId;
  final List<String> details;

  @override
  String toString() {
    return 'ApiClientError(code: $code, status: $status, traceId: $traceId, message: $message)';
  }
}

class FollowUpOptionDto {
  const FollowUpOptionDto({required this.optionId, required this.label});

  final String optionId;
  final String label;

  factory FollowUpOptionDto.fromJson(Map<String, dynamic> json) {
    return FollowUpOptionDto(
      optionId: json['optionId']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }
}

class FollowUpInterfaceDto {
  const FollowUpInterfaceDto({
    required this.interfaceType,
    required this.selectionMode,
    required this.options,
  });

  final String interfaceType;
  final String selectionMode;
  final List<FollowUpOptionDto> options;

  factory FollowUpInterfaceDto.fromJson(Map<String, dynamic> json) {
    final rawOptions = (json['options'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(FollowUpOptionDto.fromJson)
        .toList(growable: false);

    return FollowUpInterfaceDto(
      interfaceType: json['interfaceType']?.toString() ?? '',
      selectionMode: json['selectionMode']?.toString() ?? 'SINGLE',
      options: rawOptions,
    );
  }
}

class IntakeUpdateResponseDto {
  const IntakeUpdateResponseDto({
    required this.caseId,
    required this.status,
    required this.recommendedFollowUpQuestion,
    this.followUpInterface,
  });

  final String caseId;
  final String status;
  final String recommendedFollowUpQuestion;
  final FollowUpInterfaceDto? followUpInterface;

  factory IntakeUpdateResponseDto.fromJson(Map<String, dynamic> json) {
    final followUpRaw = json['followUpInterface'];

    return IntakeUpdateResponseDto(
      caseId: json['caseId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      recommendedFollowUpQuestion:
          json['recommendedFollowUpQuestion']?.toString() ?? '',
      followUpInterface: followUpRaw is Map<String, dynamic>
          ? FollowUpInterfaceDto.fromJson(followUpRaw)
          : null,
    );
  }
}

class CaseDetailDto {
  const CaseDetailDto({required this.caseId, required this.status});

  final String caseId;
  final String status;

  factory CaseDetailDto.fromJson(Map<String, dynamic> json) {
    return CaseDetailDto(
      caseId: json['caseId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}

class CaseSummaryDto {
  const CaseSummaryDto({
    required this.caseId,
    required this.status,
    required this.riskLevel,
    this.createdAt,
    this.updatedAt,
  });

  final String caseId;
  final String status;
  final String riskLevel;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CaseSummaryDto.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['createdAt']?.toString();
    final updatedAtRaw = json['updatedAt']?.toString();
    return CaseSummaryDto(
      caseId: json['caseId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      riskLevel: json['riskLevel']?.toString() ?? '',
      createdAt: (createdAtRaw == null || createdAtRaw.isEmpty)
          ? null
          : DateTime.tryParse(createdAtRaw),
      updatedAt: (updatedAtRaw == null || updatedAtRaw.isEmpty)
          ? null
          : DateTime.tryParse(updatedAtRaw),
    );
  }
}

class RoutingOptionDto {
  const RoutingOptionDto({
    required this.optionId,
    required this.label,
    required this.reason,
    required this.priority,
  });

  final String optionId;
  final String label;
  final String reason;
  final int priority;

  factory RoutingOptionDto.fromJson(Map<String, dynamic> json) {
    return RoutingOptionDto(
      optionId: json['optionId']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      priority: int.tryParse(json['priority']?.toString() ?? '') ?? 0,
    );
  }
}

class RoutingRecommendationDto {
  const RoutingRecommendationDto({
    required this.caseId,
    required this.options,
    required this.selectedOptionId,
  });

  final String caseId;
  final List<RoutingOptionDto> options;
  final String? selectedOptionId;

  factory RoutingRecommendationDto.fromJson(Map<String, dynamic> json) {
    final rawOptions = (json['options'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(RoutingOptionDto.fromJson)
        .toList(growable: false);

    final selected = json['selectedOptionId']?.toString();
    return RoutingRecommendationDto(
      caseId: json['caseId']?.toString() ?? '',
      options: rawOptions,
      selectedOptionId: selected == null || selected.isEmpty ? null : selected,
    );
  }
}

class DemoLoginResponseDto {
  const DemoLoginResponseDto({
    required this.accessToken,
    required this.tokenType,
    this.expiresAt,
  });

  final String accessToken;
  final String tokenType;
  final DateTime? expiresAt;

  factory DemoLoginResponseDto.fromJson(Map<String, dynamic> json) {
    final expiresAtRaw = json['expiresAt']?.toString();
    return DemoLoginResponseDto(
      accessToken: json['accessToken']?.toString() ?? '',
      tokenType: json['tokenType']?.toString() ?? 'Bearer',
      expiresAt: expiresAtRaw == null || expiresAtRaw.isEmpty
          ? null
          : DateTime.tryParse(expiresAtRaw),
    );
  }
}

class ChatUiOptionDto {
  const ChatUiOptionDto({required this.id, required this.label});

  final String id;
  final String label;

  factory ChatUiOptionDto.fromJson(Map<String, dynamic> json) {
    return ChatUiOptionDto(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }
}

class ChatUiHintDto {
  const ChatUiHintDto({
    required this.type,
    required this.selectionMode,
    required this.title,
    required this.subtitle,
    required this.options,
    required this.meta,
  });

  final String type;
  final String selectionMode;
  final String? title;
  final String? subtitle;
  final List<ChatUiOptionDto> options;
  final Map<String, dynamic> meta;

  factory ChatUiHintDto.fromJson(Map<String, dynamic> json) {
    final rawOptions = (json['options'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(ChatUiOptionDto.fromJson)
        .toList(growable: false);

    return ChatUiHintDto(
      type: json['type']?.toString() ?? 'NONE',
      selectionMode: json['selectionMode']?.toString() ?? 'NONE',
      title: json['title']?.toString(),
      subtitle: json['subtitle']?.toString(),
      options: rawOptions,
      meta:
          (json['meta'] as Map<String, dynamic>? ?? const <String, dynamic>{}),
    );
  }
}

class ChatTurnResponseDto {
  const ChatTurnResponseDto({
    required this.sessionId,
    required this.assistantMessage,
    required this.uiHint,
    required this.statePatch,
    required this.nextAction,
  });

  final String sessionId;
  final String assistantMessage;
  final ChatUiHintDto uiHint;
  final Map<String, dynamic> statePatch;
  final String nextAction;

  factory ChatTurnResponseDto.fromJson(Map<String, dynamic> json) {
    final rawUiHint = json['uiHint'];
    return ChatTurnResponseDto(
      sessionId: json['sessionId']?.toString() ?? '',
      assistantMessage: json['assistantMessage']?.toString() ?? '',
      uiHint: rawUiHint is Map<String, dynamic>
          ? ChatUiHintDto.fromJson(rawUiHint)
          : const ChatUiHintDto(
              type: 'NONE',
              selectionMode: 'NONE',
              title: null,
              subtitle: null,
              options: <ChatUiOptionDto>[],
              meta: <String, dynamic>{},
            ),
      statePatch:
          (json['statePatch'] as Map<String, dynamic>? ?? <String, dynamic>{}),
      nextAction: json['nextAction']?.toString() ?? '',
    );
  }
}

class ChatTurnInteractionPayload {
  const ChatTurnInteractionPayload({
    required this.interactionType,
    this.selectedOptionIds = const <String>[],
    this.selectedOptionLabels = const <String>[],
    this.sourceUiType = 'NONE',
    this.meta = const <String, dynamic>{},
  });

  final String interactionType;
  final List<String> selectedOptionIds;
  final List<String> selectedOptionLabels;
  final String sourceUiType;
  final Map<String, dynamic> meta;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'interactionType': interactionType,
      'selectedOptionIds': selectedOptionIds,
      'selectedOptionLabels': selectedOptionLabels,
      'sourceUiType': sourceUiType,
      'meta': meta,
    };
  }
}

class ChatTurnRecentMessagePayload {
  const ChatTurnRecentMessagePayload({
    required this.role,
    required this.text,
    required this.source,
  });

  final String role;
  final String text;
  final String source;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'role': role,
      'text': text,
      'source': source,
    };
  }
}

class ApiClient {
  ApiClient({String? baseUrl, String? jwt, bool? useBackend})
      : _baseUrl =
            (baseUrl ?? AuthSession.apiBaseUrlOverride ?? AppEnv.apiBaseUrl)
                .replaceAll(RegExp(r'/+$'), ''),
        _jwt = jwt ?? AppEnv.devJwt,
        _useBackend = useBackend ?? AuthSession.useBackend;

  final String _baseUrl;
  final String _jwt;
  final bool _useBackend;

  bool get isConfigured {
    if (!_useBackend) return false;
    final token = _resolvedToken;
    return _baseUrl.isNotEmpty &&
        !_isPlaceholder(_baseUrl) &&
        token != null &&
        token.isNotEmpty &&
        !_isPlaceholder(token);
  }

  String? get _resolvedToken {
    final runtimeToken = AuthSession.accessToken;
    if (runtimeToken != null && runtimeToken.trim().isNotEmpty) {
      return runtimeToken.trim();
    }
    if (_jwt.trim().isEmpty) return null;
    return _jwt.trim();
  }

  bool _isPlaceholder(String value) {
    return value.contains('<') || value.contains('>');
  }

  String createTraceId({String prefix = 'mobile-flutter'}) {
    final now = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final rand = (now.hashCode & 0xFFFFF).toRadixString(36);
    return '$prefix-$now-$rand';
  }

  T _parseDto<T>({
    required String path,
    required String traceId,
    required String parserName,
    required Map<String, dynamic> payload,
    required T Function(Map<String, dynamic>) parser,
  }) {
    try {
      return parser(payload);
    } on ApiClientError {
      rethrow;
    } catch (error) {
      throw ApiClientError(
        code: 'RESPONSE_PARSE_ERROR',
        message: '서버 응답 형식을 해석하지 못했습니다.',
        traceId: traceId,
        details: <String>[
          'path=$path',
          'parser=$parserName',
          'errorType=${error.runtimeType}',
          'payloadKeys=${payload.keys.join(',')}',
        ],
      );
    }
  }

  String _previewBody(String rawText) {
    final normalized = rawText.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) {
      return '<empty>';
    }
    const maxLength = 240;
    if (normalized.length <= maxLength) {
      return normalized;
    }
    return '${normalized.substring(0, maxLength)}...';
  }

  Map<String, dynamic> _decodeJsonMap({
    required String rawText,
    required String path,
    required String traceId,
    required int status,
  }) {
    if (rawText.trim().isEmpty) {
      return <String, dynamic>{};
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(rawText);
    } on FormatException {
      throw ApiClientError(
        code: 'RESPONSE_PARSE_ERROR',
        message: '서버 응답을 해석하지 못했습니다.',
        status: status,
        traceId: traceId,
        details: <String>[
          'path=$path',
          'reason=invalid-json',
          'body=${_previewBody(rawText)}',
        ],
      );
    }

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }

    throw ApiClientError(
      code: 'RESPONSE_PARSE_ERROR',
      message: '서버 응답 형식이 예상과 다릅니다.',
      status: status,
      traceId: traceId,
      details: <String>[
        'path=$path',
        'reason=expected-map',
        'actual=${decoded.runtimeType}',
        'body=${_previewBody(rawText)}',
      ],
    );
  }

  Future<CaseDetailDto> createCase({
    required String traceId,
    required String idempotencyKey,
    required String initialSummary,
    String scenarioType = 'SCENARIO_A',
    String housingType = 'APARTMENT',
    bool consentAccepted = true,
  }) async {
    final response = await _request(
      method: 'POST',
      path: '/api/v1/cases',
      traceId: traceId,
      idempotencyKey: idempotencyKey,
      body: <String, dynamic>{
        'scenarioType': scenarioType,
        'housingType': housingType,
        'consentAccepted': consentAccepted,
        'initialSummary': initialSummary,
      },
    );

    return _parseDto<CaseDetailDto>(
      path: '/api/v1/cases',
      traceId: traceId,
      parserName: 'CaseDetailDto',
      payload: response,
      parser: CaseDetailDto.fromJson,
    );
  }

  Future<IntakeUpdateResponseDto> appendIntakeMessage({
    required String traceId,
    required String caseId,
    required String role,
    required String message,
  }) async {
    final response = await _request(
      method: 'POST',
      path: '/api/v1/cases/$caseId/intake/messages',
      traceId: traceId,
      body: <String, dynamic>{
        'role': role,
        'message': message,
      },
    );

    return _parseDto<IntakeUpdateResponseDto>(
      path: '/api/v1/cases/$caseId/intake/messages',
      traceId: traceId,
      parserName: 'IntakeUpdateResponseDto',
      payload: response,
      parser: IntakeUpdateResponseDto.fromJson,
    );
  }

  Future<List<CaseSummaryDto>> listCases({
    required String traceId,
  }) async {
    final response = await _request(
      method: 'GET',
      path: '/api/v1/cases',
      traceId: traceId,
    );

    final rawItems = response['items'];
    if (rawItems is! List) {
      throw ApiClientError(
        code: 'RESPONSE_PARSE_ERROR',
        message: '케이스 목록 응답 형식이 예상과 다릅니다.',
        traceId: traceId,
        details: const <String>['path=/api/v1/cases', 'reason=items-not-list'],
      );
    }

    final result = <CaseSummaryDto>[];
    for (final item in rawItems) {
      if (item is Map<String, dynamic>) {
        result.add(CaseSummaryDto.fromJson(item));
      } else if (item is Map) {
        result.add(CaseSummaryDto.fromJson(
            item.map((k, v) => MapEntry(k.toString(), v))));
      }
    }
    return result;
  }

  Future<void> deleteCase({
    required String traceId,
    required String caseId,
  }) async {
    await _request(
      method: 'DELETE',
      path: '/api/v1/cases/$caseId',
      traceId: traceId,
    );
  }

  Future<void> decomposeCase({
    required String traceId,
    required String caseId,
  }) async {
    await _request(
      method: 'POST',
      path: '/api/v1/cases/$caseId/decomposition',
      traceId: traceId,
    );
  }

  Future<RoutingRecommendationDto> recommendRoute({
    required String traceId,
    required String caseId,
  }) async {
    final response = await _request(
      method: 'POST',
      path: '/api/v1/cases/$caseId/routing/recommendation',
      traceId: traceId,
    );
    return _parseDto<RoutingRecommendationDto>(
      path: '/api/v1/cases/$caseId/routing/recommendation',
      traceId: traceId,
      parserName: 'RoutingRecommendationDto',
      payload: response,
      parser: RoutingRecommendationDto.fromJson,
    );
  }

  Future<CaseDetailDto> confirmRouteDecision({
    required String traceId,
    required String caseId,
    required String optionId,
  }) async {
    final response = await _request(
      method: 'POST',
      path: '/api/v1/cases/$caseId/routing/decision',
      traceId: traceId,
      body: <String, dynamic>{
        'optionId': optionId,
        'userConfirmed': true,
      },
    );
    return _parseDto<CaseDetailDto>(
      path: '/api/v1/cases/$caseId/routing/decision',
      traceId: traceId,
      parserName: 'CaseDetailDto',
      payload: response,
      parser: CaseDetailDto.fromJson,
    );
  }

  Future<DemoLoginResponseDto> demoLogin({
    required String traceId,
    required String username,
    required String password,
  }) async {
    if (_baseUrl.isEmpty || _isPlaceholder(_baseUrl)) {
      throw ApiClientError(
        code: 'ENV_MISSING',
        message: AppEnv.missingReason ?? 'API_BASE_URL이 비어 있습니다.',
      );
    }

    final response = await _request(
      method: 'POST',
      path: '/api/v1/auth/demo-login',
      traceId: traceId,
      body: <String, dynamic>{
        'username': username,
        'password': password,
      },
      includeAuthHeader: false,
    );

    final dto = _parseDto<DemoLoginResponseDto>(
      path: '/api/v1/auth/demo-login',
      traceId: traceId,
      parserName: 'DemoLoginResponseDto',
      payload: response,
      parser: DemoLoginResponseDto.fromJson,
    );
    if (dto.accessToken.trim().isEmpty) {
      throw ApiClientError(
        code: 'DEMO_LOGIN_FAILED',
        message: '데모 로그인 응답에 토큰이 없습니다.',
      );
    }
    return dto;
  }

  Future<ChatTurnResponseDto> chatTurn({
    required String traceId,
    required String userMessage,
    String? caseId,
    String scenarioType = 'SCENARIO_A',
    String housingType = 'APARTMENT',
    bool consentAccepted = true,
    List<String> uiCapabilities = const <String>[],
    ChatTurnInteractionPayload? interaction,
    String? lastUiHintType,
    List<ChatTurnRecentMessagePayload> recentMessages =
        const <ChatTurnRecentMessagePayload>[],
  }) async {
    final context = <String, dynamic>{
      if (caseId != null && caseId.trim().isNotEmpty) 'caseId': caseId.trim(),
      'scenarioType': scenarioType,
      'housingType': housingType,
      'consentAccepted': consentAccepted,
    };

    final response = await _request(
      method: 'POST',
      path: '/api/v1/chat/turn',
      traceId: traceId,
      body: <String, dynamic>{
        'userMessage': userMessage,
        'context': context,
        'uiCapabilities': uiCapabilities,
        if (interaction != null) 'interaction': interaction.toJson(),
        if (lastUiHintType != null && lastUiHintType.trim().isNotEmpty)
          'lastUiHintType': lastUiHintType.trim(),
        if (recentMessages.isNotEmpty)
          'recentMessages': recentMessages
              .map((message) => message.toJson())
              .toList(growable: false),
      },
    );

    return _parseDto<ChatTurnResponseDto>(
      path: '/api/v1/chat/turn',
      traceId: traceId,
      parserName: 'ChatTurnResponseDto',
      payload: response,
      parser: ChatTurnResponseDto.fromJson,
    );
  }

  Future<Map<String, dynamic>> _request({
    required String method,
    required String path,
    required String traceId,
    String? idempotencyKey,
    Map<String, dynamic>? body,
    bool includeAuthHeader = true,
  }) async {
    if (!_useBackend) {
      throw ApiClientError(
        code: 'LOCAL_MODE',
        message: '로컬 모드에서는 서버 요청을 사용하지 않습니다.',
        traceId: traceId,
      );
    }

    if (_baseUrl.isEmpty || _isPlaceholder(_baseUrl)) {
      throw ApiClientError(
        code: 'ENV_MISSING',
        message: AppEnv.missingReason ?? 'API_BASE_URL이 비어 있습니다.',
      );
    }

    final token = _resolvedToken;
    if (includeAuthHeader &&
        (token == null || token.isEmpty || _isPlaceholder(token))) {
      throw ApiClientError(
        code: 'UNAUTHORIZED',
        message: '인증 토큰이 없습니다. 데모 로그인 후 다시 시도해 주세요.',
      );
    }

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 12);

    try {
      final uri = Uri.parse('$_baseUrl$path');
      final request = await client.openUrl(method, uri);
      if (includeAuthHeader && token != null && token.isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      request.headers.set('X-Trace-Id', traceId);
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'application/json; charset=utf-8',
      );
      if (idempotencyKey != null && idempotencyKey.trim().isNotEmpty) {
        request.headers.set('Idempotency-Key', idempotencyKey);
      }

      if (body != null) {
        final encoded = utf8.encode(jsonEncode(body));
        request.add(encoded);
      }

      final response =
          await request.close().timeout(const Duration(seconds: 20));
      final rawText = await utf8.decodeStream(response);
      final decoded = _decodeJsonMap(
        rawText: rawText,
        path: path,
        traceId: traceId,
        status: response.statusCode,
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final rawDetails = decoded['details'];
        final details = rawDetails is List
            ? rawDetails.map((e) => e.toString()).toList(growable: false)
            : const <String>[];

        throw ApiClientError(
          code: decoded['code']?.toString() ?? 'HTTP_${response.statusCode}',
          message:
              decoded['message']?.toString() ?? '요청 실패(${response.statusCode})',
          status: response.statusCode,
          traceId: decoded['traceId']?.toString(),
          details: details,
        );
      }

      return decoded;
    } on ApiClientError {
      rethrow;
    } on SocketException catch (e) {
      throw ApiClientError(
        code: 'NETWORK_ERROR',
        message:
            '네트워크 연결이 원활하지 않습니다. 실기기라면 localhost 대신 PC LAN IP를 사용해 주세요. (${e.message})',
        traceId: traceId,
      );
    } on TimeoutException {
      throw ApiClientError(
        code: 'NETWORK_TIMEOUT',
        message: '서버 응답이 지연되고 있습니다. 잠시 후 다시 시도해 주세요.',
        traceId: traceId,
      );
    } on HandshakeException catch (e) {
      throw ApiClientError(
        code: 'SSL_ERROR',
        message: '보안 연결(SSL)에 실패했습니다. 네트워크 환경을 확인해 주세요.',
        traceId: traceId,
        details: <String>['type=${e.runtimeType}', 'message=${e.message}'],
      );
    } on HttpException catch (e) {
      throw ApiClientError(
        code: 'HTTP_CLIENT_ERROR',
        message: 'HTTP 요청 처리 중 문제가 발생했습니다.',
        traceId: traceId,
        details: <String>['message=${e.message}'],
      );
    } on ArgumentError catch (e) {
      throw ApiClientError(
        code: 'INVALID_REQUEST',
        message: '요청 형식이 올바르지 않습니다. 설정값을 확인해 주세요.',
        traceId: traceId,
        details: <String>['message=${e.message}'],
      );
    } on FormatException catch (e) {
      throw ApiClientError(
        code: 'INVALID_URL',
        message: 'API 주소 형식이 올바르지 않습니다.',
        traceId: traceId,
        details: <String>['message=${e.message}'],
      );
    } on TypeError catch (e) {
      throw ApiClientError(
        code: 'RESPONSE_PARSE_ERROR',
        message: '서버 응답 형식이 예상과 다릅니다.',
        traceId: traceId,
        details: <String>['type=${e.runtimeType}'],
      );
    } catch (e) {
      throw ApiClientError(
        code: 'UNKNOWN_ERROR',
        message: '요청 처리 중 문제가 발생했습니다. 다시 시도해 주세요.',
        traceId: traceId,
        details: <String>['type=${e.runtimeType}', 'message=$e'],
      );
    } finally {
      client.close(force: true);
    }
  }
}
