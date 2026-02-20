import '../models/chat_session_summary.dart';

class ChatSessionStore {
  final List<ChatSessionSummary> _sessions = <ChatSessionSummary>[];
  int _nextSequence = 1;

  List<ChatSessionSummary> get sessions => List<ChatSessionSummary>.unmodifiable(_sessions);

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
    final index = _sessions.indexWhere((it) => it.sessionId == summary.sessionId);
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

  void clear() {
    _sessions.clear();
    _nextSequence = 1;
  }
}
