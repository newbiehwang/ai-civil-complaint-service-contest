import 'package:flutter/material.dart';

import '../screens/chat/chatbot_screen.dart';

class ChatSnapshotCodec {
  ChatSnapshotCodec._();

  static Map<String, Object?> encode(ChatbotScreenSnapshot snapshot) {
    return <String, Object?>{
      'isThinking': snapshot.isThinking,
      'isAiAnswerReady': snapshot.isAiAnswerReady,
      'aiAnimationNonce': snapshot.aiAnimationNonce,
      'aiText': snapshot.aiText,
      'step': snapshot.step.name,
      'miniType': snapshot.miniType.name,
      'options': snapshot.options
          .map((option) => <String, Object?>{
                'id': option.id,
                'label': option.label,
                'description': option.description,
              })
          .toList(growable: false),
      'selectedOptionIds': snapshot.selectedOptionIds.toList(growable: false),
      'data': _encodeFlowData(snapshot.data),
      'incidentDate': _dateToIso(snapshot.incidentDate),
      'incidentTime': _encodeTime(snapshot.incidentTime),
      'multiResidenceId': snapshot.multiResidenceId,
      'multiTimeBandId': snapshot.multiTimeBandId,
      'noiseDiaryDate': _dateToIso(snapshot.noiseDiaryDate),
      'noiseDiaryTime': _encodeTime(snapshot.noiseDiaryTime),
      'noiseDiaryDuration': snapshot.noiseDiaryDuration,
      'noiseDiaryType': snapshot.noiseDiaryType,
      'noiseDiaryImpact': snapshot.noiseDiaryImpact,
      'evidenceAttachmentIds':
          snapshot.evidenceAttachmentIds.toList(growable: false),
      'evidenceAttachmentNames': snapshot.evidenceAttachmentNames,
      'evidenceV2AttachmentIds':
          snapshot.evidenceV2AttachmentIds.toList(growable: false),
      'evidenceV2AttachmentNames': snapshot.evidenceV2AttachmentNames,
      'isPickingEvidence': snapshot.isPickingEvidence,
      'measureVisitDone': snapshot.measureVisitDone,
      'measureWithin30Days': snapshot.measureWithin30Days,
      'measureReceivingUnit': snapshot.measureReceivingUnit,
      'pickerOwnerIsNoiseDiary': snapshot.pickerOwnerIsNoiseDiary,
      'pickerMonth': _dateToIso(snapshot.pickerMonth),
      'pickerDateSelection': _dateToIso(snapshot.pickerDateSelection),
      'pickerIsAm': snapshot.pickerIsAm,
      'pickerHour12': snapshot.pickerHour12,
      'pickerMinute': snapshot.pickerMinute,
      'triageNoiseNowId': snapshot.triageNoiseNowId,
      'triageSafetyId': snapshot.triageSafetyId,
      'intakeResidenceId': snapshot.intakeResidenceId,
      'intakeManagementId': snapshot.intakeManagementId,
      'intakeSourceCertaintyId': snapshot.intakeSourceCertaintyId,
      'intakeNoiseTypeId': snapshot.intakeNoiseTypeId,
      'intakeFrequencyId': snapshot.intakeFrequencyId,
      'intakeTimeBandId': snapshot.intakeTimeBandId,
      'backendCaseId': snapshot.backendCaseId,
      'backendCaseStatus': snapshot.backendCaseStatus,
      'backendTraceId': snapshot.backendTraceId,
      'backendEnabled': snapshot.backendEnabled,
      'backendUiHintDriven': snapshot.backendUiHintDriven,
      'backendUiHintType': snapshot.backendUiHintType,
      'backendUiSelectionMode': snapshot.backendUiSelectionMode,
      'hasIntroBridgeShown': snapshot.hasIntroBridgeShown,
      'historyEntries': snapshot.historyEntries
          .map((entry) => <String, Object?>{
                'text': entry.text,
                'isAi': entry.isAi,
                'fromMiniInterface': entry.fromMiniInterface,
              })
          .toList(growable: false),
    };
  }

