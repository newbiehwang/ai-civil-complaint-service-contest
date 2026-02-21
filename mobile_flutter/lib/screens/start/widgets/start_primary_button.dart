import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/krds_tokens.dart';

class StartPrimaryButton extends StatefulWidget {
  const StartPrimaryButton({
    required this.label,
    required this.onPressed,
    this.width = 310,
    this.height = 60,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final double width;
  final double height;

  @override
  State<StartPrimaryButton> createState() => _StartPrimaryButtonState();
}

class _StartPrimaryButtonState extends State<StartPrimaryButton> {
  bool _isPressed = false;

  bool get _isEnabled => widget.onPressed != null;

  void _setPressed(bool value) {
    if (!_isEnabled) return;
    if (_isPressed == value) return;
    setState(() {
      _isPressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = _isEnabled ? AppColors.primary : const Color(0xFFE6EBF0);
    final pressedColor = _isEnabled ? AppColors.primaryDeep : const Color(0xFFE6EBF0);

    return Center(
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: GestureDetector(
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          onTap: widget.onPressed,
          child: AnimatedScale(
            scale: _isPressed ? 0.987 : 1,
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOut,
            child: AnimatedSlide(
              offset: _isPressed ? const Offset(0, 0.02) : Offset.zero,
              duration: const Duration(milliseconds: 90),
              curve: Curves.easeOut,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(KrdsTokens.radiusXl),
                  color: _isPressed ? pressedColor : baseColor,
                  boxShadow: _isPressed
                      ? const [
                          BoxShadow(
                            color: Color(0x18000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ]
                      : const [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
