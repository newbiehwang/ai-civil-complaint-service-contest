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

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'sessionId': sessionId,
      'title': title,
      'lastMessage': lastMessage,
      'updatedAt': updatedAt.toIso8601String(),
      'status': status.name,
      'stepLabel': stepLabel,
      'unreadCount': unreadCount,
      'caseId': caseId,
    };
  }

  factory ChatSessionSummary.fromJson(Map<String, Object?> json) {
    final statusRaw = json['status']?.toString();
    final status = ChatSessionStatus.values.firstWhere(
      (value) => value.name == statusRaw,
      orElse: () => ChatSessionStatus.awaitingInput,
    );

    final updatedAtRaw = json['updatedAt']?.toString();
    final updatedAt = updatedAtRaw == null
        ? DateTime.now()
        : (DateTime.tryParse(updatedAtRaw) ?? DateTime.now());

    final unreadCountRaw = json['unreadCount'];
    final unreadCount = unreadCountRaw is int
        ? unreadCountRaw
        : int.tryParse(unreadCountRaw?.toString() ?? '') ?? 0;

    return ChatSessionSummary(
      sessionId: json['sessionId']?.toString() ?? '',
      title: json['title']?.toString() ?? '상담',
      lastMessage: json['lastMessage']?.toString() ?? '메시지가 없습니다.',
      updatedAt: updatedAt,
      status: status,
      stepLabel: json['stepLabel']?.toString() ?? '시작 전',
      unreadCount: unreadCount,
      caseId: json['caseId']?.toString(),
    );
  }
}
