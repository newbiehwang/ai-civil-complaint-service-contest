import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../widgets/start_frame_layout.dart';
import '../widgets/start_primary_button.dart';

class StartFrameOne extends StatelessWidget {
  const StartFrameOne({
    required this.showLogo,
    required this.showTitle,
    required this.showButton,
    required this.onStart,
    super.key,
  });

  final bool showLogo;
  final bool showTitle;
  final bool showButton;
  final VoidCallback onStart;

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

          final logoSize = sx(88);
          final titleWidth = sx(248);
          final buttonWidth = sx(310);
          final buttonHeight = sx(60);

          return Stack(
            children: [
              Positioned(
                left: (w - logoSize) / 2,
                top: sy(heroTopY),
                width: logoSize,
                height: logoSize,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 520),
                  curve: Curves.easeOutCubic,
                  opacity: showLogo ? 1 : 0,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 520),
                    curve: Curves.easeOutCubic,
                    offset: showLogo ? Offset.zero : const Offset(0, 0.02),
                    child: Image.asset(
                      'assets/korea_gov24.transparent.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: (w - titleWidth) / 2,
                top: sy(titleTopY),
                width: titleWidth,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 520),
                  curve: Curves.easeOutCubic,
                  opacity: showTitle ? 1 : 0,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 520),
                    curve: Curves.easeOutCubic,
                    offset: showTitle ? Offset.zero : const Offset(0, 0.02),
                    child: const Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '신속한 처리,\n',
                            style: TextStyle(
                              fontSize: 22,
                              height: 1.4,
                              fontWeight: FontWeight.w400,
                              letterSpacing: -0.3,
                              color: Color(0xFF2D5D7B),
                            ),
                          ),
                          TextSpan(
                            text: '정부24',
                            style: TextStyle(
                              fontSize: 34,
                              height: 1.25,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.6,
                              color: Color(0xFF2D5D7B),
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: (w - buttonWidth) / 2,
                top: sy(buttonTopY),
                width: buttonWidth,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 560),
                  opacity: showButton ? 1 : 0,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 560),
                    offset: showButton ? Offset.zero : const Offset(0, 0.03),
                    curve: Curves.easeOutCubic,
                    child: StartPrimaryButton(
                      label: '시작하기',
                      onPressed: onStart,
                      width: buttonWidth,
                      height: buttonHeight,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: sy(captionTopY),
                child: const Text(
                  '평균 2분 · 언제든 중단 후 이어하기 가능',
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
