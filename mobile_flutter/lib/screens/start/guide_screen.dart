import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/krds_tokens.dart';

const List<String> _kGuideFontFallback = <String>[
  'Pretendard GOV',
  'Pretendard',
  'Apple SD Gothic Neo',
  'Noto Sans KR',
];

class GuideScreen extends StatefulWidget {
  const GuideScreen({
    required this.onDone,
    super.key,
  });

  final VoidCallback onDone;

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  static const List<_GuideStepData> _stepDataList = <_GuideStepData>[
    _GuideStepData(
      title: '민원을 한 줄로 접수하세요.',
      subtitle: 'AI가 답변을 시작하고, 입력창에서 바로 접수할 수 있어요.',
    ),
    _GuideStepData(
      title: '미니 인터페이스로 빠르게 선택하세요.',
      subtitle: 'AI 답변 후 입력창 위에 선택형 인터페이스가 나타나요.',
    ),
    _GuideStepData(
      title: '진행 상황을 단계별로 확인하세요.',
      subtitle: '접수 이후 상태를 채팅방 안에서 바로 확인할 수 있어요.',
    ),
  ];

  int _step = 0;
  int _pageEnterVersion = 0;
  double _dragDx = 0;

  @override
  void dispose() {
    super.dispose();
  }

  void _goToStep(int nextStep) {
    if (nextStep < 0 || nextStep >= _stepDataList.length || nextStep == _step) {
      return;
    }
    setState(() {
      _step = nextStep;
      _pageEnterVersion += 1;
    });
  }

  void _handleHorizontalDragStart(DragStartDetails _) {
    _dragDx = 0;
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    _dragDx += details.primaryDelta ?? 0;
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() > 220) {
      if (velocity < 0) {
        _goToStep(_step + 1);
      } else {
        _goToStep(_step - 1);
      }
      return;
    }

