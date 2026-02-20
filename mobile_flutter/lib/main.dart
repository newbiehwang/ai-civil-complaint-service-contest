import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'models/chat_session_summary.dart';
import 'screens/chat/chatbot_screen.dart';
import 'screens/chat/chat_list_screen.dart';
import 'screens/start/start_flow_screen.dart';
import 'store/chat_session_store.dart';
import 'theme/app_colors.dart';

void main() {
  runApp(const CivilComplaintApp());
}

class CivilComplaintApp extends StatelessWidget {
  const CivilComplaintApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '층간소음 상담',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
        fontFamily: 'Pretendard',
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko'),
        Locale('en'),
      ],
      home: const DemoRootScreen(),
    );
  }
}

enum RootPhase { start, chatList, chat }

class DemoRootScreen extends StatefulWidget {
  const DemoRootScreen({super.key});

  @override
  State<DemoRootScreen> createState() => _DemoRootScreenState();
}

class _DemoRootScreenState extends State<DemoRootScreen> {
  RootPhase _phase = RootPhase.start;
  int _startFlowVersion = 0;
  final ChatSessionStore _sessionStore = ChatSessionStore();
  final Map<String, ChatbotScreenSnapshot> _sessionSnapshots = <String, ChatbotScreenSnapshot>{};
  String? _activeSessionId;

  void _restart() {
    setState(() {
      _phase = RootPhase.start;
      _startFlowVersion += 1;
      _activeSessionId = null;
      _sessionSnapshots.clear();
      _sessionStore.clear();
    });
  }

  void _openChatList() {
    setState(() {
      _phase = RootPhase.chatList;
    });
  }

  void _createAndOpenSession() {
    final session = _sessionStore.createSession();
    setState(() {
      _activeSessionId = session.sessionId;
      _phase = RootPhase.chat;
    });
  }

  void _openSession(String sessionId) {
    if (_sessionStore.findById(sessionId) == null) return;
    _sessionStore.markRead(sessionId);
    setState(() {
      _activeSessionId = sessionId;
      _phase = RootPhase.chat;
    });
  }

  String _stepLabel(DemoStep step) {
    switch (step) {
      case DemoStep.waitingIssue:
      case DemoStep.noiseNow:
      case DemoStep.safety:
        return '접수';
      case DemoStep.multiForm:
      case DemoStep.residence:
      case DemoStep.timeBand:
      case DemoStep.dateTime:
        return '기본 정보';
      case DemoStep.summary:
        return '요약 확인';
      case DemoStep.pathChooser:
      case DemoStep.pathAlternative:
        return '경로 선택';
      case DemoStep.evidence:
      case DemoStep.noiseDiary:
        return '증거 준비';
      case DemoStep.draftViewer:
      case DemoStep.waitingRevision:
      case DemoStep.draftConfirm:
        return '신청서 확인';
      case DemoStep.statusFeed:
        return '진행 추적';
      case DemoStep.complete:
        return '종결';
    }
  }

  ChatSessionStatus _statusForSnapshot(ChatbotScreenSnapshot snapshot) {
    if (snapshot.step == DemoStep.complete) {
      return ChatSessionStatus.completed;
    }
    if (snapshot.step == DemoStep.waitingIssue || snapshot.step == DemoStep.waitingRevision) {
      return ChatSessionStatus.awaitingInput;
    }
    return ChatSessionStatus.inProgress;
  }

  String _normalizeLastMessage(String text) {
    final normalized = text.replaceAll('\n', ' ').replaceAll(RegExp(r'\\s+'), ' ').trim();
    if (normalized.isEmpty) return '메시지가 없습니다.';
    return normalized;
  }

  void _handleSessionSnapshot(String sessionId, ChatbotScreenSnapshot snapshot) {
    _sessionSnapshots[sessionId] = snapshot;

    final previous = _sessionStore.findById(sessionId);
    final issue = snapshot.data.userIssue?.trim();
    final title = (issue != null && issue.isNotEmpty)
        ? (issue.length > 18 ? '${issue.substring(0, 18)}…' : issue)
        : (previous?.title ?? '상담');

    _sessionStore.upsertSummary(
      ChatSessionSummary(
        sessionId: sessionId,
        title: title,
        lastMessage: _normalizeLastMessage(snapshot.aiText),
        updatedAt: DateTime.now(),
        status: _statusForSnapshot(snapshot),
        stepLabel: _stepLabel(snapshot.step),
        unreadCount: 0,
        caseId: previous?.caseId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeSessionId = _activeSessionId;
    final activeSession = activeSessionId == null ? null : _sessionStore.findById(activeSessionId);

    final content = switch (_phase) {
      RootPhase.start => StartFlowScreen(
          key: ValueKey('start-flow-$_startFlowVersion'),
          onCompleted: _createAndOpenSession,
        ),
      RootPhase.chatList => ChatListScreen(
          sessions: _sessionStore.sessions,
          onOpenSession: _openSession,
          onCreateSession: _createAndOpenSession,
        ),
      RootPhase.chat => activeSession == null
          ? ChatListScreen(
              sessions: _sessionStore.sessions,
              onOpenSession: _openSession,
              onCreateSession: _createAndOpenSession,
            )
          : ChatbotDemoScreen(
              key: ValueKey('chat-${activeSession.sessionId}'),
              onRestart: _restart,
              onBackToList: _openChatList,
              initialSnapshot: _sessionSnapshots[activeSession.sessionId],
              onSnapshotChanged: (snapshot) => _handleSessionSnapshot(activeSession.sessionId, snapshot),
            ),
    };

    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 480),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.02, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey(_phase.name),
            child: content,
          ),
        ),
      ),
    );
  }
}