  static ChatbotScreenSnapshot decode(Map<String, Object?> json) {
    final optionsRaw = (json['options'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map>()
        .map((raw) => MiniOption(
              id: raw['id']?.toString() ?? '',
              label: raw['label']?.toString() ?? '',
              description: raw['description']?.toString(),
            ))
        .toList(growable: false);

    final evidenceAttachmentNamesRaw = json['evidenceAttachmentNames'];
    final evidenceV2AttachmentNamesRaw = json['evidenceV2AttachmentNames'];

    final now = DateTime.now();
    return ChatbotScreenSnapshot(
      isThinking: _asBool(json['isThinking']),
      isAiAnswerReady: _asBool(json['isAiAnswerReady'], fallback: true),
      aiAnimationNonce: _asInt(json['aiAnimationNonce']),
      aiText: json['aiText']?.toString() ??
          '안녕하세요, 정부24 민원 서비스 도우미입니다.\n무엇을 도와드릴까요?',
      step: _parseEnum(
        DemoStep.values,
        json['step']?.toString(),
        DemoStep.waitingIssue,
      ),
      miniType: _parseEnum(
        MiniInterfaceType.values,
        json['miniType']?.toString(),
        MiniInterfaceType.none,
      ),
      options: optionsRaw,
      selectedOptionIds:
          (json['selectedOptionIds'] as List<dynamic>? ?? const <dynamic>[])
              .map((value) => value.toString())
              .where((value) => value.isNotEmpty)
              .toSet(),
      data: _decodeFlowData(json['data']),
      incidentDate: _dateFromIso(json['incidentDate']),
      incidentTime: _decodeTime(json['incidentTime']),
      multiResidenceId: _nullableText(json['multiResidenceId']),
      multiTimeBandId: _nullableText(json['multiTimeBandId']),
      noiseDiaryDate: _dateFromIso(json['noiseDiaryDate']),
      noiseDiaryTime: _decodeTime(json['noiseDiaryTime']),
      noiseDiaryDuration: _nullableText(json['noiseDiaryDuration']),
      noiseDiaryType: _nullableText(json['noiseDiaryType']),
      noiseDiaryImpact: _nullableText(json['noiseDiaryImpact']),
      evidenceAttachmentIds:
          (json['evidenceAttachmentIds'] as List<dynamic>? ?? const <dynamic>[])
              .map((value) => value.toString())
              .where((value) => value.isNotEmpty)
              .toSet(),
      evidenceAttachmentNames: _decodeStringMap(evidenceAttachmentNamesRaw),
      evidenceV2AttachmentIds:
          (json['evidenceV2AttachmentIds'] as List<dynamic>? ??
                  const <dynamic>[])
              .map((value) => value.toString())
              .where((value) => value.isNotEmpty)
              .toSet(),
      evidenceV2AttachmentNames: _decodeStringMap(evidenceV2AttachmentNamesRaw),
      isPickingEvidence: _asBool(json['isPickingEvidence']),
      measureVisitDone: _asNullableBool(json['measureVisitDone']),
      measureWithin30Days: _asNullableBool(json['measureWithin30Days']),
      measureReceivingUnit: _asNullableBool(json['measureReceivingUnit']),
      pickerOwnerIsNoiseDiary: _asBool(json['pickerOwnerIsNoiseDiary']),
      pickerMonth:
          _dateFromIso(json['pickerMonth']) ?? DateTime(now.year, now.month, 1),
      pickerDateSelection: _dateFromIso(json['pickerDateSelection']),
      pickerIsAm: _asBool(json['pickerIsAm'], fallback: true),
      pickerHour12: _asInt(json['pickerHour12'], fallback: 1),
      pickerMinute: _asInt(json['pickerMinute']),
      triageNoiseNowId: _nullableText(json['triageNoiseNowId']),
      triageSafetyId: _nullableText(json['triageSafetyId']),
      intakeResidenceId: _nullableText(json['intakeResidenceId']),
      intakeManagementId: _nullableText(json['intakeManagementId']),
      intakeSourceCertaintyId: _nullableText(json['intakeSourceCertaintyId']),
      intakeNoiseTypeId: _nullableText(json['intakeNoiseTypeId']),
      intakeFrequencyId: _nullableText(json['intakeFrequencyId']),
      intakeTimeBandId: _nullableText(json['intakeTimeBandId']),
      backendCaseId: _nullableText(json['backendCaseId']),
      backendCaseStatus: _nullableText(json['backendCaseStatus']),
      backendTraceId: _nullableText(json['backendTraceId']),
      backendEnabled: _asBool(json['backendEnabled'], fallback: false),
      backendUiHintDriven:
          _asBool(json['backendUiHintDriven'], fallback: false),
      backendUiHintType: _nullableText(json['backendUiHintType']) ?? 'NONE',
      backendUiSelectionMode:
          _nullableText(json['backendUiSelectionMode']) ?? 'NONE',
      hasIntroBridgeShown:
          _asBool(json['hasIntroBridgeShown'], fallback: false),
      historyEntries: _decodeHistoryEntries(json['historyEntries']),
    );
  }

  static Map<String, Object?> _encodeFlowData(DemoFlowData data) {
    return <String, Object?>{
      'userIssue': data.userIssue,
      'noiseNow': data.noiseNow,
      'safety': data.safety,
      'residence': data.residence,
      'management': data.management,
      'noiseType': data.noiseType,
      'frequency': data.frequency,
      'timeBand': data.timeBand,
      'sourceCertainty': data.sourceCertainty,
      'eligibilityReason': data.eligibilityReason,
      'route': data.route,
      'startedAtDate': _dateToIso(data.startedAtDate),
      'startedAtTime': _encodeTime(data.startedAtTime),
      'revisionNote': data.revisionNote,
    };
  }

  static DemoFlowData _decodeFlowData(Object? raw) {
    if (raw is! Map) {
      return const DemoFlowData();
    }

    return DemoFlowData(
      userIssue: _nullableText(raw['userIssue']),
      noiseNow: _nullableText(raw['noiseNow']),
      safety: _nullableText(raw['safety']),
      residence: _nullableText(raw['residence']),
      management: _nullableText(raw['management']),
      noiseType: _nullableText(raw['noiseType']),
      frequency: _nullableText(raw['frequency']),
      timeBand: _nullableText(raw['timeBand']),
      sourceCertainty: _nullableText(raw['sourceCertainty']),
      eligibilityReason: _nullableText(raw['eligibilityReason']),
      route: _nullableText(raw['route']),
      startedAtDate: _dateFromIso(raw['startedAtDate']),
      startedAtTime: _decodeTime(raw['startedAtTime']),
      revisionNote: _nullableText(raw['revisionNote']),
    );
  }

  static Map<String, String> _decodeStringMap(Object? raw) {
    if (raw is! Map) return <String, String>{};
    final map = <String, String>{};
    raw.forEach((key, value) {
      final normalizedKey = key.toString();
      final normalizedValue = value?.toString() ?? '';
      if (normalizedKey.isEmpty || normalizedValue.isEmpty) return;
      map[normalizedKey] = normalizedValue;
    });
    return map;
  }

  static List<ChatHistoryEntry> _decodeHistoryEntries(Object? raw) {
    if (raw is! List) return const <ChatHistoryEntry>[];
    return raw
        .whereType<Map>()
        .map(
          (item) => ChatHistoryEntry(
            text: item['text']?.toString() ?? '',
            isAi: _asBool(item['isAi']),
            fromMiniInterface: _asBool(item['fromMiniInterface']),
          ),
        )
        .where((entry) => entry.text.trim().isNotEmpty)
        .toList(growable: false);
  }

  static Map<String, int>? _encodeTime(TimeOfDay? time) {
    if (time == null) return null;
    return <String, int>{
      'hour': time.hour,
      'minute': time.minute,
    };
  }

  static TimeOfDay? _decodeTime(Object? raw) {
    if (raw is! Map) return null;
    final hour = _asInt(raw['hour'], fallback: -1);
    final minute = _asInt(raw['minute'], fallback: -1);
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  static String? _dateToIso(DateTime? value) => value?.toIso8601String();

  static DateTime? _dateFromIso(Object? raw) {
    final value = raw?.toString();
    if (value == null || value.trim().isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static String? _nullableText(Object? raw) {
    final value = raw?.toString();
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static bool _asBool(Object? raw, {bool fallback = false}) {
    if (raw is bool) return raw;
    if (raw is String) return raw.toLowerCase() == 'true';
    return fallback;
  }

  static bool? _asNullableBool(Object? raw) {
    if (raw == null) return null;
    if (raw is bool) return raw;
    if (raw is String) {
      final lower = raw.toLowerCase();
      if (lower == 'true') return true;
      if (lower == 'false') return false;
    }
    return null;
  }

  static int _asInt(Object? raw, {int fallback = 0}) {
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '') ?? fallback;
  }

  static T _parseEnum<T extends Enum>(
    List<T> values,
    String? name,
    T fallback,
  ) {
    if (name == null || name.isEmpty) return fallback;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }
}