    if (_dragDx.abs() > 40) {
      if (_dragDx < 0) {
        _goToStep(_step + 1);
      } else {
        _goToStep(_step - 1);
      }
    }
  }

  Widget _buildStepContent(int index) {
    switch (index) {
      case 0:
        return const _GuideInputDemo();
      case 1:
        return const _GuideMiniInterfaceDemo();
      default:
        return const _GuideStatusFeedDemo();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _step == _stepDataList.length - 1;

    return Container(
      color: const Color(0xFFF3F4F6),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: widget.onDone,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textMuted,
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamilyFallback: _kGuideFontFallback,
                      ),
                    ),
                    child: const Text('건너뛰기'),
                  ),
                ],
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = constraints.maxWidth > 500
                        ? 500.0
                        : constraints.maxWidth;
                    final isCompactHeight = constraints.maxHeight < 720;
                    final contentHeightFactor = isCompactHeight ? 0.92 : 0.89;
                    final minContentHeight = isCompactHeight ? 430.0 : 470.0;
                    final contentHeight =
                        (constraints.maxHeight * contentHeightFactor)
                            .clamp(minContentHeight, 760.0);
                    final contentAlignment = isCompactHeight
                        ? const Alignment(0, 0.08)
                        : const Alignment(0, 0.05);

                    return Align(
                      alignment: contentAlignment,
                      child: SizedBox(
                        width: cardWidth,
                        height: contentHeight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onHorizontalDragStart:
                                    _handleHorizontalDragStart,
                                onHorizontalDragUpdate:
                                    _handleHorizontalDragUpdate,
                                onHorizontalDragEnd: _handleHorizontalDragEnd,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 220),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeInCubic,
                                  transitionBuilder: (child, animation) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
                                  layoutBuilder:
                                      (currentChild, previousChildren) {
                                    return Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        ...previousChildren,
                                        if (currentChild != null) currentChild,
                                      ],
                                    );
                                  },
                                  child: KeyedSubtree(
                                    key: ValueKey<String>(
                                      'guide-step-$_step-$_pageEnterVersion',
                                    ),
                                    child: _GuidePage(
                                      data: _stepDataList[_step],
                                      child: _buildStepContent(_step),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List<Widget>.generate(
                                  _stepDataList.length, (index) {
                                final selected = index == _step;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  width: selected ? 20 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppColors.primary
                                        : AppColors.border,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 14),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: isLast
                                  ? SizedBox(
                                      key: const ValueKey('guide-start-btn'),
                                      height: 52,
                                      child: _GuidePrimaryButton(
                                        label: '시작하기',
                                        compact: true,
                                        onPressed: widget.onDone,
                                      ),
                                    )
                                  : const SizedBox(
                                      key: ValueKey('guide-empty-bottom'),
                                      height: 52,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideStepData {
  const _GuideStepData({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;
}

class _GuidePage extends StatelessWidget {
  const _GuidePage({
    required this.data,
    required this.child,
  });

  final _GuideStepData data;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          data.title,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 22,
            height: 1.35,
            fontWeight: FontWeight.w700,
            fontFamilyFallback: _kGuideFontFallback,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          data.subtitle,
          style: const TextStyle(
            color: AppColors.gray,
            fontSize: 14,
            height: 1.4,
            fontWeight: FontWeight.w500,
            fontFamilyFallback: _kGuideFontFallback,
          ),
        ),
        const SizedBox(height: 14),
        Expanded(child: child),
      ],
    );
  }
}

class _GuideInputDemo extends StatefulWidget {
  const _GuideInputDemo();

  @override
  State<_GuideInputDemo> createState() => _GuideInputDemoState();
}

class _GuideInputDemoState extends State<_GuideInputDemo> {
  static const String _aiSample = '안녕하세요. 어떤 소음이 가장\n불편하신가요?';
  static const String _inputSample = '윗집 소음이 새벽마다 계속돼요.';

  Timer? _timer;
  bool _aiCompleted = false;
  int _inputCount = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 45), (_) {
      if (!mounted || !_aiCompleted) return;
      setState(() {
        if (_inputCount < _inputSample.length) {
          _inputCount += 1;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _handleAiCompleted() {
    if (!mounted || _aiCompleted) return;
    setState(() {
      _aiCompleted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleInput =
        _inputSample.substring(0, _inputCount.clamp(0, _inputSample.length));

    return _GuideChatFrame(
      aiChild: LayoutBuilder(
        builder: (context, constraints) {
          final aiFontSize = constraints.maxWidth < 390 ? 24.0 : 26.0;
          return _GuideAiCharFadeText(
            text: _aiSample,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: aiFontSize,
              height: 1.36,
              fontWeight: FontWeight.w500,
              fontFamilyFallback: _kGuideFontFallback,
            ),
            charStep: const Duration(milliseconds: 40),
            fadeDuration: const Duration(milliseconds: 180),
            onCompleted: _handleAiCompleted,
          );
        },
      ),
      inputBar: _GuidePreviewInputBar(
        previewText: visibleInput,
        placeholder: _aiCompleted ? '답변 입력 또는 음성으로 말하기' : 'AI 답변을 출력하고 있어요.',
        enabled: true,
      ),
    );
  }
}

class _GuideMiniInterfaceDemo extends StatefulWidget {
  const _GuideMiniInterfaceDemo();

  @override
  State<_GuideMiniInterfaceDemo> createState() =>
      _GuideMiniInterfaceDemoState();
}

class _GuideMiniInterfaceDemoState extends State<_GuideMiniInterfaceDemo> {
  static const List<String> _options = <String>['저녁', '심야', '새벽'];

  Timer? _timer;
  int _selected = 0;
  bool _showMini = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 980), (_) {
      if (!mounted || !_showMini) return;
      setState(() {
        _selected = (_selected + 1) % _options.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _handleAiCompleted() {
    if (!mounted || _showMini) return;
    setState(() {
      _showMini = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final aiStyle = TextStyle(
      color: AppColors.primary,
      fontSize: MediaQuery.of(context).size.width < 390 ? 24 : 26,
      height: 1.36,
      fontWeight: FontWeight.w500,
      fontFamilyFallback: _kGuideFontFallback,
    );

    return _GuideChatFrame(
      aiPadding: const EdgeInsets.fromLTRB(24, 84, 24, 206),
      aiChild: _GuideAiCharFadeText(
        text: '소음이 주로 발생하는\n시간대를 선택해 주세요.',
        style: aiStyle,
        charStep: const Duration(milliseconds: 40),
        fadeDuration: const Duration(milliseconds: 180),
        onCompleted: _handleAiCompleted,
      ),
      miniInterface: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: _showMini
            ? _GuideMiniInterfaceCard(
                key: const ValueKey('guide-mini-visible'),
                child: _GuideListPickerWidget(
                  options: _options,
                  selectedIndex: _selected,
                ),
              )
            : const SizedBox.shrink(key: ValueKey('guide-mini-hidden')),
      ),
      inputBar: _GuidePreviewInputBar(
        previewText: '',
        placeholder: _showMini ? '항목을 선택해 주세요.' : 'AI 답변을 출력하고 있어요.',
        enabled: false,
      ),
    );
  }
}

class _GuideStatusFeedDemo extends StatefulWidget {
  const _GuideStatusFeedDemo();

  @override
  State<_GuideStatusFeedDemo> createState() => _GuideStatusFeedDemoState();
}

class _GuideStatusFeedDemoState extends State<_GuideStatusFeedDemo> {
  static const List<String> _labels = <String>[
    '접수 완료',
    '기관 확인 중',
    '담당자 배정',
    '처리 완료',
  ];

  Timer? _timer;
  int _activeIndex = 1;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1100), (_) {
      if (!mounted) return;
      setState(() {
        _activeIndex += 1;
        if (_activeIndex > _labels.length) {
          _activeIndex = 1;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _GuideChatFrame(
      aiChild: const SizedBox.shrink(),
      miniBottom: 92,
      miniInterface: _GuideMiniInterfaceCard(
        maxHeight: 300,
        child: _GuideStatusFeedWidget(
          labels: _labels,
          activeIndex: _activeIndex,
        ),
      ),
      inputBar: const _GuidePreviewInputBar(
        previewText: '',
        placeholder: '진행 상태를 확인해 주세요.',
        enabled: false,
      ),
    );
  }
}

class _GuideChatFrame extends StatelessWidget {
  const _GuideChatFrame({
    required this.aiChild,
    required this.inputBar,
    this.miniInterface,
    this.aiPadding = const EdgeInsets.fromLTRB(24, 104, 24, 110),
    this.miniBottom = 92,
  });

  final Widget aiChild;
  final Widget inputBar;
  final Widget? miniInterface;
  final EdgeInsets aiPadding;
  final double miniBottom;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(KrdsTokens.radiusXl),
        boxShadow: KrdsTokens.elevationPlus1,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: aiPadding,
              child: Align(
                alignment: Alignment.topLeft,
                child: aiChild,
              ),
            ),
          ),
          const Positioned(
            left: 18,
            right: 18,
            top: 16,
            child: _GuideChatTopBar(),
          ),
          if (miniInterface != null)
            Positioned(
              left: 22,
              right: 22,
              bottom: miniBottom,
              child: miniInterface!,
            ),
          Positioned(
            left: 22,
            right: 22,
            bottom: 18,
            child: inputBar,
          ),
        ],
      ),
    );
  }
}

class _GuideChatTopBar extends StatelessWidget {
  const _GuideChatTopBar();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 48,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 36,
              height: 36,
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 24,
                color: AppColors.textMain,
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Text(
              '층간소음 상담',
              style: TextStyle(
                color: AppColors.textMain,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamilyFallback: _kGuideFontFallback,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideMiniInterfaceCard extends StatelessWidget {
  const _GuideMiniInterfaceCard({
    required this.child,
    this.maxHeight = 360,
    super.key,
  });

  final Widget child;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(KrdsTokens.radiusXl),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 15, 18, 15),
      child: child,
    );
  }
}

class _GuidePreviewInputBar extends StatelessWidget {
  const _GuidePreviewInputBar({
    required this.previewText,
    required this.placeholder,
    required this.enabled,
  });

  final String previewText;
  final String placeholder;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final hasText = previewText.trim().isNotEmpty;
    final sendEnabled = enabled && hasText;

    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: enabled ? Colors.white : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(29),
        border: Border.all(color: const Color(0xFFE5EEF5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              hasText ? previewText : placeholder,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color:
                    hasText ? const Color(0xFF334155) : const Color(0xFF9CA3AF),
                fontSize: 15,
                fontWeight: FontWeight.w500,
                fontFamilyFallback: _kGuideFontFallback,
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: sendEnabled ? AppColors.primary : const Color(0xFFCFE0EC),
            ),
            child: const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideListPickerWidget extends StatelessWidget {
  const _GuideListPickerWidget({
    required this.options,
    required this.selectedIndex,
  });

  final List<String> options;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '단일 선택',
          style: TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 12,
            height: 16 / 12,
            fontWeight: FontWeight.w500,
            fontFamilyFallback: _kGuideFontFallback,
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < options.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == options.length - 1 ? 0 : 12),
            child: _GuideListPickerOptionButton(
              label: options[i],
              selected: i == selectedIndex,
            ),
          ),
        const SizedBox(height: 12),
        const _GuidePrimaryButton(
          label: '선택 완료',
          compact: true,
        ),
      ],
    );
  }
}

class _GuideListPickerOptionButton extends StatelessWidget {
  const _GuideListPickerOptionButton({
    required this.label,
    required this.selected,
  });

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      height: selected ? 61 : 58,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFF0F7FF) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? AppColors.primary : const Color(0xFFF3F4F6),
          width: selected ? 1.4 : 1,
        ),
        boxShadow: selected
            ? const [
                BoxShadow(
                  color: Color(0x18305A78),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ]
            : const [
                BoxShadow(
                  color: Color(0x0E000000),
                  blurRadius: 2,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: selected ? AppColors.primary : const Color(0xFF1F2937),
          fontSize: selected ? 16.8 : 16,
          height: 24 / 16,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          fontFamilyFallback: _kGuideFontFallback,
        ),
      ),
    );
  }
}

