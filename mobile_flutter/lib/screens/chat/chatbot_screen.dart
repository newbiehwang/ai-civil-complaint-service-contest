import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
enum MiniInterfaceType {
  none,
  listPicker,
  optionList,
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
  timeBand,
  dateTime,
  summary,
  pathChooser,
  pathAlternative,
  evidence,
  noiseDiary,
  draftViewer,
  waitingRevision,
  draftConfirm,
  statusFeed,
  complete,
}

const List<String> _kKrFontFallback = <String>[
  'Pretendard',
  'Apple SD Gothic Neo',
  'Noto Sans KR',
];

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
    this.timeBand,
    this.route,
    this.startedAtDate,
    this.startedAtTime,
    this.revisionNote,
  });

  final String? userIssue;
  final String? noiseNow;
  final String? safety;
  final String? residence;
  final String? timeBand;
  final String? route;
  final DateTime? startedAtDate;
  final TimeOfDay? startedAtTime;
  final String? revisionNote;

  DemoFlowData copyWith({
    String? userIssue,
    String? noiseNow,
    String? safety,
    String? residence,
    String? timeBand,
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
      timeBand: timeBand ?? this.timeBand,
      route: route ?? this.route,
      startedAtDate: startedAtDate ?? this.startedAtDate,
      startedAtTime: startedAtTime ?? this.startedAtTime,
      revisionNote: revisionNote ?? this.revisionNote,
    );
  }
}

class ChatbotDemoScreen extends StatefulWidget {
  const ChatbotDemoScreen({required this.onRestart, super.key});

  final VoidCallback onRestart;

  @override
  State<ChatbotDemoScreen> createState() => _ChatbotDemoScreenState();
}

class _ChatbotDemoScreenState extends State<ChatbotDemoScreen> {
  static const _durations = ['10분 미만', '10~30분', '30분 이상', '모름'];
  static const _noiseTypes = ['쿵쿵', '음악', '가구 끄는 소리', '기타'];
  static const _impacts = ['수면 방해', '업무 방해', '불안', '기타'];

  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isThinking = false;
  bool _isAiAnswerReady = false;
  int _aiAnimationNonce = 0;
  String _aiText = '안녕하세요. 어떤 소음이 가장\n불편하신가요?';
  DemoStep _step = DemoStep.waitingIssue;
  MiniInterfaceType _miniType = MiniInterfaceType.none;
  List<MiniOption> _options = const [];
  final Set<String> _selectedOptionIds = {};
  DemoFlowData _data = const DemoFlowData();

