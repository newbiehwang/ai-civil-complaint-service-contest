import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../widgets/start_frame_layout.dart';

class StartFrameThree extends StatelessWidget {
  const StartFrameThree({super.key});

  @override
  Widget build(BuildContext context) {
    return StartFrameLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 2),
          Center(
            child: SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                backgroundColor: AppColors.primary.withValues(alpha: 0.18),
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            '본인 확인\n진행 중입니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 24,
              height: 1.62,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(flex: 2),
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
