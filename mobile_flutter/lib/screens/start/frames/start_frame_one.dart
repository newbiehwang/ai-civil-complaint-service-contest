import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../widgets/start_frame_layout.dart';
import '../widgets/start_primary_button.dart';

class StartFrameOne extends StatelessWidget {
  const StartFrameOne({
    required this.showTitle,
    required this.showButton,
    required this.onStart,
    super.key,
  });

  final bool showTitle;
  final bool showButton;
  final VoidCallback onStart;

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
              width: 128,
              height: 168,
              fit: BoxFit.contain,
            ),
          ),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 420),
            opacity: showTitle ? 1 : 0,
            child: const Text(
              '신속한 처리, 정부 24',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                height: 1.62,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          const Spacer(flex: 2),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 380),
            opacity: showButton ? 1 : 0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 380),
              offset: showButton ? Offset.zero : const Offset(0, 0.03),
              curve: Curves.easeOutCubic,
              child: StartPrimaryButton(
                label: '시작하기',
                onPressed: onStart,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            '평균 2분 · 언제든 중단 후 이어하기 가능',
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
