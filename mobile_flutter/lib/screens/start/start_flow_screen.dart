import 'dart:async';

import 'package:flutter/material.dart';

import 'frames/start_frame_four.dart';
import 'frames/start_frame_one.dart';
import 'frames/start_frame_three.dart';
import 'frames/start_frame_two.dart';

enum StartFlowPhase { frame1, frame2, frame3, frame4 }

class StartFlowScreen extends StatefulWidget {
  const StartFlowScreen({required this.onCompleted, super.key});

  final VoidCallback onCompleted;

  @override
  State<StartFlowScreen> createState() => _StartFlowScreenState();
}

class _StartFlowScreenState extends State<StartFlowScreen> {
  StartFlowPhase _phase = StartFlowPhase.frame1;
  bool _showStartTitle = false;
  bool _showStartButton = false;
  final List<Timer> _timers = [];

  @override
  void initState() {
    super.initState();
    _playFrameOneReveal();
  }

  @override
  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    super.dispose();
  }

  void _playFrameOneReveal() {
    _showStartTitle = false;
    _showStartButton = false;

    _timers.add(
      Timer(const Duration(milliseconds: 280), () {
        if (!mounted || _phase != StartFlowPhase.frame1) return;
        setState(() {
          _showStartTitle = true;
        });
      }),
    );

    _timers.add(
      Timer(const Duration(milliseconds: 740), () {
        if (!mounted || _phase != StartFlowPhase.frame1) return;
        setState(() {
          _showStartButton = true;
        });
      }),
    );
  }

  void _goToFrame2() {
    setState(() {
      _phase = StartFlowPhase.frame2;
    });
  }

  void _goToFrame3() {
    setState(() {
      _phase = StartFlowPhase.frame3;
    });

    _timers.add(
      Timer(const Duration(milliseconds: 2200), () {
        if (!mounted || _phase != StartFlowPhase.frame3) return;
        setState(() {
          _phase = StartFlowPhase.frame4;
        });
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = switch (_phase) {
      StartFlowPhase.frame1 => StartFrameOne(
          showTitle: _showStartTitle,
          showButton: _showStartButton,
          onStart: _goToFrame2,
        ),
      StartFlowPhase.frame2 => StartFrameTwo(onContinue: _goToFrame3),
      StartFlowPhase.frame3 => const StartFrameThree(),
      StartFlowPhase.frame4 => StartFrameFour(onContinue: widget.onCompleted),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: KeyedSubtree(
        key: ValueKey(_phase.name),
        child: content,
      ),
    );
  }
}
