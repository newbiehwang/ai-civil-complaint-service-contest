import 'package:flutter/material.dart';

import '../../models/chat_session_summary.dart';
import '../../theme/app_colors.dart';
import '../../theme/krds_tokens.dart';

enum ChatListFilter {
  all,
  inProgress,
  completed,
}

extension on ChatListFilter {
  String get label {
    switch (this) {
      case ChatListFilter.all:
        return '전체';
      case ChatListFilter.inProgress:
        return '진행중';
      case ChatListFilter.completed:
        return '완료';
    }
  }
}

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({
    required this.sessions,
    required this.onOpenSession,
    required this.onCreateSession,
    super.key,
  });

  final List<ChatSessionSummary> sessions;
  final ValueChanged<String> onOpenSession;
  final VoidCallback onCreateSession;

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  ChatListFilter _filter = ChatListFilter.all;

  List<ChatSessionSummary> get _visibleSessions {
    switch (_filter) {
      case ChatListFilter.all:
        return widget.sessions;
      case ChatListFilter.inProgress:
        return widget.sessions
            .where((session) => session.status != ChatSessionStatus.completed)
            .toList(growable: false);
      case ChatListFilter.completed:
        return widget.sessions
            .where((session) => session.status == ChatSessionStatus.completed)
            .toList(growable: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessions = _visibleSessions;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 36, 20, 34),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(
                        selected: _filter,
                        onSelected: (filter) =>
                            setState(() => _filter = filter),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: sessions.isEmpty
                            ? _EmptyState(
                                filter: _filter,
                                onCreateSession: widget.onCreateSession)
                            : ListView.separated(
                                padding: const EdgeInsets.only(bottom: 110),
                                itemCount: sessions.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 24),
                                itemBuilder: (context, index) {
                                  final session = sessions[index];
                                  return _SessionCard(
                                    session: session,
                                    onTap: () =>
                                        widget.onOpenSession(session.sessionId),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 24,
                  bottom: 40,
                  child: _FloatingCreateButton(
                    onTap: widget.onCreateSession,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.selected,
    required this.onSelected,
  });

  final ChatListFilter selected;
  final ValueChanged<ChatListFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Expanded(
              child: Text(
                '민원 목록',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 30,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.75,
                ),
              ),
            ),
            Row(
              children: ChatListFilter.values
                  .map(
                    (filter) => Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: _FilterChipButton(
                        label: filter.label,
                        selected: selected == filter,
                        onTap: () => onSelected(filter),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          '진행 중인 민원을 실시간으로 관리하세요.',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _FilterChipButton extends StatefulWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_FilterChipButton> createState() => _FilterChipButtonState();
}

class _FilterChipButtonState extends State<_FilterChipButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: InkWell(
        onTap: widget.onTap,
        onHighlightChanged: (value) {
          if (!mounted) return;
          setState(() => _pressed = value);
        },
        borderRadius: BorderRadius.circular(KrdsTokens.radiusXl),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color:
                widget.selected ? AppColors.primary : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(KrdsTokens.radiusXl),
            boxShadow: widget.selected
                ? const [
                    BoxShadow(
                      color: Color(0x33305D7B),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ]
                : const [],
          ),
          alignment: Alignment.center,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            style: TextStyle(
              color: widget.selected ? Colors.white : const Color(0xFF94A3B8),
              fontSize: 12,
              height: 16 / 12,
              fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w400,
            ),
            child: Text(widget.label),
          ),
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.onTap,
  });

  final ChatSessionSummary session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final completed = session.status == ChatSessionStatus.completed;
    final metaColor = completed ? const Color(0xFF686868) : AppColors.secondary;
    final timeLabel = _formatUpdatedAt(session.updatedAt);
    final stepIndex = _stepIndexForSession(session);

    return Material(
      color: Colors.white,
      elevation: completed ? 1.5 : 2.5,
      shadowColor: const Color(0x22000000),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KrdsTokens.radiusXl),
        side: const BorderSide(color: Color(0xFFEEF2F7)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(KrdsTokens.radiusXl),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: metaColor,
                                borderRadius: BorderRadius.circular(9999),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              completed ? '완료' : '진행 중',
                              style: TextStyle(
                                color: metaColor,
                                fontSize: 12,
                                height: 15 / 12,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          session.title.isEmpty ? '층간소음 민원 상담' : session.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: completed
                                ? const Color(0xFF686868)
                                : const Color(0xFF2D5D7B),
                            fontSize: completed ? 18 : 20,
                            height: completed ? 28 / 18 : 25 / 20,
                            fontWeight:
                                completed ? FontWeight.w500 : FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      timeLabel,
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 12,
                        height: 16 / 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _ProgressStrip(
                stepIndex: stepIndex,
                completed: completed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip({
    required this.stepIndex,
    required this.completed,
  });

  final int stepIndex;
  final bool completed;

  static const _labels = <String>['접수', '진행', '현장확인', '종료'];
  static const _icons = <IconData>[
    Icons.assignment_turned_in_outlined,
    Icons.forum_outlined,
    Icons.home_repair_service_outlined,
    Icons.flag_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final activeColor = completed ? const Color(0xFF686868) : AppColors.primary;
    final inactiveDotBg =
        completed ? const Color(0xFF686868) : const Color(0xFFF3F4F6);
    final inactiveDotBorder =
        completed ? const Color(0xFF686868) : const Color(0xFFE5E7EB);
    final trackColor =
        completed ? const Color(0xFFE5E7EB) : const Color(0xFFF3F4F6);
    final fillFactor = (stepIndex + 1) / 4;

    return Column(
      children: [
        SizedBox(
          height: 67,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 8,
                right: 8,
                top: 16,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: trackColor,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                top: 16,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: constraints.maxWidth * fillFactor,
                        height: 4,
                        decoration: BoxDecoration(
                          color: activeColor,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List<Widget>.generate(_labels.length, (index) {
                  final isActive = index <= stepIndex;
                  return _StepNode(
                    label: _labels[index],
                    iconData: _icons[index],
                    active: isActive,
                    activeColor: activeColor,
                    inactiveFill: inactiveDotBg,
                    inactiveBorder: inactiveDotBorder,
                    completed: completed,
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepNode extends StatelessWidget {
  const _StepNode({
    required this.label,
    required this.iconData,
    required this.active,
    required this.activeColor,
    required this.inactiveFill,
    required this.inactiveBorder,
    required this.completed,
  });

  final String label;
  final IconData iconData;
  final bool active;
  final Color activeColor;
  final Color inactiveFill;
  final Color inactiveBorder;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final dotSize = active ? 44.0 : 32.0;

    return SizedBox(
      width: 56,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              color: active ? activeColor : inactiveFill,
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(
                color: active
                    ? (completed ? activeColor : const Color(0x332D5D7B))
                    : inactiveBorder,
                width: active ? (completed ? 1.0 : 2.0) : 1.0,
              ),
              boxShadow: const [],
            ),
            alignment: Alignment.center,
            child: Icon(
              iconData,
              size: active ? 16 : 15,
              color: active ? Colors.white : const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: active ? activeColor : const Color(0xFF9CA3AF),
              fontSize: 10,
              height: 15 / 10,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingCreateButton extends StatelessWidget {
  const _FloatingCreateButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9999),
        child: Ink(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(9999),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 24,
                offset: Offset(0, 10),
                spreadRadius: -6,
              ),
            ],
          ),
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.filter,
    required this.onCreateSession,
  });

  final ChatListFilter filter;
  final VoidCallback onCreateSession;

  @override
  Widget build(BuildContext context) {
    final (title, description) = switch (filter) {
      ChatListFilter.all => (
          '아직 생성된 대화창이 없어요.',
          '오른쪽 아래 버튼으로 새 민원을 시작해 주세요.',
        ),
      ChatListFilter.inProgress => (
          '진행 중인 대화창이 없어요.',
          '새 민원을 시작하면 이곳에 표시됩니다.',
        ),
      ChatListFilter.completed => (
          '완료된 대화창이 없어요.',
          '완료된 대화가 생기면 이곳에 표시됩니다.',
        ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.forum_outlined,
              size: 42,
              color: Color(0xFF457EAC),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 18,
                height: 25 / 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

int _stepIndexForSession(ChatSessionSummary session) {
  if (session.status == ChatSessionStatus.completed) {
    return 3;
  }
  if (session.status == ChatSessionStatus.awaitingInput) {
    return 0;
  }

  final step = session.stepLabel;
  if (step.contains('증거') ||
      step.contains('신청서') ||
      step.contains('경로') ||
      step.contains('추적')) {
    return 2;
  }
  if (step.contains('기본') || step.contains('접수')) {
    return 1;
  }
  return 1;
}

String _formatUpdatedAt(DateTime time) {
  final now = DateTime.now();
  final sameDay =
      now.year == time.year && now.month == time.month && now.day == time.day;
  if (sameDay) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  final month = time.month.toString().padLeft(2, '0');
  final day = time.day.toString().padLeft(2, '0');
  return '$month/$day';
}
