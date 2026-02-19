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
      child: LayoutBuilder(
        builder: (context, constraints) {
          const designWidth = 390.0;
          const designHeight = 884.0;
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          double sx(double x) => x * (w / designWidth);
          double sy(double y) => y * (h / designHeight);

          final iconSize = sx(56);
          final titleWidth = sx(162.39);
          final buttonWidth = sx(310);
          final buttonHeight = sx(60);

          return Stack(
            children: [
              Positioned(
                left: (w - iconSize) / 2,
                top: sy(287),
                width: iconSize,
                height: iconSize,
                child: ScaleTransition(
                  scale: scale,
                  child: CircleAvatar(
                    radius: iconSize / 2,
                    backgroundColor: AppColors.primary,
                    child: Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: sx(36),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: (w - titleWidth) / 2,
                top: sy(381),
                width: titleWidth,
                child: const Text(
                  '본인 확인이\n완료되었습니다.',
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
                top: sy(677.695),
                width: buttonWidth,
                child: StartPrimaryButton(
                  label: '계속하기',
                  onPressed: widget.onContinue,
                  width: buttonWidth,
                  height: buttonHeight,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: sy(753.695),
                child: const Text(
                  '민원 신고를 계속 진행합니다.',
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
