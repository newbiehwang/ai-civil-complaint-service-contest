import 'dart:async';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/api_client.dart';
import '../../services/auth_session.dart';
import '../../services/error_map.dart';
import '../../theme/app_colors.dart';
import '../../theme/krds_tokens.dart';

enum MiniInterfaceType {
  none,
  listPicker,
  multiForm,
  optionList,
  measureCheck,
  datePicker,
  timePicker,
  summaryCard,
  pathChooser,
  noiseDiaryBuilder,
  draftViewer,
  draftConfirm,
  statusFeed,
}

enum _PickerOwner {
  incident,
  noiseDiary,
}

enum DemoStep {
  waitingIssue,
  noiseNow,
  safety,
  residence,
  management,
  noiseType,
  frequency,
  timeBand,
  sourceCertainty,
  dateTime,
  ineligible,
  multiForm,
  summary,
  pathChooser,
  pathAlternative,
  evidenceV1,
  measureCheck,
  evidenceV2,
  noiseDiary,
  draftViewer,
  waitingRevision,
  draftConfirm,
  statusFeed,
  complete,
}

const List<String> _kKrFontFallback = <String>[
  'Pretendard GOV',
  'Pretendard',
  'Apple SD Gothic Neo',
  'Noto Sans KR',
];
const Color _kMiniSubtitleColor = Color(0xFF686868);

class ChatHistoryEntry {
  const ChatHistoryEntry({
    required this.text,
    required this.isAi,
    this.fromMiniInterface = false,
  });

  final String text;
  final bool isAi;
  final bool fromMiniInterface;
}

class MiniOption {
  const MiniOption({
    required this.id,
    required this.label,
    this.description,
  });

  final String id;
  final String label;
  final String? description;
}

class DemoFlowData {
  const DemoFlowData({
    this.userIssue,
    this.noiseNow,
    this.safety,
    this.residence,
    this.management,
    this.noiseType,
    this.frequency,
    this.timeBand,
    this.sourceCertainty,
    this.eligibilityReason,
    this.route,
    this.startedAtDate,
    this.startedAtTime,
    this.revisionNote,
  });

  final String? userIssue;
  final String? noiseNow;
  final String? safety;
  final String? residence;
  final String? management;
  final String? noiseType;
  final String? frequency;
  final String? timeBand;
  final String? sourceCertainty;
  final String? eligibilityReason;
  final String? route;
  final DateTime? startedAtDate;
  final TimeOfDay? startedAtTime;
  final String? revisionNote;

  DemoFlowData copyWith({
    String? userIssue,
    String? noiseNow,
    String? safety,
    String? residence,
    String? management,
    String? noiseType,
    String? frequency,
    String? timeBand,
    String? sourceCertainty,
    String? eligibilityReason,
    String? route,
    DateTime? startedAtDate,
    TimeOfDay? startedAtTime,
    String? revisionNote,
  }) {
    return DemoFlowData(
      userIssue: userIssue ?? this.userIssue,
      noiseNow: noiseNow ?? this.noiseNow,
      safety: safety ?? this.safety,
      residence: residence ?? this.residence,
      management: management ?? this.management,
      noiseType: noiseType ?? this.noiseType,
      frequency: frequency ?? this.frequency,
      timeBand: timeBand ?? this.timeBand,
      sourceCertainty: sourceCertainty ?? this.sourceCertainty,
      eligibilityReason: eligibilityReason ?? this.eligibilityReason,
      route: route ?? this.route,
      startedAtDate: startedAtDate ?? this.startedAtDate,
      startedAtTime: startedAtTime ?? this.startedAtTime,
      revisionNote: revisionNote ?? this.revisionNote,
    );
  }
}

class ChatbotScreenSnapshot {
  const ChatbotScreenSnapshot({
    required this.isThinking,
    required this.isAiAnswerReady,
    required this.aiAnimationNonce,
    required this.aiText,
    required this.step,
    required this.miniType,
    required this.options,
    required this.selectedOptionIds,
    required this.data,
    required this.incidentDate,
    required this.incidentTime,
    required this.multiResidenceId,
    required this.multiTimeBandId,
    required this.noiseDiaryDate,
    required this.noiseDiaryTime,
    required this.noiseDiaryDuration,
    required this.noiseDiaryType,
    required this.noiseDiaryImpact,
    required this.evidenceAttachmentIds,
    required this.evidenceAttachmentNames,
    required this.evidenceV2AttachmentIds,
    required this.evidenceV2AttachmentNames,
    required this.isPickingEvidence,
    required this.measureVisitDone,
    required this.measureWithin30Days,
    required this.measureReceivingUnit,
    required this.pickerOwnerIsNoiseDiary,
    required this.pickerMonth,
    required this.pickerDateSelection,
    required this.pickerIsAm,
    required this.pickerHour12,
    required this.pickerMinute,
    required this.triageNoiseNowId,
    required this.triageSafetyId,
    required this.intakeResidenceId,
    required this.intakeManagementId,
    required this.intakeSourceCertaintyId,
    required this.intakeNoiseTypeId,
    required this.intakeFrequencyId,
    required this.intakeTimeBandId,
    required this.backendCaseId,
    required this.backendCaseStatus,
    required this.backendTraceId,
    required this.backendEnabled,
    required this.backendUiHintDriven,
    required this.backendUiHintType,
    required this.backendUiSelectionMode,
    required this.historyEntries,
    required this.hasIntroBridgeShown,
  });

  final bool isThinking;
  final bool isAiAnswerReady;
  final int aiAnimationNonce;
  final String aiText;
  final DemoStep step;
  final MiniInterfaceType miniType;
  final List<MiniOption> options;
  final Set<String> selectedOptionIds;
  final DemoFlowData data;
  final DateTime? incidentDate;
  final TimeOfDay? incidentTime;
  final String? multiResidenceId;
  final String? multiTimeBandId;
  final DateTime? noiseDiaryDate;
  final TimeOfDay? noiseDiaryTime;
  final String? noiseDiaryDuration;
  final String? noiseDiaryType;
  final String? noiseDiaryImpact;
  final Set<String> evidenceAttachmentIds;
  final Map<String, String> evidenceAttachmentNames;
  final Set<String> evidenceV2AttachmentIds;
  final Map<String, String> evidenceV2AttachmentNames;
  final bool isPickingEvidence;
  final bool? measureVisitDone;
  final bool? measureWithin30Days;
  final bool? measureReceivingUnit;
  final bool pickerOwnerIsNoiseDiary;
  final DateTime pickerMonth;
  final DateTime? pickerDateSelection;
  final bool pickerIsAm;
  final int pickerHour12;
  final int pickerMinute;
  final String? triageNoiseNowId;
  final String? triageSafetyId;
  final String? intakeResidenceId;
  final String? intakeManagementId;
  final String? intakeSourceCertaintyId;
  final String? intakeNoiseTypeId;
  final String? intakeFrequencyId;
  final String? intakeTimeBandId;
  final String? backendCaseId;
  final String? backendCaseStatus;
  final String? backendTraceId;
  final bool backendEnabled;
  final bool backendUiHintDriven;
  final String backendUiHintType;
  final String backendUiSelectionMode;
  final List<ChatHistoryEntry> historyEntries;
  final bool hasIntroBridgeShown;
}

class ChatbotDemoScreen extends StatefulWidget {
  const ChatbotDemoScreen({
    required this.onRestart,
    required this.onBackToList,
    this.initialSnapshot,
    this.initialBackendCaseId,
    this.initialBackendCaseStatus,
    this.onSnapshotChanged,
    super.key,
  });

  final VoidCallback onRestart;
  final VoidCallback onBackToList;
  final ChatbotScreenSnapshot? initialSnapshot;
  final String? initialBackendCaseId;
  final String? initialBackendCaseStatus;
  final ValueChanged<ChatbotScreenSnapshot>? onSnapshotChanged;

  @override
  State<ChatbotDemoScreen> createState() => _ChatbotDemoScreenState();
}

class _ChatbotDemoScreenState extends State<ChatbotDemoScreen> {
  static const _durations = ['10분 미만', '10~30분', '30분 이상', '모름'];
  static const _noiseTypes = ['쿵쿵', '음악', '가구 끄는 소리', '기타'];
  static const _impacts = ['수면 방해', '업무 방해', '불안', '기타'];
  static const _residenceOptions = <MiniOption>[
    MiniOption(id: 'residence-apartment', label: '아파트'),
    MiniOption(id: 'residence-villa', label: '빌라'),
    MiniOption(id: 'residence-officetel', label: '오피스텔'),
    MiniOption(id: 'residence-other', label: '기타'),
  ];
  static const _timeBandOptions = <MiniOption>[
    MiniOption(id: 'time-evening', label: '저녁'),
    MiniOption(id: 'time-night', label: '심야'),
    MiniOption(id: 'time-dawn', label: '새벽'),
    MiniOption(id: 'time-irregular', label: '불규칙'),
  ];
  static const _managementOptions = <MiniOption>[
    MiniOption(id: 'management-yes', label: '있음'),
    MiniOption(id: 'management-no', label: '없음'),
    MiniOption(id: 'management-unknown', label: '모름'),
  ];
  static const _sourceCertaintyOptions = <MiniOption>[
    MiniOption(id: 'source-exact', label: '호수까지 확실'),
    MiniOption(id: 'source-floor', label: '층은 확실(호수 불명)'),
    MiniOption(id: 'source-unknown', label: '모름'),
  ];
  static const _noiseTypeOptions = <MiniOption>[
    MiniOption(id: 'noise-impact', label: '충격 소음(쿵쿵)'),
    MiniOption(id: 'noise-air', label: '공기전달 소음(TV/음악)'),
    MiniOption(id: 'noise-both', label: '둘 다'),
    MiniOption(id: 'noise-unknown', label: '잘 모르겠음'),
  ];
  static const _frequencyOptions = <MiniOption>[
    MiniOption(id: 'freq-low', label: '주 1회 이하'),
    MiniOption(id: 'freq-mid', label: '주 2~3회'),
    MiniOption(id: 'freq-high', label: '거의 매일'),
  ];
  static const _triageNoiseNowOptions = <MiniOption>[
    MiniOption(id: 'noise-now-active', label: '지금 진행 중'),
    MiniOption(id: 'noise-now-recent', label: '방금 멈춤'),
    MiniOption(id: 'noise-now-repeat', label: '자주 반복'),
  ];
  static const _triageSafetyOptions = <MiniOption>[
    MiniOption(id: 'safety-normal', label: '위협 징후 없음'),
    MiniOption(id: 'safety-unknown', label: '잘 모르겠음'),
    MiniOption(id: 'safety-danger', label: '위협 징후 있음'),
  ];

  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _multiFormScrollController = ScrollController();
  final ScrollController _conversationScrollController = ScrollController();
  final GlobalKey _currentAiAnchorKey = GlobalKey();
  final ApiClient _apiClient = ApiClient();
  final String _bootTraceId = ApiClient().createTraceId();

  bool _isThinking = false;
  bool _isAiAnswerReady = false;
  bool _isMiniInterfaceCollapsed = false;
  bool _hasIntroBridgeShown = false;
  int _aiAnimationNonce = 0;
  String _aiText = '안녕하세요, 정부24 민원 서비스 도우미입니다.\n무엇을 도와드릴까요?';
  DemoStep _step = DemoStep.waitingIssue;
  MiniInterfaceType _miniType = MiniInterfaceType.none;
  List<MiniOption> _options = const [];
  final Set<String> _selectedOptionIds = {};
  DemoFlowData _data = const DemoFlowData();

  DateTime? _incidentDate;
  TimeOfDay? _incidentTime;
  String? _multiResidenceId;
  String? _multiTimeBandId;
  DateTime? _noiseDiaryDate;
  TimeOfDay? _noiseDiaryTime;
  String? _noiseDiaryDuration;
  String? _noiseDiaryType;
  String? _noiseDiaryImpact;
  final Set<String> _evidenceAttachmentIds = <String>{};
  final Map<String, String> _evidenceAttachmentNames = <String, String>{};
  final Set<String> _evidenceV2AttachmentIds = <String>{};
  final Map<String, String> _evidenceV2AttachmentNames = <String, String>{};
  final ImagePicker _imagePicker = ImagePicker();
  bool _isPickingEvidence = false;
  bool? _measureVisitDone;
  bool? _measureWithin30Days;
  bool? _measureReceivingUnit;
  _PickerOwner _pickerOwner = _PickerOwner.incident;
  DateTime _pickerMonth = DateTime.now();
  DateTime? _pickerDateSelection;
  bool _pickerIsAm = true;
  int _pickerHour12 = 1;
  int _pickerMinute = 0;
  String? _triageNoiseNowId;
  String? _triageSafetyId;
  String? _intakeResidenceId;
  String? _intakeManagementId;
  String? _intakeSourceCertaintyId;
  String? _intakeNoiseTypeId;
  String? _intakeFrequencyId;
  String? _intakeTimeBandId;
  String? _backendCaseId;
  String? _backendCaseStatus;
  String? _backendTraceId;
  bool _isBackendUiHintDriven = false;
  String _backendUiHintType = 'NONE';
  String _backendUiSelectionMode = 'NONE';
  bool _forceLocalDemoMode = false;
  bool _isBackendRequestInFlight = false;
  bool _wasConversationScrollLocked = false;
  Future<void> _backendSyncQueue = Future<void>.value();
  final List<ChatHistoryEntry> _historyEntries = <ChatHistoryEntry>[];