class _GuideStatusFeedWidget extends StatelessWidget {
  const _GuideStatusFeedWidget({
    required this.labels,
    required this.activeIndex,
  });

  final List<String> labels;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '현재 상태',
          style: TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 12,
            height: 16 / 12,
            fontWeight: FontWeight.w500,
            fontFamilyFallback: _kGuideFontFallback,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Expanded(
              child: Text(
                '접수 확인 단계',
                style: TextStyle(
                  color: AppColors.textMain,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFamilyFallback: _kGuideFontFallback,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F1FF),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                '진행중',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  fontFamilyFallback: _kGuideFontFallback,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          '진행 상태',
          style: TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 12,
            height: 16 / 12,
            fontWeight: FontWeight.w500,
            fontFamilyFallback: _kGuideFontFallback,
          ),
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 150),
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (var i = 0; i < labels.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                        bottom: i == labels.length - 1 ? 0 : 10),
                    child: _GuideStatusTimelineItem(
                      title: labels[i],
                      state: i < activeIndex
                          ? _GuideStatusState.done
                          : i == activeIndex
                              ? _GuideStatusState.active
                              : _GuideStatusState.pending,
                      isLast: i == labels.length - 1,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Row(
          children: [
            Expanded(
              child: _GuideFilterChip(
                label: '중요 업데이트만',
                selected: true,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _GuideFilterChip(
                label: '단계별 모두',
                selected: false,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

enum _GuideStatusState { done, active, pending }

class _GuideStatusTimelineItem extends StatelessWidget {
  const _GuideStatusTimelineItem({
    required this.title,
    required this.state,
    required this.isLast,
  });

  final String title;
  final _GuideStatusState state;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final nodeBg = switch (state) {
      _GuideStatusState.done => AppColors.primary,
      _GuideStatusState.active => const Color(0xFFEAF4FF),
      _GuideStatusState.pending => Colors.white,
    };
    final nodeBorder = switch (state) {
      _GuideStatusState.done => AppColors.primary,
      _GuideStatusState.active => const Color(0xFFB9D8F7),
      _GuideStatusState.pending => AppColors.border,
    };
    final nodeIcon = switch (state) {
      _GuideStatusState.done => Icons.check_rounded,
      _GuideStatusState.active => Icons.schedule_rounded,
      _GuideStatusState.pending => Icons.radio_button_unchecked_rounded,
    };
    final nodeIconColor = switch (state) {
      _GuideStatusState.done => Colors.white,
      _GuideStatusState.active => AppColors.primary,
      _GuideStatusState.pending => const Color(0xFF94A3B8),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: nodeBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: nodeBorder),
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    child: Icon(
                      nodeIcon,
                      key: ValueKey<String>('status-icon-${state.name}'),
                      size: 12,
                      color: nodeIconColor,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  width: 2,
                  height: 26,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(
              title,
              style: TextStyle(
                color: state == _GuideStatusState.pending
                    ? const Color(0xFF64748B)
                    : AppColors.textMain,
                fontSize: 14,
                fontWeight: state == _GuideStatusState.pending
                    ? FontWeight.w500
                    : FontWeight.w700,
                fontFamilyFallback: _kGuideFontFallback,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GuideFilterChip extends StatelessWidget {
  const _GuideFilterChip({
    required this.label,
    required this.selected,
  });

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEAF4FF) : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected ? const Color(0xFFB9D8F7) : AppColors.border,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? AppColors.primary : AppColors.textMuted,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          fontFamilyFallback: _kGuideFontFallback,
        ),
      ),
    );
  }
}

class _GuidePrimaryButton extends StatefulWidget {
  const _GuidePrimaryButton({
    required this.label,
    this.compact = false,
    this.onPressed,
  });

  final String label;
  final bool compact;
  final VoidCallback? onPressed;

  @override
  State<_GuidePrimaryButton> createState() => _GuidePrimaryButtonState();
}

class _GuidePrimaryButtonState extends State<_GuidePrimaryButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onPressed == null) return;
    if (_pressed == value) return;
    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.compact ? 52.0 : 60.0;
    final radius = widget.compact ? 16.0 : 20.0;

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        scale: _pressed ? 0.987 : 1,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          offset: _pressed ? const Offset(0, 0.02) : Offset.zero,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              color: _pressed ? AppColors.primaryDeep : AppColors.primary,
              boxShadow: _pressed
                  ? const [
                      BoxShadow(
                        color: Color(0x24234A64),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ]
                  : const [
                      BoxShadow(
                        color: Color(0x33234A64),
                        blurRadius: 2,
                        offset: Offset(0, 4),
                      ),
                    ],
            ),
            alignment: Alignment.center,
            child: Text(
              widget.label,
              style: TextStyle(
                color: Colors.white,
                fontSize: widget.compact ? 20 : 22,
                fontWeight: FontWeight.w700,
                fontFamilyFallback: _kGuideFontFallback,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GuideAiCharFadeText extends StatefulWidget {
  const _GuideAiCharFadeText({
    required this.text,
    required this.style,
    required this.charStep,
    required this.fadeDuration,
    this.onCompleted,
  });

  final String text;
  final TextStyle style;
  final Duration charStep;
  final Duration fadeDuration;
  final VoidCallback? onCompleted;

  @override
  State<_GuideAiCharFadeText> createState() => _GuideAiCharFadeTextState();
}

class _GuideAiCharFadeTextState extends State<_GuideAiCharFadeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _completionNotified = false;

  List<String> _chunks = const [];
  int _totalMs = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.fadeDuration,
    )
      ..addListener(() {
        if (mounted) {
          setState(() {});
        }
      })
      ..addStatusListener(_handleStatusChanged);

    _restartCharFade();
  }

  @override
  void didUpdateWidget(covariant _GuideAiCharFadeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.charStep != widget.charStep ||
        oldWidget.fadeDuration != widget.fadeDuration) {
      _restartCharFade();
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_handleStatusChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _notifyCompleted();
    }
  }

  void _notifyCompleted() {
    if (_completionNotified) return;
    _completionNotified = true;
    final callback = widget.onCompleted;
    if (callback == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      callback();
    });
  }

  List<String> _splitCharChunks(String text) {
    return text.runes.map(String.fromCharCode).toList(growable: false);
  }

  void _restartCharFade() {
    _chunks = _splitCharChunks(widget.text);
    final stepMs = widget.charStep.inMilliseconds;
    final fadeMs = widget.fadeDuration.inMilliseconds;
    _completionNotified = false;

    _totalMs = _chunks.isEmpty ? 0 : ((_chunks.length - 1) * stepMs) + fadeMs;

    _controller.stop();
    _controller.value = 0;

    if (_totalMs <= 0) {
      _notifyCompleted();
      return;
    }

    _controller.duration = Duration(milliseconds: _totalMs);
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.style.color ?? AppColors.primary;
    final elapsedMs = _totalMs * _controller.value;
    final stepMs = widget.charStep.inMilliseconds.toDouble();
    final fadeMs = widget.fadeDuration.inMilliseconds.toDouble();

    final spans = <InlineSpan>[];
    for (var i = 0; i < _chunks.length; i++) {
      final startMs = i * stepMs;
      final alpha = ((elapsedMs - startMs) / fadeMs).clamp(0.0, 1.0);
      spans.add(
        TextSpan(
          text: _chunks[i],
          style: widget.style.copyWith(
            color: baseColor.withValues(alpha: alpha),
          ),
        ),
      );
    }

    return Text.rich(
      TextSpan(
        style: widget.style,
        children: spans,
      ),
    );
  }
}
