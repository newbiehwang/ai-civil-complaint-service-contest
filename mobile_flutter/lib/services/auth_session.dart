class AuthSession {
  AuthSession._();

  static String? _accessToken;
  static DateTime? _expiresAt;
  static String? _accountId;

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

  static void clear() {
    _accessToken = null;
    _expiresAt = null;
    _accountId = null;
  }
}
