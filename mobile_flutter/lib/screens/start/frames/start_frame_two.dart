import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../widgets/start_frame_layout.dart';
import '../widgets/start_primary_button.dart';

class StartFrameTwo extends StatelessWidget {
  const StartFrameTwo({required this.onContinue, super.key});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return StartFrameLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 2),
          Center(
            child: Image.asset(
              'assets/korea_gov24.transparent.png',
              width: 124,
              height: 124,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            '본인 확인 후 민원 신청을\n이어서 진행합니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 24,
              height: 1.62,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(flex: 2),
          StartPrimaryButton(
            label: '정부24에서 계속',
            onPressed: onContinue,
          ),
          const SizedBox(height: 16),
          const Text(
            '소요 1~2분 · 암호화된 안전한 인증',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              height: 1.33,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(flex: 1),
        ],
      ),
    );
  }
}