  DateTime? _incidentDate;
  TimeOfDay? _incidentTime;
  DateTime? _noiseDiaryDate;
  TimeOfDay? _noiseDiaryTime;
  String? _noiseDiaryDuration;
  String? _noiseDiaryType;
  String? _noiseDiaryImpact;
  final Set<String> _evidenceAttachmentIds = <String>{};
  _PickerOwner _pickerOwner = _PickerOwner.incident;
  DateTime _pickerMonth = DateTime.now();
  DateTime? _pickerDateSelection;
  bool _pickerIsAm = true;
  int _pickerHour12 = 1;
  int _pickerMinute = 0;

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_handleInputControllerChanged);
  }

  void _handleInputControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _inputController.removeListener(_handleInputControllerChanged);
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _showThinkingThen(
    VoidCallback done, {
    Duration duration = const Duration(milliseconds: 560),
  }) async {
    FocusScope.of(context).unfocus();
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
  }) {
    if (miniType != MiniInterfaceType.none) {
      FocusScope.of(context).unfocus();
    }
    setState(() {
      _aiAnimationNonce += 1;
      _isAiAnswerReady = false;
      _aiText = text;
      _step = step;
      _miniType = miniType;
      _options = options;
      _selectedOptionIds.clear();
      if (step == DemoStep.evidence) {
        _evidenceAttachmentIds.clear();
      }
    });
  }

  void _handleAiTextAnimationCompleted() {
    if (!mounted || _isThinking || _isAiAnswerReady) return;
    setState(() {
      _isAiAnswerReady = true;
    });
  }

  String _formatDate(DateTime date) {
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    return '${date.year}년 ${date.month}월 ${date.day}일 (${weekdays[date.weekday % 7]})';
  }

  String _formatTime(TimeOfDay time) {
    final meridiem = time.hour < 12 ? '오전' : '오후';
    final hour12 = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    return '$meridiem ${hour12.toString().padLeft(2, '0')}시 ${time.minute.toString().padLeft(2, '0')}분';
  }

  bool get _isNoiseDiaryReady {
    return _noiseDiaryDate != null &&
        _noiseDiaryTime != null &&
        _noiseDiaryDuration != null &&
        _noiseDiaryType != null &&
        _noiseDiaryImpact != null;
  }

  void _openIncidentDatePicker() => _openDatePicker(_PickerOwner.incident);
  void _openIncidentTimePicker() => _openTimePicker(_PickerOwner.incident);
  void _openNoiseDiaryDatePicker() => _openDatePicker(_PickerOwner.noiseDiary);
  void _openNoiseDiaryTimePicker() => _openTimePicker(_PickerOwner.noiseDiary);

  void _openDatePicker(_PickerOwner owner) {
    final now = DateTime.now();
    final selected = owner == _PickerOwner.noiseDiary ? _noiseDiaryDate : _incidentDate;
    final seed = selected ?? now;
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
      _pickerMonth = DateTime(_pickerMonth.year, _pickerMonth.month + delta, 1);
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
          : MiniInterfaceType.optionList;
    });
  }

  void _confirmDatePicker() {
    final selected = _pickerDateSelection;
    if (selected == null) return;
    setState(() {
      if (_pickerOwner == _PickerOwner.noiseDiary) {
        _noiseDiaryDate = selected;
        _miniType = MiniInterfaceType.noiseDiaryBuilder;
      } else {
        _incidentDate = selected;
        _miniType = MiniInterfaceType.optionList;
      }
    });
  }

  void _confirmTimePicker() {
    final hour24 = _pickerIsAm
        ? (_pickerHour12 % 12)
        : ((_pickerHour12 % 12) + 12);
    final selected = TimeOfDay(hour: hour24, minute: _pickerMinute);
    setState(() {
      if (_pickerOwner == _PickerOwner.noiseDiary) {
        _noiseDiaryTime = selected;
        _miniType = MiniInterfaceType.noiseDiaryBuilder;
      } else {
        _incidentTime = selected;
        _miniType = MiniInterfaceType.optionList;
      }
    });
  }

  void _submitIncidentDateTime() {
    if (_incidentDate == null || _incidentTime == null) return;

    _data = _data.copyWith(
      startedAtDate: _incidentDate,
      startedAtTime: _incidentTime,
    );

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
      text: '접수 완료! 이제부터 진행을 끝까지 추적해 드릴게요.',
      step: DemoStep.statusFeed,
      miniType: MiniInterfaceType.statusFeed,
      options: const [
        MiniOption(id: 'status-upload', label: '추가 증거 업로드'),
        MiniOption(id: 'status-summary', label: '케이스 요약 보기'),
      ],
    );
  }

  void _toggleEvidenceAttachment(String id) {
    setState(() {
      if (_evidenceAttachmentIds.contains(id)) {
        _evidenceAttachmentIds.remove(id);
      } else {
        _evidenceAttachmentIds.add(id);
      }
    });
  }

  void _submitEvidenceAttachments() {
    if (_evidenceAttachmentIds.isEmpty) return;
    _showThinkingThen(_startDraftViewer);
  }

  void _skipEvidenceAttachments() {
    setState(() {
      _evidenceAttachmentIds.clear();
    });
    _showThinkingThen(_startDraftViewer);
  }

  void _handleTextSend() {
    final input = _inputController.text.trim();
    if (input.isEmpty || !_isUiReadyAfterAi) return;

    _inputController.clear();

    if (_step == DemoStep.waitingIssue) {
      _data = _data.copyWith(userIssue: input);
      final thinkingDuration = input == '1'
          ? const Duration(seconds: 3)
          : const Duration(milliseconds: 560);
      _showThinkingThen(() {
        _setAi(
          text: '윗집 소음 때문에 많이 힘드시겠어요.\n지금도 소음이 계속되나요?',
          step: DemoStep.noiseNow,
          miniType: MiniInterfaceType.listPicker,
          options: const [
            MiniOption(id: 'noise-now-active', label: '지금 진행 중'),
            MiniOption(id: 'noise-now-recent', label: '방금 멈춤'),
            MiniOption(id: 'noise-now-repeat', label: '자주 반복'),
          ],
        );
      }, duration: thinkingDuration);
      return;
    }

    if (_step == DemoStep.waitingRevision) {
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

    switch (_step) {
      case DemoStep.noiseNow:
        _data = _data.copyWith(
          noiseNow: _options.firstWhere((e) => e.id == selectedId).label,
        );
        _showThinkingThen(() {
          _setAi(
            text: '좋아요. 안전 문제가 아닌지 10초만 확인할게요.',
            step: DemoStep.safety,
            miniType: MiniInterfaceType.listPicker,
            options: const [
              MiniOption(id: 'safety-normal', label: '없음(생활소음)'),
              MiniOption(id: 'safety-danger', label: '있음(위험)'),
              MiniOption(id: 'safety-unknown', label: '잘 모르겠음'),
            ],
          );
        });
        return;
      case DemoStep.safety:
        _data = _data.copyWith(
          safety: _options.firstWhere((e) => e.id == selectedId).label,
        );
        _showThinkingThen(() {
          _setAi(
            text: '정식 접수를 위해 기본 정보 3가지만 확인할게요.\n거주 형태를 선택해 주세요.',
            step: DemoStep.residence,
            miniType: MiniInterfaceType.listPicker,
            options: const [
              MiniOption(id: 'residence-apartment', label: '아파트'),
              MiniOption(id: 'residence-villa', label: '빌라'),
              MiniOption(id: 'residence-officetel', label: '오피스텔'),
              MiniOption(id: 'residence-other', label: '기타'),
            ],
          );
        });
        return;
      case DemoStep.residence:
        _data = _data.copyWith(
          residence: _options.firstWhere((e) => e.id == selectedId).label,
        );
        _showThinkingThen(() {
          _setAi(
            text: '소음이 주로 발생하는 시간대를 선택해 주세요.',
            step: DemoStep.timeBand,
            miniType: MiniInterfaceType.listPicker,
            options: const [
              MiniOption(id: 'time-evening', label: '저녁'),
              MiniOption(id: 'time-night', label: '심야'),
              MiniOption(id: 'time-dawn', label: '새벽'),
              MiniOption(id: 'time-irregular', label: '불규칙'),
            ],
          );
        });
        return;
      case DemoStep.timeBand:
        _data = _data.copyWith(
          timeBand: _options.firstWhere((e) => e.id == selectedId).label,
        );
        _incidentDate = null;
        _incidentTime = null;
        _setAi(
          text: '마지막으로 소음 발생 날짜와 시간을 선택해 주세요.',
          step: DemoStep.dateTime,
          miniType: MiniInterfaceType.optionList,
        );
        return;
      case DemoStep.pathAlternative:
        _data = _data.copyWith(
          route: _options.firstWhere((e) => e.id == selectedId).label,
        );
        _showThinkingThen(() {
          _setAi(
            text: '선택한 경로로 진행할게요. 증거 체크리스트에서 필요한 항목만 첨부해 주세요.',
            step: DemoStep.evidence,
            miniType: MiniInterfaceType.optionList,
          );
        });
        return;
      case DemoStep.complete:
        if (selectedId == 'complete-restart') {
          widget.onRestart();
        }
        return;
      default:
        return;
    }
  }

  bool get _isUiReadyAfterAi => !_isThinking && _isAiAnswerReady;
  bool get _isInputEnabled => _miniType == MiniInterfaceType.none;
  bool get _shouldShowMiniInterface =>
      _miniType != MiniInterfaceType.none && _isUiReadyAfterAi;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final aiFontSize = width < 390 ? 24.0 : 26.0;
    final aiTextStyle = TextStyle(
      color: AppColors.primary,
      fontSize: aiFontSize,
      height: 1.36,
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
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        child: _isThinking
                            ? Align(
                                key: const ValueKey('thinking'),
                                alignment: Alignment.topLeft,
                                child: _ThinkingWaveText(
                                  text: '답변을 준비하고 있어요.',
                                  style: aiTextStyle,
                                ),
                              )
                            : Align(
                                key: ValueKey('ai-text-$_aiAnimationNonce'),
                                alignment: Alignment.topLeft,
                                child: _AiCharFadeText(
                                  text: _aiText,
                                  charStep: const Duration(milliseconds: 40),
                                  fadeDuration: const Duration(milliseconds: 180),
                                  style: aiTextStyle,
                                  onCompleted: _handleAiTextAnimationCompleted,
                                ),
                              ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    right: 18,
                    top: 16,
                    child: _ChatTopBar(onRestart: widget.onRestart),
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
    if (_miniType == MiniInterfaceType.none) return _inputController.text.trim().isNotEmpty;
    return _miniType == MiniInterfaceType.listPicker && _selectedOptionIds.isNotEmpty;
  }

  void _handleSendPressed() {
    if (_miniType == MiniInterfaceType.listPicker) {
      _handleListSelectionSubmit();
      return;
    }
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
              _selectedOptionIds
                ..clear()
                ..add(id);
            });
          },
        );
      case MiniInterfaceType.optionList:
        if (_step == DemoStep.evidence) {
          return _EvidenceOptionListWidget(
            selectedAttachmentIds: _evidenceAttachmentIds,
            onToggleAttachment: _toggleEvidenceAttachment,
            onSubmit: _submitEvidenceAttachments,
            onSkip: _skipEvidenceAttachments,
            canSubmit: _evidenceAttachmentIds.isNotEmpty,
          );
        }
        return _OptionListWidget(
          dateLabel: _incidentDate == null ? '선택해 주세요' : _formatDate(_incidentDate!),
          timeLabel: _incidentTime == null ? '선택해 주세요' : _formatTime(_incidentTime!),
          onPickDate: _openIncidentDatePicker,
          onPickTime: _openIncidentTimePicker,
          onSubmit: _submitIncidentDateTime,
          canSubmit: _incidentDate != null && _incidentTime != null,
        );
      case MiniInterfaceType.datePicker:
        return _MiniDatePickerWidget(
          month: _pickerMonth,
          selectedDate: _pickerDateSelection,
          onPickDate: _selectPickerDate,
          onPrevMonth: () => _movePickerMonth(-1),
          onNextMonth: () => _movePickerMonth(1),
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
              hour: _pickerIsAm ? (_pickerHour12 % 12) : ((_pickerHour12 % 12) + 12),
              minute: _pickerMinute,
            ),
          ),
        );
      case MiniInterfaceType.summaryCard:
        return _SummaryCardWidget(
          rows: [
            _SummaryRow(label: '거주 형태', value: _data.residence ?? '미입력'),
            _SummaryRow(label: '주 발생 시간', value: _data.timeBand ?? '미입력'),
            _SummaryRow(
              label: '시작 시점',
              value: _data.startedAtDate != null && _data.startedAtTime != null
                  ? '${_formatDate(_data.startedAtDate!)} ${_formatTime(_data.startedAtTime!)}'
                  : '미입력',
            ),
            _SummaryRow(label: '현재 상태', value: _data.noiseNow ?? '미입력'),
          ],
          onContinue: () {
            _setAi(
              text: '추천 경로를 준비했어요.\n진행 방식을 선택해 주세요.',
              step: DemoStep.pathChooser,
              miniType: MiniInterfaceType.pathChooser,
            );
          },
          onEdit: () {
            _setAi(
              text: '수정할 정보를 다시 선택해 주세요.\n거주 형태부터 진행할게요.',
              step: DemoStep.residence,
              miniType: MiniInterfaceType.listPicker,
              options: const [
                MiniOption(id: 'residence-apartment', label: '아파트'),
                MiniOption(id: 'residence-villa', label: '빌라'),
                MiniOption(id: 'residence-officetel', label: '오피스텔'),
                MiniOption(id: 'residence-other', label: '기타'),
              ],
            );
          },
        );
      case MiniInterfaceType.pathChooser:
        return _PathChooserWidget(
          onSelectRecommended: () {
            _data = _data.copyWith(route: '이웃사이센터 조정 신청');
            _setAi(
              text: '경로를 확정했어요.\n증거 체크리스트에서 필요한 항목만 첨부해 주세요.',
              step: DemoStep.evidence,
              miniType: MiniInterfaceType.optionList,
            );
          },
          onSelectAlternative: () {
            _setAi(
              text: '원하시는 기관을 선택해 주세요.',
              step: DemoStep.pathAlternative,
              miniType: MiniInterfaceType.listPicker,
              options: const [
                MiniOption(id: 'path-epeople', label: '국민신문고'),
                MiniOption(id: 'path-management', label: '관리사무소 공식 민원'),
                MiniOption(id: 'path-dispute', label: '분쟁조정(후순위)'),
              ],
            );
          },
        );
      case MiniInterfaceType.noiseDiaryBuilder:
        return _NoiseDiaryBuilderWidget(
          dateLabel: _noiseDiaryDate == null ? '선택해 주세요' : _formatDate(_noiseDiaryDate!),
          timeLabel: _noiseDiaryTime == null ? '선택해 주세요' : _formatTime(_noiseDiaryTime!),
          onPickDate: _openNoiseDiaryDatePicker,
          onPickTime: _openNoiseDiaryTimePicker,
          selectedDuration: _noiseDiaryDuration,
          selectedType: _noiseDiaryType,
          selectedImpact: _noiseDiaryImpact,
          onSelectDuration: (value) => setState(() => _noiseDiaryDuration = value),
          onSelectType: (value) => setState(() => _noiseDiaryType = value),
          onSelectImpact: (value) => setState(() => _noiseDiaryImpact = value),
          durations: _durations,
          noiseTypes: _noiseTypes,
          impacts: _impacts,
          canSubmit: _isNoiseDiaryReady,
          onSubmit: () {
            _showThinkingThen(_startDraftViewer);
          },
        );
      case MiniInterfaceType.draftViewer:
        return _DraftViewerWidget(
          previewLines: _buildDraftPreviewLines(),
          guidePoints: _buildDraftGuidePoints(),
          onApprove: _goStatusFeed,
          onEdit: () {
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
          onApprove: _goStatusFeed,
          onEditAgain: () {
            _setAi(
              text: '수정할 내용을 다시 입력해 주세요.',
              step: DemoStep.waitingRevision,
              miniType: MiniInterfaceType.none,
            );
          },
        );
      case MiniInterfaceType.statusFeed:
        return _StatusFeedWidget(
          onUploadMore: () {
            _setAi(
              text: '추가 증거를 선택해 주세요.',
              step: DemoStep.evidence,
              miniType: MiniInterfaceType.optionList,
            );
          },
          onOpenSummary: () {
            _setAi(
              text: '종결 요약입니다.\n처음으로 돌아가 새 케이스를 시작할 수 있어요.',
              step: DemoStep.complete,
              miniType: MiniInterfaceType.listPicker,
              options: const [MiniOption(id: 'complete-restart', label: '처음으로 돌아가기')],
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
      '주 발생 시간: ${_data.timeBand ?? '미입력'}',
      '시작 시점: ${_data.startedAtDate != null && _data.startedAtTime != null ? '${_formatDate(_data.startedAtDate!)} ${_formatTime(_data.startedAtTime!)}' : '미입력'}',
      '현재 상태: ${_data.noiseNow ?? '미입력'}',
      '추천 경로: ${_data.route ?? '미선택'}',
    ];

    if (_isNoiseDiaryReady) {
      lines.add('소음일지: ${_formatDate(_noiseDiaryDate!)} ${_formatTime(_noiseDiaryTime!)} · $_noiseDiaryDuration · $_noiseDiaryType · $_noiseDiaryImpact');
    }
    if (_evidenceAttachmentIds.isNotEmpty) {
      final labels = <String>[];
      if (_evidenceAttachmentIds.contains('evidence-audio')) labels.add('녹음 파일');
      if (_evidenceAttachmentIds.contains('evidence-video')) labels.add('동영상');
      if (labels.isNotEmpty) {
        lines.add('첨부 파일: ${labels.join(', ')}');
      }
    }

    return lines;
  }

  List<String> _buildDraftGuidePoints() {
    return [
      '사실 중심 문장으로 정리돼 기관 검토가 쉬워요.',
      '날짜/시간/유형이 포함되어 처리 누락을 줄여요.',
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
  const _ChatTopBar({required this.onRestart});

  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _BackIconButton(onPressed: onRestart),
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
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 520),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18305A78),
            blurRadius: 22,
            offset: Offset(0, 9),
          ),
          BoxShadow(
            color: Color(0x0C305A78),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 15, 18, 15),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: child,
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
              decoration: InputDecoration.collapsed(
                hintText: placeholder,
                hintStyle: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
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
                color: sendEnabled ? AppColors.primary : const Color(0xFFCFE0EC),
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListPickerWidget extends StatelessWidget {
  const _ListPickerWidget({
    required this.options,
    required this.selectedIds,
    required this.onTapOption,
  });

  final List<MiniOption> options;
  final Set<String> selectedIds;
  final ValueChanged<String> onTapOption;

  @override
  Widget build(BuildContext context) {
    const maxVisibleOptions = 5;
    const optionHeight = 58.0;
    const optionGap = 12.0;
    const maxOptionsHeight =
        (optionHeight * maxVisibleOptions) + (optionGap * (maxVisibleOptions - 1));
    final optionsColumn = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < options.length; i++) ...[
          Padding(
            padding: EdgeInsets.only(bottom: i == options.length - 1 ? 0 : optionGap),
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
        const Text(
          '단일 선택',
          style: TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 12,
            height: 16 / 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        if (options.length > maxVisibleOptions)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: maxOptionsHeight),
            child: SingleChildScrollView(child: optionsColumn),
          )
        else
          optionsColumn,
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
  State<_ListPickerOptionButton> createState() => _ListPickerOptionButtonState();
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
          ),
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
        const Text(
          '날짜 및 시간 선택',
          style: TextStyle(
            color: Color(0xFF8B99AC),
            fontSize: 13,
            height: 18 / 13,
            fontWeight: FontWeight.w600,
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
    required this.onToggleAttachment,
    required this.onSubmit,
    required this.onSkip,
    required this.canSubmit,
  });

  final Set<String> selectedAttachmentIds;
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
          '체크리스트 · 선택사항',
          style: TextStyle(
            color: Color(0xFF8B99AC),
            fontSize: 13,
            height: 18 / 13,
            fontWeight: FontWeight.w600,
            fontFamilyFallback: _kKrFontFallback,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '필요한 항목만 첨부해 주세요.',
          style: TextStyle(
            color: Color(0xFF9CA3AF),
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
                value: isAudioSelected ? '선택됨' : '음성 파일 첨부',
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
                value: isVideoSelected ? '선택됨' : '영상 파일 첨부',
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
        OutlinedButton(
          onPressed: onSkip,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            side: const BorderSide(color: AppColors.borderStrong),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text(
            '건너뛰기',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
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
                color: selected ? const Color(0xFFEAF3FF) : const Color(0xFFF4F8FC),
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
              selected ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
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
    required this.onBack,
    required this.onConfirm,
    required this.selectedDateLabel,
  });

  final DateTime month;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onPickDate;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onBack;
  final VoidCallback onConfirm;
  final String selectedDateLabel;

  @override
  Widget build(BuildContext context) {
    final days = _calendarDays(month);
    const weekdayLabels = ['일', '월', '화', '수', '목', '금', '토'];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '날짜 선택',
          style: TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 12,
            height: 16 / 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
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
                child: Text(
                  '${month.year}년 ${month.month}월',
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    fontFamilyFallback: _kKrFontFallback,
                  ),
                ),
              ),
            ),
            _MiniIconCircleButton(
              icon: Icons.chevron_right_rounded,
              onTap: onNextMonth,
            ),
          ],
        ),
        const SizedBox(height: 8),
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
            final selected = selectedDate != null &&
                day.year == selectedDate!.year &&
                day.month == selectedDate!.month &&
                day.day == selectedDate!.day;

            return InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => onPickDate(day),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 27,
                  height: 27,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : inMonth
                              ? AppColors.textMain
                              : const Color(0xFFCBD5E1),
                      fontSize: 12.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      fontFamilyFallback: _kKrFontFallback,
                    ),
                  ),
                ),
              ),
            );
          },
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

  @override
  void initState() {
    super.initState();
    _hourController = FixedExtentScrollController(
      initialItem: (widget.hour12 - 1) + (12 * 200),
    );
    _minuteController = FixedExtentScrollController(
      initialItem: widget.minute + (60 * 100),
    );
  }

  @override
  void didUpdateWidget(covariant _MiniTimePickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hour12 != widget.hour12) {
      _hourController.jumpToItem((widget.hour12 - 1) + (12 * 200));
    }
    if (oldWidget.minute != widget.minute) {
      _minuteController.jumpToItem(widget.minute + (60 * 100));
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
        const Text(
          '시간 선택',
          style: TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 12,
            height: 16 / 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        _MiniBackButton(onTap: widget.onBack),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MeridiemToggleButton(
                label: '오전',
                selected: widget.isAm,
                onTap: () => widget.onSelectMeridiem(true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MeridiemToggleButton(
                label: '오후',
                selected: !widget.isAm,
                onTap: () => widget.onSelectMeridiem(false),
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
                      onIndexChanged: (index) => widget.onSelectHour((index % 12) + 1),
                      itemBuilder: (index) {
                        final hour = (index % 12) + 1;
                        return _wheelText(
                          hour.toString().padLeft(2, '0'),
                          selected: hour == widget.hour12,
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: _MiniWheelPicker(
                      controller: _minuteController,
                      itemExtent: 36,
                      onIndexChanged: (index) => widget.onSelectMinute(index % 60),
                      itemBuilder: (index) {
                        final minute = index % 60;
                        return _wheelText(
                          minute.toString().padLeft(2, '0'),
                          selected: minute == widget.minute,
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
          summaryValue: widget.selectedTimeLabel,
          actionLabel: '시간 선택 완료',
          onPressed: widget.onConfirm,
        ),
      ],
    );
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
        scale: _pressed ? 0.985 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.selected ? const Color(0xFFF0F7FF) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.selected ? AppColors.primary : AppColors.border,
              width: widget.selected ? 1.4 : 1,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.selected ? AppColors.primary : AppColors.textMuted,
              fontSize: widget.selected ? 16 : 15,
              fontWeight: widget.selected ? FontWeight.w800 : FontWeight.w600,
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
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
      label: const Text('이전 단계'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 34),
        padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
        side: const BorderSide(color: AppColors.border),
        foregroundColor: AppColors.textMuted,
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }
}

class _MiniIconCircleButton extends StatelessWidget {
  const _MiniIconCircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
          side: const BorderSide(color: AppColors.border),
          foregroundColor: AppColors.textMuted,
        ),
        child: Icon(icon, size: 19),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '요약 확인',
          style: TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 12,
            height: 16 / 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 250),
          child: SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rows[i].label,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                rows[i].value,
                                style: const TextStyle(
                                  color: AppColors.textMain,
                                  fontSize: 16,
                                  height: 1.35,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (i < rows.length - 1)
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 10, 0, 10),
                        child: Divider(height: 1, color: AppColors.border),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 9),
        _PrimaryButton(label: '계속하기', onPressed: onContinue, compact: true),
        const SizedBox(height: 7),
        OutlinedButton(
          onPressed: onEdit,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            side: const BorderSide(color: AppColors.borderStrong),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text(
            '수정',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _PathChooserWidget extends StatefulWidget {
  const _PathChooserWidget({
    required this.onSelectRecommended,
    required this.onSelectAlternative,
  });

  final VoidCallback onSelectRecommended;
  final VoidCallback onSelectAlternative;

  @override
  State<_PathChooserWidget> createState() => _PathChooserWidgetState();
}

class _PathChooserWidgetState extends State<_PathChooserWidget> {
  bool _openReason = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '단일 선택',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        _SelectableCardButton(
          selected: false,
          title: '이웃사이센터 조정 신청',
          subtitle: '층간소음 상담/조정 절차에 가장 빠르게 연결돼요.',
          leadingBadge: '추천',
          onTap: widget.onSelectRecommended,
          trailing: TextButton(
            onPressed: () => setState(() => _openReason = !_openReason),
            child: Text(_openReason ? '추천 이유 접기' : '추천 이유 보기'),
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
        const SizedBox(height: 10),
        _SelectableCardButton(
          selected: false,
          title: '다른 기관 선택',
          onTap: widget.onSelectAlternative,
        ),
      ],
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
          child: Text('• ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Color(0xFF475569), fontSize: 12.5, height: 1.35),
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
          style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w700),
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
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5, fontWeight: FontWeight.w700),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
        const Text('신청서 초안', style: TextStyle(color: AppColors.textMain, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 360),
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
                      const Text('수정 포인트', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      ...guidePoints.map(
                        (point) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('• $point', style: const TextStyle(color: Color(0xFF475569), fontSize: 12.5, height: 1.35)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _PrimaryButton(label: '좋아요, 접수', onPressed: onApprove, compact: true),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: onEdit,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    side: const BorderSide(color: AppColors.borderStrong),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('수정 요청', style: TextStyle(color: AppColors.textMuted, fontSize: 18, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
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
        const Text('수정 반영 확인', style: TextStyle(color: AppColors.textMain, fontSize: 18, fontWeight: FontWeight.w700)),
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
                              ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
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
                              color: highlightIndexes.contains(i) ? const Color(0xFF1D4ED8) : const Color(0xFF334155),
                              fontSize: 13,
                              height: 1.42,
                              fontWeight: highlightIndexes.contains(i) ? FontWeight.w700 : FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _PrimaryButton(label: '좋아요, 접수해주세요', onPressed: onApprove, compact: true),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: onEditAgain,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    side: const BorderSide(color: AppColors.borderStrong),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('다시 수정', style: TextStyle(color: AppColors.textMuted, fontSize: 18, fontWeight: FontWeight.w700)),
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
                  style: const TextStyle(color: Color(0xFF334155), fontSize: 13, fontWeight: FontWeight.w600, height: 1.4),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _StatusFeedWidget extends StatelessWidget {
  const _StatusFeedWidget({
    required this.onUploadMore,
    required this.onOpenSummary,
  });

  final VoidCallback onUploadMore;
  final VoidCallback onOpenSummary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('진행 상태', style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FeedLine(icon: '✅', title: '접수 완료', subtitle: '접수번호 DEMO-24001'),
              SizedBox(height: 8),
              _FeedLine(icon: '⏳', title: '기관 확인 중', subtitle: '담당부서 검토 진행중'),
              SizedBox(height: 8),
              _FeedLine(icon: '⏳', title: '담당자 배정', subtitle: '배정 시 알림 예정'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _SelectableCardButton(title: '추가 증거 업로드', selected: false, onTap: onUploadMore),
        const SizedBox(height: 8),
        _SelectableCardButton(title: '케이스 요약 보기', selected: false, onTap: onOpenSummary),
      ],
    );
  }
}

class _FeedLine extends StatelessWidget {
  const _FeedLine({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final String icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textMain, fontSize: 14, fontWeight: FontWeight.w700)),
              Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12.5, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}

class _SelectableCardButton extends StatelessWidget {
  const _SelectableCardButton({
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.leadingBadge,
    this.trailing,
    this.extra,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;
  final String? subtitle;
  final String? leadingBadge;
  final Widget? trailing;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: selected ? AppColors.blueTint : Colors.white,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (leadingBadge != null)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.blueTint,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  leadingBadge!,
                  style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            Text(
              title,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.textMain,
                fontSize: 18,
                height: 1.25,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: const TextStyle(color: Color(0xFF475569), fontSize: 13, height: 1.35),
              ),
            ],
            if (trailing != null) trailing!,
            if (extra != null) extra!,
          ],
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

  List<String> _chunks = const [];
  int _totalMs = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.fadeDuration,
    )..addListener(() {
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

  List<String> _splitCharChunks(String text) {
    return text.runes.map(String.fromCharCode).toList(growable: false);
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
    _chunks = _splitCharChunks(widget.text);
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
      spans.add(
        TextSpan(
          text: _chunks[i],
          style: widget.style.copyWith(
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

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: compact ? 52 : 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          foregroundColor: Colors.white,
          backgroundColor: onPressed == null ? const Color(0xFFE6EBF0) : AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: TextStyle(
            fontSize: compact ? 18 : 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}