  @override
  void initState() {
    super.initState();
    if (widget.initialSnapshot != null) {
      _restoreFromSnapshot(widget.initialSnapshot!);
    } else {
      final initialCaseId = widget.initialBackendCaseId?.trim();
      if (initialCaseId != null && initialCaseId.isNotEmpty) {
        _backendCaseId = initialCaseId;
      }
      final initialCaseStatus = widget.initialBackendCaseStatus?.trim();
      if (initialCaseStatus != null && initialCaseStatus.isNotEmpty) {
        _backendCaseStatus = initialCaseStatus;
      }
    }
    _backendTraceId ??= _bootTraceId;
    _inputController.addListener(_handleInputControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.initialSnapshot == null &&
          _historyEntries.isEmpty &&
          _step == DemoStep.waitingIssue &&
          _isBackendEnabled) {
        unawaited(
          _requestBackendTurnForText(
            '',
            thinkingDuration: const Duration(milliseconds: 240),
            allowLocalFallback: false,
          ),
        );
      }
      if (_isAiAnswerReady) {
        _pinCurrentAiToTop();
      }
    });
  }

  void _handleInputControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    widget.onSnapshotChanged?.call(_buildSnapshot());
    _inputController.removeListener(_handleInputControllerChanged);
    _inputController.dispose();
    _focusNode.dispose();
    _multiFormScrollController.dispose();
    _conversationScrollController.dispose();
    super.dispose();
  }

  void _restoreFromSnapshot(ChatbotScreenSnapshot snapshot) {
    _isThinking = snapshot.isThinking;
    _isAiAnswerReady = snapshot.isAiAnswerReady;
    _aiAnimationNonce = snapshot.aiAnimationNonce;
    _aiText = snapshot.aiText;
    _step = snapshot.step;
    _miniType = snapshot.miniType;
    _options = List<MiniOption>.from(snapshot.options);
    _selectedOptionIds
      ..clear()
      ..addAll(snapshot.selectedOptionIds);
    _data = snapshot.data;
    _incidentDate = snapshot.incidentDate;
    _incidentTime = snapshot.incidentTime;
    _multiResidenceId = snapshot.multiResidenceId;
    _multiTimeBandId = snapshot.multiTimeBandId;
    _noiseDiaryDate = snapshot.noiseDiaryDate;
    _noiseDiaryTime = snapshot.noiseDiaryTime;
    _noiseDiaryDuration = snapshot.noiseDiaryDuration;
    _noiseDiaryType = snapshot.noiseDiaryType;
    _noiseDiaryImpact = snapshot.noiseDiaryImpact;
    _evidenceAttachmentIds
      ..clear()
      ..addAll(snapshot.evidenceAttachmentIds);
    _evidenceAttachmentNames
      ..clear()
      ..addAll(snapshot.evidenceAttachmentNames);
    _evidenceV2AttachmentIds
      ..clear()
      ..addAll(snapshot.evidenceV2AttachmentIds);
    _evidenceV2AttachmentNames
      ..clear()
      ..addAll(snapshot.evidenceV2AttachmentNames);
    _isPickingEvidence = snapshot.isPickingEvidence;
    _measureVisitDone = snapshot.measureVisitDone;
    _measureWithin30Days = snapshot.measureWithin30Days;
    _measureReceivingUnit = snapshot.measureReceivingUnit;
    _pickerOwner = snapshot.pickerOwnerIsNoiseDiary
        ? _PickerOwner.noiseDiary
        : _PickerOwner.incident;
    _pickerMonth = snapshot.pickerMonth;
    _pickerDateSelection = snapshot.pickerDateSelection;
    _pickerIsAm = snapshot.pickerIsAm;
    _pickerHour12 = snapshot.pickerHour12;
    _pickerMinute = snapshot.pickerMinute;
    _triageNoiseNowId = snapshot.triageNoiseNowId;
    _triageSafetyId = snapshot.triageSafetyId;
    _intakeResidenceId = snapshot.intakeResidenceId;
    _intakeManagementId = snapshot.intakeManagementId;
    _intakeSourceCertaintyId = snapshot.intakeSourceCertaintyId;
    _intakeNoiseTypeId = snapshot.intakeNoiseTypeId;
    _intakeFrequencyId = snapshot.intakeFrequencyId;
    _intakeTimeBandId = snapshot.intakeTimeBandId;
    _backendCaseId = snapshot.backendCaseId;
    _backendCaseStatus = snapshot.backendCaseStatus;
    _backendTraceId = snapshot.backendTraceId;
    _isBackendUiHintDriven = snapshot.backendUiHintDriven;
    _backendUiHintType = snapshot.backendUiHintType;
    _backendUiSelectionMode = snapshot.backendUiSelectionMode;
    _historyEntries
      ..clear()
      ..addAll(snapshot.historyEntries);
    _hasIntroBridgeShown = snapshot.hasIntroBridgeShown;
    _wasConversationScrollLocked =
        snapshot.isThinking || !snapshot.isAiAnswerReady;
  }

  ChatbotScreenSnapshot _buildSnapshot() {
    final safeIsAiAnswerReady = _isThinking ? true : _isAiAnswerReady;
    return ChatbotScreenSnapshot(
      isThinking: false,
      isAiAnswerReady: safeIsAiAnswerReady,
      aiAnimationNonce: _aiAnimationNonce,
      aiText: _aiText,
      step: _step,
      miniType: _miniType,
      options: List<MiniOption>.from(_options),
      selectedOptionIds: Set<String>.from(_selectedOptionIds),
      data: _data,
      incidentDate: _incidentDate,
      incidentTime: _incidentTime,
      multiResidenceId: _multiResidenceId,
      multiTimeBandId: _multiTimeBandId,
      noiseDiaryDate: _noiseDiaryDate,
      noiseDiaryTime: _noiseDiaryTime,
      noiseDiaryDuration: _noiseDiaryDuration,
      noiseDiaryType: _noiseDiaryType,
      noiseDiaryImpact: _noiseDiaryImpact,
      evidenceAttachmentIds: Set<String>.from(_evidenceAttachmentIds),
      evidenceAttachmentNames:
          Map<String, String>.from(_evidenceAttachmentNames),
      evidenceV2AttachmentIds: Set<String>.from(_evidenceV2AttachmentIds),
      evidenceV2AttachmentNames:
          Map<String, String>.from(_evidenceV2AttachmentNames),
      isPickingEvidence: _isPickingEvidence,
      measureVisitDone: _measureVisitDone,
      measureWithin30Days: _measureWithin30Days,
      measureReceivingUnit: _measureReceivingUnit,
      pickerOwnerIsNoiseDiary: _pickerOwner == _PickerOwner.noiseDiary,
      pickerMonth: _pickerMonth,
      pickerDateSelection: _pickerDateSelection,
      pickerIsAm: _pickerIsAm,
      pickerHour12: _pickerHour12,
      pickerMinute: _pickerMinute,
      triageNoiseNowId: _triageNoiseNowId,
      triageSafetyId: _triageSafetyId,
      intakeResidenceId: _intakeResidenceId,
      intakeManagementId: _intakeManagementId,
      intakeSourceCertaintyId: _intakeSourceCertaintyId,
      intakeNoiseTypeId: _intakeNoiseTypeId,
      intakeFrequencyId: _intakeFrequencyId,
      intakeTimeBandId: _intakeTimeBandId,
      backendCaseId: _backendCaseId,
      backendCaseStatus: _backendCaseStatus,
      backendTraceId: _backendTraceId ?? _bootTraceId,
      backendEnabled: _isBackendEnabled,
      backendUiHintDriven: _isBackendUiHintDriven,
      backendUiHintType: _backendUiHintType,
      backendUiSelectionMode: _backendUiSelectionMode,
      historyEntries: List<ChatHistoryEntry>.from(_historyEntries),
      hasIntroBridgeShown: _hasIntroBridgeShown,
    );
  }

  void _handleBackToList() {
    widget.onSnapshotChanged?.call(_buildSnapshot());
    widget.onBackToList();
  }

  void _appendHistory({
    required String text,
    required bool isAi,
    bool fromMiniInterface = false,
  }) {
    final normalized = text.trim();
    if (normalized.isEmpty) return;
    if (_historyEntries.isNotEmpty) {
      final last = _historyEntries.last;
      if (last.text == normalized &&
          last.isAi == isAi &&
          last.fromMiniInterface == fromMiniInterface) {
        return;
      }
    }
    _historyEntries.add(
      ChatHistoryEntry(
        text: normalized,
        isAi: isAi,
        fromMiniInterface: fromMiniInterface,
      ),
    );
  }

  void _archiveCurrentAiToHistory() {
    _appendHistory(text: _aiText, isAi: true);
  }

  void _recordUserChatInput(String text) {
    _collapseHistoryToCurrent(immediate: true);
    _archiveCurrentAiToHistory();
    _appendHistory(text: text, isAi: false);
  }

  void _recordMiniResponse(String text) {
    _collapseHistoryToCurrent(immediate: true);
    _archiveCurrentAiToHistory();
    _appendHistory(text: text, isAi: false, fromMiniInterface: true);
  }

  void _collapseHistoryToCurrent({bool immediate = false}) {
    _pinCurrentAiToTop(animate: !immediate);
  }

  void _pinCurrentAiToTop({bool animate = false}) {
    final context = _currentAiAnchorKey.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      alignment: 0,
      duration: animate ? const Duration(milliseconds: 220) : Duration.zero,
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _showThinkingThen(
    VoidCallback done, {
    Duration duration = const Duration(milliseconds: 560),
  }) async {
    FocusScope.of(context).unfocus();
    _collapseHistoryToCurrent(immediate: true);
    setState(() {
      _isThinking = true;
    });
    await Future<void>.delayed(duration);
    if (!mounted) return;
    setState(() {
      _isThinking = false;
    });
    done();
  }

  void _setAi({
    required String text,
    required DemoStep step,
    MiniInterfaceType miniType = MiniInterfaceType.none,
    List<MiniOption> options = const [],
    bool backendUiHintDriven = false,
    String backendUiHintType = 'NONE',
    String backendUiSelectionMode = 'NONE',
  }) {
    if (miniType != MiniInterfaceType.none) {
      FocusScope.of(context).unfocus();
    }
    setState(() {
      _aiAnimationNonce += 1;
      _isAiAnswerReady = false;
      _isMiniInterfaceCollapsed = false;
      _aiText = _formatAiTextForDisplay(text);
      _step = step;
      _miniType = miniType;
      _options = options;
      _isBackendUiHintDriven = backendUiHintDriven;
      _backendUiHintType = backendUiHintType;
      _backendUiSelectionMode = backendUiSelectionMode;
      _selectedOptionIds.clear();
      if (step == DemoStep.evidenceV1) {
        _evidenceAttachmentIds.clear();
        _evidenceAttachmentNames.clear();
      }
      if (step == DemoStep.evidenceV2) {
        _evidenceV2AttachmentIds.clear();
        _evidenceV2AttachmentNames.clear();
      }
    });
  }

  String _formatAiTextForDisplay(String raw) {
    final normalized =
        raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
    if (normalized.isEmpty) return normalized;

    final compact = normalized
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'[ \t]*\n+[ \t]*'), '\n')
        .trim();
    if (compact.isEmpty) return normalized;

    final withLineBreak = compact.replaceAllMapped(
      RegExp(r'([.!?。！？])\s*(?=\S)'),
      (match) => '${match.group(1)}\n',
    );

    return withLineBreak.replaceAll(RegExp(r'\n{2,}'), '\n').trim();
  }

  void _handleAiTextAnimationCompleted() {
    if (!mounted || _isThinking || _isAiAnswerReady) return;
    setState(() {
      _isAiAnswerReady = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _pinCurrentAiToTop();
    });
  }

  String _formatDate(DateTime date) {
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    return '${date.year}년 ${date.month}월 ${date.day}일 (${weekdays[date.weekday % 7]})';
  }

  String _formatTime(TimeOfDay time) {
    final meridiem = time.hour < 12 ? '오전' : '오후';
    final hour12 =
        time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    return '$meridiem ${hour12.toString().padLeft(2, '0')}시 ${time.minute.toString().padLeft(2, '0')}분';
  }

  bool get _isNoiseDiaryReady {
    return _noiseDiaryDate != null &&
        _noiseDiaryTime != null &&
        _noiseDiaryDuration != null &&
        _noiseDiaryType != null &&
        _noiseDiaryImpact != null;
  }

  bool get _isMultiFormReady {
    return _multiResidenceId != null &&
        _multiTimeBandId != null &&
        _incidentDate != null &&
        _incidentTime != null;
  }

  bool get _isIntakeBasicReady {
    return _intakeResidenceId != null &&
        _intakeManagementId != null &&
        _intakeSourceCertaintyId != null;
  }

  bool get _isIntakeDetailReady {
    return _intakeNoiseTypeId != null &&
        _intakeFrequencyId != null &&
        _intakeTimeBandId != null &&
        _incidentDate != null &&
        _incidentTime != null;
  }

  String? _optionIdByLabel(List<MiniOption> options, String? label) {
    if (label == null) return null;
    for (final option in options) {
      if (option.label == label) return option.id;
    }
    return null;
  }

  bool get _isMeasureCheckReady {
    return _measureVisitDone != null &&
        _measureWithin30Days != null &&
        _measureReceivingUnit != null;
  }

  bool get _isMeasureEligible {
    return _measureVisitDone == true &&
        _measureWithin30Days == true &&
        _measureReceivingUnit == true;
  }

  bool get _isServerMode => AuthSession.useBackend;
  bool get _allowLocalDemoFallback => !_isServerMode;

  bool get _isBackendEnabled => _apiClient.isConfigured && !_forceLocalDemoMode;

  String _housingTypeForBackend() {
    final residence = (_data.residence ?? '').trim();
    switch (residence) {
      case '아파트':
        return 'APARTMENT';
      case '빌라':
        return 'VILLA';
      case '오피스텔':
        return 'OFFICETEL';
      default:
        return 'OTHER';
    }
  }

  Future<ChatTurnResponseDto> _sendChatTurnMessage(
    String message, {
    ChatTurnInteractionPayload? interaction,
  }) async {
    final traceId = _backendTraceId ?? _bootTraceId;
    final lastUiHintType = _backendUiHintType == 'NONE'
        ? _sourceUiTypeFromMiniType(_miniType)
        : _backendUiHintType;
    final response = await _apiClient.chatTurn(
      traceId: traceId,
      userMessage: message,
      caseId: _backendCaseId,
      housingType: _housingTypeForBackend(),
      uiCapabilities: const <String>[
        'LIST_PICKER',
        'OPTION_LIST',
        'SUMMARY_CARD',
        'PATH_CHOOSER',
        'STATUS_FEED',
      ],
      interaction: interaction,
      lastUiHintType: lastUiHintType,
      recentMessages: _buildRecentMessagesForPlanner(),
    );
    if (response.sessionId.trim().isNotEmpty) {
      _backendCaseId = response.sessionId.trim();
    }
    final backendStatus = response.statePatch['status']?.toString();
    if (backendStatus != null && backendStatus.trim().isNotEmpty) {
      _backendCaseStatus = backendStatus.trim();
    }
    _backendTraceId = traceId;
    return response;
  }

  String _normalizeBackendSelectionMode(String raw) {
    final normalized = raw.trim().toUpperCase();
    if (normalized == 'MULTIPLE') return 'MULTIPLE';
    if (normalized == 'SINGLE') return 'SINGLE';
    return 'NONE';
  }

  String _sourceUiTypeFromMiniType(MiniInterfaceType miniType) {
    switch (miniType) {
      case MiniInterfaceType.listPicker:
        return 'LIST_PICKER';
      case MiniInterfaceType.optionList:
      case MiniInterfaceType.datePicker:
      case MiniInterfaceType.timePicker:
        return 'OPTION_LIST';
      case MiniInterfaceType.pathChooser:
        return 'PATH_CHOOSER';
      case MiniInterfaceType.summaryCard:
        return 'SUMMARY_CARD';
      case MiniInterfaceType.statusFeed:
        return 'STATUS_FEED';
      default:
        return 'NONE';
    }
  }

  List<ChatTurnRecentMessagePayload> _buildRecentMessagesForPlanner() {
    if (_historyEntries.isEmpty) {
      return const <ChatTurnRecentMessagePayload>[];
    }
    final start = _historyEntries.length > 10 ? _historyEntries.length - 10 : 0;
    final slice = _historyEntries.sublist(start);
    return slice
        .map(
          (entry) => ChatTurnRecentMessagePayload(
            role: entry.isAi ? 'ASSISTANT' : 'USER',
            text: entry.text,
            source: entry.fromMiniInterface ? 'MINI_INTERFACE' : 'CHAT_INPUT',
          ),
        )
        .toList(growable: false);
  }

  MiniInterfaceType _miniTypeFromBackendUiHint({
    required String uiType,
    required List<MiniOption> options,
  }) {
    final normalized = uiType.trim().toUpperCase();
    switch (normalized) {
      case 'LIST_PICKER':
        return options.isEmpty
            ? MiniInterfaceType.none
            : MiniInterfaceType.listPicker;
      case 'OPTION_LIST':
        return MiniInterfaceType.optionList;
      case 'PATH_CHOOSER':
        return options.isEmpty
            ? MiniInterfaceType.none
            : MiniInterfaceType.pathChooser;
      case 'SUMMARY_CARD':
        return MiniInterfaceType.summaryCard;
      case 'STATUS_FEED':
        return MiniInterfaceType.statusFeed;
      default:
        return MiniInterfaceType.none;
    }
  }

  List<String> _requiredFieldsFromUiMeta(Map<String, dynamic> meta) {
    final raw = meta['requiredFields'];
    if (raw is! List) return const <String>[];
    return raw
        .map((value) => value?.toString().trim() ?? '')
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  DemoStep _intakeStepFromRequiredFields(List<String> requiredFields) {
    bool hasAny(Set<String> targets) =>
        requiredFields.any((field) => targets.contains(field));

    if (hasAny(<String>{'noiseNow', 'safety', 'safetyContinue'})) {
      return DemoStep.noiseNow;
    }
    if (hasAny(<String>{'residence', 'management', 'sourceCertainty'})) {
      return DemoStep.multiForm;
    }
    if (hasAny(<String>{'noiseType', 'frequency', 'timeBand'})) {
      return DemoStep.dateTime;
    }
    return _step;
  }

  DemoStep _stepFromBackendTurn(
    ChatTurnResponseDto response,
    MiniInterfaceType miniType,
    List<MiniOption> options,
  ) {
    final nextAction = response.nextAction.trim().toUpperCase();
    final uiType = response.uiHint.type.trim().toUpperCase();

    if (miniType == MiniInterfaceType.pathChooser || uiType == 'PATH_CHOOSER') {
      return DemoStep.pathChooser;
    }
    if (miniType == MiniInterfaceType.statusFeed || uiType == 'STATUS_FEED') {
      return DemoStep.statusFeed;
    }
    if (miniType == MiniInterfaceType.summaryCard || uiType == 'SUMMARY_CARD') {
      return DemoStep.summary;
    }
    if (miniType == MiniInterfaceType.optionList || uiType == 'OPTION_LIST') {
      if (nextAction == 'UPLOAD_EVIDENCE' ||
          nextAction == 'OPTIONAL_EVIDENCE_OR_SUBMIT' ||
          nextAction == 'SUBMIT_CASE') {
        return DemoStep.evidenceV1;
      }
      return DemoStep.dateTime;
    }
    if (nextAction == 'CLOSE_CASE' || nextAction == 'DONE') {
      return DemoStep.complete;
    }
    if (nextAction == 'WAIT_INSTITUTION_RESULT' ||
        nextAction == 'RESPOND_SUPPLEMENT') {
      return DemoStep.statusFeed;
    }
    if (nextAction == 'CONFIRM_ROUTE') {
      return DemoStep.pathChooser;
    }
    if (nextAction == 'UPLOAD_EVIDENCE' ||
        nextAction == 'OPTIONAL_EVIDENCE_OR_SUBMIT') {
      return DemoStep.evidenceV1;
    }
    if (nextAction == 'REQUEST_DECOMPOSITION' ||
        nextAction == 'REQUEST_ROUTING_RECOMMENDATION') {
      return DemoStep.pathChooser;
    }

    if (miniType == MiniInterfaceType.listPicker && options.isNotEmpty) {
      final labels = options.map((option) => option.label).toSet();
      if (labels.contains('지금 진행 중') && labels.contains('방금 멈춤')) {
        return DemoStep.noiseNow;
      }
      if (labels.contains('위협 징후 없음')) {
        return DemoStep.safety;
      }
      if (labels.contains('아파트')) {
        return DemoStep.residence;
      }
      if (labels.contains('있음') &&
          labels.contains('없음') &&
          labels.contains('모름')) {
        return DemoStep.management;
      }
      if (labels.contains('충격 소음(쿵쿵)')) {
        return DemoStep.noiseType;
      }
      if (labels.contains('거의 매일')) {
        return DemoStep.frequency;
      }
      if (labels.contains('저녁')) {
        return DemoStep.timeBand;
      }
      if (labels.contains('호수까지 확실')) {
        return DemoStep.sourceCertainty;
      }
    }

    return _step;
  }

  Future<List<MiniOption>> _resolveBackendUiOptions(ChatUiHintDto hint) async {
    final options = hint.options
        .map((option) => MiniOption(
              id: option.id.trim(),
              label: option.label.trim(),
            ))
        .where((option) => option.id.isNotEmpty && option.label.isNotEmpty)
        .toList(growable: false);

    final hintType = hint.type.trim().toUpperCase();
    if (hintType != 'PATH_CHOOSER' || options.isNotEmpty) {
      return options;
    }

    final caseId = _backendCaseId?.trim();
    if (caseId == null || caseId.isEmpty) return options;

    try {
      final traceId = _backendTraceId ?? _bootTraceId;
      final recommendation =
          await _apiClient.recommendRoute(traceId: traceId, caseId: caseId);
      return recommendation.options
          .where((option) =>
              option.optionId.trim().isNotEmpty &&
              option.label.trim().isNotEmpty)
          .map(
            (option) => MiniOption(
              id: option.optionId.trim(),
              label: option.label.trim(),
              description:
                  option.reason.trim().isEmpty ? null : option.reason.trim(),
            ),
          )
          .toList(growable: false);
    } catch (error) {
      _showApiErrorSnack(error);
      return options;
    }
  }

  Future<void> _applyBackendTurn(ChatTurnResponseDto response) async {
    final hint = response.uiHint;
    final options = await _resolveBackendUiOptions(hint);
    final flowStep =
        (hint.meta['flowStep']?.toString() ?? '').trim().toLowerCase();
    final requiredFields = _requiredFieldsFromUiMeta(hint.meta);
    final currentActionRequired =
        (response.statePatch['currentActionRequired']?.toString() ?? '')
            .trim()
            .toUpperCase();
    final forceNoMiniInterface = currentActionRequired == 'GENERAL_CHAT';
    final forceIntakeMultiForm = !forceNoMiniInterface &&
        currentActionRequired == 'INTAKE_REQUIRED' &&
        flowStep == 'intake' &&
        requiredFields.isNotEmpty;
    final effectiveUiType =
        forceNoMiniInterface ? 'NONE' : hint.type.trim().toUpperCase();
    final effectiveOptions =
        forceNoMiniInterface ? const <MiniOption>[] : options;
    final mappedMiniType = _miniTypeFromBackendUiHint(
      uiType: effectiveUiType,
      options: effectiveOptions,
    );
    final miniType =
        forceIntakeMultiForm ? MiniInterfaceType.multiForm : mappedMiniType;
    final nextStep = forceIntakeMultiForm
        ? _intakeStepFromRequiredFields(requiredFields)
        : _stepFromBackendTurn(response, miniType, effectiveOptions);
    final assistantMessage = response.assistantMessage.trim().isEmpty
        ? '다음 단계를 진행해 주세요.'
        : response.assistantMessage.trim();
    final selectedRouteLabel =
        (response.statePatch['selectedRouteLabel']?.toString() ?? '').trim();
    final selectedRouteOptionId =
        (response.statePatch['selectedRouteOptionId']?.toString() ?? '').trim();

    String? routeLabelToSync;
    if (selectedRouteLabel.isNotEmpty) {
      routeLabelToSync = selectedRouteLabel;
    } else if (selectedRouteOptionId.isNotEmpty) {
      routeLabelToSync =
          _optionLabelById(effectiveOptions, selectedRouteOptionId) ??
              _optionLabelById(_options, selectedRouteOptionId);
    }
    if (routeLabelToSync != null && routeLabelToSync.trim().isNotEmpty) {
      _data = _data.copyWith(route: routeLabelToSync.trim());
    }

    if (!mounted) return;
    _setAi(
      text: assistantMessage,
      step: nextStep,
      miniType: miniType,
      options: effectiveOptions,
      backendUiHintDriven:
          !forceNoMiniInterface && miniType != MiniInterfaceType.none,
      backendUiHintType: effectiveUiType,
      backendUiSelectionMode:
          _normalizeBackendSelectionMode(hint.selectionMode),
    );
  }

  Future<void> _runBackendTurnRequest({
    required Future<ChatTurnResponseDto> Function() request,
    Duration thinkingDuration = const Duration(milliseconds: 560),
    VoidCallback? onFailureContinueLocal,
    bool allowLocalFallback = true,
  }) async {
    if (!_isBackendEnabled || _isBackendRequestInFlight) return;

    FocusScope.of(context).unfocus();
    _collapseHistoryToCurrent(immediate: true);
    setState(() {
      _isThinking = true;
      _isAiAnswerReady = true;
      _isBackendRequestInFlight = true;
    });

    VoidCallback? localFallback;
    try {
      await Future<void>.delayed(thinkingDuration);
      final response = await _requestWithRetry(request);
      if (mounted && _forceLocalDemoMode) {
        setState(() {
          _forceLocalDemoMode = false;
        });
      }
      await _applyBackendTurn(response);
    } catch (error) {
      _showAiRequestFailureSnack(
        error,
        onRetry: () {
          if (!mounted) return;
          setState(() {
            _forceLocalDemoMode = false;
          });
          unawaited(
            _runBackendTurnRequest(
              request: request,
              thinkingDuration: thinkingDuration,
              onFailureContinueLocal: null,
              allowLocalFallback: false,
            ),
          );
        },
      );
      if (_allowLocalDemoFallback && allowLocalFallback) {
        localFallback = onFailureContinueLocal;
      }
    } finally {
      if (mounted) {
        setState(() {
          _isThinking = false;
          _isBackendRequestInFlight = false;
        });
      }
    }
    if (mounted && localFallback != null) {
      localFallback();
    }
  }

  Future<ChatTurnResponseDto> _requestWithRetry(
    Future<ChatTurnResponseDto> Function() request,
  ) async {
    const maxAttempts = 2;
    Object? lastError;

    for (var attempt = 1; attempt <= maxAttempts; attempt += 1) {
      try {
        return await request();
      } catch (error) {
        lastError = error;
        final isLast = attempt >= maxAttempts;
        if (isLast || !_isRetryableChatError(error)) {
          rethrow;
        }
        debugPrint(
          '[chat-api-retry] attempt=$attempt reason=${error.runtimeType} trace=${_backendTraceId ?? _bootTraceId}',
        );
        await Future<void>.delayed(const Duration(milliseconds: 280));
      }
    }

    throw lastError ?? StateError('Unknown chat request error');
  }

  bool _isRetryableChatError(Object error) {
    if (error is ApiClientError) {
      final code = error.code.trim().toUpperCase();
      if (code == 'NETWORK_ERROR' ||
          code == 'UNKNOWN_ERROR' ||
          code == 'SERVICE_UNAVAILABLE' ||
          code == 'LLM_UNAVAILABLE') {
        return true;
      }
      if (error.status != null && error.status! >= 500) {
        return true;
      }
      return false;
    }
    return false;
  }

  Future<void> _requestBackendTurnForText(
    String userMessage, {
    Duration thinkingDuration = const Duration(milliseconds: 560),
    ChatTurnInteractionPayload? interaction,
    VoidCallback? onFailureContinueLocal,
    bool allowLocalFallback = true,
  }) async {
    final message = userMessage.trim();
    if (message.isEmpty && interaction == null && !_isBackendEnabled) return;

    await _runBackendTurnRequest(
      request: () => _sendChatTurnMessage(message, interaction: interaction),
      thinkingDuration: thinkingDuration,
      onFailureContinueLocal: onFailureContinueLocal,
      allowLocalFallback: allowLocalFallback,
    );
  }

  Future<void> _requestBackendTurnForSelection({
    VoidCallback? onFailureContinueLocal,
    bool allowLocalFallback = true,
  }) async {
    final selected = _options
        .where((option) => _selectedOptionIds.contains(option.id))
        .toList(growable: false);
    if (selected.isEmpty) return;
    final selectedIds =
        selected.map((option) => option.id).where((id) => id.isNotEmpty).toList(
              growable: false,
            );
    final selectedLabels = selected
        .map((option) => option.label)
        .where((label) => label.trim().isNotEmpty)
        .toList(growable: false);

    final isSubmitConfirm = selectedIds.any(
      (id) => id == 'submit-confirm' || id == 'submit-now',
    );
    final interaction = ChatTurnInteractionPayload(
      interactionType: isSubmitConfirm ? 'SYSTEM_CONFIRM' : 'MINI_SELECTION',
      selectedOptionIds: selectedIds,
      selectedOptionLabels: selectedLabels,
      sourceUiType: _backendUiHintType == 'NONE'
          ? _sourceUiTypeFromMiniType(_miniType)
          : _backendUiHintType,
      meta: <String, dynamic>{
        if (isSubmitConfirm) 'confirmed': true,
      },
    );

    final message = selectedLabels.isEmpty
        ? (_inputController.text.trim().isEmpty
            ? '선택 완료'
            : _inputController.text.trim())
        : (_backendUiSelectionMode == 'MULTIPLE'
            ? selectedLabels.join(', ')
            : selectedLabels.first);

    await _requestBackendTurnForText(
      message,
      thinkingDuration: const Duration(milliseconds: 420),
      interaction: interaction,
      onFailureContinueLocal: onFailureContinueLocal,
      allowLocalFallback: allowLocalFallback,
    );
  }

  void _showAiRequestFailureSnack(
    Object error, {
    required VoidCallback onRetry,
  }) {
    final fallbackTraceId = _backendTraceId ?? _bootTraceId;
    var code = 'UNKNOWN_ERROR';
    var traceId = fallbackTraceId;
    if (error is ApiClientErrorLike) {
      final rawCode = error.code?.trim();
      if (rawCode != null && rawCode.isNotEmpty) {
        code = rawCode;
      }
    }
    if (error is ApiClientError) {
      final rawTrace = error.traceId?.trim();
      if (rawTrace != null && rawTrace.isNotEmpty) {
        traceId = rawTrace;
      }
      debugPrint(
        '[chat-ai-request-failed] code=$code traceId=$traceId details=${error.details.join(' || ')}',
      );
    } else {
      debugPrint(
        '[chat-ai-request-failed] code=$code traceId=$traceId type=${error.runtimeType} value=$error',
      );
    }

    if (!mounted) return;
    setState(() {
      if (_allowLocalDemoFallback) {
        _forceLocalDemoMode = true;
      }
      _isBackendUiHintDriven = false;
      _backendUiHintType = 'NONE';
      _backendUiSelectionMode = 'NONE';
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('서버 연결이 원활하지 않아요. 인터넷 연결을 확인해주세요.'),
        action: SnackBarAction(
          label: '재시도',
          onPressed: onRetry,
        ),
      ),
    );
  }

  String? _buildErrorDiagnostic(Object error) {
    if (error is! ApiClientErrorLike) return null;
    final parts = <String>[];
    final code = error.code;
    if (code != null && code.trim().isNotEmpty) {
      parts.add('code=$code');
    }
    final status = error.status;
    if (status != null) {
      parts.add('status=$status');
    }
    if (error is ApiClientError &&
        error.traceId != null &&
        error.traceId!.trim().isNotEmpty) {
      parts.add('trace=${error.traceId}');
    }
    if (parts.isEmpty) return null;
    return parts.join(' | ');
  }

  void _showApiErrorSnack(Object error) {
    final message = toKoreanErrorMessage(error);
    final diagnostic = _buildErrorDiagnostic(error);
    if (error is ApiClientError) {
      debugPrint(
        '[chat-api-error] ${error.toString()} details=${error.details.join(' || ')}',
      );
    } else {
      debugPrint('[chat-api-error] type=${error.runtimeType} value=$error');
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          diagnostic == null ? message : '$message\n$diagnostic',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  void _enqueueBackendSyncMessages(List<String> messages) {
    if (!_isBackendEnabled || messages.isEmpty) return;

    _backendSyncQueue = _backendSyncQueue.then((_) async {
      for (final raw in messages) {
        final message = raw.trim();
        if (message.isEmpty) continue;
        await _sendChatTurnMessage(message);
      }
    }).catchError((error) {
      _showApiErrorSnack(error);
    });
  }

  void _enqueueBackendSyncMessage(String message) {
    _enqueueBackendSyncMessages(<String>[message]);
  }

  Future<void> _syncBackendRouteAndAdvance(String selectedLabel) async {
    if (!_isBackendEnabled) {
      _data = _data.copyWith(route: selectedLabel);
      _showThinkingThen(() {
        _setAi(
          text: '선택한 경로로 진행할게요.\n증거 제출을 진행해 주세요.',
          step: DemoStep.evidenceV1,
          miniType: MiniInterfaceType.optionList,
        );
      });
      return;
    }

    if (_isBackendRequestInFlight) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isBackendRequestInFlight = true;
      _isThinking = true;
    });

    try {
      await _backendSyncQueue;
      await Future<void>.delayed(const Duration(milliseconds: 420));
      if (!mounted) return;

      final response = await _sendChatTurnMessage(selectedLabel);

      if (!mounted) return;
      if (_forceLocalDemoMode) {
        setState(() {
          _forceLocalDemoMode = false;
        });
      }

      if (!mounted) return;

      _data = _data.copyWith(route: selectedLabel);
      await _applyBackendTurn(response);
    } catch (error) {
      _showAiRequestFailureSnack(
        error,
        onRetry: () {
          if (!mounted) return;
          setState(() {
            _forceLocalDemoMode = false;
          });
          unawaited(_syncBackendRouteAndAdvance(selectedLabel));
        },
      );
      if (_allowLocalDemoFallback) {
        if (!mounted) return;
        _data = _data.copyWith(route: selectedLabel);
        _setAi(
          text: '선택한 경로로 진행할게요.\n증거 제출을 진행해 주세요.',
          step: DemoStep.evidenceV1,
          miniType: MiniInterfaceType.optionList,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isThinking = false;
          _isBackendRequestInFlight = false;
        });
      }
    }
  }

  String? _optionLabelById(List<MiniOption> options, String? id) {
    if (id == null) return null;
    for (final option in options) {
      if (option.id == id) return option.label;
    }
    return null;
  }

  ({bool eligible, String reason}) _evaluateEligibility() {
    if (_data.safety == '있음(위험)') {
      return (
        eligible: false,
        reason: '안전 위험 징후가 있어요.',
      );
    }

    final residence = _data.residence ?? '';
    final isJointHousing =
        residence == '아파트' || residence == '빌라' || residence == '오피스텔';
    if (!isJointHousing) {
      return (
        eligible: false,
        reason: '층간소음 공식 절차 대상이 아니에요.',
      );
    }

    if (_data.sourceCertainty == '모름') {
      return (
        eligible: false,
        reason: '발생 세대 확인이 먼저 필요해요.',
      );
    }

    return (eligible: true, reason: '층간소음 절차 진행이 가능합니다.');
  }

  void _openIncidentDatePicker() => _openDatePicker(_PickerOwner.incident);
  void _openIncidentTimePicker() => _openTimePicker(_PickerOwner.incident);
  void _openNoiseDiaryDatePicker() => _openDatePicker(_PickerOwner.noiseDiary);
  void _openNoiseDiaryTimePicker() => _openTimePicker(_PickerOwner.noiseDiary);

  void _openDatePicker(_PickerOwner owner) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected =
        owner == _PickerOwner.noiseDiary ? _noiseDiaryDate : _incidentDate;
    final seed = (selected != null && selected.isAfter(today))
        ? today
        : (selected ?? now);
    setState(() {
      _pickerOwner = owner;
      _pickerMonth = DateTime(seed.year, seed.month, 1);
      _pickerDateSelection = DateTime(seed.year, seed.month, seed.day);
      _miniType = MiniInterfaceType.datePicker;
    });
  }

  void _openTimePicker(_PickerOwner owner) {
    final seed = owner == _PickerOwner.noiseDiary
        ? (_noiseDiaryTime ?? const TimeOfDay(hour: 22, minute: 10))
        : (_incidentTime ?? const TimeOfDay(hour: 14, minute: 30));
    final hour12 = seed.hour % 12 == 0 ? 12 : seed.hour % 12;

    setState(() {
      _pickerOwner = owner;
      _pickerIsAm = seed.hour < 12;
      _pickerHour12 = hour12;
      _pickerMinute = seed.minute;
      _miniType = MiniInterfaceType.timePicker;
    });
  }

  void _movePickerMonth(int delta) {
    setState(() {
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month, 1);
      var target = DateTime(_pickerMonth.year, _pickerMonth.month + delta, 1);
      if (target.isAfter(currentMonth)) {
        target = currentMonth;
      }
      _pickerMonth = target;
      if (_pickerDateSelection != null) {
        final safeDay = _pickerDateSelection!.day.clamp(
          1,
          DateUtils.getDaysInMonth(target.year, target.month),
        );
        final safeDate = DateTime(target.year, target.month, safeDay);
        final today = DateTime(now.year, now.month, now.day);
        _pickerDateSelection = safeDate.isAfter(today) ? today : safeDate;
      }
    });
  }

  void _setPickerYear(int year) {
    setState(() {
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month, 1);
      var target = DateTime(year, _pickerMonth.month, 1);
      if (target.isAfter(currentMonth)) {
        target = currentMonth;
      }
      _pickerMonth = target;
      if (_pickerDateSelection != null) {
        final safeDay = _pickerDateSelection!.day.clamp(
          1,
          DateUtils.getDaysInMonth(target.year, target.month),
        );
        final safeDate = DateTime(target.year, target.month, safeDay);
        final today = DateTime(now.year, now.month, now.day);
        _pickerDateSelection = safeDate.isAfter(today) ? today : safeDate;
      }
    });
  }

  void _setPickerMonthValue(int month) {
    setState(() {
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month, 1);
      var target = DateTime(_pickerMonth.year, month, 1);
      if (target.isAfter(currentMonth)) {
        target = currentMonth;
      }
      _pickerMonth = target;
      if (_pickerDateSelection != null) {
        final safeDay = _pickerDateSelection!.day.clamp(
          1,
          DateUtils.getDaysInMonth(target.year, target.month),
        );
        final safeDate = DateTime(target.year, target.month, safeDay);
        final today = DateTime(now.year, now.month, now.day);
        _pickerDateSelection = safeDate.isAfter(today) ? today : safeDate;
      }
    });
  }

  void _selectPickerDate(DateTime day) {
    setState(() {
      _pickerDateSelection = DateTime(day.year, day.month, day.day);
    });
  }

  void _cancelPicker() {
    setState(() {
      _miniType = _pickerOwner == _PickerOwner.noiseDiary
          ? MiniInterfaceType.noiseDiaryBuilder
          : ((_step == DemoStep.multiForm || _step == DemoStep.dateTime)
              ? MiniInterfaceType.multiForm
              : MiniInterfaceType.optionList);
    });
  }

  void _confirmDatePicker() {
    final selected = _pickerDateSelection;
    if (selected == null) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final safeSelected = selected.isAfter(today) ? today : selected;
    setState(() {
      if (_pickerOwner == _PickerOwner.noiseDiary) {
        _noiseDiaryDate = safeSelected;
        _miniType = MiniInterfaceType.noiseDiaryBuilder;
      } else {
        _incidentDate = safeSelected;
        _miniType = (_step == DemoStep.multiForm || _step == DemoStep.dateTime)
            ? MiniInterfaceType.multiForm
            : MiniInterfaceType.optionList;
      }
    });
  }

  void _confirmTimePicker() {
    final hour24 =
        _pickerIsAm ? (_pickerHour12 % 12) : ((_pickerHour12 % 12) + 12);
    final selected = TimeOfDay(hour: hour24, minute: _pickerMinute);
    setState(() {
      if (_pickerOwner == _PickerOwner.noiseDiary) {
        _noiseDiaryTime = selected;
        _miniType = MiniInterfaceType.noiseDiaryBuilder;
      } else {
        _incidentTime = selected;
        _miniType = (_step == DemoStep.multiForm || _step == DemoStep.dateTime)
            ? MiniInterfaceType.multiForm
            : MiniInterfaceType.optionList;
      }
    });
  }

  void _submitIntakeBasicMultiForm() {
    if (!_isIntakeBasicReady) return;

    final residenceLabel =
        _optionLabelById(_residenceOptions, _intakeResidenceId);
    final managementLabel =
        _optionLabelById(_managementOptions, _intakeManagementId);
    final sourceCertaintyLabel =
        _optionLabelById(_sourceCertaintyOptions, _intakeSourceCertaintyId);

    _data = _data.copyWith(
      residence: residenceLabel,
      management: managementLabel,
      sourceCertainty: sourceCertaintyLabel,
    );
    _recordMiniResponse(
      '기본 정보 입력: ${residenceLabel ?? '미입력'}, ${managementLabel ?? '미입력'}, ${sourceCertaintyLabel ?? '미입력'}',
    );

    if (_isBackendEnabled) {
      final messageParts = <String>[
        if (residenceLabel != null) '거주 형태 $residenceLabel',
        if (managementLabel != null) '관리사무소 $managementLabel',
        if (sourceCertaintyLabel != null) '발생원 특정 $sourceCertaintyLabel',
      ];
      final message = messageParts.join(', ');
      final interaction = ChatTurnInteractionPayload(
        interactionType: 'MINI_SELECTION',
        selectedOptionIds: <String>[
          if (_intakeResidenceId != null) _intakeResidenceId!,
          if (_intakeManagementId != null) _intakeManagementId!,
          if (_intakeSourceCertaintyId != null) _intakeSourceCertaintyId!,
        ],
        selectedOptionLabels: <String>[
          if (residenceLabel != null) residenceLabel,
          if (managementLabel != null) managementLabel,
          if (sourceCertaintyLabel != null) sourceCertaintyLabel,
        ],
        sourceUiType:
            _backendUiHintType == 'NONE' ? 'LIST_PICKER' : _backendUiHintType,
        meta: <String, dynamic>{
          'filledSlots': <String, dynamic>{
            if (residenceLabel != null) 'residence': residenceLabel,
            if (managementLabel != null) 'management': managementLabel,
            if (sourceCertaintyLabel != null)
              'sourceCertainty': sourceCertaintyLabel,
          },
        },
      );
      unawaited(
        _requestBackendTurnForText(
          message,
          interaction: interaction,
          thinkingDuration: const Duration(milliseconds: 420),
          onFailureContinueLocal: () {
            _showThinkingThen(() {
              _setAi(
                text: '좋아요. 소음 패턴과 시작 시점을 입력해 주세요.',
                step: DemoStep.dateTime,
                miniType: MiniInterfaceType.multiForm,
              );
            });
          },
        ),
      );
      return;
    }

    _showThinkingThen(() {
      _setAi(
        text: '좋아요. 소음 패턴과 시작 시점을 입력해 주세요.',
        step: DemoStep.dateTime,
        miniType: MiniInterfaceType.multiForm,
      );
    });
  }

  void _submitIntakeDetailMultiForm() {
    if (!_isIntakeDetailReady) return;

    final noiseTypeLabel =
        _optionLabelById(_noiseTypeOptions, _intakeNoiseTypeId);
    final frequencyLabel =
        _optionLabelById(_frequencyOptions, _intakeFrequencyId);
    final timeBandLabel = _optionLabelById(_timeBandOptions, _intakeTimeBandId);

    _data = _data.copyWith(
      noiseType: noiseTypeLabel,
      frequency: frequencyLabel,
      timeBand: timeBandLabel,
      startedAtDate: _incidentDate,
      startedAtTime: _incidentTime,
    );
    _recordMiniResponse(
      '소음 패턴 입력: ${noiseTypeLabel ?? '미입력'}, ${frequencyLabel ?? '미입력'}, ${timeBandLabel ?? '미입력'}',
    );

    if (_isBackendEnabled) {
      final detailParts = <String>[
        if (noiseTypeLabel != null) '소음 유형 $noiseTypeLabel',
        if (frequencyLabel != null) '빈도 $frequencyLabel',
        if (timeBandLabel != null) '시간대 $timeBandLabel',
        if (_incidentDate != null) '발생 날짜 ${_formatDate(_incidentDate!)}',
        if (_incidentTime != null) '발생 시간 ${_formatTime(_incidentTime!)}',
      ];
      final detailMessage = detailParts.join(', ');
      final interaction = ChatTurnInteractionPayload(
        interactionType: 'MINI_SELECTION',
        selectedOptionIds: <String>[
          if (_intakeNoiseTypeId != null) _intakeNoiseTypeId!,
          if (_intakeFrequencyId != null) _intakeFrequencyId!,
          if (_intakeTimeBandId != null) _intakeTimeBandId!,
        ],
        selectedOptionLabels: <String>[
          if (noiseTypeLabel != null) noiseTypeLabel,
          if (frequencyLabel != null) frequencyLabel,
          if (timeBandLabel != null) timeBandLabel,
          if (_incidentDate != null) _formatDate(_incidentDate!),
          if (_incidentTime != null) _formatTime(_incidentTime!),
        ],
        sourceUiType:
            _backendUiHintType == 'NONE' ? 'LIST_PICKER' : _backendUiHintType,
        meta: <String, dynamic>{
          'filledSlots': <String, dynamic>{
            if (noiseTypeLabel != null) 'noiseType': noiseTypeLabel,
            if (frequencyLabel != null) 'frequency': frequencyLabel,
            if (timeBandLabel != null) 'timeBand': timeBandLabel,
            if (_incidentDate != null && _incidentTime != null)
              'startedAt':
                  '${_formatDate(_incidentDate!)} ${_formatTime(_incidentTime!)}',
          },
        },
      );
      unawaited(
        _requestBackendTurnForText(
          detailMessage,
          interaction: interaction,
          thinkingDuration: const Duration(milliseconds: 420),
          onFailureContinueLocal: () {
            final eligibility = _evaluateEligibility();
            _data = _data.copyWith(eligibilityReason: eligibility.reason);

            if (!eligibility.eligible) {
              _setAi(
                text: '${eligibility.reason}\n대체 경로로 즉시 연결할게요.',
                step: DemoStep.ineligible,
                miniType: MiniInterfaceType.listPicker,
                options: const [
                  MiniOption(id: 'ineligible-next', label: '바로 연결'),
                ],
              );
              return;
            }

            _setAi(
              text: '정리해드릴게요.',
              step: DemoStep.summary,
              miniType: MiniInterfaceType.summaryCard,
              options: const [
                MiniOption(id: 'summary-edit', label: '수정'),
                MiniOption(id: 'summary-next', label: '다음'),
              ],
            );
          },
        ),
      );
      return;
    }

    final eligibility = _evaluateEligibility();
    _data = _data.copyWith(eligibilityReason: eligibility.reason);

    if (!eligibility.eligible) {
      _setAi(
        text: '${eligibility.reason}\n대체 경로로 즉시 연결할게요.',
        step: DemoStep.ineligible,
        miniType: MiniInterfaceType.listPicker,
        options: const [
          MiniOption(id: 'ineligible-next', label: '바로 연결'),
        ],
      );
      return;
    }

    _setAi(
      text: '정리해드릴게요.',
      step: DemoStep.summary,
      miniType: MiniInterfaceType.summaryCard,
      options: const [
        MiniOption(id: 'summary-edit', label: '수정'),
        MiniOption(id: 'summary-next', label: '다음'),
      ],
    );
  }

  void _submitTriageMultiForm() {
    if (_triageNoiseNowId == null || _triageSafetyId == null) return;

    final noiseNowLabel =
        _optionLabelById(_triageNoiseNowOptions, _triageNoiseNowId);
    final safetyLabel = _optionLabelById(_triageSafetyOptions, _triageSafetyId);
    if (noiseNowLabel == null || safetyLabel == null) return;

    _data = _data.copyWith(
      noiseNow: noiseNowLabel,
      safety: safetyLabel,
    );
    _recordMiniResponse('현재 소음 상태: $noiseNowLabel / 안전 긴급도: $safetyLabel');

    if (_isBackendEnabled) {
      final message = '현재 소음 상태 $noiseNowLabel, 안전 긴급도 $safetyLabel';
      final interaction = ChatTurnInteractionPayload(
        interactionType: 'MINI_SELECTION',
        selectedOptionIds: <String>[
          if (_triageNoiseNowId != null) _triageNoiseNowId!,
          if (_triageSafetyId != null) _triageSafetyId!,
        ],
        selectedOptionLabels: <String>[noiseNowLabel, safetyLabel],
        sourceUiType:
            _backendUiHintType == 'NONE' ? 'LIST_PICKER' : _backendUiHintType,
        meta: <String, dynamic>{
          'filledSlots': <String, dynamic>{
            'noiseNow': noiseNowLabel,
            'safety': safetyLabel,
          },
        },
      );
      unawaited(
        _requestBackendTurnForText(
          message,
          interaction: interaction,
          thinkingDuration: const Duration(milliseconds: 420),
          onFailureContinueLocal: () {
            if (_triageSafetyId == 'safety-danger') {
              _showThinkingThen(() {
                _setAi(
                  text:
                      '위협·폭행 우려가 있으면 112 신고가 우선입니다.\n안전 안내를 확인한 뒤 계속 진행할 수 있어요.',
                  step: DemoStep.safety,
                  miniType: MiniInterfaceType.listPicker,
                  options: const [
                    MiniOption(id: 'safety-guide', label: '112 안전 안내 확인'),
                    MiniOption(id: 'safety-continue', label: '생활소음 접수 계속'),
                  ],
                );
              });
              return;
            }

            _goIntakeMultiFormBasic(
              '좋아요. 기본 정보를 입력해 주세요.',
              resetSelections: true,
            );
          },
        ),
      );
      return;
    }

    if (_triageSafetyId == 'safety-danger') {
      _showThinkingThen(() {
        _setAi(
          text: '위협·폭행 우려가 있으면 112 신고가 우선입니다.\n안전 안내를 확인한 뒤 계속 진행할 수 있어요.',
          step: DemoStep.safety,
          miniType: MiniInterfaceType.listPicker,
          options: const [
            MiniOption(id: 'safety-guide', label: '112 안전 안내 확인'),
            MiniOption(id: 'safety-continue', label: '생활소음 접수 계속'),
          ],
        );
      });
      return;
    }

    _goIntakeMultiFormBasic(
      '좋아요. 기본 정보를 입력해 주세요.',
      resetSelections: true,
    );
  }

  void _goIntakeMultiFormBasic(
    String prompt, {
    bool resetSelections = false,
  }) {
    if (resetSelections) {
      _intakeResidenceId = null;
      _intakeManagementId = null;
      _intakeSourceCertaintyId = null;
      _intakeNoiseTypeId = null;
      _intakeFrequencyId = null;
      _intakeTimeBandId = null;
      _incidentDate = null;
      _incidentTime = null;
    } else {
      _intakeResidenceId = _optionIdByLabel(_residenceOptions, _data.residence);
      _intakeManagementId =
          _optionIdByLabel(_managementOptions, _data.management);
      _intakeSourceCertaintyId =
          _optionIdByLabel(_sourceCertaintyOptions, _data.sourceCertainty);
      _intakeNoiseTypeId = _optionIdByLabel(_noiseTypeOptions, _data.noiseType);
      _intakeFrequencyId = _optionIdByLabel(_frequencyOptions, _data.frequency);
      _intakeTimeBandId = _optionIdByLabel(_timeBandOptions, _data.timeBand);
      _incidentDate = _data.startedAtDate;
      _incidentTime = _data.startedAtTime;
    }

    _showThinkingThen(() {
      _setAi(
        text: prompt,
        step: DemoStep.multiForm,
        miniType: MiniInterfaceType.multiForm,
      );
    });
  }

  void _startDraftViewer() {
    _setAi(
      text: '신청서 초안을 작성했어요. 확인해 주세요.',
      step: DemoStep.draftViewer,
      miniType: MiniInterfaceType.draftViewer,
      options: const [
        MiniOption(id: 'draft-submit', label: '좋아요, 접수'),
        MiniOption(id: 'draft-edit', label: '수정 요청'),
      ],
    );
  }

  void _goStatusFeed() {
    _setAi(
      text: '접수를 완료했어요.\n이제 사용자 확인 기반 타임라인으로 진행을 추적해드릴게요.',
      step: DemoStep.statusFeed,
      miniType: MiniInterfaceType.statusFeed,
      options: const [
        MiniOption(id: 'status-upload', label: '추가 증거 업로드'),
        MiniOption(id: 'status-summary', label: '케이스 요약 보기'),
      ],
    );
  }

  Future<void> _toggleEvidenceAttachment(String id) async {
    if (_isPickingEvidence) return;

    if (_evidenceAttachmentIds.contains(id)) {
      setState(() {
        _evidenceAttachmentIds.remove(id);
        _evidenceAttachmentNames.remove(id);
      });
      return;
    }

    setState(() {
      _isPickingEvidence = true;
    });

    try {
      String? selectedFileName;

      if (id == 'evidence-audio') {
        final result = await FilePicker.platform.pickFiles(
          // NOTE: iOS에서 FileType.audio 경로에서 네이티브 예외가 나는 케이스가 있어
          // custom 확장자 필터로 우회한다.
          type: FileType.custom,
          allowedExtensions: const <String>[
            'm4a',
            'mp3',
            'wav',
            'aac',
            'caf',
            'flac',
          ],
          allowMultiple: false,
          withData: false,
        );
        if (result != null && result.files.isNotEmpty) {
          selectedFileName = result.files.first.name;
        }
      } else if (id == 'evidence-video') {
        final picked = await _imagePicker.pickVideo(
          source: ImageSource.gallery,
        );
        if (picked != null) {
          selectedFileName = _extractFileName(picked.path);
        }
      }

      if (!mounted) return;
      if (selectedFileName == null || selectedFileName.trim().isEmpty) return;

      setState(() {
        _evidenceAttachmentIds.add(id);
        _evidenceAttachmentNames[id] = selectedFileName!;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('첨부 파일을 불러오지 못했어요. 다시 시도해 주세요.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPickingEvidence = false;
        });
      }
    }
  }

  String _extractFileName(String path) {
    final normalized = path.replaceAll('\\', '/');
    final index = normalized.lastIndexOf('/');
    return index >= 0 ? normalized.substring(index + 1) : normalized;
  }

  void _submitEvidenceAttachments() {
    if (_evidenceAttachmentIds.isEmpty) return;
    _recordMiniResponse('증거 제출 완료');
    _showThinkingThen(_goMeasureCheck);
  }

  void _skipEvidenceAttachments() {
    setState(() {
      _evidenceAttachmentIds.clear();
      _evidenceAttachmentNames.clear();
    });
    _recordMiniResponse('증거 제출 건너뛰기');
    _showThinkingThen(_goMeasureCheck);
  }

  void _goMeasureCheck() {
    _measureVisitDone = null;
    _measureWithin30Days = null;
    _measureReceivingUnit = null;
    _setAi(
      text: '측정 단계 전환 조건을 확인해 주세요.',
      step: DemoStep.measureCheck,
      miniType: MiniInterfaceType.measureCheck,
    );
  }

  Future<void> _toggleEvidenceV2Attachment(String id) async {
    if (_isPickingEvidence) return;

    if (_evidenceV2AttachmentIds.contains(id)) {
      setState(() {
        _evidenceV2AttachmentIds.remove(id);
        _evidenceV2AttachmentNames.remove(id);
      });
      return;
    }

    setState(() {
      _isPickingEvidence = true;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const <String>[
          'pdf',
          'hwp',
          'doc',
          'docx',
          'txt',
          'jpg',
          'jpeg',
          'png',
        ],
        allowMultiple: false,
        withData: false,
      );
      if (result == null || result.files.isEmpty) return;
      final selectedFileName = result.files.first.name;
      if (selectedFileName.trim().isEmpty) return;

      if (!mounted) return;
      setState(() {
        _evidenceV2AttachmentIds.add(id);
        _evidenceV2AttachmentNames[id] = selectedFileName;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('파일을 불러오지 못했어요. 다시 시도해 주세요.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPickingEvidence = false;
        });
      }
    }
  }

  void _submitMeasureCheck() {
    if (!_isMeasureCheckReady) return;
    _recordMiniResponse('측정 전환 체크 완료');

    if (_isMeasureEligible) {
      _data = _data.copyWith(eligibilityReason: '측정 전환 조건 충족');
      _showThinkingThen(() {
        _setAi(
          text: '측정 단계 전환이 가능해요.\n증거 제출을 진행해 주세요.',
          step: DemoStep.evidenceV2,
          miniType: MiniInterfaceType.optionList,
        );
      });
      return;
    }

    final missing = <String>[];
    if (_measureVisitDone != true) missing.add('방문상담 이후 지속');
    if (_measureWithin30Days != true) missing.add('30일 이내');
    if (_measureReceivingUnit != true) missing.add('수음세대 신청');
    _data = _data.copyWith(
      eligibilityReason: '측정 전환 보류: ${missing.join(', ')}',
    );
    _showThinkingThen(_startDraftViewer);
  }

  void _submitEvidenceV2Attachments() {
    if (_evidenceV2AttachmentIds.length < 2) return;
    _recordMiniResponse('측정 단계 증거 제출 완료');
    _showThinkingThen(_startDraftViewer);
  }

  void _skipEvidenceV2Attachments() {
    _recordMiniResponse('측정 단계 증거 제출 건너뛰기');
    _showThinkingThen(_startDraftViewer);
  }

  void _submitNoiseDiaryBuilder() {
    if (!_isNoiseDiaryReady) return;
    _recordMiniResponse('소음일지 작성 완료');
    _showThinkingThen(_startDraftViewer);
  }

  void _handleTextSend() {
    final input = _inputController.text.trim();
    if (input.isEmpty || !_isUiReadyAfterAi) return;

    _inputController.clear();
    _recordUserChatInput(input);

    if (_step == DemoStep.waitingIssue) {
      if (_isBackendEnabled) {
        _data = _data.copyWith(userIssue: input);
        _hasIntroBridgeShown = true;
        unawaited(
          _requestBackendTurnForText(
            input,
            thinkingDuration: const Duration(milliseconds: 420),
            allowLocalFallback: false,
          ),
        );
        return;
      }

      if (!_hasIntroBridgeShown) {
        _showThinkingThen(() {
          _hasIntroBridgeShown = true;
          _setAi(
            text:
                '말씀해 주셔서 감사합니다.\n접수에 필요한 정보를 단계별로 정리해 드릴게요.\n접수를 도와드릴 수 있어요. 진행할까요?',
            step: DemoStep.waitingIssue,
            miniType: MiniInterfaceType.none,
          );
        }, duration: const Duration(milliseconds: 640));
        return;
      }

      _data = _data.copyWith(userIssue: input);
      final thinkingDuration = input == '1'
          ? const Duration(seconds: 3)
          : const Duration(milliseconds: 560);
      _showThinkingThen(() {
        _triageNoiseNowId = null;
        _triageSafetyId = null;
        _setAi(
          text: '힘드셨겠어요.\n현재 소음 상태와 안전 긴급도를 함께 선택해 주세요.',
          step: DemoStep.noiseNow,
          miniType: MiniInterfaceType.multiForm,
        );
      }, duration: thinkingDuration);
      return;
    }

    if (_step == DemoStep.waitingRevision) {
      if (_isBackendEnabled && _isBackendUiHintDriven) {
        unawaited(
          _requestBackendTurnForText(
            input,
            thinkingDuration: const Duration(milliseconds: 560),
            onFailureContinueLocal: () {
              _data = _data.copyWith(revisionNote: input);
              _setAi(
                text: '반영했습니다. 추가된 문장을 표시했어요.\n이대로 접수할까요?',
                step: DemoStep.draftConfirm,
                miniType: MiniInterfaceType.draftConfirm,
                options: const [
                  MiniOption(id: 'draft-confirm-submit', label: '좋아요, 접수해주세요'),
                  MiniOption(id: 'draft-confirm-edit', label: '다시 수정'),
                ],
              );
            },
          ),
        );
        return;
      }

      _data = _data.copyWith(revisionNote: input);
      _showThinkingThen(() {
        _setAi(
          text: '반영했습니다. 추가된 문장을 표시했어요.\n이대로 접수할까요?',
          step: DemoStep.draftConfirm,
          miniType: MiniInterfaceType.draftConfirm,
          options: const [
            MiniOption(id: 'draft-confirm-submit', label: '좋아요, 접수해주세요'),
            MiniOption(id: 'draft-confirm-edit', label: '다시 수정'),
          ],
        );
      });
      return;
    }

    if (_isBackendEnabled) {
      unawaited(
        _requestBackendTurnForText(
          input,
          thinkingDuration: const Duration(milliseconds: 420),
          onFailureContinueLocal: () {
            _setAi(
              text: '현재 단계는 아래 선택지로 진행해 주세요.',
              step: _step,
              miniType: _miniType,
              options: _options,
            );
          },
        ),
      );
      return;
    }

    _showThinkingThen(() {
      _setAi(
        text: '현재 단계는 아래 선택지로 진행해 주세요.',
        step: _step,
        miniType: _miniType,
        options: _options,
      );
    });
  }

  void _handleListSelectionSubmit() {
    if (_selectedOptionIds.isEmpty) return;
    final selectedId = _selectedOptionIds.first;
    final selectedLabel = _options.firstWhere((e) => e.id == selectedId).label;
    _recordMiniResponse(selectedLabel);

    if (_isBackendEnabled && _isBackendUiHintDriven) {
      unawaited(
        _requestBackendTurnForSelection(
          onFailureContinueLocal: () {
            _handleLocalListSelectionSubmit(
              selectedId: selectedId,
              selectedLabel: selectedLabel,
            );
          },
        ),
      );
      return;
    }

    _handleLocalListSelectionSubmit(
      selectedId: selectedId,
      selectedLabel: selectedLabel,
    );
  }

  void _handleLocalListSelectionSubmit({
    required String selectedId,
    required String selectedLabel,
  }) {
    switch (_step) {
      case DemoStep.noiseNow:
        return;
      case DemoStep.safety:
        if (selectedId == 'safety-guide') {
          _showThinkingThen(() {
            _setAi(
              text: '긴급 위험 시 112, 비긴급은 110/지자체 민원으로 연결할 수 있어요.\n계속 진행할까요?',
              step: DemoStep.safety,
              miniType: MiniInterfaceType.listPicker,
              options: const [
                MiniOption(id: 'safety-continue', label: '생활소음 접수 계속'),
              ],
            );
          });
          return;
        }
        if (selectedId != 'safety-continue') return;
        _enqueueBackendSyncMessage('생활소음 접수 계속');
        _goIntakeMultiFormBasic(
          '좋아요. 기본 정보를 입력해 주세요.',
          resetSelections: true,
        );
        return;
      case DemoStep.residence:
      case DemoStep.management:
      case DemoStep.noiseType:
      case DemoStep.frequency:
      case DemoStep.timeBand:
      case DemoStep.sourceCertainty:
      case DemoStep.dateTime:
        return;
      case DemoStep.ineligible:
        if (selectedId != 'ineligible-next') return;
        _showThinkingThen(() {
          _setAi(
            text: '적합한 대체 경로를 선택해 주세요.',
            step: DemoStep.pathAlternative,
            miniType: MiniInterfaceType.listPicker,
            options: const [
              MiniOption(id: 'path-local', label: '지자체 소음 민원'),
              MiniOption(id: 'path-epeople', label: '국민신문고'),
              MiniOption(id: 'path-112', label: '112 신고 안내'),
            ],
          );
        });
        return;
      case DemoStep.pathAlternative:
        unawaited(_syncBackendRouteAndAdvance(selectedLabel));
        return;
      case DemoStep.complete:
        if (selectedId == 'complete-restart') {
          widget.onSnapshotChanged?.call(_buildSnapshot());
          widget.onRestart();
        }
        return;
      default:
        if (_step == DemoStep.waitingIssue) {
          _data = _data.copyWith(userIssue: selectedLabel);
          _triageNoiseNowId = null;
          _triageSafetyId = null;
          _setAi(
            text: '힘드셨겠어요.\n현재 소음 상태와 안전 긴급도를 함께 선택해 주세요.',
            step: DemoStep.noiseNow,
            miniType: MiniInterfaceType.multiForm,
          );
          return;
        }
        return;
    }
  }

  void _handlePathChooserSelectionSubmit() {
    if (_selectedOptionIds.isEmpty || _step != DemoStep.pathChooser) return;
    final selectedId = _selectedOptionIds.first;
    final selectedLabel = _options
        .firstWhere(
          (option) => option.id == selectedId,
          orElse: () => const MiniOption(id: 'unknown', label: '선택'),
        )
        .label;
    _recordMiniResponse(selectedLabel);

    if (_isBackendEnabled && _isBackendUiHintDriven) {
      unawaited(
        _requestBackendTurnForSelection(
          onFailureContinueLocal: () {
            if (selectedId == 'path-recommended') {
              unawaited(_syncBackendRouteAndAdvance('이웃사이센터 조정 신청'));
              return;
            }
            if (selectedId == 'path-alternative') {
              _showThinkingThen(() {
                _setAi(
                  text: '원하시는 기관을 선택해 주세요.',
                  step: DemoStep.pathAlternative,
                  miniType: MiniInterfaceType.listPicker,
                  options: const [
                    MiniOption(id: 'path-epeople', label: '국민신문고'),
                    MiniOption(id: 'path-management', label: '관리사무소 공식 민원'),
                    MiniOption(id: 'path-local', label: '지자체 소음 민원'),
                  ],
                );
              });
            }
          },
        ),
      );
      return;
    }

    if (selectedId == 'path-recommended') {
      unawaited(_syncBackendRouteAndAdvance('이웃사이센터 조정 신청'));
      return;
    }

    if (selectedId == 'path-alternative') {
      _showThinkingThen(() {
        _setAi(
          text: '원하시는 기관을 선택해 주세요.',
          step: DemoStep.pathAlternative,
          miniType: MiniInterfaceType.listPicker,
          options: const [
            MiniOption(id: 'path-epeople', label: '국민신문고'),
            MiniOption(id: 'path-management', label: '관리사무소 공식 민원'),
            MiniOption(id: 'path-local', label: '지자체 소음 민원'),
          ],
        );
      });
    }
  }

  bool get _isUiReadyAfterAi => !_isThinking && _isAiAnswerReady;
  bool get _isInputEnabled => _miniType == MiniInterfaceType.none;
  bool get _shouldShowMiniInterface =>
      _miniType != MiniInterfaceType.none && _isUiReadyAfterAi;

  String get _miniInterfaceCollapsedTitle {
    switch (_miniType) {
      case MiniInterfaceType.listPicker:
        return '단일 선택';
      case MiniInterfaceType.multiForm:
        if (_step == DemoStep.dateTime) return '소음 패턴 입력';
        return '기본 정보 입력';
      case MiniInterfaceType.optionList:
        if (_step == DemoStep.evidenceV1 || _step == DemoStep.evidenceV2) {
          return '증거 제출';
        }
        return '날짜 및 시간 선택';
      case MiniInterfaceType.measureCheck:
        return '측정 전환 체크';
      case MiniInterfaceType.datePicker:
        return '날짜 선택';
      case MiniInterfaceType.timePicker:
        return '시간 선택';
      case MiniInterfaceType.summaryCard:
        return '요약 확인';
      case MiniInterfaceType.pathChooser:
        return '단일 선택';
      case MiniInterfaceType.noiseDiaryBuilder:
        return '소음일지 작성';
      case MiniInterfaceType.draftViewer:
        return '신청서 초안';
      case MiniInterfaceType.draftConfirm:
        return '수정 반영 확인';
      case MiniInterfaceType.statusFeed:
        return '진행 상태';
      case MiniInterfaceType.none:
        return '';
    }
  }

  Duration _charStepForAiText(String text) {
    final length = text.runes.length;
    if (length >= 140) return const Duration(milliseconds: 14);
    if (length >= 95) return const Duration(milliseconds: 18);
    if (length >= 65) return const Duration(milliseconds: 22);
    if (length >= 45) return const Duration(milliseconds: 28);
    if (length >= 30) return const Duration(milliseconds: 34);
    return const Duration(milliseconds: 40);
  }

  Duration _charFadeForAiText(String text) {
    final length = text.runes.length;
    if (length >= 95) return const Duration(milliseconds: 145);
    if (length >= 45) return const Duration(milliseconds: 160);
    return const Duration(milliseconds: 180);
  }

  Widget _buildCurrentAiMessageWidget(TextStyle aiTextStyle) {
    final charStep = _charStepForAiText(_aiText);
    final fadeDuration = _charFadeForAiText(_aiText);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      layoutBuilder: (currentChild, _) {
        return currentChild ?? const SizedBox.shrink();
      },
      transitionBuilder: (child, animation) {
        final fadeIn = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(opacity: fadeIn, child: child);
      },
      child: _isThinking
          ? Align(
              key: const ValueKey('thinking'),
              alignment: Alignment.topLeft,
              child: _ThinkingWaveText(
                text: '답변을 준비하고 있어요.',
                style: aiTextStyle.copyWith(color: AppColors.textMuted),
              ),
            )
          : _isAiAnswerReady
              ? Align(
                  key: const ValueKey('ai-text-static'),
                  alignment: Alignment.topLeft,
                  child: _MarkdownText(
                    text: _aiText,
                    style: aiTextStyle,
                  ),
                )
              : Align(
                  key: ValueKey('ai-text-$_aiAnimationNonce'),
                  alignment: Alignment.topLeft,
                  child: _AiCharFadeText(
                    text: _aiText,
                    charStep: charStep,
                    fadeDuration: fadeDuration,
                    style: aiTextStyle,
                    onCompleted: _handleAiTextAnimationCompleted,
                  ),
                ),
    );
  }

  Widget _buildConversationArea(
    TextStyle aiTextStyle,
    double viewportHeight,
  ) {
    final isScrollLocked = _isThinking || !_isAiAnswerReady;
    if (isScrollLocked != _wasConversationScrollLocked) {
      _wasConversationScrollLocked = isScrollLocked;
      if (isScrollLocked) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _pinCurrentAiToTop();
        });
      }
    }

    final currentMessage = KeyedSubtree(
      key: const ValueKey('current-ai-message'),
      child: Container(
        key: _currentAiAnchorKey,
        alignment: Alignment.topLeft,
        child: _buildCurrentAiMessageWidget(aiTextStyle),
      ),
    );

    return ListView(
      controller: _conversationScrollController,
      physics: isScrollLocked
          ? const NeverScrollableScrollPhysics()
          : const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
      padding: EdgeInsets.zero,
      children: [
        for (final item in _historyEntries) _HistoryMessageLine(entry: item),
        if (_historyEntries.isNotEmpty) const SizedBox(height: 20),
        currentMessage,
        SizedBox(height: viewportHeight),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final aiFontSize = width < 390 ? 20.0 : 21.0;
    final aiTextStyle = TextStyle(
      color: AppColors.primary,
      fontSize: aiFontSize,
      height: 1.34,
      fontWeight: FontWeight.w500,
    );

    final inputPlaceholder = _isThinking
        ? '답변을 준비하고 있어요.'
        : !_isAiAnswerReady
            ? 'AI 답변을 출력하고 있어요.'
            : _miniType == MiniInterfaceType.none
                ? (_step == DemoStep.waitingRevision
                    ? '수정 내용을 입력해 주세요.'
                    : '답변 입력 또는 음성으로 말하기')
                : '항목을 선택해 주세요.';

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 104, 24, 110),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return _buildConversationArea(
                            aiTextStyle,
                            constraints.maxHeight,
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    right: 18,
                    top: 16,
                    child: _ChatTopBar(onBackToList: _handleBackToList),
                  ),
                  Positioned(
                    left: 22,
                    right: 22,
                    bottom: 92,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      layoutBuilder: (currentChild, previousChildren) {
                        return Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            ...previousChildren,
                            if (currentChild != null) currentChild,
                          ],
                        );
                      },
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      },
                      child: _shouldShowMiniInterface
                          ? _MiniInterfaceCard(
                              key: ValueKey(
                                'mini-${_miniType.name}-$_aiAnimationNonce',
                              ),
                              title: _miniInterfaceCollapsedTitle,
                              collapsed: _isMiniInterfaceCollapsed,
                              onToggleCollapsed: () {
                                setState(() {
                                  _isMiniInterfaceCollapsed =
                                      !_isMiniInterfaceCollapsed;
                                });
                              },
                              child: _buildMiniInterface(context),
                            )
                          : const SizedBox.shrink(
                              key: ValueKey('mini-hidden'),
                            ),
                    ),
                  ),
                  Positioned(
                    left: 22,
                    right: 22,
                    bottom: 18,
                    child: _InputBar(
                      controller: _inputController,
                      focusNode: _focusNode,
                      placeholder: inputPlaceholder,
                      enabled: _isInputEnabled && _isUiReadyAfterAi,
                      sendEnabled: _isSendEnabled,
                      onSend: _handleSendPressed,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool get _isSendEnabled {
    if (!_isUiReadyAfterAi) return false;
    if (_miniType == MiniInterfaceType.none) {
      return _inputController.text.trim().isNotEmpty;
    }
    return false;
  }

  void _handleSendPressed() {
    _handleTextSend();
  }

  Widget _buildMiniInterface(BuildContext context) {
    switch (_miniType) {
      case MiniInterfaceType.listPicker:
        return _ListPickerWidget(
          options: _options,
          selectedIds: _selectedOptionIds,
          onTapOption: (id) {
            setState(() {
              final allowMultiple = _isBackendUiHintDriven &&
                  _backendUiSelectionMode == 'MULTIPLE';
              if (allowMultiple) {
                if (_selectedOptionIds.contains(id)) {
                  _selectedOptionIds.remove(id);
                } else {
                  _selectedOptionIds.add(id);
                }
              } else {
                _selectedOptionIds
                  ..clear()
                  ..add(id);
              }
            });
          },
          canSubmit: _selectedOptionIds.isNotEmpty,
          onSubmit: _handleListSelectionSubmit,
        );
      case MiniInterfaceType.multiForm:
        if (_step == DemoStep.noiseNow) {
          return _TriageMultiFormWidget(
            noiseNowOptions: _triageNoiseNowOptions,
            safetyOptions: _triageSafetyOptions,
            selectedNoiseNowId: _triageNoiseNowId,
            selectedSafetyId: _triageSafetyId,
            onSelectNoiseNow: (id) => setState(() => _triageNoiseNowId = id),
            onSelectSafety: (id) => setState(() => _triageSafetyId = id),
            canSubmit: _triageNoiseNowId != null && _triageSafetyId != null,
            onSubmit: _submitTriageMultiForm,
          );
        }
        if (_step == DemoStep.multiForm) {
          return _IntakeMultiFormBasicWidget(
            scrollController: _multiFormScrollController,
            residenceOptions: _residenceOptions,
            selectedResidenceId: _intakeResidenceId,
            onSelectResidence: (id) => setState(() => _intakeResidenceId = id),
            managementOptions: _managementOptions,
            selectedManagementId: _intakeManagementId,
            onSelectManagement: (id) =>
                setState(() => _intakeManagementId = id),
            sourceCertaintyOptions: _sourceCertaintyOptions,
            selectedSourceCertaintyId: _intakeSourceCertaintyId,
            onSelectSourceCertainty: (id) =>
                setState(() => _intakeSourceCertaintyId = id),
            canSubmit: _isIntakeBasicReady,
            onSubmit: _submitIntakeBasicMultiForm,
          );
        }
        if (_step == DemoStep.dateTime) {
          return _IntakeMultiFormDetailWidget(
            scrollController: _multiFormScrollController,
            noiseTypeOptions: _noiseTypeOptions,
            selectedNoiseTypeId: _intakeNoiseTypeId,
            onSelectNoiseType: (id) => setState(() => _intakeNoiseTypeId = id),
            frequencyOptions: _frequencyOptions,
            selectedFrequencyId: _intakeFrequencyId,
            onSelectFrequency: (id) => setState(() => _intakeFrequencyId = id),
            timeBandOptions: _timeBandOptions,
            selectedTimeBandId: _intakeTimeBandId,
            onSelectTimeBand: (id) => setState(() => _intakeTimeBandId = id),
            dateLabel:
                _incidentDate == null ? '선택해 주세요' : _formatDate(_incidentDate!),
            timeLabel:
                _incidentTime == null ? '선택해 주세요' : _formatTime(_incidentTime!),
            onPickDate: _openIncidentDatePicker,
            onPickTime: _openIncidentTimePicker,
            canSubmit: _isIntakeDetailReady,
            onSubmit: _submitIntakeDetailMultiForm,
          );
        }
        return _MultiFormWidget(
          scrollController: _multiFormScrollController,
          residenceOptions: _residenceOptions,
          selectedResidenceId: _multiResidenceId,
          onSelectResidence: (id) => setState(() => _multiResidenceId = id),
          timeBandOptions: _timeBandOptions,
          selectedTimeBandId: _multiTimeBandId,
          onSelectTimeBand: (id) => setState(() => _multiTimeBandId = id),
          dateLabel:
              _incidentDate == null ? '선택해 주세요' : _formatDate(_incidentDate!),
          timeLabel:
              _incidentTime == null ? '선택해 주세요' : _formatTime(_incidentTime!),
          onPickDate: _openIncidentDatePicker,
          onPickTime: _openIncidentTimePicker,
          canSubmit: _isMultiFormReady,
          onSubmit: () {},
        );
      case MiniInterfaceType.optionList:
        if (_step == DemoStep.evidenceV1) {
          return _EvidenceOptionListWidget(
            selectedAttachmentIds: _evidenceAttachmentIds,
            audioFileName: _evidenceAttachmentNames['evidence-audio'],
            videoFileName: _evidenceAttachmentNames['evidence-video'],
            isPicking: _isPickingEvidence,
            onToggleAttachment: (id) {
              _toggleEvidenceAttachment(id);
            },
            onSubmit: _submitEvidenceAttachments,
            onSkip: _skipEvidenceAttachments,
            canSubmit: _evidenceAttachmentIds.isNotEmpty,
          );
        }
        if (_step == DemoStep.evidenceV2) {
          return _EvidencePackV2Widget(
            selectedAttachmentIds: _evidenceV2AttachmentIds,
            formFileName: _evidenceV2AttachmentNames['evidence-v2-form'],
            diaryFileName: _evidenceV2AttachmentNames['evidence-v2-diary'],
            isPicking: _isPickingEvidence,
            onToggleAttachment: (id) {
              _toggleEvidenceV2Attachment(id);
            },
            onSubmit: _submitEvidenceV2Attachments,
            onSkip: _skipEvidenceV2Attachments,
            canSubmit: _evidenceV2AttachmentIds.length >= 2,
          );
        }
        return _OptionListWidget(
          dateLabel:
              _incidentDate == null ? '선택해 주세요' : _formatDate(_incidentDate!),
          timeLabel:
              _incidentTime == null ? '선택해 주세요' : _formatTime(_incidentTime!),
          onPickDate: _openIncidentDatePicker,
          onPickTime: _openIncidentTimePicker,
          onSubmit: _isBackendUiHintDriven
              ? () => unawaited(_requestBackendTurnForText(
                    '${_incidentDate == null ? '' : _formatDate(_incidentDate!)} ${_incidentTime == null ? '' : _formatTime(_incidentTime!)}'
                        .trim(),
                    thinkingDuration: const Duration(milliseconds: 420),
                    onFailureContinueLocal: _submitIntakeDetailMultiForm,
                  ))
              : _submitIntakeDetailMultiForm,
          canSubmit: _isBackendUiHintDriven
              ? (_incidentDate != null && _incidentTime != null)
              : _isIntakeDetailReady,
        );
      case MiniInterfaceType.measureCheck:
        return _MeasureTransitionCheckWidget(
          visitDone: _measureVisitDone,
          within30Days: _measureWithin30Days,
          receivingUnit: _measureReceivingUnit,
          onSelectVisitDone: (value) =>
              setState(() => _measureVisitDone = value),
          onSelectWithin30Days: (value) =>
              setState(() => _measureWithin30Days = value),
          onSelectReceivingUnit: (value) =>
              setState(() => _measureReceivingUnit = value),
          canSubmit: _isMeasureCheckReady,
          onSubmit: _submitMeasureCheck,
        );
      case MiniInterfaceType.datePicker:
        return _MiniDatePickerWidget(
          month: _pickerMonth,
          selectedDate: _pickerDateSelection,
          onPickDate: _selectPickerDate,
          onPrevMonth: () => _movePickerMonth(-1),
          onNextMonth: () => _movePickerMonth(1),
          onSelectYear: _setPickerYear,
          onSelectMonth: _setPickerMonthValue,
          onBack: _cancelPicker,
          onConfirm: _confirmDatePicker,
          selectedDateLabel: _pickerDateSelection == null
              ? '선택해 주세요'
              : _formatDate(_pickerDateSelection!),
        );
      case MiniInterfaceType.timePicker:
        return _MiniTimePickerWidget(
          isAm: _pickerIsAm,
          hour12: _pickerHour12,
          minute: _pickerMinute,
          onBack: _cancelPicker,
          onConfirm: _confirmTimePicker,
          onSelectMeridiem: (isAm) => setState(() => _pickerIsAm = isAm),
          onSelectHour: (hour) => setState(() => _pickerHour12 = hour),
          onSelectMinute: (minute) => setState(() => _pickerMinute = minute),
          selectedTimeLabel: _formatTime(
            TimeOfDay(
              hour: _pickerIsAm
                  ? (_pickerHour12 % 12)
                  : ((_pickerHour12 % 12) + 12),
              minute: _pickerMinute,
            ),
          ),
        );
      case MiniInterfaceType.summaryCard:
        return _SummaryCardWidget(
          rows: [
            _SummaryRow(label: '거주 형태', value: _data.residence ?? '미입력'),
            _SummaryRow(label: '관리주체', value: _data.management ?? '미입력'),
            _SummaryRow(label: '소음 유형', value: _data.noiseType ?? '미입력'),
            _SummaryRow(label: '반복 빈도', value: _data.frequency ?? '미입력'),
            _SummaryRow(label: '주 발생 시간', value: _data.timeBand ?? '미입력'),
            _SummaryRow(label: '발생원 특정', value: _data.sourceCertainty ?? '미입력'),
            _SummaryRow(
              label: '시작 시점',
              value: _data.startedAtDate != null && _data.startedAtTime != null
                  ? '${_formatDate(_data.startedAtDate!)} ${_formatTime(_data.startedAtTime!)}'
                  : '미입력',
            ),
            _SummaryRow(label: '현재 상태', value: _data.noiseNow ?? '미입력'),
          ],
          onContinue: () {
            _recordMiniResponse('다음');
            _setAi(
              text: '추천 경로를 준비했어요.\n진행 방식을 선택해 주세요.',
              step: DemoStep.pathChooser,
              miniType: MiniInterfaceType.pathChooser,
            );
          },
          onEdit: () {
            _recordMiniResponse('수정');
            _goIntakeMultiFormBasic('수정할 기본 정보를 다시 입력해 주세요.');
          },
        );
      case MiniInterfaceType.pathChooser:
        final pathOptions = _options.isNotEmpty
            ? _options
            : const <MiniOption>[
                MiniOption(
                  id: 'path-recommended',
                  label: '이웃사이센터 조정 신청',
                  description: '층간소음 상담/조정 절차에 가장 빠르게 연결돼요.',
                ),
                MiniOption(
                  id: 'path-alternative',
                  label: '다른 기관 선택',
                ),
              ];
        return _PathChooserWidget(
          options: pathOptions,
          selectedId:
              _selectedOptionIds.isEmpty ? null : _selectedOptionIds.first,
          onSelect: (id) {
            setState(() {
              _selectedOptionIds
                ..clear()
                ..add(id);
            });
          },
          canSubmit: _selectedOptionIds.isNotEmpty,
          onSubmit: _handlePathChooserSelectionSubmit,
        );
      case MiniInterfaceType.noiseDiaryBuilder:
        return _NoiseDiaryBuilderWidget(
          dateLabel: _noiseDiaryDate == null
              ? '선택해 주세요'
              : _formatDate(_noiseDiaryDate!),
          timeLabel: _noiseDiaryTime == null
              ? '선택해 주세요'
              : _formatTime(_noiseDiaryTime!),
          onPickDate: _openNoiseDiaryDatePicker,
          onPickTime: _openNoiseDiaryTimePicker,
          selectedDuration: _noiseDiaryDuration,
          selectedType: _noiseDiaryType,
          selectedImpact: _noiseDiaryImpact,
          onSelectDuration: (value) =>
              setState(() => _noiseDiaryDuration = value),
          onSelectType: (value) => setState(() => _noiseDiaryType = value),
          onSelectImpact: (value) => setState(() => _noiseDiaryImpact = value),
          durations: _durations,
          noiseTypes: _noiseTypes,
          impacts: _impacts,
          canSubmit: _isNoiseDiaryReady,
          onSubmit: _submitNoiseDiaryBuilder,
        );
      case MiniInterfaceType.draftViewer:
        return _DraftViewerWidget(
          previewLines: _buildDraftPreviewLines(),
          guidePoints: _buildDraftGuidePoints(),
          onApprove: () {
            _recordMiniResponse('좋아요, 접수');
            _goStatusFeed();
          },
          onEdit: () {
            _recordMiniResponse('수정 요청');
            _setAi(
              text: '수정할 내용을 아래 입력창에 적어주세요.',
              step: DemoStep.waitingRevision,
              miniType: MiniInterfaceType.none,
            );
          },
        );
      case MiniInterfaceType.draftConfirm:
        return _DraftConfirmWidget(
          previewLines: _buildDraftConfirmLines(),
          highlightIndexes: _data.revisionNote?.trim().isNotEmpty == true
              ? {_buildDraftConfirmLines().length - 1}
              : const <int>{},
          onApprove: () {
            _recordMiniResponse('좋아요, 접수해주세요');
            _goStatusFeed();
          },
          onEditAgain: () {
            _recordMiniResponse('다시 수정');
            _setAi(
              text: '수정할 내용을 다시 입력해 주세요.',
              step: DemoStep.waitingRevision,
              miniType: MiniInterfaceType.none,
            );
          },
        );
      case MiniInterfaceType.statusFeed:
        return _StatusFeedWidget(
          routeLabel: _data.route ?? '미선택',
          needsSupplementLikely: _evidenceAttachmentIds.isEmpty,
          onUploadMore: () {
            _recordMiniResponse('추가 증거 업로드');
            _setAi(
              text: '추가 증거를 선택해 주세요.',
              step: DemoStep.evidenceV1,
              miniType: MiniInterfaceType.optionList,
            );
          },
          onOpenSummary: () {
            _recordMiniResponse('케이스 요약 보기');
            _setAi(
              text: '종결 요약입니다.\n처음으로 돌아가 새 케이스를 시작할 수 있어요.',
              step: DemoStep.complete,
              miniType: MiniInterfaceType.listPicker,
              options: const [
                MiniOption(id: 'complete-restart', label: '처음으로 돌아가기')
              ],
            );
          },
        );
      case MiniInterfaceType.none:
        return const SizedBox.shrink();
    }
  }

  List<String> _buildDraftPreviewLines() {
    final lines = <String>[
      '제목: 층간소음 민원 접수 초안',
      '거주 형태: ${_data.residence ?? '미입력'}',
      '관리주체: ${_data.management ?? '미입력'}',
      '소음 유형: ${_data.noiseType ?? '미입력'}',
      '반복 빈도: ${_data.frequency ?? '미입력'}',
      '주 발생 시간: ${_data.timeBand ?? '미입력'}',
      '발생원 특정: ${_data.sourceCertainty ?? '미입력'}',
      '시작 시점: ${_data.startedAtDate != null && _data.startedAtTime != null ? '${_formatDate(_data.startedAtDate!)} ${_formatTime(_data.startedAtTime!)}' : '미입력'}',
      '현재 상태: ${_data.noiseNow ?? '미입력'}',
      '추천 경로: ${_data.route ?? '미선택'}',
    ];

    if (_isNoiseDiaryReady) {
      lines.add(
          '소음일지: ${_formatDate(_noiseDiaryDate!)} ${_formatTime(_noiseDiaryTime!)} · $_noiseDiaryDuration · $_noiseDiaryType · $_noiseDiaryImpact');
    }
    if (_evidenceAttachmentIds.isNotEmpty) {
      final labels = <String>[];
      if (_evidenceAttachmentIds.contains('evidence-audio')) {
        labels.add(
            '녹음 파일(${_evidenceAttachmentNames['evidence-audio'] ?? '첨부됨'})');
      }
      if (_evidenceAttachmentIds.contains('evidence-video')) {
        labels
            .add('동영상(${_evidenceAttachmentNames['evidence-video'] ?? '첨부됨'})');
      }
      if (labels.isNotEmpty) {
        lines.add('증거 제출: ${labels.join(', ')}');
      }
    }

    if (_evidenceV2AttachmentIds.isNotEmpty) {
      final labels = <String>[];
      if (_evidenceV2AttachmentIds.contains('evidence-v2-form')) {
        labels.add(
            '측정 신청서(${_evidenceV2AttachmentNames['evidence-v2-form'] ?? '첨부됨'})');
      }
      if (_evidenceV2AttachmentIds.contains('evidence-v2-diary')) {
        labels.add(
            '발생일지(${_evidenceV2AttachmentNames['evidence-v2-diary'] ?? '첨부됨'})');
      }
      if (labels.isNotEmpty) {
        lines.add('측정 서류 제출: ${labels.join(', ')}');
      }
    }

    return lines;
  }

  List<String> _buildDraftGuidePoints() {
    return [
      _data.eligibilityReason ?? '입력한 정보로 적합 경로를 자동 판별했어요.',
      '사실 중심 문장으로 정리돼 기관 검토가 쉬워요.',
      '날짜/시간/빈도가 포함되어 처리 누락을 줄여요.',
      _data.revisionNote?.trim().isNotEmpty == true
          ? '최근 반영 요청: ${_data.revisionNote!.trim()}'
          : '필요하면 수정 요청으로 문장을 보완할 수 있어요.',
    ];
  }

  List<String> _buildDraftConfirmLines() {
    final lines = _buildDraftPreviewLines();
    if (_data.revisionNote?.trim().isNotEmpty == true) {
      lines.add('추가 반영: ${_data.revisionNote!.trim()}');
    }
    return lines;
  }
}

class _ChatTopBar extends StatelessWidget {
  const _ChatTopBar({required this.onBackToList});

  final VoidCallback onBackToList;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _BackIconButton(onPressed: onBackToList),
          ),
          const Align(
            alignment: Alignment.center,
            child: Text(
              '층간소음 상담',
              style: TextStyle(
                color: AppColors.textMain,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackIconButton extends StatefulWidget {
  const _BackIconButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_BackIconButton> createState() => _BackIconButtonState();
}

class _BackIconButtonState extends State<_BackIconButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        scale: _pressed ? 0.9 : 1,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 110),
          opacity: _pressed ? 0.55 : 1,
          child: const SizedBox(
            width: 36,
            height: 36,
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 24,
              color: AppColors.textMain,
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniInterfaceCard extends StatelessWidget {
  const _MiniInterfaceCard({
    super.key,
    required this.child,
    required this.title,
    required this.collapsed,
    required this.onToggleCollapsed,
  });

  final Widget child;
  final String title;
  final bool collapsed;
  final VoidCallback onToggleCollapsed;

  @override
  Widget build(BuildContext context) {
    final double cardRadius = collapsed
        ? KrdsTokens.radiusXl + KrdsTokens.space4
        : KrdsTokens.radiusXl;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: 58,
        maxHeight: collapsed ? 58 : 520,
      ),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 28,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _kMiniSubtitleColor,
                      fontSize: 12,
                      height: 16 / 12,
                      fontWeight: FontWeight.w500,
                      fontFamilyFallback: _kKrFontFallback,
                    ),
                  ),
                ),
                _MiniInterfaceToggleButton(
                  collapsed: collapsed,
                  onTap: onToggleCollapsed,
                ),
              ],
            ),
          ),
          ClipRect(
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeInOutCubic,
              alignment: Alignment.topCenter,
              heightFactor: collapsed ? 0 : 1,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                opacity: collapsed ? 0 : 1,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeInOutCubic,
                  alignment: Alignment.topCenter,
                  scale: collapsed ? 0.9 : 1,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniInterfaceToggleButton extends StatefulWidget {
  const _MiniInterfaceToggleButton({
    required this.collapsed,
    required this.onTap,
  });

  final bool collapsed;
  final VoidCallback onTap;

  @override
  State<_MiniInterfaceToggleButton> createState() =>
      _MiniInterfaceToggleButtonState();
}

class _MiniInterfaceToggleButtonState
    extends State<_MiniInterfaceToggleButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        scale: _pressed ? 0.96 : 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.collapsed ? '펼치기' : '접기',
                style: TextStyle(
                  color: _pressed ? AppColors.primary : AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                widget.collapsed
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: _pressed ? AppColors.primary : AppColors.textMuted,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.placeholder,
    required this.enabled,
    required this.sendEnabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String placeholder;
  final bool enabled;
  final bool sendEnabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
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
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                isDense: true,
                isCollapsed: true,
                contentPadding: EdgeInsets.zero,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
              ),
              style: const TextStyle(
                color: AppColors.textMain,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: sendEnabled ? onSend : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    sendEnabled ? AppColors.primary : const Color(0xFFCFE0EC),
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded,
                  size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryMessageLine extends StatelessWidget {
  const _HistoryMessageLine({required this.entry});

  final ChatHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final alignment = entry.isAi ? Alignment.centerLeft : Alignment.centerRight;
    final verticalPadding = entry.isAi
        ? const EdgeInsets.only(bottom: 18)
        : const EdgeInsets.only(bottom: 22);
    const userBubbleRadius = BorderRadius.all(Radius.circular(14));

    const userTextStyle = TextStyle(
      color: AppColors.textMain,
      fontSize: 15.5,
      height: 1.45,
      fontWeight: FontWeight.w500,
      fontFamilyFallback: _kKrFontFallback,
    );

    if (entry.isAi) {
      return Padding(
        padding: verticalPadding,
        child: Align(
          alignment: alignment,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: _MarkdownText(
              text: entry.text,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 18,
                height: 1.36,
                fontWeight: FontWeight.w500,
                fontFamilyFallback: _kKrFontFallback,
              ),
            ),
          ),
        ),
      );
    }

    if (entry.fromMiniInterface) {
      return Padding(
        padding: verticalPadding,
        child: Align(
          alignment: alignment,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F6F8),
                borderRadius: userBubbleRadius,
                border: Border.all(color: const Color(0xFFD9E4ED), width: 1),
              ),
              child: Text(
                '선택 응답 · ${entry.text}',
                textAlign: TextAlign.right,
                style: userTextStyle.copyWith(
                  color: _kMiniSubtitleColor,
                  fontSize: 12,
                  height: 16 / 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: verticalPadding,
      child: Align(
        alignment: alignment,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFC),
              borderRadius: userBubbleRadius,
              border: Border.all(color: const Color(0xFFDCE7F0), width: 1),
            ),
            child: Text(
              entry.text,
              textAlign: TextAlign.right,
              style: userTextStyle,
            ),
          ),
        ),
      ),
    );
  }
}

