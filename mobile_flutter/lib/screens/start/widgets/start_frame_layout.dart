import 'package:flutter/material.dart';

class StartFrameLayout extends StatelessWidget {
  const StartFrameLayout({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final frameWidth = constraints.maxWidth < 390 ? constraints.maxWidth : 390.0;

        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: frameWidth,
            height: constraints.maxHeight,
            child: child,
          ),
        );
      },
    );
  }
}
