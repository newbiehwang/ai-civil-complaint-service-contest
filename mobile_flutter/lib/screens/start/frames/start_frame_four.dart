import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../widgets/start_frame_layout.dart';
import '../widgets/start_primary_button.dart';

class StartFrameFour extends StatefulWidget {
  const StartFrameFour({required this.onContinue, super.key});

  final VoidCallback onContinue;

  @override
  State<StartFrameFour> createState() => _StartFrameFourState();
}

class _StartFrameFourState extends State<StartFrameFour>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    return StartFrameLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 2),
          const Text(
            '본인 확인이\n완료되었습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 24,
              height: 1.62,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          ScaleTransition(
            scale: scale,
            child: const Center(
              child: CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary,
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
          ),
          const Spacer(flex: 2),
          StartPrimaryButton(label: '계속하기', onPressed: widget.onContinue),
          const SizedBox(height: 16),
          const Text(
            '민원 신고를 계속 진행합니다.',
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
