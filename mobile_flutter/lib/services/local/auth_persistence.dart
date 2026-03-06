import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthPersistenceState {
  const AuthPersistenceState({
    required this.accessToken,
    required this.expiresAtIso,
    required this.accountId,
    required this.profile,
    required this.useBackend,
    required this.apiBaseUrlOverride,
  });

  final String? accessToken;
  final String? expiresAtIso;
  final String? accountId;
  final Map<String, Object?>? profile;
  final bool useBackend;
  final String? apiBaseUrlOverride;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'accessToken': accessToken,
      'expiresAtIso': expiresAtIso,
      'accountId': accountId,
      'profile': profile,
      'useBackend': useBackend,
      'apiBaseUrlOverride': apiBaseUrlOverride,
    };
  }

  factory AuthPersistenceState.fromJson(Map<String, Object?> json) {
    final useBackendRaw = json['useBackend'];
    final useBackend = useBackendRaw is bool
        ? useBackendRaw
        : useBackendRaw?.toString().toLowerCase() == 'true';

    return AuthPersistenceState(
      accessToken: json['accessToken']?.toString(),
      expiresAtIso: json['expiresAtIso']?.toString(),
      accountId: json['accountId']?.toString(),
      profile: json['profile'] is Map<String, Object?>
          ? (json['profile'] as Map<String, Object?>)
          : null,
      useBackend: useBackend,
      apiBaseUrlOverride: json['apiBaseUrlOverride']?.toString(),
    );
  }
}

class AuthPersistence {
  AuthPersistence({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _storageKey = 'app.v1.auth_state';
  final FlutterSecureStorage _storage;

  Future<AuthPersistenceState?> read() async {
    try {
      final raw = await _storage.read(key: _storageKey);
      if (raw == null || raw.trim().isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return AuthPersistenceState.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(AuthPersistenceState state) async {
    try {
      final raw = jsonEncode(state.toJson());
      await _storage.write(key: _storageKey, value: raw);
    } catch (_) {
      // Ignore persistence failures to avoid blocking login flows.
    }
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _storageKey);
    } catch (_) {
      // Ignore cleanup failures.
    }
  }
}