class _ListPickerWidget extends StatelessWidget {
  const _ListPickerWidget({
    required this.options,
    required this.selectedIds,
    required this.onTapOption,
    required this.canSubmit,
    required this.onSubmit,
  });

  final List<MiniOption> options;
  final Set<String> selectedIds;
  final ValueChanged<String> onTapOption;
  final bool canSubmit;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    const maxVisibleOptions = 5;
    const optionHeight = 58.0;
    const optionGap = 12.0;
    const maxOptionsHeight = (optionHeight * maxVisibleOptions) +
        (optionGap * (maxVisibleOptions - 1));
    final optionsColumn = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < options.length; i++) ...[
          Padding(
            padding: EdgeInsets.only(
                bottom: i == options.length - 1 ? 0 : optionGap),
            child: _ListPickerOptionButton(
              selected: selectedIds.contains(options[i].id),
              label: options[i].label,
              onTap: () => onTapOption(options[i].id),
            ),
          ),
        ],
      ],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (options.length > maxVisibleOptions)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: maxOptionsHeight),
            child: SingleChildScrollView(child: optionsColumn),
          )
        else
          optionsColumn,
        const SizedBox(height: 12),
        _PrimaryButton(
          label: '선택 완료',
          onPressed: canSubmit ? onSubmit : null,
          compact: true,
        ),
      ],
    );
  }
}

