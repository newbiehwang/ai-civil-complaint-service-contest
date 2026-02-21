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
      child: LayoutBuilder(
        builder: (context, constraints) {
          const designWidth = 390.0;
          const designHeight = 884.0;
          const heroTopY = 270.0;
          const titleTopY = 381.0;
          const buttonTopY = 677.695;
          const captionTopY = 753.695;
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          double sx(double x) => x * (w / designWidth);
          double sy(double y) => y * (h / designHeight);

          final buttonWidth = sx(310);
          final buttonHeight = sx(60);
          final logoSize = sx(88);
          final titleWidth = sx(247.68);

          return Stack(
            children: [
              Positioned(
                left: (w - logoSize) / 2,
                top: sy(heroTopY),
                width: logoSize,
                height: logoSize,
                child: Image.asset(
                  'assets/korea_gov24.transparent.png',
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                left: (w - titleWidth) / 2,
                top: sy(titleTopY),
                width: titleWidth,
                child: const Text(
                  '본인 확인 후 민원 신청을\n이어서 진행합니다.',
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
                left: (w - buttonWidth) / 2,
                top: sy(buttonTopY),
                width: buttonWidth,
                child: StartPrimaryButton(
                  label: '정부24에서 계속',
                  onPressed: onContinue,
                  width: buttonWidth,
                  height: buttonHeight,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: sy(captionTopY),
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
