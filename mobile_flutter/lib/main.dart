import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';

import 'models/chat_session_summary.dart';
import 'screens/chat/chatbot_screen.dart';
import 'screens/chat/chat_list_screen.dart';
import 'screens/start/guide_screen.dart';
import 'screens/start/start_flow_screen.dart';
import 'services/api_client.dart';
import 'services/auth_session.dart';
import 'services/error_map.dart';
import 'services/local/chat_session_persistence.dart';
import 'store/chat_session_store.dart';
import 'theme/krds_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthSession.restore();
  await ChatSessionPersistence.instance.initialize();
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
  final ChatSessionPersistence _sessionPersistence =
      ChatSessionPersistence.instance;
  final Set<String> _hydratedAccounts = <String>{};
  final Map<String, Future<void>> _accountHydrationFutures =
      <String, Future<void>>{};
  final Map<String, Set<String>> _hiddenSessionIdsByAccount =
      <String, Set<String>>{};
  String? _activeAccountId;
  String? _activeSessionId;

  String _sessionAccountKey(String accountId, {required bool useBackend}) {
    final scope = useBackend ? 'server' : 'local';
    return '$scope:$accountId';
  }

  String? _currentSessionAccountKey() {
    final accountId = _currentAccountId;
    if (accountId == null) return null;
    return _sessionAccountKey(accountId, useBackend: AuthSession.useBackend);
  }

  Set<String> _hiddenSessionIdsForAccount(String sessionAccountKey) {
    return _hiddenSessionIdsByAccount.putIfAbsent(
      sessionAccountKey,
      () => <String>{},
    );
  }

  @override
  void initState() {
    super.initState();
    _bootstrapFromSavedSession();
  }

  void _bootstrapFromSavedSession() {
    final token = AuthSession.accessToken;
    final accountId = _normalizeAccountId(AuthSession.accountId);
    if (token == null || accountId == null) {
      return;
    }

    _activeAccountId = accountId;
    _activeSessionId = null;
    _phase = RootPhase.chatList;
    unawaited(_ensureAccountHydrated(accountId,
        forceRefresh: AuthSession.useBackend));
  }

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
      _sessionStoresByAccount.clear();
      _sessionSnapshotsByAccount.clear();
      _hydratedAccounts.clear();
      _accountHydrationFutures.clear();
      _hiddenSessionIdsByAccount.clear();
      AuthSession.clear();
    });
  }

  void _handleStartCompleted() {
    setState(() {
      _phase = RootPhase.guide;
    });
  }

  void _handleGuideCompleted() {
    unawaited(_handleGuideCompletedAsync());
  }

  Future<void> _handleGuideCompletedAsync() async {
    final accountId = _normalizeAccountId(AuthSession.accountId) ?? 'demo';
    await _ensureAccountHydrated(accountId, forceRefresh: true);
    if (!mounted) return;

    setState(() {
      _activeAccountId = accountId;
      _activeSessionId = null;
      _phase = RootPhase.chatList;
    });
  }

  void _openChatList() {
    unawaited(_openChatListAsync());
  }

  Future<void> _openChatListAsync() async {
    final accountId = _currentAccountId;
    if (accountId == null) {
      if (!mounted) return;
      setState(() {
        _phase = RootPhase.start;
      });
      return;
    }

    await _ensureAccountHydrated(accountId,
        forceRefresh: AuthSession.useBackend);
    if (!mounted) return;

    setState(() {
      _activeAccountId = accountId;
      _activeSessionId = null;
      _phase = RootPhase.chatList;
    });
  }

  void _createAndOpenSession() {
    unawaited(_createAndOpenSessionAsync());
  }

  Future<void> _createAndOpenSessionAsync() async {
    final accountId = _currentAccountId;
    if (accountId == null) {
      if (!mounted) return;
      setState(() {
        _phase = RootPhase.start;
      });
      return;
    }

    await _ensureAccountHydrated(accountId,
        forceRefresh: AuthSession.useBackend);
    if (!mounted) return;

    final sessionAccountKey =
        _sessionAccountKey(accountId, useBackend: AuthSession.useBackend);

    final session = AuthSession.useBackend
        ? await _createServerBackedSession()
        : _storeForAccount(sessionAccountKey).createSession();
    if (!AuthSession.useBackend) {
      unawaited(
          _sessionPersistence.saveSessionSummary(sessionAccountKey, session));
    }

    setState(() {
      _storeForAccount(sessionAccountKey).upsertSummary(session);
      _activeAccountId = accountId;
      _activeSessionId = session.sessionId;
      _phase = RootPhase.chat;
    });
  }

  void _openSession(String sessionId) {
    unawaited(_openSessionAsync(sessionId));
  }

  Future<void> _openSessionAsync(String sessionId) async {
    final accountId = _currentAccountId;
    if (accountId == null) return;

    await _ensureAccountHydrated(accountId,
        forceRefresh: AuthSession.useBackend);
    if (!mounted) return;

    final sessionAccountKey =
        _sessionAccountKey(accountId, useBackend: AuthSession.useBackend);
    final store = _storeForAccount(sessionAccountKey);
    if (store.findById(sessionId) == null) return;
    store.markRead(sessionId);
    final summary = store.findById(sessionId);
    if (!AuthSession.useBackend && summary != null) {
      unawaited(
          _sessionPersistence.saveSessionSummary(sessionAccountKey, summary));
    }
    setState(() {
      _activeAccountId = accountId;
      _activeSessionId = sessionId;
      _phase = RootPhase.chat;
    });
  }

  Future<void> _ensureAccountHydrated(String accountId,
      {bool forceRefresh = false}) {
    final useBackend = AuthSession.useBackend;
    final sessionAccountKey =
        _sessionAccountKey(accountId, useBackend: useBackend);

    if (!forceRefresh && _hydratedAccounts.contains(sessionAccountKey)) {
      return Future<void>.value();
    }
    if (forceRefresh) {
      _hydratedAccounts.remove(sessionAccountKey);
    }
    final existing = _accountHydrationFutures[sessionAccountKey];
    if (existing != null) {
      return existing;
    }

    final future = _hydrateAccountInternal(
      accountId: accountId,
      sessionAccountKey: sessionAccountKey,
      useBackend: useBackend,
    );
    _accountHydrationFutures[sessionAccountKey] = future;
    return future;
  }

  Future<void> _hydrateAccountInternal({
    required String accountId,
    required String sessionAccountKey,
    required bool useBackend,
  }) async {
    try {
      final summaries = useBackend
          ? await _loadServerSessionSummaries()
          : await _sessionPersistence.loadSessionSummaries(sessionAccountKey);
      final hiddenIds = _hiddenSessionIdsByAccount[sessionAccountKey];
      final filteredSummaries = (hiddenIds == null || hiddenIds.isEmpty)
          ? summaries
          : summaries
              .where((summary) => !hiddenIds.contains(summary.sessionId))
              .toList(growable: false);
      final snapshots = useBackend
          ? _retainSnapshotsForServerCases(
              existing: _sessionSnapshotsByAccount[sessionAccountKey] ??
                  <String, ChatbotScreenSnapshot>{},
              summaries: filteredSummaries,
            )
          : await _sessionPersistence.loadSnapshots(sessionAccountKey);
      if (!mounted) return;

      setState(() {
        _sessionStoresByAccount[sessionAccountKey] =
            ChatSessionStore(initialSessions: filteredSummaries);
        _sessionSnapshotsByAccount[sessionAccountKey] =
            Map<String, ChatbotScreenSnapshot>.from(snapshots);
        _hydratedAccounts.add(sessionAccountKey);
      });
    } catch (error) {
      debugPrint(
          '[session-hydrate-error] account=$accountId mode=${useBackend ? "server" : "local"} error=$error');
      if (!mounted) return;
      setState(() {
        _sessionStoresByAccount.putIfAbsent(
            sessionAccountKey, () => ChatSessionStore());
        _sessionSnapshotsByAccount.putIfAbsent(
            sessionAccountKey, () => <String, ChatbotScreenSnapshot>{});
        _hydratedAccounts.add(sessionAccountKey);
      });
    } finally {
      _accountHydrationFutures.remove(sessionAccountKey);
    }
  }

  Map<String, ChatbotScreenSnapshot> _retainSnapshotsForServerCases({
    required Map<String, ChatbotScreenSnapshot> existing,
    required List<ChatSessionSummary> summaries,
  }) {
    final allowedIds = summaries
        .map((summary) => summary.sessionId.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    final filtered = <String, ChatbotScreenSnapshot>{};
    for (final entry in existing.entries) {
      if (allowedIds.contains(entry.key)) {
        filtered[entry.key] = entry.value;
      }
    }
    return filtered;
  }

  Future<ChatSessionSummary> _createServerBackedSession() async {
    final apiClient = ApiClient();
    final traceId = apiClient.createTraceId(prefix: 'mobile-create-case');
    final idempotencyKey =
        'mobile-create-${DateTime.now().microsecondsSinceEpoch}';
    final detail = await apiClient.createCase(
      traceId: traceId,
      idempotencyKey: idempotencyKey,
      initialSummary: '새 상담 시작',
      scenarioType: 'SCENARIO_A',
      housingType: 'APARTMENT',
      consentAccepted: true,
    );

    return ChatSessionSummary(
      sessionId: detail.caseId,
      title: '층간소음 민원 상담',
      lastMessage: '민원이 생성되었습니다.',
      updatedAt: DateTime.now(),
      status: ChatSessionStatus.awaitingInput,
      stepLabel: _stepLabelByBackendStatus(detail.status),
      unreadCount: 0,
      caseId: detail.caseId,
    );
  }

  Future<List<ChatSessionSummary>> _loadServerSessionSummaries() async {
    final apiClient = ApiClient();
    final traceId = apiClient.createTraceId(prefix: 'mobile-list-cases');
    final cases = await apiClient.listCases(traceId: traceId);
    final now = DateTime.now();

    return cases.map((item) {
      final caseId = item.caseId.trim();
      final updatedAt = item.updatedAt?.toLocal() ?? now;
      return ChatSessionSummary(
        sessionId: caseId,
        title: '층간소음 민원 상담',
        lastMessage: _lastMessageByBackendStatus(item.status),
        updatedAt: updatedAt,
        status: _chatStatusByBackendStatus(item.status),
        stepLabel: _stepLabelByBackendStatus(item.status),
        unreadCount: 0,
        caseId: caseId,
      );
    }).toList(growable: false);
  }

  String _lastMessageByBackendStatus(String rawStatus) {
    switch (rawStatus.trim().toUpperCase()) {
      case 'RECEIVED':
        return '접수 정보를 입력 중입니다.';
      case 'CLASSIFIED':
        return '민원 분류가 완료되었습니다.';
      case 'ROUTE_CONFIRMED':
        return '추천 경로가 확정되었습니다.';
      case 'EVIDENCE_COLLECTING':
      case 'FORMAL_SUBMISSION_READY':
        return '증거 제출 단계입니다.';
      case 'INSTITUTION_PROCESSING':
        return '기관 처리 진행 중입니다.';
      case 'SUPPLEMENT_REQUIRED':
        return '보완자료 요청이 도착했습니다.';
      case 'COMPLETED':
      case 'CLOSED':
        return '민원 처리가 완료되었습니다.';
      default:
        return '민원 진행 상태를 확인해 주세요.';
    }
  }

  ChatSessionStatus _chatStatusByBackendStatus(String rawStatus) {
    switch (rawStatus.trim().toUpperCase()) {
      case 'COMPLETED':
      case 'CLOSED':
        return ChatSessionStatus.completed;
      case 'RECEIVED':
        return ChatSessionStatus.awaitingInput;
      default:
        return ChatSessionStatus.inProgress;
    }
  }

  String _stepLabelByBackendStatus(String rawStatus) {
    switch (rawStatus.trim().toUpperCase()) {
      case 'RECEIVED':
        return '접수';
      case 'CLASSIFIED':
        return '분류';
      case 'ROUTE_CONFIRMED':
        return '경로 선택';
      case 'EVIDENCE_COLLECTING':
      case 'FORMAL_SUBMISSION_READY':
        return '증거 준비';
      case 'INSTITUTION_PROCESSING':
      case 'SUPPLEMENT_REQUIRED':
        return '진행 추적';
      case 'COMPLETED':
      case 'CLOSED':
        return '종결';
      default:
        return '진행 중';
    }
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
    final sessionAccountKey =
        _sessionAccountKey(accountId, useBackend: AuthSession.useBackend);
    final snapshots = _snapshotsForAccount(sessionAccountKey);
    snapshots[sessionId] = snapshot;

    final store = _storeForAccount(sessionAccountKey);
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
    final persistedSummary = store.findById(sessionId);
    if (persistedSummary != null) {
      unawaited(_persistSessionState(
        accountId: sessionAccountKey,
        sessionId: sessionId,
        summary: persistedSummary,
        snapshot: snapshot,
      ));
    }
  }

  Future<void> _persistSessionState({
    required String accountId,
    required String sessionId,
    required ChatSessionSummary summary,
    required ChatbotScreenSnapshot snapshot,
  }) async {
    if (AuthSession.useBackend) {
      return;
    }
    try {
      await _sessionPersistence.saveSessionSummary(accountId, summary);
      await _sessionPersistence.saveSnapshot(accountId, sessionId, snapshot);
    } catch (error) {
      debugPrint(
        '[session-persist-error] account=$accountId session=$sessionId error=$error',
      );
    }
  }

  void _deleteSession(String sessionId) {
    unawaited(_deleteSessionAsync(sessionId));
  }

  Future<void> _deleteSessionAsync(String sessionId) async {
    final sessionAccountKey = _currentSessionAccountKey();
    if (sessionAccountKey == null) return;

    final store = _storeForAccount(sessionAccountKey);
    final snapshots = _snapshotsForAccount(sessionAccountKey);
    final summary = store.findById(sessionId);
    if (summary == null) return;

    if (AuthSession.useBackend) {
      final caseId = (summary.caseId ?? summary.sessionId).trim();
      if (caseId.isEmpty) return;
      try {
        final apiClient = ApiClient();
        final traceId = apiClient.createTraceId(prefix: 'mobile-delete-case');
        await apiClient.deleteCase(traceId: traceId, caseId: caseId);
      } catch (error) {
        debugPrint(
          '[session-delete-backend-error] account=$sessionAccountKey session=$sessionId error=$error',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(toKoreanErrorMessage(error)),
            ),
          );
        }
        return;
      }
    }

    final removed = store.removeById(sessionId);
    snapshots.remove(sessionId);
    if (!removed) return;

    if (!AuthSession.useBackend) {
      try {
        await _sessionPersistence.deleteSession(sessionAccountKey, sessionId);
      } catch (error) {
        debugPrint(
          '[session-delete-error] account=$sessionAccountKey session=$sessionId error=$error',
        );
      }
    } else {
      _hiddenSessionIdsForAccount(sessionAccountKey).add(sessionId);
    }

    if (!mounted) return;
    setState(() {
      if (_activeSessionId == sessionId) {
        _activeSessionId = null;
        _phase = RootPhase.chatList;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final accountId = _currentAccountId;
    final sessionAccountKey = _currentSessionAccountKey();
    final sessionStore =
        sessionAccountKey == null ? null : _storeForAccount(sessionAccountKey);
    final sessionSnapshots = sessionAccountKey == null
        ? null
        : _snapshotsForAccount(sessionAccountKey);

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
              initialBackendCaseId: AuthSession.useBackend
                  ? (activeSession.caseId ?? activeSession.sessionId)
                  : null,
              initialBackendCaseStatus: AuthSession.useBackend
                  ? _backendStatusFromSession(activeSession)
                  : null,
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

  String? _backendStatusFromSession(ChatSessionSummary session) {
    final status = session.status;
    if (status == ChatSessionStatus.completed) {
      return 'COMPLETED';
    }
    if (status == ChatSessionStatus.awaitingInput) {
      return 'RECEIVED';
    }
    return null;
  }
}
