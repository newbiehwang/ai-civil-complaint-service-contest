import 'package:flutter/foundation.dart';

class AppEnv {
  const AppEnv._();

  static const _apiBaseUrlPrimary =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');
  static const _apiBaseUrlLegacy =
      String.fromEnvironment('EXPO_PUBLIC_API_BASE_URL', defaultValue: '');
  static const _apiBaseUrlMacos =
      String.fromEnvironment('API_BASE_URL_MACOS', defaultValue: '');

  static const _devJwtPrimary =
      String.fromEnvironment('DEV_JWT', defaultValue: '');
  static const _devJwtLegacy =
      String.fromEnvironment('EXPO_PUBLIC_DEV_JWT', defaultValue: '');
  static const _devJwtMacos =
      String.fromEnvironment('DEV_JWT_MACOS', defaultValue: '');

  static bool get _isMacosTarget =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  static String get apiBaseUrl {
    final value = _isMacosTarget
        ? (_apiBaseUrlMacos.isNotEmpty
            ? _apiBaseUrlMacos
            : (_apiBaseUrlPrimary.isNotEmpty
                ? _apiBaseUrlPrimary
                : _apiBaseUrlLegacy))
        : (_apiBaseUrlPrimary.isNotEmpty
            ? _apiBaseUrlPrimary
            : _apiBaseUrlLegacy);
    return value.replaceAll(RegExp(r'/+$'), '');
  }

  static String get devJwt => _isMacosTarget
      ? (_devJwtMacos.isNotEmpty
          ? _devJwtMacos
          : (_devJwtPrimary.isNotEmpty ? _devJwtPrimary : _devJwtLegacy))
      : (_devJwtPrimary.isNotEmpty ? _devJwtPrimary : _devJwtLegacy);

  static bool get isConfigured => apiBaseUrl.isNotEmpty && devJwt.isNotEmpty;

  static String? get missingReason {
    if (apiBaseUrl.isEmpty && devJwt.isEmpty) {
      return _isMacosTarget
          ? 'API_BASE_URL_MACOS(또는 API_BASE_URL), DEV_JWT_MACOS(또는 DEV_JWT)가 비어 있습니다.'
          : 'API_BASE_URL, DEV_JWT가 비어 있습니다.';
    }
    if (apiBaseUrl.isEmpty) {
      return _isMacosTarget
          ? 'API_BASE_URL_MACOS(또는 API_BASE_URL)이 비어 있습니다.'
          : 'API_BASE_URL이 비어 있습니다.';
    }
    if (devJwt.isEmpty) {
      return _isMacosTarget
          ? 'DEV_JWT_MACOS(또는 DEV_JWT)가 비어 있습니다.'
          : 'DEV_JWT가 비어 있습니다.';
    }
    return null;
  }
}
