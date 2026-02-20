import 'package:flutter/material.dart';

enum ChatSessionStatus {
  inProgress,
  awaitingInput,
  completed,
}

extension ChatSessionStatusLabel on ChatSessionStatus {
  String get label {
    switch (this) {
      case ChatSessionStatus.inProgress:
        return '진행중';
      case ChatSessionStatus.awaitingInput:
        return '입력 대기';
      case ChatSessionStatus.completed:
        return '완료';
    }
  }

  Color get chipBackground {
    switch (this) {
      case ChatSessionStatus.inProgress:
        return const Color(0xFFEAF4FF);
      case ChatSessionStatus.awaitingInput:
        return const Color(0xFFFFF7E6);
      case ChatSessionStatus.completed:
        return const Color(0xFFEAF8F0);
    }
  }

  Color get chipForeground {
    switch (this) {
      case ChatSessionStatus.inProgress:
        return const Color(0xFF2D5D7B);
      case ChatSessionStatus.awaitingInput:
        return const Color(0xFF8A5A00);
      case ChatSessionStatus.completed:
        return const Color(0xFF1D6D43);
    }
  }
}

class ChatSessionSummary {
  const ChatSessionSummary({
    required this.sessionId,
    required this.title,
    required this.lastMessage,
    required this.updatedAt,
    required this.status,
    required this.stepLabel,
    this.unreadCount = 0,
    this.caseId,
  });

  final String sessionId;
  final String title;
  final String lastMessage;
  final DateTime updatedAt;
  final ChatSessionStatus status;
  final String stepLabel;
  final int unreadCount;
  final String? caseId;

  ChatSessionSummary copyWith({
    String? title,
    String? lastMessage,
    DateTime? updatedAt,
    ChatSessionStatus? status,
    String? stepLabel,
    int? unreadCount,
    String? caseId,
  }) {
    return ChatSessionSummary(
      sessionId: sessionId,
      title: title ?? this.title,
      lastMessage: lastMessage ?? this.lastMessage,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      stepLabel: stepLabel ?? this.stepLabel,
      unreadCount: unreadCount ?? this.unreadCount,
      caseId: caseId ?? this.caseId,
    );
  }
}
