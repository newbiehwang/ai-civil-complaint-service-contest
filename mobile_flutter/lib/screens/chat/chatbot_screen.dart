import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
enum MiniInterfaceType {
  none,
  listPicker,
  optionList,
  summaryCard,
  pathChooser,
  noiseDiaryBuilder,
  draftViewer,
  draftConfirm,
  statusFeed,
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
      _aiText = text;
      _step = step;
      _miniType = miniType;
      _options = options;
      _selectedOptionIds.clear();
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

  Future<void> _pickIncidentDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _incidentDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      locale: const Locale('ko'),
    );
    if (picked == null) return;
    setState(() {
      _incidentDate = picked;
    });
  }

  Future<void> _pickIncidentTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _incidentTime ?? const TimeOfDay(hour: 14, minute: 30),
    );
    if (picked == null) return;
    setState(() {
      _incidentTime = picked;
    });
  }

  Future<void> _pickNoiseDiaryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _noiseDiaryDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      locale: const Locale('ko'),
    );
    if (picked == null) return;
    setState(() {
      _noiseDiaryDate = picked;
    });
  }

  Future<void> _pickNoiseDiaryTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _noiseDiaryTime ?? const TimeOfDay(hour: 22, minute: 10),
    );
    if (picked == null) return;
    setState(() {
      _noiseDiaryTime = picked;
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

  void _handleTextSend() {
    final input = _inputController.text.trim();
    if (input.isEmpty || _isThinking) return;

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
            miniType: MiniInterfaceType.listPicker,
            options: const [
              MiniOption(id: 'evidence-diary', label: '소음일지 작성'),
              MiniOption(id: 'evidence-skip', label: '증거 첨부 건너뛰기'),
            ],
          );
        });
        return;
      case DemoStep.evidence:
        if (selectedId == 'evidence-diary') {
          _noiseDiaryDate = null;
          _noiseDiaryTime = null;
          _noiseDiaryDuration = null;
          _noiseDiaryType = null;
          _noiseDiaryImpact = null;
          _setAi(
            text: '소음일지를 작성해 주세요.',
            step: DemoStep.noiseDiary,
            miniType: MiniInterfaceType.noiseDiaryBuilder,
          );
        } else {
          _showThinkingThen(_startDraftViewer);
        }
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

  bool get _isInputEnabled => _miniType == MiniInterfaceType.none;

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
                                key: ValueKey(_aiText),
                                alignment: Alignment.topLeft,
                                child: _AiCharFadeText(
                                  text: _aiText,
                                  charStep: const Duration(milliseconds: 40),
                                  fadeDuration: const Duration(milliseconds: 180),
                                  style: aiTextStyle,
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
                  if (_miniType != MiniInterfaceType.none)
                    Positioned(
                      left: 22,
                      right: 22,
                      bottom: 92,
                      child: _MiniInterfaceCard(
                        child: _buildMiniInterface(context),
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
                      enabled: _isInputEnabled && !_isThinking,
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
    if (_isThinking) return false;
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
        return _OptionListWidget(
          dateLabel: _incidentDate == null ? '선택해 주세요' : _formatDate(_incidentDate!),
          timeLabel: _incidentTime == null ? '선택해 주세요' : _formatTime(_incidentTime!),
          onPickDate: _pickIncidentDate,
          onPickTime: _pickIncidentTime,
          onSubmit: _submitIncidentDateTime,
          canSubmit: _incidentDate != null && _incidentTime != null,
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
              miniType: MiniInterfaceType.listPicker,
              options: const [
                MiniOption(id: 'evidence-diary', label: '소음일지 작성'),
                MiniOption(id: 'evidence-skip', label: '증거 첨부 건너뛰기'),
              ],
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
          onPickDate: _pickNoiseDiaryDate,
          onPickTime: _pickNoiseDiaryTime,
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
              miniType: MiniInterfaceType.listPicker,
              options: const [
                MiniOption(id: 'evidence-diary', label: '소음일지 작성'),
                MiniOption(id: 'evidence-skip', label: '증거 첨부 건너뛰기'),
              ],
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
  const _MiniInterfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 510),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: child,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '단일 선택',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ...options.map(
          (option) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SelectableCardButton(
              selected: selectedIds.contains(option.id),
              title: option.label,
              onTap: () => onTapOption(option.id),
            ),
          ),
        ),
      ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '날짜 및 시간 선택',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
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
        _PrimaryButton(
          label: '정보 확인 및 제출',
          onPressed: canSubmit ? onSubmit : null,
          compact: true,
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
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.blueTint,
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.textMain,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '요약 확인',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 7),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rows[i].label,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            rows[i].value,
                            style: const TextStyle(
                              color: AppColors.textMain,
                              fontSize: 18,
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
                    padding: EdgeInsets.fromLTRB(18, 12, 0, 12),
                    child: Divider(height: 1, color: AppColors.border),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        _PrimaryButton(label: '계속하기', onPressed: onContinue, compact: true),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: onEdit,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            side: const BorderSide(color: AppColors.borderStrong),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text(
            '수정',
            style: TextStyle(color: AppColors.textMuted, fontSize: 18, fontWeight: FontWeight.w700),
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
  });

  final String text;
  final TextStyle style;
  final Duration charStep;
  final Duration fadeDuration;

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
      });
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
    _controller.dispose();
    super.dispose();
  }

  List<String> _splitCharChunks(String text) {
    return text.runes.map(String.fromCharCode).toList(growable: false);
  }

  void _restartCharFade() {
    _chunks = _splitCharChunks(widget.text);
    final stepMs = widget.charStep.inMilliseconds;
    final fadeMs = widget.fadeDuration.inMilliseconds;
    _totalMs = _chunks.isEmpty ? 0 : ((_chunks.length - 1) * stepMs) + fadeMs;
    _controller.stop();
    _controller.value = 0;
    if (_totalMs <= 0) return;
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
