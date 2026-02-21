class AuthSession {
  AuthSession._();

  static String? _accessToken;
  static DateTime? _expiresAt;
  static String? _accountId;
  static bool _useBackend = true;
  static String? _apiBaseUrlOverride;

  static String? get accessToken {
    if (_accessToken == null || _accessToken!.trim().isEmpty) {
      return null;
    }
    if (_expiresAt != null && DateTime.now().isAfter(_expiresAt!)) {
      clear();
      return null;
    }
    return _accessToken;
  }

  static bool get hasToken => accessToken != null;
  static bool get useBackend => _useBackend;
  static String? get apiBaseUrlOverride {
    final raw = _apiBaseUrlOverride?.trim();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  static String? get accountId {
    final raw = _accountId?.trim();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  static void applyToken(
    String token, {
    DateTime? expiresAt,
    String? accountId,
  }) {
    _accessToken = token.trim();
    _expiresAt = expiresAt;
    _accountId = accountId?.trim();
  }

  static void configureConnectionMode({
    required bool useBackend,
    String? apiBaseUrlOverride,
  }) {
    _useBackend = useBackend;
    final normalized = apiBaseUrlOverride?.trim();
    _apiBaseUrlOverride =
        (normalized == null || normalized.isEmpty) ? null : normalized;
  }

  static void clear() {
    _accessToken = null;
    _expiresAt = null;
    _accountId = null;
    _useBackend = true;
    _apiBaseUrlOverride = null;
  }
}
