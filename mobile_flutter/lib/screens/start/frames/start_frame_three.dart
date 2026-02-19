import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../widgets/start_frame_layout.dart';

class StartFrameThree extends StatelessWidget {
  const StartFrameThree({super.key});

  @override
  Widget build(BuildContext context) {
    return StartFrameLayout(
      child: LayoutBuilder(
        builder: (context, constraints) {
          const designWidth = 390.0;
          const designHeight = 884.0;
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          double sx(double x) => x * (w / designWidth);
          double sy(double y) => y * (h / designHeight);

          final spinnerSize = sx(56);
          final titleWidth = sx(147.04);

          return Stack(
            children: [
              Positioned(
                left: (w - spinnerSize) / 2,
                top: sy(303),
                width: spinnerSize,
                height: spinnerSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.18),
                ),
              ),
              Positioned(
                left: (w - titleWidth) / 2,
                top: sy(381),
                width: titleWidth,
                child: const Text(
                  '본인 확인\n진행 중입니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 24,
                    height: 39 / 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: sy(753.695),
                child: const Text(
                  '소요 1~2분 · 암호화된 안전한 인증',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    height: 16 / 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
