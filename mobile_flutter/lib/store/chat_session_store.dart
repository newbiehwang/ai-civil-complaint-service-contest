import '../models/chat_session_summary.dart';

class ChatSessionStore {
  ChatSessionStore({List<ChatSessionSummary>? initialSessions})
      : _sessions = List<ChatSessionSummary>.from(initialSessions ?? const []) {
    _sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _nextSequence = _computeNextSequence(_sessions);
  }

  final List<ChatSessionSummary> _sessions;
  late int _nextSequence;

  List<ChatSessionSummary> get sessions =>
      List<ChatSessionSummary>.unmodifiable(_sessions);

  ChatSessionSummary createSession({String? title}) {
    final now = DateTime.now();
    final session = ChatSessionSummary(
      sessionId: 'session-${now.microsecondsSinceEpoch}',
      title: title ?? '상담 ${_nextSequence++}',
      lastMessage: '아직 대화를 시작하지 않았어요.',
      updatedAt: now,
      status: ChatSessionStatus.awaitingInput,
      stepLabel: '시작 전',
    );
    _sessions.insert(0, session);
    return session;
  }

  ChatSessionSummary? findById(String sessionId) {
    for (final session in _sessions) {
      if (session.sessionId == sessionId) return session;
    }
    return null;
  }

  void upsertSummary(ChatSessionSummary summary) {
    final index =
        _sessions.indexWhere((it) => it.sessionId == summary.sessionId);
    if (index >= 0) {
      _sessions[index] = summary;
    } else {
      _sessions.insert(0, summary);
    }
    _sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  void markRead(String sessionId) {
    final index = _sessions.indexWhere((it) => it.sessionId == sessionId);
    if (index < 0) return;
    final session = _sessions[index];
    if (session.unreadCount == 0) return;
    _sessions[index] = session.copyWith(unreadCount: 0);
  }

  bool removeById(String sessionId) {
    final before = _sessions.length;
    _sessions.removeWhere((it) => it.sessionId == sessionId);
    return _sessions.length != before;
  }

  void clear() {
    _sessions.clear();
    _nextSequence = 1;
  }

  static int _computeNextSequence(List<ChatSessionSummary> sessions) {
    var maxSequence = 0;
    for (final session in sessions) {
      final match = RegExp(r'^상담\s+(\d+)$').firstMatch(session.title.trim());
      if (match == null) continue;
      final value = int.tryParse(match.group(1) ?? '');
      if (value == null) continue;
      if (value > maxSequence) {
        maxSequence = value;
      }
    }
    return maxSequence + 1;
  }
}