class _ListPickerOptionButton extends StatefulWidget {
  const _ListPickerOptionButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_ListPickerOptionButton> createState() =>
      _ListPickerOptionButtonState();
}

class _ListPickerOptionButtonState extends State<_ListPickerOptionButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        scale: _pressed ? 0.99 : 1,
        child: AnimatedContainer(
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
            boxShadow: _pressed
                ? const [
                    BoxShadow(
                      color: Color(0x10000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ]
                : selected
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
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.left,
            style: TextStyle(
              color: selected ? AppColors.primary : const Color(0xFF1F2937),
              fontSize: selected ? 16.8 : 16,
              height: 24 / 16,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _TriageMultiFormWidget extends StatelessWidget {
  const _TriageMultiFormWidget({
    required this.noiseNowOptions,
    required this.safetyOptions,
    required this.selectedNoiseNowId,
    required this.selectedSafetyId,
    required this.onSelectNoiseNow,
    required this.onSelectSafety,
    required this.canSubmit,
    required this.onSubmit,
  });

  final List<MiniOption> noiseNowOptions;
  final List<MiniOption> safetyOptions;
  final String? selectedNoiseNowId;
  final String? selectedSafetyId;
  final ValueChanged<String> onSelectNoiseNow;
  final ValueChanged<String> onSelectSafety;
  final bool canSubmit;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final containerHeight = (screenHeight * 0.50).clamp(360.0, 500.0);

    return SizedBox(
      height: containerHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '현재 소음 상태',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamilyFallback: _kKrFontFallback,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _MultiFormButtonGrid(
                    options: noiseNowOptions,
                    selectedId: selectedNoiseNowId,
                    onSelect: onSelectNoiseNow,
                    iconBuilder: _triageNoiseNowIconForOption,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '안전 긴급도',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamilyFallback: _kKrFontFallback,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _MultiFormButtonGrid(
                    options: safetyOptions,
                    selectedId: selectedSafetyId,
                    onSelect: onSelectSafety,
                    iconBuilder: _triageSafetyIconForOption,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _PrimaryButton(
            label: '다음',
            onPressed: canSubmit ? onSubmit : null,
            compact: true,
          ),
        ],
      ),
    );
  }
}

class _IntakeMultiFormBasicWidget extends StatelessWidget {
  const _IntakeMultiFormBasicWidget({
    required this.scrollController,
    required this.residenceOptions,
    required this.selectedResidenceId,
    required this.onSelectResidence,
    required this.managementOptions,
    required this.selectedManagementId,
    required this.onSelectManagement,
    required this.sourceCertaintyOptions,
    required this.selectedSourceCertaintyId,
    required this.onSelectSourceCertainty,
    required this.canSubmit,
    required this.onSubmit,
  });

  final ScrollController scrollController;
  final List<MiniOption> residenceOptions;
  final String? selectedResidenceId;
  final ValueChanged<String> onSelectResidence;
  final List<MiniOption> managementOptions;
  final String? selectedManagementId;
  final ValueChanged<String> onSelectManagement;
  final List<MiniOption> sourceCertaintyOptions;
  final String? selectedSourceCertaintyId;
  final ValueChanged<String> onSelectSourceCertainty;
  final bool canSubmit;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final containerHeight = (screenHeight * 0.50).clamp(360.0, 500.0);

    return SizedBox(
      height: containerHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              key: const PageStorageKey<String>('intake-basic-scroll'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '거주 형태',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamilyFallback: _kKrFontFallback,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _MultiFormButtonGrid(
                    options: residenceOptions,
                    selectedId: selectedResidenceId,
                    onSelect: onSelectResidence,
                    iconBuilder: _residenceIconForOption,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '관리사무소(관리주체) 유무',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamilyFallback: _kKrFontFallback,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _MultiFormButtonGrid(
                    options: managementOptions,
                    selectedId: selectedManagementId,
                    onSelect: onSelectManagement,
                    iconBuilder: _managementIconForOption,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '발생원 특정 정도',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamilyFallback: _kKrFontFallback,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _MultiFormButtonGrid(
                    options: sourceCertaintyOptions,
                    selectedId: selectedSourceCertaintyId,
                    onSelect: onSelectSourceCertainty,
                    iconBuilder: _sourceCertaintyIconForOption,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _PrimaryButton(
            label: '다음',
            onPressed: canSubmit ? onSubmit : null,
            compact: true,
          ),
        ],
      ),
    );
  }
}

class _IntakeMultiFormDetailWidget extends StatelessWidget {
  const _IntakeMultiFormDetailWidget({
    required this.scrollController,
    required this.noiseTypeOptions,
    required this.selectedNoiseTypeId,
    required this.onSelectNoiseType,
    required this.frequencyOptions,
    required this.selectedFrequencyId,
    required this.onSelectFrequency,
    required this.timeBandOptions,
    required this.selectedTimeBandId,
    required this.onSelectTimeBand,
    required this.dateLabel,
    required this.timeLabel,
    required this.onPickDate,
    required this.onPickTime,
    required this.canSubmit,
    required this.onSubmit,
  });

  final ScrollController scrollController;
  final List<MiniOption> noiseTypeOptions;
  final String? selectedNoiseTypeId;
  final ValueChanged<String> onSelectNoiseType;
  final List<MiniOption> frequencyOptions;
  final String? selectedFrequencyId;
  final ValueChanged<String> onSelectFrequency;
  final List<MiniOption> timeBandOptions;
  final String? selectedTimeBandId;
  final ValueChanged<String> onSelectTimeBand;
  final String dateLabel;
  final String timeLabel;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final bool canSubmit;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final containerHeight = (screenHeight * 0.56).clamp(400.0, 560.0);

    return SizedBox(
      height: containerHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              key: const PageStorageKey<String>('intake-detail-scroll'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '소음 유형',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamilyFallback: _kKrFontFallback,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _MultiFormButtonGrid(
                    options: noiseTypeOptions,
                    selectedId: selectedNoiseTypeId,
                    onSelect: onSelectNoiseType,
                    iconBuilder: _noiseTypeIconForOption,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '반복 빈도',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamilyFallback: _kKrFontFallback,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _MultiFormButtonGrid(
                    options: frequencyOptions,
                    selectedId: selectedFrequencyId,
                    onSelect: onSelectFrequency,
                    iconBuilder: _frequencyIconForOption,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '주 발생 시간',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamilyFallback: _kKrFontFallback,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _MultiFormButtonGrid(
                    options: timeBandOptions,
                    selectedId: selectedTimeBandId,
                    onSelect: onSelectTimeBand,
                    iconBuilder: _timeBandIconForOption,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '소음 시작 시점',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamilyFallback: _kKrFontFallback,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _MultiFormDateTimeRow(
                    icon: Icons.calendar_month_rounded,
                    label: '발생 날짜',
                    value: dateLabel,
                    onTap: onPickDate,
                  ),
                  const SizedBox(height: 8),
                  _MultiFormDateTimeRow(
                    icon: Icons.schedule_rounded,
                    label: '발생 시간',
                    value: timeLabel,
                    onTap: onPickTime,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _PrimaryButton(
            label: '정보 확인',
            onPressed: canSubmit ? onSubmit : null,
            compact: true,
          ),
        ],
      ),
    );
  }
}

class _MultiFormWidget extends StatelessWidget {
  const _MultiFormWidget({
    required this.scrollController,
    required this.residenceOptions,
    required this.selectedResidenceId,
    required this.onSelectResidence,
    required this.timeBandOptions,
    required this.selectedTimeBandId,
    required this.onSelectTimeBand,
    required this.dateLabel,
    required this.timeLabel,
    required this.onPickDate,
    required this.onPickTime,
    required this.canSubmit,
    required this.onSubmit,
  });

  final ScrollController scrollController;
  final List<MiniOption> residenceOptions;
  final String? selectedResidenceId;
  final ValueChanged<String> onSelectResidence;
  final List<MiniOption> timeBandOptions;
  final String? selectedTimeBandId;
  final ValueChanged<String> onSelectTimeBand;
  final String dateLabel;
  final String timeLabel;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final bool canSubmit;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final containerHeight = (screenHeight * 0.50).clamp(360.0, 500.0);

    return SizedBox(
      height: containerHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              key: const PageStorageKey<String>('multi-form-scroll'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '거주 형태',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamilyFallback: _kKrFontFallback,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _MultiFormButtonGrid(
                    options: residenceOptions,
                    selectedId: selectedResidenceId,
                    onSelect: onSelectResidence,
                    iconBuilder: _residenceIconForOption,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '주 발생 시간',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamilyFallback: _kKrFontFallback,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _MultiFormButtonGrid(
                    options: timeBandOptions,
                    selectedId: selectedTimeBandId,
                    onSelect: onSelectTimeBand,
                    iconBuilder: _timeBandIconForOption,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '시작 시점',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamilyFallback: _kKrFontFallback,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _MultiFormDateTimeRow(
                    icon: Icons.calendar_month_rounded,
                    label: '발생 날짜',
                    value: dateLabel,
                    onTap: onPickDate,
                  ),
                  const SizedBox(height: 8),
                  _MultiFormDateTimeRow(
                    icon: Icons.schedule_rounded,
                    label: '발생 시간',
                    value: timeLabel,
                    onTap: onPickTime,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _PrimaryButton(
            label: '다음',
            onPressed: canSubmit ? onSubmit : null,
            compact: true,
          ),
        ],
      ),
    );
  }
}

class _MultiFormButtonGrid extends StatelessWidget {
  const _MultiFormButtonGrid({
    required this.options,
    required this.selectedId,
    required this.onSelect,
    required this.iconBuilder,
  });

  final List<MiniOption> options;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final IconData Function(String id) iconBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final width =
            ((constraints.maxWidth - spacing) / 2).clamp(120.0, 200.0);

        return Wrap(
          spacing: spacing,
          runSpacing: 12,
          children: [
            for (final option in options)
              SizedBox(
                width: width,
                child: _MultiFormGridButton(
                  label: option.label,
                  icon: iconBuilder(option.id),
                  selected: selectedId == option.id,
                  onTap: () => onSelect(option.id),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MultiFormGridButton extends StatefulWidget {
  const _MultiFormGridButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_MultiFormGridButton> createState() => _MultiFormGridButtonState();
}

class _MultiFormGridButtonState extends State<_MultiFormGridButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        scale: _pressed ? 0.985 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? AppColors.primary : const Color(0xFFF3F4F6),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x12305A78),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 20,
                color: selected ? AppColors.primary : const Color(0xFF8EA1B6),
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? AppColors.primary : const Color(0xFF4B5563),
                  fontSize: 16,
                  height: 24 / 16,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontFamilyFallback: _kKrFontFallback,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MultiFormDateTimeRow extends StatelessWidget {
  const _MultiFormDateTimeRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE6EEF5)),
                color: const Color(0xFFF4F8FC),
              ),
              child: Icon(icon, color: AppColors.primary, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF7E8EA4),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamilyFallback: _kKrFontFallback,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMain,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamilyFallback: _kKrFontFallback,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: Color(0xFF9AA9BB),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _residenceIconForOption(String id) {
  switch (id) {
    case 'residence-apartment':
      return Icons.apartment_rounded;
    case 'residence-villa':
      return Icons.home_work_rounded;
    case 'residence-officetel':
      return Icons.business_rounded;
    case 'residence-other':
      return Icons.home_rounded;
    default:
      return Icons.home_rounded;
  }
}

IconData _timeBandIconForOption(String id) {
  switch (id) {
    case 'time-evening':
      return Icons.wb_sunny_rounded;
    case 'time-night':
      return Icons.bedtime_rounded;
    case 'time-dawn':
      return Icons.wb_twilight_rounded;
    case 'time-irregular':
      return Icons.schedule_rounded;
    default:
      return Icons.schedule_rounded;
  }
}

IconData _managementIconForOption(String id) {
  switch (id) {
    case 'management-yes':
      return Icons.approval_rounded;
    case 'management-no':
      return Icons.block_rounded;
    case 'management-unknown':
      return Icons.help_outline_rounded;
    default:
      return Icons.approval_rounded;
  }
}

IconData _sourceCertaintyIconForOption(String id) {
  switch (id) {
    case 'source-exact':
      return Icons.pin_drop_rounded;
    case 'source-floor':
      return Icons.layers_rounded;
    case 'source-unknown':
      return Icons.blur_on_rounded;
    default:
      return Icons.pin_drop_rounded;
  }
}

IconData _noiseTypeIconForOption(String id) {
  switch (id) {
    case 'noise-impact':
      return Icons.fitness_center_rounded;
    case 'noise-air':
      return Icons.speaker_rounded;
    case 'noise-both':
      return Icons.graphic_eq_rounded;
    case 'noise-unknown':
      return Icons.help_outline_rounded;
    default:
      return Icons.graphic_eq_rounded;
  }
}

IconData _frequencyIconForOption(String id) {
  switch (id) {
    case 'freq-low':
      return Icons.looks_one_rounded;
    case 'freq-mid':
      return Icons.looks_two_rounded;
    case 'freq-high':
      return Icons.looks_3_rounded;
    default:
      return Icons.looks_two_rounded;
  }
}

IconData _triageNoiseNowIconForOption(String id) {
  switch (id) {
    case 'noise-now-active':
      return Icons.volume_up_rounded;
    case 'noise-now-recent':
      return Icons.pause_circle_outline_rounded;
    case 'noise-now-repeat':
      return Icons.repeat_rounded;
    default:
      return Icons.volume_up_rounded;
  }
}

IconData _triageSafetyIconForOption(String id) {
  switch (id) {
    case 'safety-normal':
      return Icons.shield_outlined;
    case 'safety-unknown':
      return Icons.help_outline_rounded;
    case 'safety-danger':
      return Icons.warning_amber_rounded;
    default:
      return Icons.shield_outlined;
  }
}

class _OptionListWidget extends StatelessWidget {
  const _OptionListWidget({
    required this.dateLabel,
    required this.timeLabel,
    required this.onPickDate,
    required this.onPickTime,
    required this.onSubmit,
    required this.canSubmit,
  });

  final String dateLabel;
  final String timeLabel;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final VoidCallback onSubmit;
  final bool canSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: Column(
            children: [
              _OptionDateTimeRow(
                icon: Icons.calendar_month_rounded,
                label: '발생 날짜',
                value: dateLabel,
                onTap: onPickDate,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Divider(height: 1, color: AppColors.border),
              ),
              _OptionDateTimeRow(
                icon: Icons.schedule_rounded,
                label: '발생 시간',
                value: timeLabel,
                onTap: onPickTime,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _PrimaryButton(
          label: '정보 확인 및 제출',
          onPressed: canSubmit ? onSubmit : null,
          compact: true,
        ),
      ],
    );
  }
}

class _EvidenceOptionListWidget extends StatelessWidget {
  const _EvidenceOptionListWidget({
    required this.selectedAttachmentIds,
    required this.audioFileName,
    required this.videoFileName,
    required this.isPicking,
    required this.onToggleAttachment,
    required this.onSubmit,
    required this.onSkip,
    required this.canSubmit,
  });

  final Set<String> selectedAttachmentIds;
  final String? audioFileName;
  final String? videoFileName;
  final bool isPicking;
  final ValueChanged<String> onToggleAttachment;
  final VoidCallback onSubmit;
  final VoidCallback onSkip;
  final bool canSubmit;

  @override
  Widget build(BuildContext context) {
    final isAudioSelected = selectedAttachmentIds.contains('evidence-audio');
    final isVideoSelected = selectedAttachmentIds.contains('evidence-video');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '상담 단계에서 필요한 자료를 선택해 주세요. (선택사항)',
          style: TextStyle(
            color: _kMiniSubtitleColor,
            fontSize: 12,
            height: 1.3,
            fontWeight: FontWeight.w500,
            fontFamilyFallback: _kKrFontFallback,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: Column(
            children: [
              _OptionDateTimeRow(
                icon: Icons.mic_rounded,
                label: '녹음 파일 첨부',
                value: isPicking
                    ? '불러오는 중...'
                    : isAudioSelected
                        ? (audioFileName ?? '첨부됨')
                        : '오디오 파일 선택',
                selected: isAudioSelected,
                onTap: () => onToggleAttachment('evidence-audio'),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Divider(height: 1, color: AppColors.border),
              ),
              _OptionDateTimeRow(
                icon: Icons.video_file_rounded,
                label: '동영상 첨부',
                value: isPicking
                    ? '불러오는 중...'
                    : isVideoSelected
                        ? (videoFileName ?? '첨부됨')
                        : '갤러리에서 영상 선택',
                selected: isVideoSelected,
                onTap: () => onToggleAttachment('evidence-video'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _PrimaryButton(
          label: '선택 완료',
          onPressed: canSubmit ? onSubmit : null,
          compact: true,
        ),
        const SizedBox(height: 8),
        _SecondaryButton(
          label: '자료 없이 진행',
          onPressed: onSkip,
          compact: true,
        ),
      ],
    );
  }
}

class _EvidencePackV2Widget extends StatelessWidget {
  const _EvidencePackV2Widget({
    required this.selectedAttachmentIds,
    required this.formFileName,
    required this.diaryFileName,
    required this.isPicking,
    required this.onToggleAttachment,
    required this.onSubmit,
    required this.onSkip,
    required this.canSubmit,
  });

  final Set<String> selectedAttachmentIds;
  final String? formFileName;
  final String? diaryFileName;
  final bool isPicking;
  final ValueChanged<String> onToggleAttachment;
  final VoidCallback onSubmit;
  final VoidCallback onSkip;
  final bool canSubmit;

  @override
  Widget build(BuildContext context) {
    final isFormSelected = selectedAttachmentIds.contains('evidence-v2-form');
    final isDiarySelected = selectedAttachmentIds.contains('evidence-v2-diary');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '측정 단계 제출에 필요한 2개 서류를 첨부해 주세요. (필수)',
          style: TextStyle(
            color: _kMiniSubtitleColor,
            fontSize: 12,
            height: 1.3,
            fontWeight: FontWeight.w500,
            fontFamilyFallback: _kKrFontFallback,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: Column(
            children: [
              _OptionDateTimeRow(
                icon: Icons.description_rounded,
                label: '층간소음 측정 신청서',
                value: isPicking
                    ? '불러오는 중...'
                    : isFormSelected
                        ? (formFileName ?? '첨부됨')
                        : 'PDF/HWP 파일 선택',
                selected: isFormSelected,
                onTap: () => onToggleAttachment('evidence-v2-form'),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Divider(height: 1, color: AppColors.border),
              ),
              _OptionDateTimeRow(
                icon: Icons.fact_check_rounded,
                label: '층간소음 발생일지',
                value: isPicking
                    ? '불러오는 중...'
                    : isDiarySelected
                        ? (diaryFileName ?? '첨부됨')
                        : '발생일지 파일 선택',
                selected: isDiarySelected,
                onTap: () => onToggleAttachment('evidence-v2-diary'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _PrimaryButton(
          label: '제출 준비 완료',
          onPressed: canSubmit ? onSubmit : null,
          compact: true,
        ),
        const SizedBox(height: 8),
        _SecondaryButton(
          label: '측정 단계 건너뛰기',
          onPressed: onSkip,
          compact: true,
        ),
      ],
    );
  }
}

class _MeasureTransitionCheckWidget extends StatelessWidget {
  const _MeasureTransitionCheckWidget({
    required this.visitDone,
    required this.within30Days,
    required this.receivingUnit,
    required this.onSelectVisitDone,
    required this.onSelectWithin30Days,
    required this.onSelectReceivingUnit,
    required this.canSubmit,
    required this.onSubmit,
  });

  final bool? visitDone;
  final bool? within30Days;
  final bool? receivingUnit;
  final ValueChanged<bool> onSelectVisitDone;
  final ValueChanged<bool> onSelectWithin30Days;
  final ValueChanged<bool> onSelectReceivingUnit;
  final bool canSubmit;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 380),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _MeasureCheckRow(
                    title: '방문상담 이후에도 갈등이 지속되나요?',
                    value: visitDone,
                    onSelect: onSelectVisitDone,
                  ),
                  const SizedBox(height: 8),
                  _MeasureCheckRow(
                    title: '방문상담 후 30일 이내 신청인가요?',
                    value: within30Days,
                    onSelect: onSelectWithin30Days,
                  ),
                  const SizedBox(height: 8),
                  _MeasureCheckRow(
                    title: '수음세대(피해 세대) 신청인가요?',
                    value: receivingUnit,
                    onSelect: onSelectReceivingUnit,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _PrimaryButton(
            label: '측정 전환 판단',
            onPressed: canSubmit ? onSubmit : null,
            compact: true,
          ),
        ],
      ),
    );
  }
}

class _MeasureCheckRow extends StatelessWidget {
  const _MeasureCheckRow({
    required this.title,
    required this.value,
    required this.onSelect,
  });

  final String title;
  final bool? value;
  final ValueChanged<bool> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12305A78),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textMain,
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w700,
              fontFamilyFallback: _kKrFontFallback,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MeasureToggleButton(
                  label: '예',
                  selected: value == true,
                  onTap: () => onSelect(true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MeasureToggleButton(
                  label: '아니오',
                  selected: value == false,
                  onTap: () => onSelect(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MeasureToggleButton extends StatefulWidget {
  const _MeasureToggleButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_MeasureToggleButton> createState() => _MeasureToggleButtonState();
}

class _MeasureToggleButtonState extends State<_MeasureToggleButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        scale: _pressed ? 0.985 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.selected ? AppColors.blueTint : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.selected ? AppColors.primary : AppColors.border,
              width: widget.selected ? 1.4 : 1,
            ),
            boxShadow: _pressed
                ? const [
                    BoxShadow(
                      color: Color(0x10000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ]
                : widget.selected
                    ? const [
                        BoxShadow(
                          color: Color(0x16305A78),
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ]
                    : const [
                        BoxShadow(
                          color: Color(0x0B000000),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.selected ? AppColors.primary : AppColors.textMuted,
              fontSize: 14,
              fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w600,
              fontFamilyFallback: _kKrFontFallback,
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionDateTimeRow extends StatelessWidget {
  const _OptionDateTimeRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        color: selected ? const Color(0xFFF3F8FF) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? AppColors.primary : const Color(0xFFE6EEF5),
                ),
                color: selected
                    ? const Color(0xFFEAF3FF)
                    : const Color(0xFFF4F8FC),
              ),
              child: Icon(icon, color: AppColors.primary, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF7E8EA4),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamilyFallback: _kKrFontFallback,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? AppColors.primary : AppColors.textMain,
                      fontSize: 16,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                      fontFamilyFallback: _kKrFontFallback,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.chevron_right_rounded,
              size: selected ? 21 : 22,
              color: selected ? AppColors.primary : const Color(0xFF9AA9BB),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniDatePickerWidget extends StatelessWidget {
  const _MiniDatePickerWidget({
    required this.month,
    required this.selectedDate,
    required this.onPickDate,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onSelectYear,
    required this.onSelectMonth,
    required this.onBack,
    required this.onConfirm,
    required this.selectedDateLabel,
  });

  final DateTime month;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onPickDate;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<int> onSelectYear;
  final ValueChanged<int> onSelectMonth;
  final VoidCallback onBack;
  final VoidCallback onConfirm;
  final String selectedDateLabel;

  @override
  Widget build(BuildContext context) {
    final days = _calendarDays(month);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentYear = today.year;
    final yearOptions = List<int>.generate(11, (i) => currentYear - 10 + i);
    final currentMonthStart = DateTime(today.year, today.month, 1);
    final monthStart = DateTime(month.year, month.month, 1);
    final canMoveNext = monthStart.isBefore(currentMonthStart);
    final monthOptions = month.year == currentYear
        ? List<int>.generate(today.month, (i) => i + 1)
        : List<int>.generate(12, (i) => i + 1);
    const weekdayLabels = ['일', '월', '화', '수', '목', '금', '토'];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MiniBackButton(onTap: onBack),
        const SizedBox(height: 8),
        Row(
          children: [
            _MiniIconCircleButton(
              icon: Icons.chevron_left_rounded,
              onTap: onPrevMonth,
            ),
            Expanded(
              child: Center(
                child: Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _MiniPickerSelector<int>(
                      valueLabel: '${month.year}년',
                      options: yearOptions,
                      optionLabel: (year) => '$year년',
                      onSelected: onSelectYear,
                    ),
                    _MiniPickerSelector<int>(
                      valueLabel: '${month.month}월',
                      options: monthOptions,
                      optionLabel: (value) => '$value월',
                      onSelected: onSelectMonth,
                    ),
                  ],
                ),
              ),
            ),
            _MiniIconCircleButton(
              icon: Icons.chevron_right_rounded,
              onTap: canMoveNext ? onNextMonth : null,
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            final offset = Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(animation);
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: offset,
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey<String>('month-${month.year}-${month.month}'),
            child: Column(
              children: [
                Row(
                  children: [
                    for (final weekday in weekdayLabels)
                      Expanded(
                        child: Center(
                          child: Text(
                            weekday,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              fontFamilyFallback: _kKrFontFallback,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: days.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                    mainAxisExtent: 30,
                  ),
                  itemBuilder: (context, index) {
                    final day = days[index];
                    final inMonth = day.month == month.month;
                    final isFuture = day.isAfter(today);
                    final selected = selectedDate != null &&
                        day.year == selectedDate!.year &&
                        day.month == selectedDate!.month &&
                        day.day == selectedDate!.day;

                    return InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: isFuture ? null : () => onPickDate(day),
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          width: 27,
                          height: 27,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : isFuture
                                      ? const Color(0xFFD6DEE8)
                                      : inMonth
                                          ? AppColors.textMain
                                          : const Color(0xFFCBD5E1),
                              fontSize: 12.5,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                              fontFamilyFallback: _kKrFontFallback,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        _PickerBottomSection(
          summaryLabel: '선택된 날짜',
          summaryValue: selectedDateLabel,
          actionLabel: '날짜 선택 완료',
          onPressed: selectedDate == null ? null : onConfirm,
        ),
      ],
    );
  }

  List<DateTime> _calendarDays(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final firstNextMonth = DateTime(month.year, month.month + 1, 1);
    final daysInMonth = firstNextMonth.subtract(const Duration(days: 1)).day;
    final leading = first.weekday % 7;
    final totalCells = ((leading + daysInMonth + 6) ~/ 7) * 7;
    final start = first.subtract(Duration(days: leading));
    return List<DateTime>.generate(
      totalCells,
      (i) => DateTime(start.year, start.month, start.day + i),
      growable: false,
    );
  }
}

class _MiniTimePickerWidget extends StatefulWidget {
  const _MiniTimePickerWidget({
    required this.isAm,
    required this.hour12,
    required this.minute,
    required this.onBack,
    required this.onConfirm,
    required this.onSelectMeridiem,
    required this.onSelectHour,
    required this.onSelectMinute,
    required this.selectedTimeLabel,
  });

  final bool isAm;
  final int hour12;
  final int minute;
  final VoidCallback onBack;
  final VoidCallback onConfirm;
  final ValueChanged<bool> onSelectMeridiem;
  final ValueChanged<int> onSelectHour;
  final ValueChanged<int> onSelectMinute;
  final String selectedTimeLabel;

  @override
  State<_MiniTimePickerWidget> createState() => _MiniTimePickerWidgetState();
}

class _MiniTimePickerWidgetState extends State<_MiniTimePickerWidget> {
  late final FixedExtentScrollController _hourController;
  late final FixedExtentScrollController _minuteController;
  late bool _localIsAm;
  late int _localHour12;
  late int _localMinute;

  @override
  void initState() {
    super.initState();
    _localIsAm = widget.isAm;
    _localHour12 = widget.hour12;
    _localMinute = widget.minute;
    _hourController = FixedExtentScrollController(
      initialItem: (_localHour12 - 1) + (12 * 200),
    );
    _minuteController = FixedExtentScrollController(
      initialItem: _localMinute + (60 * 100),
    );
  }

  @override
  void didUpdateWidget(covariant _MiniTimePickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isAm != widget.isAm) {
      _localIsAm = widget.isAm;
    }
    if (oldWidget.hour12 != widget.hour12) {
      _localHour12 = widget.hour12;
      _hourController.jumpToItem((_localHour12 - 1) + (12 * 200));
    }
    if (oldWidget.minute != widget.minute) {
      _localMinute = widget.minute;
      _minuteController.jumpToItem(_localMinute + (60 * 100));
    }
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MiniBackButton(onTap: widget.onBack),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MeridiemToggleButton(
                label: '오전',
                selected: _localIsAm,
                onTap: () => setState(() => _localIsAm = true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MeridiemToggleButton(
                label: '오후',
                selected: !_localIsAm,
                onTap: () => setState(() => _localIsAm = false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 136,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            color: const Color(0xFFF9FAFB),
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.center,
                child: Container(
                  height: 36,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderStrong),
                    color: Colors.white,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: IgnorePointer(
                  child: Container(
                    height: 28,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFF9FAFB), Color(0x00F9FAFB)],
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: IgnorePointer(
                  child: Container(
                    height: 28,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00F9FAFB), Color(0xFFF9FAFB)],
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _MiniWheelPicker(
                      controller: _hourController,
                      itemExtent: 36,
                      onIndexChanged: (index) {
                        final nextHour = (index % 12) + 1;
                        if (_localHour12 == nextHour) return;
                        setState(() => _localHour12 = nextHour);
                      },
                      itemBuilder: (index) {
                        final hour = (index % 12) + 1;
                        return _wheelText(
                          hour.toString().padLeft(2, '0'),
                          selected: hour == _localHour12,
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: _MiniWheelPicker(
                      controller: _minuteController,
                      itemExtent: 36,
                      onIndexChanged: (index) {
                        final nextMinute = index % 60;
                        if (_localMinute == nextMinute) return;
                        setState(() => _localMinute = nextMinute);
                      },
                      itemBuilder: (index) {
                        final minute = index % 60;
                        return _wheelText(
                          minute.toString().padLeft(2, '0'),
                          selected: minute == _localMinute,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _PickerBottomSection(
          summaryLabel: '선택된 시간',
          summaryValue: _formatLocalTime(),
          actionLabel: '시간 선택 완료',
          onPressed: () {
            widget.onSelectMeridiem(_localIsAm);
            widget.onSelectHour(_localHour12);
            widget.onSelectMinute(_localMinute);
            widget.onConfirm();
          },
        ),
      ],
    );
  }

  String _formatLocalTime() {
    final meridiem = _localIsAm ? '오전' : '오후';
    return '$meridiem ${_localHour12.toString().padLeft(2, '0')}시 ${_localMinute.toString().padLeft(2, '0')}분';
  }

  Widget _wheelText(String text, {required bool selected}) {
    return Center(
      child: Text(
        text,
        style: TextStyle(
          color: selected ? AppColors.primary : AppColors.textMuted,
          fontSize: selected ? 20 : 14.5,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
          letterSpacing: selected ? 0.2 : 0,
        ),
      ),
    );
  }
}

class _MeridiemToggleButton extends StatefulWidget {
  const _MeridiemToggleButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_MeridiemToggleButton> createState() => _MeridiemToggleButtonState();
}

class _MeridiemToggleButtonState extends State<_MeridiemToggleButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 110),
        scale: _pressed ? 0.97 : 1,
        child: SizedBox(
          height: 34,
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 140),
              style: TextStyle(
                color:
                    widget.selected ? AppColors.primary : AppColors.textMuted,
                fontSize: widget.selected ? 17 : 16,
                fontWeight: widget.selected ? FontWeight.w800 : FontWeight.w600,
                fontFamilyFallback: _kKrFontFallback,
              ),
              child: Text(widget.label),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniBackButton extends StatelessWidget {
  const _MiniBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
      label: const Text('이전'),
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        foregroundColor: AppColors.textMuted,
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          fontFamilyFallback: _kKrFontFallback,
        ),
      ),
    );
  }
}

class _MiniPickerSelector<T> extends StatelessWidget {
  const _MiniPickerSelector({
    required this.valueLabel,
    required this.options,
    required this.optionLabel,
    required this.onSelected,
  });

  final String valueLabel;
  final List<T> options;
  final String Function(T value) optionLabel;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      tooltip: '',
      padding: EdgeInsets.zero,
      onSelected: onSelected,
      itemBuilder: (context) {
        return options
            .map(
              (value) => PopupMenuItem<T>(
                value: value,
                child: Text(
                  optionLabel(value),
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    fontFamilyFallback: _kKrFontFallback,
                  ),
                ),
              ),
            )
            .toList(growable: false);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              valueLabel,
              style: const TextStyle(
                color: AppColors.textMain,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                fontFamilyFallback: _kKrFontFallback,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.expand_more_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniIconCircleButton extends StatelessWidget {
  const _MiniIconCircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      splashRadius: 18,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 30, height: 30),
      icon: Icon(
        icon,
        size: 22,
        color: onTap == null ? const Color(0xFFD1D8E1) : AppColors.textMuted,
      ),
    );
  }
}

class _MiniWheelPicker extends StatelessWidget {
  const _MiniWheelPicker({
    required this.controller,
    required this.itemExtent,
    required this.onIndexChanged,
    required this.itemBuilder,
  });

  final FixedExtentScrollController controller;
  final double itemExtent;
  final ValueChanged<int> onIndexChanged;
  final Widget Function(int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: itemExtent,
      perspective: 0.004,
      diameterRatio: 1.8,
      useMagnifier: true,
      magnification: 1.08,
      overAndUnderCenterOpacity: 0.62,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onIndexChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        builder: (context, index) => itemBuilder(index),
      ),
    );
  }
}

class _PickerBottomSection extends StatelessWidget {
  const _PickerBottomSection({
    required this.summaryLabel,
    required this.summaryValue,
    required this.actionLabel,
    required this.onPressed,
  });

  final String summaryLabel;
  final String summaryValue;
  final String actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: 11),
        Text(
          summaryLabel,
          style: const TextStyle(
            color: Color(0xFF8FA1B6),
            fontSize: 13,
            fontWeight: FontWeight.w700,
            fontFamilyFallback: _kKrFontFallback,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          summaryValue,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textMain,
            fontSize: 17,
            height: 1.3,
            fontWeight: FontWeight.w800,
            fontFamilyFallback: _kKrFontFallback,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 58,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              foregroundColor: Colors.white,
              backgroundColor: onPressed == null
                  ? const Color(0xFFE6EBF0)
                  : AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              textStyle: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                fontFamilyFallback: _kKrFontFallback,
              ),
            ),
            onPressed: onPressed,
            child: Text(actionLabel),
          ),
        ),
      ],
    );
  }
}

class _SummaryRow {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;
}

class _SummaryCardWidget extends StatelessWidget {
  const _SummaryCardWidget({
    required this.rows,
    required this.onContinue,
    required this.onEdit,
  });

  final List<_SummaryRow> rows;
  final VoidCallback onContinue;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 420.0;
        final containerHeight = maxHeight.clamp(310.0, 420.0).toDouble();

        return SizedBox(
          height: containerHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Scrollbar(
                  thumbVisibility: true,
                  radius: const Radius.circular(999),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(right: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < rows.length; i++) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: _SummaryItemRow(row: rows[i]),
                          ),
                          if (i < rows.length - 1)
                            const Padding(
                              padding: EdgeInsets.fromLTRB(18, 14, 0, 14),
                              child:
                                  Divider(height: 1, color: AppColors.border),
                            ),
                        ],
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _PrimaryButton(
                  label: '계속하기', onPressed: onContinue, compact: true),
              const SizedBox(height: 8),
              _SecondaryButton(
                label: '수정',
                onPressed: onEdit,
                compact: true,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryItemRow extends StatelessWidget {
  const _SummaryItemRow({required this.row});

  final _SummaryRow row;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                  fontFamilyFallback: _kKrFontFallback,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                row.value,
                style: const TextStyle(
                  color: AppColors.textMain,
                  fontSize: 16.5,
                  height: 1.45,
                  fontWeight: FontWeight.w700,
                  fontFamilyFallback: _kKrFontFallback,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PathChooserWidget extends StatefulWidget {
  const _PathChooserWidget({
    required this.options,
    required this.selectedId,
    required this.onSelect,
    required this.canSubmit,
    required this.onSubmit,
  });

  final List<MiniOption> options;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final bool canSubmit;
  final VoidCallback onSubmit;

  @override
  State<_PathChooserWidget> createState() => _PathChooserWidgetState();
}

class _PathChooserWidgetState extends State<_PathChooserWidget> {
  bool _openReason = false;

  String _compactPathTitle(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return raw;
    final compact = trimmed.split(RegExp(r'\s*[—–-]\s*')).first.trim();
    return compact.isEmpty ? trimmed : compact;
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.options.isNotEmpty
        ? widget.options
        : const <MiniOption>[
            MiniOption(
              id: 'path-recommended',
              label: '이웃사이센터 조정 신청',
              description: '층간소음 상담/조정 절차에 가장 빠르게 연결돼요.',
            ),
            MiniOption(
              id: 'path-alternative',
              label: '다른 기관 선택',
            ),
          ];
    final recommended = options.first;
    final alternatives =
        options.length > 1 ? options.sublist(1) : const <MiniOption>[];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 356),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: _SelectableCardButton(
                compact: true,
                selected: widget.selectedId == recommended.id,
                title: _compactPathTitle(recommended.label),
                subtitle: (recommended.description ?? '').trim().isEmpty
                    ? '층간소음 상담/조정 절차에 가장 빠르게 연결돼요.'
                    : recommended.description!.trim(),
                leadingBadge: '추천',
                onTap: () => widget.onSelect(recommended.id),
                emphasizeTitle: false,
                trailing: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 118,
                    child: TextButton(
                      onPressed: () =>
                          setState(() => _openReason = !_openReason),
                      child: Text(_openReason ? '추천 이유 접기' : '추천 이유 보기'),
                    ),
                  ),
                ),
                extra: _openReason
                    ? const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ReasonText(text: '층간소음 조정 절차와 가장 잘 맞아요.'),
                            _ReasonText(text: '초기 접수부터 중재 요청까지 빠르게 이어집니다.'),
                            _ReasonText(text: '필요 시 이후 민원 제출 단계로 전환 가능합니다.'),
                          ],
                        ),
                      )
                    : null,
              ),
            ),
            for (final option in alternatives) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: _SelectableCardButton(
                  compact: true,
                  centerContent: true,
                  selected: widget.selectedId == option.id,
                  title: _compactPathTitle(option.label),
                  subtitle: (option.description ?? '').trim().isEmpty
                      ? null
                      : option.description!.trim(),
                  onTap: () => widget.onSelect(option.id),
                  emphasizeTitle: false,
                ),
              ),
            ],
            const SizedBox(height: 12),
            _PrimaryButton(
              label: '선택 완료',
              onPressed: widget.canSubmit ? widget.onSubmit : null,
              compact: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReasonText extends StatelessWidget {
  const _ReasonText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Text('• ',
              style: TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w700)),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
                color: Color(0xFF475569), fontSize: 12.5, height: 1.35),
          ),
        ),
      ],
    );
  }
}

class _NoiseDiaryBuilderWidget extends StatelessWidget {
  const _NoiseDiaryBuilderWidget({
    required this.dateLabel,
    required this.timeLabel,
    required this.onPickDate,
    required this.onPickTime,
    required this.selectedDuration,
    required this.selectedType,
    required this.selectedImpact,
    required this.onSelectDuration,
    required this.onSelectType,
    required this.onSelectImpact,
    required this.durations,
    required this.noiseTypes,
    required this.impacts,
    required this.canSubmit,
    required this.onSubmit,
  });

  final String dateLabel;
  final String timeLabel;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final String? selectedDuration;
  final String? selectedType;
  final String? selectedImpact;
  final ValueChanged<String> onSelectDuration;
  final ValueChanged<String> onSelectType;
  final ValueChanged<String> onSelectImpact;
  final List<String> durations;
  final List<String> noiseTypes;
  final List<String> impacts;
  final bool canSubmit;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '소음일지를 작성해 주세요.',
          style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 360),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _OptionDateTimeRow(
                  icon: Icons.calendar_month_rounded,
                  label: '발생 날짜',
                  value: dateLabel,
                  onTap: onPickDate,
                ),
                const SizedBox(height: 8),
                _OptionDateTimeRow(
                  icon: Icons.schedule_rounded,
                  label: '발생 시간',
                  value: timeLabel,
                  onTap: onPickTime,
                ),
                const SizedBox(height: 12),
                _ChoiceSection(
                  title: '지속시간',
                  values: durations,
                  selectedValue: selectedDuration,
                  onSelect: onSelectDuration,
                ),
                _ChoiceSection(
                  title: '유형',
                  values: noiseTypes,
                  selectedValue: selectedType,
                  onSelect: onSelectType,
                ),
                _ChoiceSection(
                  title: '영향',
                  values: impacts,
                  selectedValue: selectedImpact,
                  onSelect: onSelectImpact,
                ),
                const SizedBox(height: 8),
                _PrimaryButton(
                  label: '일지 생성',
                  onPressed: canSubmit ? onSubmit : null,
                  compact: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChoiceSection extends StatelessWidget {
  const _ChoiceSection({
    required this.title,
    required this.values,
    required this.selectedValue,
    required this.onSelect,
  });

  final String title;
  final List<String> values;
  final String? selectedValue;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12.5,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values.map((value) {
              final selected = selectedValue == value;
              return InkWell(
                onTap: () => onSelect(value),
                borderRadius: BorderRadius.circular(12),
                child: Ink(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: selected ? AppColors.blueTint : Colors.white,
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.border,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      color: selected ? AppColors.primary : AppColors.textMain,
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _DraftViewerWidget extends StatelessWidget {
  const _DraftViewerWidget({
    required this.previewLines,
    required this.guidePoints,
    required this.onApprove,
    required this.onEdit,
  });

  final List<String> previewLines;
  final List<String> guidePoints;
  final VoidCallback onApprove;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 410),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TextCard(lines: previewLines),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: const Color(0xFFF8FBFF),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('수정 포인트',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            ...guidePoints.map(
                              (point) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text('• $point',
                                    style: const TextStyle(
                                        color: Color(0xFF475569),
                                        fontSize: 12.5,
                                        height: 1.35)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _PrimaryButton(
                  label: '좋아요, 접수', onPressed: onApprove, compact: true),
              const SizedBox(height: 8),
              _SecondaryButton(
                label: '수정 요청',
                onPressed: onEdit,
                compact: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DraftConfirmWidget extends StatelessWidget {
  const _DraftConfirmWidget({
    required this.previewLines,
    required this.highlightIndexes,
    required this.onApprove,
    required this.onEditAgain,
  });

  final List<String> previewLines;
  final Set<int> highlightIndexes;
  final VoidCallback onApprove;
  final VoidCallback onEditAgain;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('수정 반영 확인',
            style: TextStyle(
                color: AppColors.textMain,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 360),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < previewLines.length; i++)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: highlightIndexes.contains(i)
                              ? const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2)
                              : EdgeInsets.zero,
                          decoration: highlightIndexes.contains(i)
                              ? BoxDecoration(
                                  color: AppColors.blueTint,
                                  borderRadius: BorderRadius.circular(8),
                                )
                              : null,
                          child: Text(
                            previewLines[i],
                            style: TextStyle(
                              color: highlightIndexes.contains(i)
                                  ? const Color(0xFF1D4ED8)
                                  : const Color(0xFF334155),
                              fontSize: 13,
                              height: 1.42,
                              fontWeight: highlightIndexes.contains(i)
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _PrimaryButton(
                    label: '좋아요, 접수해주세요', onPressed: onApprove, compact: true),
                const SizedBox(height: 8),
                _SecondaryButton(
                  label: '다시 수정',
                  onPressed: onEditAgain,
                  compact: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TextCard extends StatelessWidget {
  const _TextCard({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines
            .map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  line,
                  style: const TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.4),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _StatusFeedWidget extends StatefulWidget {
  const _StatusFeedWidget({
    required this.routeLabel,
    required this.needsSupplementLikely,
    required this.onUploadMore,
    required this.onOpenSummary,
  });

  final String routeLabel;
  final bool needsSupplementLikely;
  final VoidCallback onUploadMore;
  final VoidCallback onOpenSummary;

  @override
  State<_StatusFeedWidget> createState() => _StatusFeedWidgetState();
}

class _StatusFeedWidgetState extends State<_StatusFeedWidget> {
  bool _importantOnly = true;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final statusFeedHeight = (screenHeight * 0.5).clamp(370.0, 450.0);
    final allEvents = <_StatusEvent>[
      const _StatusEvent(
        code: 'INTAKE_DONE',
        title: '대화형 접수 완료',
        subtitle: '필수 질문 수집을 마쳤어요.',
        stepState: _StatusStepState.done,
        important: true,
      ),
      const _StatusEvent(
        code: 'ELIGIBLE',
        title: '적합성 판별 완료',
        subtitle: '층간소음 절차 대상 여부를 확인했어요.',
        stepState: _StatusStepState.done,
        important: true,
      ),
      _StatusEvent(
        code: 'ROUTED',
        title: '경로 확정',
        subtitle: '선택 경로: ${widget.routeLabel}',
        stepState: _StatusStepState.done,
        important: true,
      ),
      const _StatusEvent(
        code: 'PACKAGE_READY',
        title: '접수 패키지 준비',
        subtitle: '요약/증거 패키지를 생성했어요.',
        stepState: _StatusStepState.done,
        important: false,
      ),
      const _StatusEvent(
        code: 'SUBMITTED_BY_USER',
        title: '사용자 제출 완료',
        subtitle: '최종 확인 후 접수가 진행됐어요.',
        stepState: _StatusStepState.done,
        important: true,
      ),
      const _StatusEvent(
        code: 'RECEIPT_CONFIRMED',
        title: '접수 확인',
        subtitle: '접수번호/확인 단계가 진행 중이에요.',
        stepState: _StatusStepState.active,
        important: true,
      ),
      if (widget.needsSupplementLikely)
        const _StatusEvent(
          code: 'SUPPLEMENT_REQUIRED',
          title: '보완요청 가능성',
          subtitle: '증거가 부족하면 추가자료 요청이 올 수 있어요.',
          stepState: _StatusStepState.pending,
          important: true,
        ),
      const _StatusEvent(
        code: 'VISIT_SCHEDULED',
        title: '방문상담/일정',
        subtitle: '기관 회신 후 일정이 잡혀요.',
        stepState: _StatusStepState.pending,
        important: false,
      ),
      const _StatusEvent(
        code: 'MEASURE_ELIGIBLE',
        title: '소음측정 전환 판단',
        subtitle: '조건 충족 시 측정 단계로 넘어가요.',
        stepState: _StatusStepState.pending,
        important: false,
      ),
      const _StatusEvent(
        code: 'CLOSED',
        title: '종결',
        subtitle: '처리 완료 후 후속 안내를 드려요.',
        stepState: _StatusStepState.pending,
        important: false,
      ),
    ];
    final visibleEvents = _importantOnly
        ? allEvents
            .where((event) =>
                event.important || event.stepState == _StatusStepState.active)
            .toList(growable: false)
        : allEvents;

    return SizedBox(
      height: statusFeedHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 2),
              child: Column(
                children: [
                  _StatusSummaryCard(
                    statusText: widget.needsSupplementLikely
                        ? '보완요청 가능성 확인 중'
                        : '접수 확인 단계',
                    updatedAtText: '마지막 갱신 5분 전',
                    etaText: widget.needsSupplementLikely
                        ? '추가자료 요청 가능'
                        : '예상 소요 1~2일',
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                      color: Colors.white,
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < visibleEvents.length; i++)
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: i == visibleEvents.length - 1 ? 0 : 12,
                            ),
                            child: _StatusTimelineItem(
                              code: visibleEvents[i].code,
                              title: visibleEvents[i].title,
                              subtitle: visibleEvents[i].subtitle,
                              stepState: visibleEvents[i].stepState,
                              highlight: visibleEvents[i].code ==
                                  'SUPPLEMENT_REQUIRED',
                              isLast: i == visibleEvents.length - 1,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _StatusNextActionCard(
                    needsSupplementLikely: widget.needsSupplementLikely,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatusFilterChip(
                  label: '중요 업데이트만',
                  selected: _importantOnly,
                  onTap: () => setState(() => _importantOnly = true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatusFilterChip(
                  label: '단계별 모두',
                  selected: !_importantOnly,
                  onTap: () => setState(() => _importantOnly = false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _PrimaryButton(
            label: '케이스 요약 보기',
            onPressed: widget.onOpenSummary,
            compact: true,
          ),
          const SizedBox(height: 8),
          _SecondaryButton(
            label: '추가 증거 업로드',
            onPressed: widget.onUploadMore,
            compact: true,
          ),
        ],
      ),
    );
  }
}

class _StatusSummaryCard extends StatelessWidget {
  const _StatusSummaryCard({
    required this.statusText,
    required this.updatedAtText,
    required this.etaText,
  });

  final String statusText;
  final String updatedAtText;
  final String etaText;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        color: const Color(0xFFF3F9FF),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.schedule_rounded,
              size: 19,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        statusText,
                        style: const TextStyle(
                          color: AppColors.textMain,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
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
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$updatedAtText · $etaText',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusNextActionCard extends StatelessWidget {
  const _StatusNextActionCard({required this.needsSupplementLikely});

  final bool needsSupplementLikely;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        color: const Color(0xFFF8FCFF),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '다음에 할 일',
            style: TextStyle(
              color: AppColors.textMain,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            needsSupplementLikely
                ? '보완요청 가능성이 있어요. 필요한 경우 바로 추가자료를 업로드해 주세요.'
                : '기관 확인 단계입니다. 주요 업데이트가 생기면 바로 알려드릴게요.',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusEvent {
  const _StatusEvent({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.stepState,
    required this.important,
  });

  final String code;
  final String title;
  final String subtitle;
  final _StatusStepState stepState;
  final bool important;
}

enum _StatusStepState { done, active, pending }

class _StatusTimelineItem extends StatelessWidget {
  const _StatusTimelineItem({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.stepState,
    this.highlight = false,
    this.isLast = false,
  });

  final String code;
  final String title;
  final String subtitle;
  final _StatusStepState stepState;
  final bool highlight;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final (nodeBg, nodeBorder, nodeIcon, nodeIconColor) = switch (stepState) {
      _StatusStepState.done => (
          AppColors.primary,
          AppColors.primary,
          Icons.check_rounded,
          Colors.white,
        ),
      _StatusStepState.active => (
          const Color(0xFFEAF4FF),
          const Color(0xFFB9D8F7),
          Icons.schedule_rounded,
          AppColors.primary,
        ),
      _StatusStepState.pending => (
          Colors.white,
          AppColors.border,
          Icons.radio_button_unchecked_rounded,
          const Color(0xFF94A3B8),
        ),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: nodeBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: nodeBorder),
                  ),
                  child: Icon(nodeIcon, size: 13, color: nodeIconColor),
                ),
              ),
              if (!isLast)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 2,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: highlight
                ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
                : EdgeInsets.zero,
            decoration: highlight
                ? BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFAC9A5)),
                  )
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  code,
                  style: TextStyle(
                    color: highlight
                        ? const Color(0xFFB45309)
                        : const Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    color: stepState == _StatusStepState.pending
                        ? const Color(0xFF475569)
                        : AppColors.textMain,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  const _StatusFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
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
          ),
        ),
      ),
    );
  }
}

class _SelectableCardButton extends StatefulWidget {
  const _SelectableCardButton({
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.leadingBadge,
    this.trailing,
    this.extra,
    this.centerContent = false,
    this.compact = false,
    this.emphasizeTitle = true,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;
  final String? subtitle;
  final String? leadingBadge;
  final Widget? trailing;
  final Widget? extra;
  final bool centerContent;
  final bool compact;
  final bool emphasizeTitle;

  @override
  State<_SelectableCardButton> createState() => _SelectableCardButtonState();
}

class _SelectableCardButtonState extends State<_SelectableCardButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final verticalPadding = widget.compact ? 11.0 : 14.0;
    final titleSize = widget.compact ? 17.0 : 18.0;

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        scale: _pressed ? 0.992 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          padding:
              EdgeInsets.symmetric(horizontal: 14, vertical: verticalPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: widget.selected ? AppColors.blueTint : Colors.white,
            border: Border.all(
              color: widget.selected ? AppColors.primary : AppColors.border,
              width: widget.selected ? 2 : 1,
            ),
            boxShadow: _pressed
                ? const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Color(0x18234A64),
                      blurRadius: 2,
                      offset: Offset(0, 3),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: widget.centerContent
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              if (widget.leadingBadge != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.blueTint,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    widget.leadingBadge!,
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              Text(
                widget.title,
                textAlign:
                    widget.centerContent ? TextAlign.center : TextAlign.left,
                style: TextStyle(
                  color: widget.emphasizeTitle && widget.selected
                      ? AppColors.primary
                      : AppColors.textMain,
                  fontSize: titleSize,
                  height: 1.25,
                  fontWeight:
                      widget.emphasizeTitle ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  widget.subtitle!,
                  textAlign:
                      widget.centerContent ? TextAlign.center : TextAlign.left,
                  style: const TextStyle(
                      color: Color(0xFF475569), fontSize: 13, height: 1.35),
                ),
              ],
              if (widget.trailing != null) widget.trailing!,
              if (widget.extra != null) widget.extra!,
            ],
          ),
        ),
      ),
    );
  }
}

class _AiCharFadeText extends StatefulWidget {
  const _AiCharFadeText({
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
  State<_AiCharFadeText> createState() => _AiCharFadeTextState();
}

class _ThinkingWaveText extends StatefulWidget {
  const _ThinkingWaveText({
    required this.text,
    required this.style,
  });

  final String text;
  final TextStyle style;

  @override
  State<_ThinkingWaveText> createState() => _ThinkingWaveTextState();
}

class _ThinkingWaveTextState extends State<_ThinkingWaveText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = widget.style.copyWith(color: AppColors.textMuted);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Stack(
          children: [
            Text(
              widget.text,
              textAlign: TextAlign.left,
              style: baseStyle,
            ),
            ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (bounds) {
                final width = bounds.width;
                final shimmerWidth = width * 0.42;
                final travel = width + shimmerWidth * 2;
                final offsetX = -shimmerWidth + (travel * _controller.value);

                return LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.85),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.52, 1],
                ).createShader(
                  Rect.fromLTWH(
                    offsetX - shimmerWidth,
                    0,
                    shimmerWidth * 2,
                    bounds.height,
                  ),
                );
              },
              child: Text(
                widget.text,
                textAlign: TextAlign.left,
                style: baseStyle,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AiCharFadeTextState extends State<_AiCharFadeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _completionNotified = false;

  List<_MarkdownStyledChar> _chunks = const [];
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
  void didUpdateWidget(covariant _AiCharFadeText oldWidget) {
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
    final onCompleted = widget.onCompleted;
    if (onCompleted == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      onCompleted();
    });
  }

  void _restartCharFade() {
    _chunks = _buildStyledChars(widget.text);
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
      final styled = _markdownStyle(
        widget.style,
        _chunks[i].bold,
        _chunks[i].italic,
      );
      spans.add(
        TextSpan(
          text: _chunks[i].char,
          style: styled.copyWith(
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

class _MarkdownText extends StatelessWidget {
  const _MarkdownText({
    required this.text,
    required this.style,
  });

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final spans = _buildMarkdownTextSpans(text, style);
    return Text.rich(
      TextSpan(
        style: style,
        children: spans,
      ),
      textAlign: TextAlign.left,
    );
  }
}

class _MarkdownSegment {
  const _MarkdownSegment({
    required this.text,
    required this.bold,
    required this.italic,
  });

  final String text;
  final bool bold;
  final bool italic;
}

class _MarkdownStyledChar {
  const _MarkdownStyledChar({
    required this.char,
    required this.bold,
    required this.italic,
  });

  final String char;
  final bool bold;
  final bool italic;
}

TextStyle _markdownStyle(TextStyle base, bool bold, bool italic) {
  final baseWeight = base.fontWeight ?? FontWeight.w500;
  return base.copyWith(
    fontWeight: bold ? FontWeight.w700 : baseWeight,
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
  );
}

List<InlineSpan> _buildMarkdownTextSpans(String raw, TextStyle baseStyle) {
  final segments = _parseMarkdownSegments(raw);
  if (segments.isEmpty) {
    return <InlineSpan>[TextSpan(text: raw, style: baseStyle)];
  }
  return segments
      .where((segment) => segment.text.isNotEmpty)
      .map(
        (segment) => TextSpan(
          text: segment.text,
          style: _markdownStyle(baseStyle, segment.bold, segment.italic),
        ),
      )
      .toList(growable: false);
}

List<_MarkdownStyledChar> _buildStyledChars(String raw) {
  final segments = _parseMarkdownSegments(raw);
  if (segments.isEmpty) {
    return raw.runes
        .map(
          (rune) => _MarkdownStyledChar(
            char: String.fromCharCode(rune),
            bold: false,
            italic: false,
          ),
        )
        .toList(growable: false);
  }
  final chars = <_MarkdownStyledChar>[];
  for (final segment in segments) {
    for (final rune in segment.text.runes) {
      chars.add(
        _MarkdownStyledChar(
          char: String.fromCharCode(rune),
          bold: segment.bold,
          italic: segment.italic,
        ),
      );
    }
  }
  return chars;
}

List<_MarkdownSegment> _parseMarkdownSegments(String raw) {
  if (raw.isEmpty) return const [];

  final segments = <_MarkdownSegment>[];
  final buffer = StringBuffer();
  var bold = false;
  var italic = false;
  var i = 0;

  bool hasUnescaped(String marker, int from) {
    var cursor = raw.indexOf(marker, from);
    while (cursor != -1) {
      final escaped = cursor > 0 && raw.substring(cursor - 1, cursor) == r'\';
      if (!escaped) return true;
      cursor = raw.indexOf(marker, cursor + marker.length);
    }
    return false;
  }

  void flush() {
    if (buffer.isEmpty) return;
    segments.add(
      _MarkdownSegment(
        text: buffer.toString(),
        bold: bold,
        italic: italic,
      ),
    );
    buffer.clear();
  }

  while (i < raw.length) {
    final current = raw.substring(i, i + 1);
    if (current == r'\' && i + 1 < raw.length) {
      buffer.write(raw.substring(i + 1, i + 2));
      i += 2;
      continue;
    }

    if (raw.startsWith('**', i)) {
      if (bold) {
        // closing bold marker
        flush();
        bold = false;
        i += 2;
        continue;
      }
      if (hasUnescaped('**', i + 2)) {
        // opening bold marker (only when closing marker exists ahead)
        flush();
        bold = true;
        i += 2;
        continue;
      }
    }

    if (current == '*') {
      if (italic) {
        // closing italic marker
        flush();
        italic = false;
        i += 1;
        continue;
      }
      if (hasUnescaped('*', i + 1)) {
        // opening italic marker (only when closing marker exists ahead)
        flush();
        italic = true;
        i += 1;
        continue;
      }
    }

    buffer.write(current);
    i += 1;
  }

  flush();
  return segments;
}

class _PrimaryButton extends StatefulWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool compact;

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  void _setPressed(bool value) {
    if (!_enabled) return;
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.compact ? 52.0 : 60.0;
    final radius = widget.compact ? 16.0 : 20.0;
    final baseColor = _enabled ? AppColors.primary : const Color(0xFFE6EBF0);
    final pressedColor =
        _enabled ? AppColors.primaryDeep : const Color(0xFFE6EBF0);

    return SizedBox(
      width: double.infinity,
      height: height,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.987 : 1,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          child: AnimatedSlide(
            offset: _pressed ? const Offset(0, 0.02) : Offset.zero,
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                color: _pressed ? pressedColor : baseColor,
                boxShadow: _enabled
                    ? _pressed
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
                          ]
                    : const [],
              ),
              alignment: Alignment.center,
              child: Text(
                widget.label,
                style: TextStyle(
                  color: _enabled ? Colors.white : const Color(0xFF9CA3AF),
                  fontSize: widget.compact ? 18 : 22,
                  fontWeight: FontWeight.w700,
                  fontFamilyFallback: _kKrFontFallback,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatefulWidget {
  const _SecondaryButton({
    required this.label,
    required this.onPressed,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool compact;

  @override
  State<_SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<_SecondaryButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  void _setPressed(bool value) {
    if (!_enabled) return;
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.compact ? 48.0 : 54.0;
    final radius = widget.compact ? 14.0 : 16.0;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.99 : 1,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              color: _pressed ? const Color(0xFFF8FAFC) : Colors.white,
              border: Border.all(color: AppColors.borderStrong),
              boxShadow: _enabled
                  ? _pressed
                      ? const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ]
                      : const [
                          BoxShadow(
                            color: Color(0x1A234A64),
                            blurRadius: 2,
                            offset: Offset(0, 3),
                          ),
                        ]
                  : const [],
            ),
            alignment: Alignment.center,
            child: Text(
              widget.label,
              style: TextStyle(
                color: _enabled ? AppColors.textMuted : const Color(0xFFB7C1CD),
                fontSize: widget.compact ? 16.5 : 17,
                fontWeight: FontWeight.w700,
                fontFamilyFallback: _kKrFontFallback,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
