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
  final TextEditingController _usernameController =
      TextEditingController(text: 'demo');
  final TextEditingController _passwordController =
      TextEditingController(text: '1234');
  final TextEditingController _serverIpController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorText;
  _LoginMode _mode = _LoginMode.server;

  bool get _isServerMode => _mode == _LoginMode.server;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _serverIpController.dispose();
    super.dispose();
  }

  String? _normalizeServerBaseUrl(String raw) {
    var value = raw.trim();
    if (value.isEmpty) return null;

    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      value = 'http://$value';
    }
    if (RegExp(r'^https?://[^/:]+$').hasMatch(value)) {
      value = '$value:8080';
    }

    final uri = Uri.tryParse(value);
    if (uri == null || uri.host.trim().isEmpty) {
      return null;
    }
    return value.replaceAll(RegExp(r'/+$'), '');
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorText = '아이디와 비밀번호를 입력해 주세요.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      if (_mode == _LoginMode.local) {
        AuthSession.configureConnectionMode(
          useBackend: false,
          apiBaseUrlOverride: null,
        );
        AuthSession.applyToken(
          'local-demo-token',
          accountId: username,
        );
      } else {
        final inputBaseUrl = _normalizeServerBaseUrl(_serverIpController.text);
        if (_serverIpController.text.trim().isNotEmpty &&
            inputBaseUrl == null) {
          throw ApiClientError(
            code: 'INVALID_BASE_URL',
            message: '서버 IP 형식이 올바르지 않습니다. 예: 172.30.1.22:8080',
          );
        }

        final apiClient = ApiClient(
          baseUrl: inputBaseUrl ?? AppEnv.apiBaseUrl,
          useBackend: true,
        );
        final traceId = apiClient.createTraceId(prefix: 'demo-login');
        final response = await apiClient.demoLogin(
          traceId: traceId,
          username: username,
          password: password,
        );
        AuthSession.configureConnectionMode(
          useBackend: true,
          apiBaseUrlOverride: inputBaseUrl,
        );
        AuthSession.applyToken(
          response.accessToken,
          expiresAt: response.expiresAt,
          accountId: username,
        );
      }

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
          '정부24 데모 로그인',
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
                      '본인확인을 진행합니다.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ModeSelector(
                      mode: _mode,
                      enabled: !_isSubmitting,
                      onChanged: (next) {
                        if (_mode == next) return;
                        setState(() {
                          _mode = next;
                          _errorText = null;
                        });
                      },
                    ),
                    if (_isServerMode) ...[
                      const SizedBox(height: 10),
                      _LabeledField(
                        label: '서버 IP (선택)',
                        hintText: '비워두면 .env 값을 사용해요 (예: 172.30.1.22:8080)',
                        controller: _serverIpController,
                        enabled: !_isSubmitting,
                        textInputAction: TextInputAction.next,
                      ),
                    ],
                    const SizedBox(height: 14),
                    _LabeledField(
                      label: '아이디',
                      controller: _usernameController,
                      enabled: !_isSubmitting,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 10),
                    _LabeledField(
                      label: '비밀번호',
                      controller: _passwordController,
                      enabled: !_isSubmitting,
                      obscureText: true,
                      onSubmitted: (_) => _submit(),
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
                                '로그인하고 계속',
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

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    required this.enabled,
    this.hintText,
    this.obscureText = false,
    this.textInputAction,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
  final String? hintText;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          obscureText: obscureText,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          style: const TextStyle(
            color: AppColors.textMain,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: true,
            fillColor: const Color(0xFFF9FBFD),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}

enum _LoginMode { local, server }

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({
    required this.mode,
    required this.enabled,
    required this.onChanged,
  });

  final _LoginMode mode;
  final bool enabled;
  final ValueChanged<_LoginMode> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget buildChip({
      required _LoginMode value,
      required String label,
    }) {
      final selected = mode == value;
      return Expanded(
        child: GestureDetector(
          onTap: enabled ? () => onChanged(value) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        buildChip(value: _LoginMode.local, label: '로컬'),
        const SizedBox(width: 8),
        buildChip(value: _LoginMode.server, label: '서버'),
      ],
    );
  }
}
