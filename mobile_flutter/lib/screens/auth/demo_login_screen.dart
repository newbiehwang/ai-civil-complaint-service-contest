import 'package:flutter/material.dart';

import '../../config/app_env.dart';
import '../../services/api_client.dart';
import '../../services/auth_session.dart';
import '../../services/error_map.dart';
import '../../theme/app_colors.dart';

class DemoLoginScreen extends StatefulWidget {
  const DemoLoginScreen({super.key});

  @override
  State<DemoLoginScreen> createState() => _DemoLoginScreenState();
}

class _DemoLoginScreenState extends State<DemoLoginScreen> {
  bool _isSubmitting = false;
  String? _errorText;

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final username = AppEnv.demoLoginUsername.trim();
    final password = AppEnv.demoLoginPassword.trim();
    final baseUrl = AppEnv.apiBaseUrl.trim();

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      if (baseUrl.isEmpty) {
        throw ApiClientError(
          code: 'ENV_MISSING',
          message: AppEnv.missingReason ?? 'API_BASE_URL이 비어 있습니다.',
        );
      }
      if (!AppEnv.isDemoLoginConfigured) {
        throw ApiClientError(
          code: 'ENV_MISSING',
          message: AppEnv.missingDemoLoginReason ??
              'DEMO_LOGIN_USERNAME / DEMO_LOGIN_PASSWORD가 비어 있습니다.',
        );
      }

      final apiClient = ApiClient(baseUrl: baseUrl, useBackend: true);
      final traceId = apiClient.createTraceId(prefix: 'demo-login');
      final response = await apiClient.demoLogin(
        traceId: traceId,
        username: username,
        password: password,
      );

      AuthSession.configureConnectionMode(
        useBackend: true,
        apiBaseUrlOverride: null,
      );
      AuthSession.applyToken(
        response.accessToken,
        expiresAt: response.expiresAt,
        accountId: username,
        profile: response.profile == null
            ? null
            : AuthUserProfile(
                name: response.profile!.name,
                phone: response.profile!.phone,
                email: response.profile!.email,
                housingName: response.profile!.housingName,
                address: response.profile!.address,
              ),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (error is ApiClientError) {
        debugPrint(
          '[demo-login-error] ${error.toString()} details=${error.details.join(' || ')}',
        );
      } else {
        debugPrint('[demo-login-error] type=${error.runtimeType} value=$error');
      }
      if (!mounted) return;
      setState(() {
        _errorText = toKoreanErrorMessage(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '정부24 로그인',
          style: TextStyle(
            color: AppColors.textMain,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textMain),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x17305A78),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '데모 로그인',
                      style: TextStyle(
                        color: AppColors.textMain,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '아래 버튼을 누르면 .env에 설정된 데모 계정으로\n서버 인증을 진행합니다.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '서버: ${AppEnv.apiBaseUrl.isEmpty ? '(미설정)' : AppEnv.apiBaseUrl}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '계정: ${AppEnv.demoLoginUsername.isEmpty ? '(미설정)' : AppEnv.demoLoginUsername}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_errorText != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _errorText!,
                        style: const TextStyle(
                          color: Color(0xFFCC2E2E),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text(
                                '데모 로그인',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
