import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';

import 'models/chat_session_summary.dart';
import 'screens/chat/chatbot_screen.dart';
import 'screens/chat/chat_list_screen.dart';
import 'screens/start/guide_screen.dart';
import 'screens/start/start_flow_screen.dart';
import 'services/auth_session.dart';
import 'store/chat_session_store.dart';
import 'theme/krds_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  runApp(const CivilComplaintApp());
}

class CivilComplaintApp extends StatelessWidget {
  const CivilComplaintApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '층간소음 상담',
      theme: KrdsTheme.light(),
      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
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

enum RootPhase { start, guide, chatList, chat }

class DemoRootScreen extends StatefulWidget {
  const DemoRootScreen({super.key});

  @override
  State<DemoRootScreen> createState() => _DemoRootScreenState();
}

class _DemoRootScreenState extends State<DemoRootScreen> {
  RootPhase _phase = RootPhase.start;
  int _startFlowVersion = 0;
  final Map<String, ChatSessionStore> _sessionStoresByAccount =
      <String, ChatSessionStore>{};
  final Map<String, Map<String, ChatbotScreenSnapshot>>
      _sessionSnapshotsByAccount =
      <String, Map<String, ChatbotScreenSnapshot>>{};
  String? _activeAccountId;
  String? _activeSessionId;

  String? _normalizeAccountId(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized.toLowerCase();
  }

  String? get _currentAccountId {
    final stateAccount = _normalizeAccountId(_activeAccountId);
    if (stateAccount != null) return stateAccount;
    return _normalizeAccountId(AuthSession.accountId);
  }

  ChatSessionStore _storeForAccount(String accountId) {
    return _sessionStoresByAccount.putIfAbsent(
      accountId,
      () => ChatSessionStore(),
    );
  }

  Map<String, ChatbotScreenSnapshot> _snapshotsForAccount(String accountId) {
    return _sessionSnapshotsByAccount.putIfAbsent(
      accountId,
      () => <String, ChatbotScreenSnapshot>{},
    );
  }

  void _restart() {
    setState(() {
      _phase = RootPhase.start;
      _startFlowVersion += 1;
      _activeAccountId = null;
      _activeSessionId = null;
      AuthSession.clear();
    });
  }

  void _handleStartCompleted() {
    setState(() {
      _phase = RootPhase.guide;
    });
  }

  void _handleGuideCompleted() {
    final accountId = _normalizeAccountId(AuthSession.accountId) ?? 'demo';
    _storeForAccount(accountId);
    _snapshotsForAccount(accountId);

    setState(() {
      _activeAccountId = accountId;
      _activeSessionId = null;
      _phase = RootPhase.chatList;
    });
  }

  void _openChatList() {
    final accountId = _currentAccountId;
    if (accountId == null) {
      setState(() {
        _phase = RootPhase.start;
      });
      return;
    }

    setState(() {
      _activeAccountId = accountId;
      _activeSessionId = null;
      _phase = RootPhase.chatList;
    });
  }

  void _createAndOpenSession() {
    final accountId = _currentAccountId;
    if (accountId == null) {
      setState(() {
        _phase = RootPhase.start;
      });
      return;
    }

    final session = _storeForAccount(accountId).createSession();
    setState(() {
      _activeAccountId = accountId;
      _activeSessionId = session.sessionId;
      _phase = RootPhase.chat;
    });
  }

  void _openSession(String sessionId) {
    final accountId = _currentAccountId;
    if (accountId == null) return;

    final store = _storeForAccount(accountId);
    if (store.findById(sessionId) == null) return;
    store.markRead(sessionId);
    setState(() {
      _activeAccountId = accountId;
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
      case DemoStep.residence:
      case DemoStep.management:
      case DemoStep.noiseType:
      case DemoStep.frequency:
      case DemoStep.timeBand:
      case DemoStep.sourceCertainty:
      case DemoStep.dateTime:
        return '기본 정보';
      case DemoStep.ineligible:
        return '대체 경로';
      case DemoStep.multiForm:
        return '기본 정보';
      case DemoStep.summary:
        return '요약 확인';
      case DemoStep.pathChooser:
      case DemoStep.pathAlternative:
        return '경로 선택';
      case DemoStep.evidenceV1:
      case DemoStep.measureCheck:
      case DemoStep.evidenceV2:
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
    if (snapshot.step == DemoStep.waitingIssue ||
        snapshot.step == DemoStep.waitingRevision) {
      return ChatSessionStatus.awaitingInput;
    }
    return ChatSessionStatus.inProgress;
  }

  String _normalizeLastMessage(String text) {
    final normalized =
        text.replaceAll('\n', ' ').replaceAll(RegExp(r'\\s+'), ' ').trim();
    if (normalized.isEmpty) return '메시지가 없습니다.';
    return normalized;
  }

  void _handleSessionSnapshot(
      String accountId, String sessionId, ChatbotScreenSnapshot snapshot) {
    final snapshots = _snapshotsForAccount(accountId);
    snapshots[sessionId] = snapshot;

    final store = _storeForAccount(accountId);
    final previous = store.findById(sessionId);
    final issue = snapshot.data.userIssue?.trim();
    final title = (issue != null && issue.isNotEmpty)
        ? (issue.length > 18 ? '${issue.substring(0, 18)}…' : issue)
        : (previous?.title ?? '상담');

    store.upsertSummary(
      ChatSessionSummary(
        sessionId: sessionId,
        title: title,
        lastMessage: _normalizeLastMessage(snapshot.aiText),
        updatedAt: DateTime.now(),
        status: _statusForSnapshot(snapshot),
        stepLabel: _stepLabel(snapshot.step),
        unreadCount: 0,
        caseId: snapshot.backendCaseId ?? previous?.caseId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountId = _currentAccountId;
    final sessionStore = accountId == null ? null : _storeForAccount(accountId);
    final sessionSnapshots =
        accountId == null ? null : _snapshotsForAccount(accountId);

    final activeSessionId = _activeSessionId;
    final activeSession = activeSessionId == null
        ? null
        : sessionStore?.findById(activeSessionId);

    final content = switch (_phase) {
      RootPhase.start => StartFlowScreen(
          key: ValueKey('start-flow-$_startFlowVersion'),
          onCompleted: _handleStartCompleted,
        ),
      RootPhase.guide => GuideScreen(
          onDone: _handleGuideCompleted,
        ),
      RootPhase.chatList => ChatListScreen(
          sessions: sessionStore?.sessions ?? const <ChatSessionSummary>[],
          onOpenSession: _openSession,
          onCreateSession: _createAndOpenSession,
          onLogout: _restart,
          accountId: accountId ?? 'demo',
        ),
      RootPhase.chat => activeSession == null
          ? ChatListScreen(
              sessions: sessionStore?.sessions ?? const <ChatSessionSummary>[],
              onOpenSession: _openSession,
              onCreateSession: _createAndOpenSession,
              onLogout: _restart,
              accountId: accountId ?? 'demo',
            )
          : ChatbotDemoScreen(
              key: ValueKey('chat-${activeSession.sessionId}'),
              onRestart: _restart,
              onBackToList: _openChatList,
              initialSnapshot: sessionSnapshots?[activeSession.sessionId],
              onSnapshotChanged: (snapshot) {
                final current = _currentAccountId;
                if (current == null) return;
                _handleSessionSnapshot(
                    current, activeSession.sessionId, snapshot);
              },
            ),
    };

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedSwitcher(
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
    );
  }
}
