import 'dart:async';

import 'local/auth_persistence.dart';

class AuthSession {
  AuthSession._();

  static final AuthPersistence _persistence = AuthPersistence();
  static String? _accessToken;
  static DateTime? _expiresAt;
  static String? _accountId;
  static bool _useBackend = true;
  static String? _apiBaseUrlOverride;
  static Future<void>? _restoreFuture;

  static String? get accessToken {
    if (_accessToken == null || _accessToken!.trim().isEmpty) {
      return null;
    }
    // Product policy: keep signed-in session until explicit logout.
    // Token expiry metadata is retained for diagnostics only.
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

  static Future<void> restore() {
    _restoreFuture ??= _restoreInternal();
    return _restoreFuture!;
  }

  static Future<void> _restoreInternal() async {
    final state = await _persistence.read();
    if (state == null) return;

    _accessToken = state.accessToken?.trim();
    _accountId = state.accountId?.trim();
    _apiBaseUrlOverride = state.apiBaseUrlOverride?.trim();
    _useBackend = state.useBackend;

    final expiresAtRaw = state.expiresAtIso?.trim();
    _expiresAt = (expiresAtRaw == null || expiresAtRaw.isEmpty)
        ? null
        : DateTime.tryParse(expiresAtRaw);
  }

  static void applyToken(
    String token, {
    DateTime? expiresAt,
    String? accountId,
  }) {
    _accessToken = token.trim();
    _expiresAt = expiresAt;
    _accountId = accountId?.trim();
    unawaited(_persistCurrentState());
  }

  static void configureConnectionMode({
    required bool useBackend,
    String? apiBaseUrlOverride,
  }) {
    _useBackend = useBackend;
    final normalized = apiBaseUrlOverride?.trim();
    _apiBaseUrlOverride =
        (normalized == null || normalized.isEmpty) ? null : normalized;
    unawaited(_persistCurrentState());
  }

  static void clear() {
    _accessToken = null;
    _expiresAt = null;
    _accountId = null;
    _useBackend = true;
    _apiBaseUrlOverride = null;
    unawaited(_persistence.clear());
  }

  static Future<void> _persistCurrentState() {
    final payload = AuthPersistenceState(
      accessToken: _accessToken,
      expiresAtIso: _expiresAt?.toIso8601String(),
      accountId: _accountId,
      useBackend: _useBackend,
      apiBaseUrlOverride: _apiBaseUrlOverride,
    );
    return _persistence.write(payload);
  }
}
