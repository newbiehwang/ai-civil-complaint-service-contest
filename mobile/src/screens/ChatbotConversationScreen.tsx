import { ReactNode, useCallback, useEffect, useMemo, useRef, useState } from "react";
import {
  Animated,
  Easing,
  Keyboard,
  KeyboardEvent,
  NativeScrollEvent,
  NativeSyntheticEvent,
  Platform,
  Pressable,
  ScrollView,
  StyleProp,
  StyleSheet,
  Text,
  TextStyle,
  TextInput,
  useWindowDimensions,
  View,
  ViewStyle,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { TypewriterText } from "../components/TypewriterText";
import { apiClient } from "../services/apiClient";
import { toKoreanErrorMessage } from "../services/errorMap";
import { useCaseContext } from "../store/caseContext";
import type {
  CaseStatus,
  CreateCaseRequest,
  FollowUpInterface,
  IntakeUpdateResponse,
  RoutingRecommendation,
  SubmitCaseRequest,
  TimelineEvent,
} from "../types/api";

const BASE_WIDTH = 390;
const BASE_HEIGHT = 884;
const KEYBOARD_GAP = 12;

type ResponseInputMode = "text" | "mini";
type MiniSelectionMode = "single" | "multiple";
type MiniInterfaceContext =
  | "intake"
  | "routing"
  | "optionList"
  | "mediation"
  | "submission"
  | "timeline"
  | "completion";

type MiniOptionKind = "choice" | "other";

type MiniOption = {
  id: string;
  label: string;
  kind?: MiniOptionKind;
  description?: string;
  badge?: string;
};

type OptionListView = "overview" | "datePicker" | "timePicker";
type OptionListMeridiem = "오전" | "오후";
type OptionListDateTimeSelection = {
  meridiem: OptionListMeridiem;
  hour: number;
  minute: number;
};
type OptionListKind = "dateTime" | "attachment";
type OptionListAttachmentType = "NOISE_LOG" | "AUDIO_FILE" | "VIDEO_FILE";
type OptionListAttachment = {
  id: string;
  type: OptionListAttachmentType;
  name: string;
  uri: string;
};
type MiniInterfaceType = "ListPicker" | "OptionList";

type MiniInterfaceConfig = {
  prompt: string;
  selectionMode: MiniSelectionMode;
  context: MiniInterfaceContext;
  miniInterfaceType: MiniInterfaceType;
  selectionHint?: string;
  optionListKind?: OptionListKind;
  options: MiniOption[];
};

type AiTurn = {
  id: string;
  text: string;
  inputMode: ResponseInputMode;
  miniInterface?: MiniInterfaceConfig | null;
};

type FlowStepKey =
  | "intake"
  | "classification"
  | "routing"
  | "evidence"
  | "mediation"
  | "submission"
  | "tracking"
  | "completion";

type FlowStepDefinition = {
  key: FlowStepKey;
  number: number;
  label: string;
  doneToast: string;
};

const INITIAL_AI_TURN: AiTurn = {
  id: "chatbot-turn-1",
  text: "안녕하세요. 어떤 소음이 가장\n불편하신가요?",
  inputMode: "text",
  miniInterface: null,
};

type ChatbotConversationScreenProps = {
  onBack?: () => void;
  onRouteConfirmed?: () => void;
  onRestartFlow?: () => void;
};

type ThinkingWaveTextProps = {
  text: string;
  style?: StyleProp<TextStyle>;
};

type MiniAnimatedPressableProps = {
  children: ReactNode;
  onPress: () => void;
  style?: StyleProp<ViewStyle>;
  disabled?: boolean;
  pressScale?: number;
};

type OptionListSelectableRowProps = {
  selected: boolean;
  onPress: () => void;
  children: ReactNode;
  disabled?: boolean;
};

type DebugLogLevel = "INFO" | "ERROR";

type DebugLogItem = {
  id: string;
  timestamp: string;
  level: DebugLogLevel;
  message: string;
};

type ApiLikeError = {
  code?: string;
  status?: number;
  traceId?: string;
  details?: string[];
  message?: string;
};

const THINKING_TEXT = "답변을 준비하고 있어요.";
const REQUEST_ERROR_FALLBACK = "요청 처리 중 문제가 발생했어요. 다시 시도해 주세요.";
const TIMELINE_COMPLETED_EVENT = "CASE_COMPLETED";
const OPTION_LIST_DATE = "option-list-date";
const OPTION_LIST_TIME = "option-list-time";
const OPTION_LIST_SUBMIT = "option-list-submit";
const OPTION_LIST_ATTACHMENT_NOISE_LOG = "option-list-attachment-noise-log";
const OPTION_LIST_ATTACHMENT_AUDIO_FILE = "option-list-attachment-audio-file";
const OPTION_LIST_ATTACHMENT_VIDEO_FILE = "option-list-attachment-video-file";
const OPTION_LIST_ATTACHMENT_SUBMIT = "option-list-attachment-submit";
const KO_WEEKDAYS = ["일", "월", "화", "수", "목", "금", "토"] as const;
const OPTION_LIST_TIME_MERIDIEM_WHEEL: Array<OptionListMeridiem | null> = [null, "오전", "오후", null];
const OPTION_LIST_TIME_HOURS_BASE = Array.from({ length: 12 }, (_, index) => index + 1);
const OPTION_LIST_TIME_MINUTES_BASE = Array.from({ length: 60 }, (_, index) => index);
const OPTION_LIST_TIME_HOUR_REPEAT = 9;
const OPTION_LIST_TIME_MINUTE_REPEAT = 5;
const OPTION_LIST_WHEEL_ITEM_HEIGHT = 36;

const OPTION_LIST_TIME_HOURS_WHEEL = Array.from(
  { length: OPTION_LIST_TIME_HOURS_BASE.length * OPTION_LIST_TIME_HOUR_REPEAT },
  (_, index) => OPTION_LIST_TIME_HOURS_BASE[index % OPTION_LIST_TIME_HOURS_BASE.length] ?? 1,
);

const OPTION_LIST_TIME_MINUTES_WHEEL = Array.from(
  { length: OPTION_LIST_TIME_MINUTES_BASE.length * OPTION_LIST_TIME_MINUTE_REPEAT },
  (_, index) => OPTION_LIST_TIME_MINUTES_BASE[index % OPTION_LIST_TIME_MINUTES_BASE.length] ?? 0,
);

const MEDIATION_OPTION_TRY_FIRST = "mediation-try-first";
const MEDIATION_OPTION_PROCEED_SUBMISSION = "mediation-proceed-submission";

const SUBMISSION_OPTION_MCP = "submission-mcp-api";
const SUBMISSION_OPTION_MANUAL = "submission-manual-pdf";

const TIMELINE_OPTION_REFRESH = "timeline-refresh";
const TIMELINE_OPTION_RESTART = "timeline-restart";

const COMPLETION_OPTION_RESTART = "completion-restart";

const FLOW_STEPS: FlowStepDefinition[] = [
  { key: "intake", number: 1, label: "접수", doneToast: "1단계 접수 완료" },
  { key: "classification", number: 2, label: "분류", doneToast: "2단계 분류 완료" },
  { key: "routing", number: 3, label: "경로 확정", doneToast: "3단계 경로 확정 완료" },
  { key: "evidence", number: 4, label: "증거 수집", doneToast: "4단계 증거 수집 완료" },
  { key: "mediation", number: 5, label: "조정 지원", doneToast: "5단계 조정 지원 완료" },
  { key: "submission", number: 6, label: "정식 제출", doneToast: "6단계 제출 완료" },
  { key: "tracking", number: 7, label: "진행 추적", doneToast: "7단계 진행 추적 완료" },
  { key: "completion", number: 8, label: "종결", doneToast: "8단계 종결 완료" },
];

const STATUS_FALLBACK_TEXT: Partial<Record<CaseStatus, string>> = {
  RECEIVED: "접수했어요. 핵심 정보만 조금 더 알려주세요.",
  CLASSIFIED: "분류가 끝났어요. 추천 경로를 확인해요.",
  ROUTE_CONFIRMED: "경로를 확정했어요. 증거를 준비해요.",
  EVIDENCE_COLLECTING: "증거를 모으면 제출 단계로 넘어가요.",
  FORMAL_SUBMISSION_READY: "제출 준비가 끝났어요. 제출을 진행해요.",
};

function toMonthStart(date: Date): Date {
  return new Date(date.getFullYear(), date.getMonth(), 1);
}

function addMonth(date: Date, offset: number): Date {
  return new Date(date.getFullYear(), date.getMonth() + offset, 1);
}

function isSameDate(a: Date, b: Date): boolean {
  return (
    a.getFullYear() === b.getFullYear() &&
    a.getMonth() === b.getMonth() &&
    a.getDate() === b.getDate()
  );
}

function formatOptionListDate(date: Date): string {
  return `${date.getFullYear()}년 ${date.getMonth() + 1}월 ${date.getDate()}일 (${KO_WEEKDAYS[date.getDay()]})`;
}

function formatOptionListTime(value: OptionListDateTimeSelection): string {
  const hour = value.hour.toString().padStart(2, "0");
  const minute = value.minute.toString().padStart(2, "0");
  return `${value.meridiem} ${hour}시 ${minute}분`;
}

function createCalendarCells(monthStart: Date): Array<Date | null> {
  const startOffset = monthStart.getDay();
  const daysInMonth = new Date(monthStart.getFullYear(), monthStart.getMonth() + 1, 0).getDate();
  const cells: Array<Date | null> = [];

  for (let i = 0; i < startOffset; i += 1) {
    cells.push(null);
  }
  for (let day = 1; day <= daysInMonth; day += 1) {
    cells.push(new Date(monthStart.getFullYear(), monthStart.getMonth(), day));
  }
  while (cells.length < 42) {
    cells.push(null);
  }
  return cells;
}

function clampNumber(value: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, value));
}

function getMeridiemWheelInitialIndex(value: OptionListMeridiem): number {
  return value === "오전" ? 1 : 2;
}

function getCyclicWheelCenterIndex(
  value: number,
  values: number[],
  repeatCount: number,
): number {
  const baseIndex = Math.max(0, values.indexOf(value));
  return Math.floor(repeatCount / 2) * values.length + baseIndex;
}

function compactAiText(rawText: string): string {
  const normalized = rawText.replace(/\s+/g, " ").trim();
  if (!normalized) {
    return "입력 내용을 확인했어요.";
  }

  const sentenceTokens = normalized.match(/[^.!?\n]+[.!?]?/g) ?? [normalized];
  const selected = sentenceTokens
    .map((sentence) => sentence.trim())
    .filter(Boolean)
    .slice(0, 2)
    .join(" ");

  if (selected.length <= 72) {
    return selected;
  }

  return `${selected.slice(0, 69).trim()}...`;
}

function resolveAiTurnText(response: IntakeUpdateResponse): string {
  const followUp = response.recommendedFollowUpQuestion?.trim();
  if (followUp) {
    return compactAiText(followUp);
  }

  return compactAiText(
    STATUS_FALLBACK_TEXT[response.status] ??
      "입력을 확인했어요. 다음 안내를 이어갈게요.",
  );
}

function mapApiFollowUpInterface(
  followUpInterface: FollowUpInterface | null | undefined,
  prompt: string,
): MiniInterfaceConfig | null {
  if (!followUpInterface || followUpInterface.interfaceType !== "OPTIONS") {
    return null;
  }

  const options = (followUpInterface.options ?? []).slice(0, 4).reduce<MiniOption[]>((acc, option, index) => {
    const label = option.label?.trim();
    if (!label) {
      return acc;
    }

    const id = option.optionId?.trim() || `mini-option-${index + 1}`;
    acc.push({
      id,
      label,
      kind: label === "기타" ? "other" : "choice",
      description: "선택 후 보내기로 전달",
      badge: `선택 ${index + 1}`,
    });
    return acc;
  }, []);

  if (options.length === 0) {
    return null;
  }

  return {
    prompt,
    selectionMode: followUpInterface.selectionMode === "MULTIPLE" ? "multiple" : "single",
    context: "intake",
    miniInterfaceType: "ListPicker",
    selectionHint: followUpInterface.selectionMode === "MULTIPLE" ? "복수 선택 가능" : "단일 선택",
    options,
  };
}

function createListPickerInterface(
  prompt: string,
  optionLabels: string[],
  selectionMode: MiniSelectionMode = "single",
  context: MiniInterfaceContext = "intake",
): MiniInterfaceConfig {
  return {
    prompt,
    selectionMode,
    context,
    miniInterfaceType: "ListPicker",
    selectionHint: selectionMode === "multiple" ? "복수 선택 가능" : "단일 선택",
    options: optionLabels.map((label, index) => {
      const isOther = label === "기타";
      return {
        id: `mini-option-${index + 1}-${label}`,
        label,
        kind: isOther ? "other" : "choice",
        description: isOther ? "직접 입력으로 전환" : "선택 후 보내기로 전달",
        badge: isOther ? "직접입력" : `선택 ${index + 1}`,
      };
    }),
  };
}

function mapRoutingRecommendationToMiniInterface(
  recommendation: RoutingRecommendation,
): MiniInterfaceConfig | null {
  const options = (recommendation.options ?? [])
    .slice(0, 4)
    .map((option, index) => {
      const rawReason = option.reason?.trim();
      return {
        id: option.optionId,
        label: option.label,
        kind: "choice" as const,
        description: rawReason ? compactAiText(rawReason) : "추천 이유가 반영된 경로",
        badge: `경로 ${index + 1}`,
      };
    });

  if (options.length === 0) {
    return null;
  }

  return {
    prompt: "추천 경로를 준비했어요. 가장 맞는 경로 하나를 선택해 주세요.",
    selectionMode: "single",
    context: "routing",
    miniInterfaceType: "ListPicker",
    selectionHint: "단일 선택",
    options,
  };
}

function createOptionListInterface(optionListKind: OptionListKind = "dateTime"): MiniInterfaceConfig {
  if (optionListKind === "attachment") {
    return {
      prompt: "필요한 자료 항목만 선택해 주세요.",
      selectionMode: "single",
      context: "optionList",
      miniInterfaceType: "OptionList",
      optionListKind: "attachment",
      selectionHint: "옵션 선택",
      options: [
        { id: OPTION_LIST_ATTACHMENT_NOISE_LOG, label: "소음일지" },
        { id: OPTION_LIST_ATTACHMENT_AUDIO_FILE, label: "녹음 파일" },
        { id: OPTION_LIST_ATTACHMENT_VIDEO_FILE, label: "영상 파일" },
        { id: OPTION_LIST_ATTACHMENT_SUBMIT, label: "선택 완료" },
      ],
    };
  }

  return {
    prompt: "소음이 발생한 날짜와 시간을 선택해 주세요.",
    selectionMode: "single",
    context: "optionList",
    miniInterfaceType: "OptionList",
    optionListKind: "dateTime",
    selectionHint: "옵션 선택",
    options: [
      { id: OPTION_LIST_DATE, label: "발생 날짜" },
      { id: OPTION_LIST_TIME, label: "발생 시간" },
      { id: OPTION_LIST_SUBMIT, label: "정보 확인 및 제출" },
    ],
  };
}

function createMediationMiniInterface(): MiniInterfaceConfig {
  return {
    prompt: "다음 진행 방식을 선택해 주세요.",
    selectionMode: "single",
    context: "mediation",
    miniInterfaceType: "ListPicker",
    selectionHint: "단일 선택",
    options: [
      {
        id: MEDIATION_OPTION_TRY_FIRST,
        label: "조정 먼저",
        description: "관리사무소 조정 요청 문구로 시작",
        badge: "권장",
      },
      {
        id: MEDIATION_OPTION_PROCEED_SUBMISSION,
        label: "바로 제출",
        description: "정부24 제출 단계로 바로 이동",
        badge: "빠른 진행",
      },
    ],
  };
}

function createSubmissionMiniInterface(hasFallbackHint = false): MiniInterfaceConfig {
  return {
    prompt: hasFallbackHint
      ? "연동이 지연 중이에요. 수동 제출로 진행해 주세요."
      : "제출 방식을 선택해 주세요.",
    selectionMode: "single",
    context: "submission",
    miniInterfaceType: "ListPicker",
    selectionHint: "단일 선택",
    options: [
      {
        id: SUBMISSION_OPTION_MCP,
        label: "정부24 연계",
        description: "자동 제출 채널로 접수",
        badge: "기본",
      },
      {
        id: SUBMISSION_OPTION_MANUAL,
        label: "수동 제출",
        description: "서식(PDF) 기반으로 제출",
        badge: "폴백",
      },
    ],
  };
}

function createTimelineMiniInterface(lastEvent?: TimelineEvent): MiniInterfaceConfig {
  const prompt = lastEvent
    ? `현재 상태: ${lastEvent.title}`
    : "진행 상태를 확인해 볼까요?";

  return {
    prompt,
    selectionMode: "single",
    context: "timeline",
    miniInterfaceType: "ListPicker",
    selectionHint: "단일 선택",
    options: [
      {
        id: TIMELINE_OPTION_REFRESH,
        label: "상태 새로고침",
        description: "최신 처리 상태 조회",
        badge: "조회",
      },
      {
        id: TIMELINE_OPTION_RESTART,
        label: "처음으로",
        description: "새 상담을 다시 시작",
        badge: "재시작",
      },
    ],
  };
}

function createCompletionMiniInterface(): MiniInterfaceConfig {
  return {
    prompt: "민원 처리가 완료됐어요.",
    selectionMode: "single",
    context: "completion",
    miniInterfaceType: "ListPicker",
    selectionHint: "단일 선택",
    options: [
      {
        id: COMPLETION_OPTION_RESTART,
        label: "처음으로 돌아가기",
        description: "새 상담을 시작",
        badge: "완료",
      },
    ],
  };
}

function createDebugMiniInterfaceInput(
  compactUserInput: string,
): { text: string; inputMode: ResponseInputMode; miniInterface: MiniInterfaceConfig | null } | null {
  if (!__DEV__) {
    return null;
  }

  if (compactUserInput === "2") {
    const miniInterface = createListPickerInterface(
      "테스트(복수 선택)입니다. 해당되는 시간대를 모두 선택해 주세요.",
      ["아침", "낮", "저녁", "기타"],
      "multiple",
    );
    return { text: miniInterface.prompt, inputMode: "mini", miniInterface };
  }

  if (compactUserInput === "3") {
    const miniInterface = createListPickerInterface(
      "테스트(단일 선택)입니다. 가장 불편한 시간대를 하나 선택해 주세요.",
      ["아침", "낮", "저녁", "기타"],
      "single",
    );
    return { text: miniInterface.prompt, inputMode: "mini", miniInterface };
  }

  if (
    compactUserInput === "4" ||
    compactUserInput === "날짜시간테스트" ||
    compactUserInput === "증거날짜시간"
  ) {
    const miniInterface = createOptionListInterface("dateTime");
    return {
      text: "테스트입니다. 소음이 발생한 날짜와 시간을 선택해 주세요.",
      inputMode: "mini",
      miniInterface,
    };
  }

  if (compactUserInput === "5" || compactUserInput === "첨부옵션테스트") {
    const miniInterface = createOptionListInterface("attachment");
    return {
      text: "테스트입니다. 자료 옵션을 선택해 주세요.",
      inputMode: "mini",
      miniInterface,
    };
  }

  return null;
}

function ThinkingWaveText({ text, style }: ThinkingWaveTextProps) {
  const phase = useRef(new Animated.Value(0)).current;
  const containerOpacity = useRef(new Animated.Value(0)).current;
  const chars = useMemo(() => Array.from(text), [text]);

  useEffect(() => {
    containerOpacity.setValue(0);
    const fadeIn = Animated.timing(containerOpacity, {
      toValue: 1,
      duration: 420,
      easing: Easing.out(Easing.cubic),
      useNativeDriver: true,
    });
    fadeIn.start();
    return () => fadeIn.stop();
  }, [containerOpacity, text]);

  useEffect(() => {
    const travelLength = chars.length + 3;
    phase.setValue(-2);

    const loop = Animated.loop(
      Animated.sequence([
        Animated.timing(phase, {
          toValue: travelLength,
          duration: Math.max(1800, chars.length * 130),
          easing: Easing.linear,
          useNativeDriver: false,
        }),
        Animated.delay(220),
      ]),
    );

    loop.start();
    return () => {
      loop.stop();
      phase.stopAnimation();
    };
  }, [chars.length, phase]);

  return (
    <Animated.View style={{ opacity: containerOpacity }}>
      <Text style={style}>
        {chars.map((char, index) => (
          <Animated.Text
            key={`thinking-wave-${index}`}
            style={{
              color: phase.interpolate({
                inputRange: [index - 1.2, index, index + 1.2],
                outputRange: ["#9ca3af", "#e5e7eb", "#9ca3af"],
                extrapolate: "clamp",
              }),
              opacity: phase.interpolate({
                inputRange: [index - 2.2, index - 0.8, index, index + 0.8, index + 2.2],
                outputRange: [0.58, 0.72, 1, 0.72, 0.58],
                extrapolate: "clamp",
              }),
            }}
          >
            {char}
          </Animated.Text>
        ))}
      </Text>
    </Animated.View>
  );
}

function MiniAnimatedPressable({
  children,
  onPress,
  style,
  disabled = false,
  pressScale = 0.97,
}: MiniAnimatedPressableProps) {
  const pressAnim = useRef(new Animated.Value(0)).current;

  const handlePressIn = useCallback(() => {
    if (disabled) {
      return;
    }
    Animated.timing(pressAnim, {
      toValue: 1,
      duration: 90,
      easing: Easing.out(Easing.cubic),
      useNativeDriver: true,
    }).start();
  }, [disabled, pressAnim]);

  const handlePressOut = useCallback(() => {
    Animated.timing(pressAnim, {
      toValue: 0,
      duration: 150,
      easing: Easing.out(Easing.cubic),
      useNativeDriver: true,
    }).start();
  }, [pressAnim]);

  const animatedStyle = useMemo(
    () => ({
      opacity: pressAnim.interpolate({
        inputRange: [0, 1],
        outputRange: [1, 0.92],
      }),
      transform: [
        {
          scale: pressAnim.interpolate({
            inputRange: [0, 1],
            outputRange: [1, pressScale],
          }),
        },
      ],
    }),
    [pressAnim, pressScale],
  );

  return (
    <Animated.View style={animatedStyle}>
      <Pressable
        onPress={onPress}
        disabled={disabled}
        onPressIn={handlePressIn}
        onPressOut={handlePressOut}
        style={style}
      >
        {children}
      </Pressable>
    </Animated.View>
  );
}

function OptionListSelectableRow({
  selected,
  onPress,
  children,
  disabled = false,
}: OptionListSelectableRowProps) {
  const selectedAnim = useRef(new Animated.Value(selected ? 1 : 0)).current;

  useEffect(() => {
    Animated.timing(selectedAnim, {
      toValue: selected ? 1 : 0,
      duration: 220,
      easing: Easing.out(Easing.cubic),
      useNativeDriver: true,
    }).start();
  }, [selected, selectedAnim]);

  const animatedStyle = useMemo(
    () => ({
      transform: [
        {
          scale: selectedAnim.interpolate({
            inputRange: [0, 1],
            outputRange: [1, 1.012],
          }),
        },
        {
          translateY: selectedAnim.interpolate({
            inputRange: [0, 1],
            outputRange: [0, -1],
          }),
        },
      ],
      opacity: selectedAnim.interpolate({
        inputRange: [0, 1],
        outputRange: [1, 0.995],
      }),
    }),
    [selectedAnim],
  );

  return (
    <Animated.View style={animatedStyle}>
      <MiniAnimatedPressable
        style={styles.evidenceDateTimeRow}
        onPress={onPress}
        disabled={disabled}
        pressScale={0.985}
      >
        {children}
      </MiniAnimatedPressable>
    </Animated.View>
  );
}

function EvidenceCalendarIcon() {
  return (
    <View style={styles.evidenceIconCalendarBase}>
      <View style={styles.evidenceIconCalendarTopLine} />
      <View style={styles.evidenceIconCalendarRingLeft} />
      <View style={styles.evidenceIconCalendarRingRight} />
    </View>
  );
}

function EvidenceClockIcon() {
  return (
    <View style={styles.evidenceIconClockBase}>
      <View style={styles.evidenceIconClockHandHour} />
      <View style={styles.evidenceIconClockHandMinute} />
      <View style={styles.evidenceIconClockDot} />
    </View>
  );
}

function EvidenceMicIcon() {
  return (
    <View style={styles.evidenceIconMicBase}>
      <View style={styles.evidenceIconMicHead} />
      <View style={styles.evidenceIconMicStem} />
      <View style={styles.evidenceIconMicFoot} />
    </View>
  );
}

function EvidenceVideoIcon() {
  return (
    <View style={styles.evidenceIconVideoBase}>
      <View style={styles.evidenceIconVideoLens} />
      <View style={styles.evidenceIconVideoDot} />
    </View>
  );
}

function getExpoImagePickerModule():
  | null
  | {
      requestMediaLibraryPermissionsAsync: () => Promise<{ granted: boolean }>;
      launchImageLibraryAsync: (options?: Record<string, unknown>) => Promise<{
        canceled: boolean;
        assets?: Array<{ uri: string; fileName?: string | null }>;
      }>;
      MediaTypeOptions?: { All?: unknown; Videos?: unknown };
    } {
  try {
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    return require("expo-image-picker");
  } catch {
    return null;
  }
}

function getExpoDocumentPickerModule():
  | null
  | {
      getDocumentAsync: (options?: {
        type?: string | string[];
        multiple?: boolean;
        copyToCacheDirectory?: boolean;
      }) => Promise<{
        canceled?: boolean;
        assets?: Array<{ uri: string; name?: string }>;
      }>;
    } {
  try {
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    return require("expo-document-picker");
  } catch {
    return null;
  }
}

function keyboardEasingToAnimated(easing?: KeyboardEvent["easing"]) {
  switch (easing) {
    case "easeIn":
      return Easing.in(Easing.ease);
    case "easeOut":
      return Easing.out(Easing.ease);
    case "linear":
      return Easing.linear;
    case "easeInEaseOut":
      return Easing.inOut(Easing.ease);
    default:
      return Easing.out(Easing.cubic);
  }
}

function extractApiErrorInfo(error: unknown): {
  code: string | null;
  status: number | null;
  traceId: string | null;
  details: string[];
} {
  if (!error || typeof error !== "object") {
    return { code: null, status: null, traceId: null, details: [] };
  }

  const candidate = error as ApiLikeError;
  const details = Array.isArray(candidate.details)
    ? candidate.details.filter((item): item is string => typeof item === "string")
    : [];

  return {
    code: typeof candidate.code === "string" ? candidate.code : null,
    status: typeof candidate.status === "number" ? candidate.status : null,
    traceId: typeof candidate.traceId === "string" ? candidate.traceId : null,
    details,
  };
}

export function ChatbotConversationScreen({
  onBack,
  onRouteConfirmed,
  onRestartFlow,
}: ChatbotConversationScreenProps) {
  const [draft, setDraft] = useState("");
  const [selectedMiniOptionIds, setSelectedMiniOptionIds] = useState<string[]>([]);
  const [isInputFocused, setIsInputFocused] = useState(false);
  const [isAiMessageCompleted, setIsAiMessageCompleted] = useState(false);
  const [isGeneratingReply, setIsGeneratingReply] = useState(false);
  const [apiErrorMessage, setApiErrorMessage] = useState<string | null>(null);
  const [visibleSentenceCount, setVisibleSentenceCount] = useState(1);
  const [currentAiTurn, setCurrentAiTurn] = useState<AiTurn>(INITIAL_AI_TURN);
  const [currentFlowStep, setCurrentFlowStep] = useState<FlowStepKey>("intake");
  const [completedFlowSteps, setCompletedFlowSteps] = useState<FlowStepKey[]>([]);
  const [isStepTodoOpen, setIsStepTodoOpen] = useState(false);
  const [stepToastMessage, setStepToastMessage] = useState<string | null>(null);
  const [optionListKind, setOptionListKind] = useState<OptionListKind>("dateTime");
  const [optionListView, setOptionListView] = useState<OptionListView>("overview");
  const [selectedOptionListDate, setSelectedOptionListDate] = useState<Date | null>(null);
  const [selectedOptionListTime, setSelectedOptionListTime] = useState<OptionListDateTimeSelection | null>(null);
  const [optionListAttachments, setOptionListAttachments] = useState<OptionListAttachment[]>([]);
  const [optionListPickerMonth, setOptionListPickerMonth] = useState<Date>(() => toMonthStart(new Date()));
  const [draftOptionListDate, setDraftOptionListDate] = useState<Date>(() => new Date());
  const [draftOptionListTime, setDraftOptionListTime] = useState<OptionListDateTimeSelection>({
    meridiem: "오후",
    hour: 2,
    minute: 30,
  });
  const [meridiemWheelIndex, setMeridiemWheelIndex] = useState<number>(getMeridiemWheelInitialIndex("오후"));
  const [hourWheelIndex, setHourWheelIndex] = useState<number>(
    getCyclicWheelCenterIndex(2, OPTION_LIST_TIME_HOURS_BASE, OPTION_LIST_TIME_HOUR_REPEAT),
  );
  const [minuteWheelIndex, setMinuteWheelIndex] = useState<number>(
    getCyclicWheelCenterIndex(30, OPTION_LIST_TIME_MINUTES_BASE, OPTION_LIST_TIME_MINUTE_REPEAT),
  );
  const [debugLogs, setDebugLogs] = useState<DebugLogItem[]>([]);
  const [isDebugLogOpen, setIsDebugLogOpen] = useState(false);
  const {
    caseId,
    status,
    traceId,
    applyCaseDetail,
    applyIntakeUpdate,
    setSubmissionResponse,
    setTimelineEvents,
    setMediationDecision,
    setCaseFromCreate,
    setRoutingRecommendation,
    resetCase,
  } = useCaseContext();
  const { width, height } = useWindowDimensions();
  const insets = useSafeAreaInsets();
  const turnSequenceRef = useRef(2);
  const completedFlowStepsRef = useRef<Set<FlowStepKey>>(new Set());
  const createCaseIdempotencyKeyRef = useRef(`mobile-create-case-${Date.now()}`);
  const replyTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const optionListMeridiemWheelRef = useRef<ScrollView | null>(null);
  const optionListHourWheelRef = useRef<ScrollView | null>(null);
  const optionListMinuteWheelRef = useRef<ScrollView | null>(null);
  const optionListFadeAnim = useRef(new Animated.Value(1)).current;
  const wheelLastHandledOffsetRef = useRef<Record<"meridiem" | "hour" | "minute", number>>({
    meridiem: Number.NaN,
    hour: Number.NaN,
    minute: Number.NaN,
  });
  const backButtonPressAnim = useRef(new Animated.Value(0)).current;
  // Keep AI responses rendered sentence-by-sentence so each sentence appears on its own line.
  const aiSentences = useMemo(() => {
    const tokens = currentAiTurn.text.match(/[^.!?\n]+[.!?]?/g) ?? [];
    const normalized = tokens.map((sentence) => sentence.trim()).filter((sentence) => sentence.length > 0);
    return normalized.length > 0 ? normalized : [currentAiTurn.text];
  }, [currentAiTurn.text]);
  const inputFocusAnim = useRef(new Animated.Value(0)).current;
  const inputKeyboardLift = useRef(new Animated.Value(0)).current;
  const inputRevealAnim = useRef(new Animated.Value(0)).current;
  const miniInterfaceRevealAnim = useRef(new Animated.Value(0)).current;
  const stepSubtitleAnim = useRef(new Animated.Value(1)).current;
  const stepTodoRevealAnim = useRef(new Animated.Value(0)).current;
  const stepToastAnim = useRef(new Animated.Value(0)).current;
  const currentMiniInterface = currentAiTurn.miniInterface ?? null;
  const currentMiniOptions = currentMiniInterface?.options ?? [];
  const currentMiniSelectionMode = currentMiniInterface?.selectionMode ?? "single";
  const miniContext = currentMiniInterface?.context ?? null;
  const miniInterfaceType = currentMiniInterface?.miniInterfaceType ?? null;
  const isMiniInterfaceMode = currentAiTurn.inputMode === "mini";
  const isOptionListMiniContext = miniInterfaceType === "OptionList";
  const isListPickerMiniContext = miniInterfaceType === "ListPicker";
  const shouldShowMiniInterface =
    isAiMessageCompleted &&
    !isGeneratingReply &&
    isMiniInterfaceMode &&
    (isOptionListMiniContext || (isListPickerMiniContext && currentMiniOptions.length > 0));
  const shouldShowRouteRecommendationAction =
    status === "CLASSIFIED" && isAiMessageCompleted && !isGeneratingReply && !shouldShowMiniInterface;
  const isInputDisabled = isGeneratingReply || shouldShowMiniInterface;

  const availableWidth = width;
  const availableHeight = height;
  const horizontalPadding = Math.max(20, Math.round((24 / BASE_WIDTH) * availableWidth));
  const contentWidth = Math.max(0, availableWidth - horizontalPadding * 2);
  const inputHeight = 56;
  const inputBaseBottom = insets.bottom + 16;
  const miniPanelBottom = inputBaseBottom + inputHeight + 24;
  const topInsetOffset = Math.max(insets.top - 20, 0);
  const optionListCalendarCells = useMemo(() => createCalendarCells(optionListPickerMonth), [optionListPickerMonth]);
  const optionListDateLabel = selectedOptionListDate ? formatOptionListDate(selectedOptionListDate) : "선택해 주세요";
  const optionListTimeLabel = selectedOptionListTime ? formatOptionListTime(selectedOptionListTime) : "선택해 주세요";
  const optionListNoiseLogAttachments = useMemo(
    () => optionListAttachments.filter((item) => item.type === "NOISE_LOG"),
    [optionListAttachments],
  );
  const optionListAudioFileAttachments = useMemo(
    () => optionListAttachments.filter((item) => item.type === "AUDIO_FILE"),
    [optionListAttachments],
  );
  const optionListVideoFileAttachments = useMemo(
    () => optionListAttachments.filter((item) => item.type === "VIDEO_FILE"),
    [optionListAttachments],
  );
  const optionListNoiseLogLabel =
    optionListNoiseLogAttachments.length > 0
      ? `${optionListNoiseLogAttachments.length}개 선택됨`
      : "선택해 주세요";
  const optionListAudioFileLabel =
    optionListAudioFileAttachments.length > 0
      ? `${optionListAudioFileAttachments.length}개 선택됨`
      : "선택해 주세요";
  const optionListVideoFileLabel =
    optionListVideoFileAttachments.length > 0
      ? `${optionListVideoFileAttachments.length}개 선택됨`
      : "선택해 주세요";
  const isOptionListDateTimeReady = Boolean(selectedOptionListDate && selectedOptionListTime);

  const dismissKeyboard = useCallback(() => {
    Keyboard.dismiss();
    setIsInputFocused(false);
  }, []);

  const transitionOptionListView = useCallback(
    (nextView: OptionListView, afterSwitch?: () => void) => {
      if (optionListView === nextView) {
        afterSwitch?.();
        return;
      }

      optionListFadeAnim.stopAnimation();
      Animated.timing(optionListFadeAnim, {
        toValue: 0,
        duration: 90,
        easing: Easing.out(Easing.cubic),
        useNativeDriver: true,
      }).start(({ finished }) => {
        if (!finished) {
          return;
        }

        setOptionListView(nextView);
        requestAnimationFrame(() => {
          afterSwitch?.();
          Animated.timing(optionListFadeAnim, {
            toValue: 1,
            duration: 180,
            easing: Easing.out(Easing.cubic),
            useNativeDriver: true,
          }).start();
        });
      });
    },
    [optionListFadeAnim, optionListView],
  );

  const handleBackPressIn = useCallback(() => {
    Animated.timing(backButtonPressAnim, {
      toValue: 1,
      duration: 110,
      easing: Easing.out(Easing.cubic),
      useNativeDriver: true,
    }).start();
  }, [backButtonPressAnim]);

  const handleBackPressOut = useCallback(() => {
    Animated.timing(backButtonPressAnim, {
      toValue: 0,
      duration: 170,
      easing: Easing.out(Easing.cubic),
      useNativeDriver: true,
    }).start();
  }, [backButtonPressAnim]);

  const handleBackPress = useCallback(() => {
    onBack?.();
  }, [onBack]);

  const toggleDebugLog = useCallback(() => {
    setIsDebugLogOpen((previous) => !previous);
  }, []);

  const pushAiTurn = useCallback(
    (text: string, inputMode: ResponseInputMode, miniInterface: MiniInterfaceConfig | null = null) => {
      const nextTurnId = `chatbot-turn-${turnSequenceRef.current}`;
      turnSequenceRef.current += 1;
      setCurrentAiTurn({
        id: nextTurnId,
        text,
        inputMode,
        miniInterface,
      });
    },
    [],
  );

  const appendDebugLog = useCallback((message: string, level: DebugLogLevel = "INFO") => {
    const now = new Date();
    const timestamp = now.toLocaleTimeString("ko-KR", { hour12: false });
    setDebugLogs((previous) => {
      const next: DebugLogItem = {
        id: `${now.getTime()}-${Math.random().toString(36).slice(2, 7)}`,
        timestamp,
        level,
        message,
      };
      return [next, ...previous].slice(0, 40);
    });
  }, []);

  const applyApiError = useCallback((error: unknown, action: string) => {
    const info = extractApiErrorInfo(error);
    let userMessage = toKoreanErrorMessage(error);

    if (info.code === "CASE_STATE_CONFLICT") {
      const currentState = info.details
        .find((detail) => detail.startsWith("currentState="))
        ?.replace("currentState=", "");
      const requiredState = info.details
        .find((detail) => detail.startsWith("requiredState="))
        ?.replace("requiredState=", "");

      if (currentState || requiredState) {
        userMessage = `요청 순서가 맞지 않아요. 현재: ${currentState ?? "-"}, 필요: ${requiredState ?? "-"}`;
      }
    }

    setApiErrorMessage(userMessage);

    const summaryParts = [
      `action=${action}`,
      info.status ? `status=${info.status}` : null,
      info.code ? `code=${info.code}` : null,
      info.traceId ? `traceId=${info.traceId}` : null,
    ].filter((part): part is string => Boolean(part));

    appendDebugLog(summaryParts.join(" | "), "ERROR");
    if (info.details.length > 0) {
      appendDebugLog(`details: ${info.details.join(" | ")}`, "ERROR");
    }
  }, [appendDebugLog]);

  const showStepDoneToast = useCallback(
    (message: string) => {
      setStepToastMessage(message);
      stepToastAnim.stopAnimation();
      stepToastAnim.setValue(0);

      Animated.sequence([
        Animated.timing(stepToastAnim, {
          toValue: 1,
          duration: 220,
          easing: Easing.out(Easing.cubic),
          useNativeDriver: true,
        }),
        Animated.delay(820),
        Animated.timing(stepToastAnim, {
          toValue: 0,
          duration: 220,
          easing: Easing.in(Easing.cubic),
          useNativeDriver: true,
        }),
      ]).start(({ finished }) => {
        if (finished) {
          setStepToastMessage(null);
        }
      });
    },
    [stepToastAnim],
  );

  const markFlowStepCompleted = useCallback(
    (step: FlowStepKey, showToast = true) => {
      if (completedFlowStepsRef.current.has(step)) {
        return false;
      }
      completedFlowStepsRef.current.add(step);
      setCompletedFlowSteps(Array.from(completedFlowStepsRef.current));
      const stepInfo = showToast ? FLOW_STEPS.find((item) => item.key === step) : null;
      if (showToast && stepInfo) {
        showStepDoneToast(stepInfo.doneToast);
      }
      return true;
    },
    [showStepDoneToast],
  );

  const moveToFlowStep = useCallback(
    (step: FlowStepKey) => {
      setCurrentFlowStep(step);
    },
    [],
  );

  const startGeneratingThenRespond = useCallback(
    (text: string, inputMode: ResponseInputMode, delayMs = 3000) => {
      if (replyTimerRef.current) {
        clearTimeout(replyTimerRef.current);
        replyTimerRef.current = null;
      }

      setIsGeneratingReply(true);
      setIsAiMessageCompleted(false);
      setVisibleSentenceCount(0);

      replyTimerRef.current = setTimeout(() => {
        setIsGeneratingReply(false);
        pushAiTurn(text, inputMode, null);
        replyTimerRef.current = null;
      }, delayMs);
    },
    [pushAiTurn],
  );

  const handleMiniOptionPress = useCallback(
    (option: MiniOption) => {
      if (isGeneratingReply) {
        return;
      }
      Keyboard.dismiss();
      setIsInputFocused(false);
      setSelectedMiniOptionIds((previous) => {
        const isSelected = previous.includes(option.id);
        if (currentMiniSelectionMode === "multiple") {
          if (isSelected) {
            return previous.filter((id) => id !== option.id);
          }
          return [...previous, option.id];
        }
        if (isSelected) {
          return [];
        }
        return [option.id];
      });
    },
    [currentMiniSelectionMode, isGeneratingReply],
  );

  const handleOpenOptionListDatePicker = useCallback(() => {
    if (optionListKind !== "dateTime") {
      return;
    }
    setApiErrorMessage(null);
    const base = selectedOptionListDate ?? new Date();
    setDraftOptionListDate(base);
    setOptionListPickerMonth(toMonthStart(base));
    transitionOptionListView("datePicker");
  }, [optionListKind, selectedOptionListDate, transitionOptionListView]);

  const handleOpenOptionListTimePicker = useCallback(() => {
    if (optionListKind !== "dateTime") {
      return;
    }
    setApiErrorMessage(null);
    const nextDraft = selectedOptionListTime ?? {
      meridiem: "오후" as const,
      hour: 2,
      minute: 30,
    };
    setDraftOptionListTime(nextDraft);
    const meridiemIndex = getMeridiemWheelInitialIndex(nextDraft.meridiem);
    const hourIndex = getCyclicWheelCenterIndex(
      nextDraft.hour,
      OPTION_LIST_TIME_HOURS_BASE,
      OPTION_LIST_TIME_HOUR_REPEAT,
    );
    const minuteIndex = getCyclicWheelCenterIndex(
      nextDraft.minute,
      OPTION_LIST_TIME_MINUTES_BASE,
      OPTION_LIST_TIME_MINUTE_REPEAT,
    );
    setMeridiemWheelIndex(meridiemIndex);
    setHourWheelIndex(hourIndex);
    setMinuteWheelIndex(minuteIndex);
    transitionOptionListView("timePicker", () => {
      optionListMeridiemWheelRef.current?.scrollTo({
        y: meridiemIndex * OPTION_LIST_WHEEL_ITEM_HEIGHT,
        animated: false,
      });
      optionListHourWheelRef.current?.scrollTo({
        y: hourIndex * OPTION_LIST_WHEEL_ITEM_HEIGHT,
        animated: false,
      });
      optionListMinuteWheelRef.current?.scrollTo({
        y: minuteIndex * OPTION_LIST_WHEEL_ITEM_HEIGHT,
        animated: false,
      });
    });
  }, [optionListKind, selectedOptionListTime, transitionOptionListView]);

  const handleOpenOptionListAttachmentPicker = useCallback(
    async (attachmentType: OptionListAttachmentType) => {
      if (optionListKind !== "attachment" || isGeneratingReply) {
        return;
      }

      setApiErrorMessage(null);

      try {
        let pickerAssets: Array<{ uri: string; fileName?: string | null; name?: string }> = [];

        if (attachmentType === "VIDEO_FILE") {
          const imagePicker = getExpoImagePickerModule();
          if (!imagePicker) {
            throw new Error("영상 선택 기능을 불러오지 못했어요. 앱을 다시 실행해 주세요.");
          }

          const permission = await imagePicker.requestMediaLibraryPermissionsAsync();
          if (!permission.granted) {
            setApiErrorMessage("갤러리 권한이 필요해요. 권한을 허용한 뒤 다시 시도해 주세요.");
            return;
          }

          const pickerResult = await imagePicker.launchImageLibraryAsync({
            mediaTypes: imagePicker.MediaTypeOptions?.Videos,
            allowsMultipleSelection: true,
            quality: 1,
          });

          if (pickerResult.canceled || !pickerResult.assets?.length) {
            return;
          }

          pickerAssets = pickerResult.assets;
        } else {
          const documentPicker = getExpoDocumentPickerModule();
          if (!documentPicker) {
            throw new Error("파일 선택 기능을 불러오지 못했어요. 앱을 다시 실행해 주세요.");
          }

          const pickerResult = await documentPicker.getDocumentAsync({
            type: attachmentType === "AUDIO_FILE" ? ["audio/*"] : ["*/*"],
            multiple: true,
            copyToCacheDirectory: false,
          });

          if (pickerResult.canceled || !pickerResult.assets?.length) {
            return;
          }

          pickerAssets = pickerResult.assets;
        }

        setOptionListAttachments((previous) => {
          const existingKeys = new Set(previous.map((item) => `${item.type}:${item.uri}`));
          const next = [...previous];

          for (const asset of pickerAssets) {
            if (!asset.uri) {
              continue;
            }
            const key = `${attachmentType}:${asset.uri}`;
            if (existingKeys.has(key)) {
              continue;
            }
            existingKeys.add(key);
            const fileName =
              asset.fileName?.trim() ||
              asset.name?.trim() ||
              asset.uri.split("/").filter(Boolean).pop() ||
              "선택한 파일";
            next.push({
              id: `${attachmentType}-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
              type: attachmentType,
              name: fileName,
              uri: asset.uri,
            });
          }
          return next;
        });
      } catch (error: unknown) {
        applyApiError(error, "option-list-attachment-pick");
      }
    },
    [applyApiError, isGeneratingReply, optionListKind],
  );

  const handleOptionListTimeWheelScrollEnd = useCallback(
    (
      field: "meridiem" | "hour" | "minute",
      event: NativeSyntheticEvent<NativeScrollEvent>,
    ) => {
      const offsetY = event.nativeEvent.contentOffset.y;
      const lastHandledOffset = wheelLastHandledOffsetRef.current[field];
      if (Math.abs(lastHandledOffset - offsetY) < 0.5) {
        return;
      }
      wheelLastHandledOffsetRef.current[field] = offsetY;

      const rawIndex = Math.round(offsetY / OPTION_LIST_WHEEL_ITEM_HEIGHT);

      if (field === "meridiem") {
        const index = clampNumber(rawIndex, 1, 2);
        const nextValue = OPTION_LIST_TIME_MERIDIEM_WHEEL[index];
        const snappedY = index * OPTION_LIST_WHEEL_ITEM_HEIGHT;
        setMeridiemWheelIndex(index);
        if (nextValue) {
          setDraftOptionListTime((previous) =>
            previous.meridiem === nextValue ? previous : { ...previous, meridiem: nextValue },
          );
        }
        if (Math.abs(offsetY - snappedY) > 0.5) {
          requestAnimationFrame(() => {
            optionListMeridiemWheelRef.current?.scrollTo({ y: snappedY, animated: true });
          });
        }
        return;
      }

      if (field === "hour") {
        const boundedIndex = clampNumber(rawIndex, 0, OPTION_LIST_TIME_HOURS_WHEEL.length - 1);
        const nextValue = OPTION_LIST_TIME_HOURS_WHEEL[boundedIndex] ?? 1;
        const shouldRecenter =
          boundedIndex < OPTION_LIST_TIME_HOURS_BASE.length ||
          boundedIndex >= OPTION_LIST_TIME_HOURS_WHEEL.length - OPTION_LIST_TIME_HOURS_BASE.length;
        const recenteredIndex = shouldRecenter
          ? getCyclicWheelCenterIndex(nextValue, OPTION_LIST_TIME_HOURS_BASE, OPTION_LIST_TIME_HOUR_REPEAT)
          : boundedIndex;
        const snappedY = recenteredIndex * OPTION_LIST_WHEEL_ITEM_HEIGHT;

        setHourWheelIndex(recenteredIndex);
        setDraftOptionListTime((previous) =>
          previous.hour === nextValue ? previous : { ...previous, hour: nextValue },
        );

        if (Math.abs(offsetY - snappedY) > 0.5) {
          requestAnimationFrame(() => {
            optionListHourWheelRef.current?.scrollTo({ y: snappedY, animated: true });
          });
        }
        return;
      }

      const boundedIndex = clampNumber(rawIndex, 0, OPTION_LIST_TIME_MINUTES_WHEEL.length - 1);
      const nextValue = OPTION_LIST_TIME_MINUTES_WHEEL[boundedIndex] ?? 0;
      const shouldRecenter =
        boundedIndex < OPTION_LIST_TIME_MINUTES_BASE.length ||
        boundedIndex >= OPTION_LIST_TIME_MINUTES_WHEEL.length - OPTION_LIST_TIME_MINUTES_BASE.length;
      const recenteredIndex = shouldRecenter
        ? getCyclicWheelCenterIndex(nextValue, OPTION_LIST_TIME_MINUTES_BASE, OPTION_LIST_TIME_MINUTE_REPEAT)
        : boundedIndex;
      const snappedY = recenteredIndex * OPTION_LIST_WHEEL_ITEM_HEIGHT;

      setMinuteWheelIndex(recenteredIndex);
      setDraftOptionListTime((previous) =>
        previous.minute === nextValue ? previous : { ...previous, minute: nextValue },
      );

      if (Math.abs(offsetY - snappedY) > 0.5) {
        requestAnimationFrame(() => {
          optionListMinuteWheelRef.current?.scrollTo({ y: snappedY, animated: true });
        });
      }
    },
    [],
  );

  const handleOptionListTimeWheelScrollEndDrag = useCallback(
    (
      field: "meridiem" | "hour" | "minute",
      event: NativeSyntheticEvent<NativeScrollEvent>,
    ) => {
      const velocityY = Math.abs(event.nativeEvent.velocity?.y ?? 0);
      if (velocityY > 0.05) {
        return;
      }
      handleOptionListTimeWheelScrollEnd(field, event);
    },
    [handleOptionListTimeWheelScrollEnd],
  );

  const handleSubmitOptionList = useCallback(() => {
    if (optionListKind === "dateTime") {
      if (!isOptionListDateTimeReady) {
        setApiErrorMessage("날짜와 시간을 모두 선택해 주세요.");
        return;
      }

      setApiErrorMessage(null);
      appendDebugLog(
        `action=option-list-datetime-submit | date=${selectedOptionListDate ? formatOptionListDate(selectedOptionListDate) : "-"} | time=${selectedOptionListTime ? formatOptionListTime(selectedOptionListTime) : "-"}`,
        "INFO",
      );
      setOptionListView("overview");
      setOptionListKind("attachment");
      pushAiTurn(
        "자료는 선택사항이에요. 필요한 항목만 선택해 주세요.",
        "mini",
        createOptionListInterface("attachment"),
      );
      return;
    }

      setApiErrorMessage(null);
      appendDebugLog(
        `action=option-list-attachment-submit | noiseLog=${optionListNoiseLogAttachments.length} | audioFile=${optionListAudioFileAttachments.length} | videoFile=${optionListVideoFileAttachments.length}`,
        "INFO",
      );
    markFlowStepCompleted("evidence");
    moveToFlowStep("mediation");
    pushAiTurn(
      "정보를 확인했어요. 다음 진행 방식을 선택해 주세요.",
      "mini",
      createMediationMiniInterface(),
    );
  }, [
    appendDebugLog,
    isOptionListDateTimeReady,
    markFlowStepCompleted,
    moveToFlowStep,
    optionListAudioFileAttachments.length,
    optionListKind,
    optionListNoiseLogAttachments.length,
    optionListVideoFileAttachments.length,
    pushAiTurn,
    selectedOptionListDate,
    selectedOptionListTime,
  ]);

  const ensureCaseId = useCallback(async () => {
    if (caseId) {
      appendDebugLog(`action=create-case | 기존 case 사용 ${caseId}`, "INFO");
      return caseId;
    }

    const requestBody: CreateCaseRequest = {
      scenarioType: "INTER_FLOOR_NOISE",
      housingType: "APARTMENT",
      consentAccepted: true,
    };

    appendDebugLog("action=create-case | 새 케이스 생성 요청", "INFO");
    const createdCase = await apiClient.createCase(requestBody, {
      traceId,
      idempotencyKey: createCaseIdempotencyKeyRef.current,
    });

    if (!createdCase.caseId) {
      throw new Error("민원 케이스 생성에 실패했습니다. 잠시 후 다시 시도해 주세요.");
    }

    setCaseFromCreate(createdCase);
    appendDebugLog(`action=create-case | 생성 성공 ${createdCase.caseId}`, "INFO");
    return createdCase.caseId;
  }, [appendDebugLog, caseId, setCaseFromCreate, traceId]);

  const sendMessageToApi = useCallback(
    async (message: string) => {
      const ensuredCaseId = await ensureCaseId();
      appendDebugLog(`action=intake-message | case=${ensuredCaseId} | message=${message}`, "INFO");

      const intakeResponse = await apiClient.appendIntakeMessage(
        ensuredCaseId,
        {
          role: "USER",
          message,
        },
        { traceId },
      );

      applyIntakeUpdate(intakeResponse);
      appendDebugLog(`action=intake-message | status=${intakeResponse.status}`, "INFO");
      return intakeResponse;
    },
    [appendDebugLog, applyIntakeUpdate, ensureCaseId, traceId],
  );

  const syncFlowWithStatus = useCallback(
    (nextStatus: CaseStatus) => {
      if (nextStatus === "RECEIVED") {
        markFlowStepCompleted("intake");
        moveToFlowStep("classification");
        return;
      }

      if (nextStatus === "CLASSIFIED") {
        markFlowStepCompleted("intake", false);
        markFlowStepCompleted("classification");
        moveToFlowStep("routing");
        return;
      }

      if (nextStatus === "ROUTE_CONFIRMED") {
        markFlowStepCompleted("routing");
        moveToFlowStep("evidence");
        return;
      }

      if (nextStatus === "EVIDENCE_COLLECTING") {
        moveToFlowStep("evidence");
        return;
      }

      if (nextStatus === "FORMAL_SUBMISSION_READY") {
        moveToFlowStep("submission");
      }
    },
    [markFlowStepCompleted, moveToFlowStep],
  );

  const fetchTimelineState = useCallback(
    async (targetCaseId: string) => {
      const timeline = await apiClient.getTimeline(targetCaseId, { traceId });
      const sorted = [...timeline.events].sort(
        (a, b) => new Date(a.occurredAt).getTime() - new Date(b.occurredAt).getTime(),
      );
      setTimelineEvents(sorted);
      appendDebugLog(`action=get-timeline | 이벤트 ${sorted.length}건`, "INFO");
      return sorted;
    },
    [appendDebugLog, setTimelineEvents, traceId],
  );

  const restartFromChat = useCallback(() => {
    setApiErrorMessage(null);
    setDraft("");
    setSelectedMiniOptionIds([]);
    setIsInputFocused(false);
    setIsAiMessageCompleted(false);
    setIsGeneratingReply(false);
    setVisibleSentenceCount(1);
    setOptionListKind("dateTime");
    setOptionListView("overview");
    setSelectedOptionListDate(null);
    setSelectedOptionListTime(null);
    setOptionListAttachments([]);
    setOptionListPickerMonth(toMonthStart(new Date()));
    setDraftOptionListDate(new Date());
    setDraftOptionListTime({
      meridiem: "오후",
      hour: 2,
      minute: 30,
    });
    setMeridiemWheelIndex(getMeridiemWheelInitialIndex("오후"));
    setHourWheelIndex(getCyclicWheelCenterIndex(2, OPTION_LIST_TIME_HOURS_BASE, OPTION_LIST_TIME_HOUR_REPEAT));
    setMinuteWheelIndex(
      getCyclicWheelCenterIndex(30, OPTION_LIST_TIME_MINUTES_BASE, OPTION_LIST_TIME_MINUTE_REPEAT),
    );
    turnSequenceRef.current = 2;
    completedFlowStepsRef.current = new Set();
    setCompletedFlowSteps([]);
    setCurrentFlowStep("intake");
    setIsStepTodoOpen(false);
    setStepToastMessage(null);
    stepToastAnim.setValue(0);

    if (onRestartFlow) {
      onRestartFlow();
      return;
    }

    resetCase();
    setCurrentAiTurn(INITIAL_AI_TURN);
  }, [onRestartFlow, resetCase, stepToastAnim]);

  const handleRequestRouteRecommendation = useCallback(async () => {
    if (isGeneratingReply) {
      return;
    }

    Keyboard.dismiss();
    setIsInputFocused(false);
    setApiErrorMessage(null);
    moveToFlowStep("routing");
    setIsGeneratingReply(true);
    setIsAiMessageCompleted(false);
    setVisibleSentenceCount(0);

    try {
      const ensuredCaseId = await ensureCaseId();
      appendDebugLog(`action=decompose-case | case=${ensuredCaseId}`, "INFO");
      await apiClient.decomposeCase(ensuredCaseId, { traceId });
      appendDebugLog(`action=recommend-route | case=${ensuredCaseId}`, "INFO");
      const recommendation = await apiClient.recommendRoute(ensuredCaseId, { traceId });
      setRoutingRecommendation(recommendation);
      appendDebugLog(`action=recommend-route | 옵션 ${recommendation.options.length}개`, "INFO");

      const miniInterface = mapRoutingRecommendationToMiniInterface(recommendation);
      if (!miniInterface) {
        pushAiTurn("추천 경로를 아직 준비하지 못했어요. 잠시 후 다시 시도해 주세요.", "text", null);
        return;
      }

      pushAiTurn(miniInterface.prompt, "mini", miniInterface);
    } catch (error: unknown) {
      applyApiError(error, "recommend-route");
      pushAiTurn(REQUEST_ERROR_FALLBACK, "text", null);
    } finally {
      setIsGeneratingReply(false);
    }
  }, [applyApiError, appendDebugLog, ensureCaseId, isGeneratingReply, moveToFlowStep, pushAiTurn, setRoutingRecommendation, traceId]);

  const handleSend = useCallback(async () => {
    if (isGeneratingReply) {
      return;
    }

    if (shouldShowMiniInterface) {
      if (selectedMiniOptionIds.length === 0) {
        return;
      }

      Keyboard.dismiss();
      setIsInputFocused(false);

      const selectedOptions = currentMiniOptions.filter((option) =>
        selectedMiniOptionIds.includes(option.id),
      );
      setSelectedMiniOptionIds([]);
      const selectedPrimary = selectedOptions[0];
      const miniContext = currentMiniInterface?.context ?? "intake";

      if (miniContext === "routing") {
        const selectedRouteOption = selectedPrimary;
        if (!selectedRouteOption) {
          return;
        }

        setApiErrorMessage(null);
        setIsGeneratingReply(true);
        setIsAiMessageCompleted(false);
        setVisibleSentenceCount(0);

        try {
          const ensuredCaseId = await ensureCaseId();
          appendDebugLog(`action=confirm-route | case=${ensuredCaseId} | option=${selectedRouteOption.id}`, "INFO");
          const confirmedCase = await apiClient.confirmRouteDecision(
            ensuredCaseId,
            {
              optionId: selectedRouteOption.id,
              userConfirmed: true,
              note: "mobile-chat-route-confirm",
            },
            { traceId },
          );
          applyCaseDetail(confirmedCase);
          appendDebugLog(`action=confirm-route | status=${confirmedCase.status}`, "INFO");
          markFlowStepCompleted("routing");
          moveToFlowStep("evidence");

          const routeConfirmedText =
            confirmedCase.status === "ROUTE_CONFIRMED"
              ? `${selectedRouteOption.label}로 경로를 확정했어요.`
              : "경로를 반영했어요.";
          setOptionListKind("dateTime");
          setOptionListView("overview");
          setSelectedOptionListDate(null);
          setSelectedOptionListTime(null);
          setOptionListAttachments([]);
          pushAiTurn(
            `${routeConfirmedText}\n날짜와 시간을 선택해 주세요.`,
            "mini",
            createOptionListInterface("dateTime"),
          );
          onRouteConfirmed?.();
        } catch (error: unknown) {
          applyApiError(error, "confirm-route");
          pushAiTurn(REQUEST_ERROR_FALLBACK, "text", null);
        } finally {
          setIsGeneratingReply(false);
        }
        return;
      }

      if (miniContext === "optionList") {
        return;
      }

      if (miniContext === "mediation") {
        if (!selectedPrimary) {
          return;
        }

        if (selectedPrimary.id === MEDIATION_OPTION_TRY_FIRST) {
          setMediationDecision("TRY_MEDIATION_FIRST");
          markFlowStepCompleted("mediation");
          moveToFlowStep("submission");
          pushAiTurn(
            "조정 먼저 시도를 선택했어요. 필요하면 바로 제출도 가능해요.",
            "mini",
            createSubmissionMiniInterface(),
          );
          return;
        }

        setMediationDecision("PROCEED_FORMAL_SUBMISSION");
        markFlowStepCompleted("mediation");
        moveToFlowStep("submission");
        pushAiTurn(
          "정식 제출을 선택했어요. 제출 방식을 골라주세요.",
          "mini",
          createSubmissionMiniInterface(),
        );
        return;
      }

      if (miniContext === "submission") {
        if (!selectedPrimary) {
          return;
        }

        const submissionChannel: SubmitCaseRequest["submissionChannel"] =
          selectedPrimary.id === SUBMISSION_OPTION_MANUAL ? "MANUAL_PDF" : "MCP_API";

        setApiErrorMessage(null);
        setIsGeneratingReply(true);
        setIsAiMessageCompleted(false);
        setVisibleSentenceCount(0);

        try {
          const ensuredCaseId = await ensureCaseId();
          appendDebugLog(`action=submit-case | case=${ensuredCaseId} | channel=${submissionChannel}`, "INFO");
          const response = await apiClient.submitCase(
            ensuredCaseId,
            {
              submissionChannel,
              userConsent: true,
              identityVerified: true,
            },
            {
              traceId,
              idempotencyKey: `chat-submit-${ensuredCaseId}-${submissionChannel}`,
            },
          );
          setSubmissionResponse(response);
          appendDebugLog(`action=submit-case | submissionId=${response.submissionId}`, "INFO");
          markFlowStepCompleted("submission");
          moveToFlowStep("tracking");

          const detail = await apiClient.getCase(ensuredCaseId, { traceId });
          applyCaseDetail(detail);
          appendDebugLog(`action=get-case | status=${detail.status}`, "INFO");

          const timeline = await fetchTimelineState(ensuredCaseId);
          const completedEvent = timeline.find((event) => event.eventType === TIMELINE_COMPLETED_EVENT);

          if (completedEvent) {
            markFlowStepCompleted("tracking");
            markFlowStepCompleted("completion");
            moveToFlowStep("completion");
            pushAiTurn(
              "제출과 처리가 모두 완료됐어요.",
              "mini",
              createCompletionMiniInterface(),
            );
          } else {
            pushAiTurn(
              "제출이 접수됐어요. 진행 상태를 확인해 볼까요?",
              "mini",
              createTimelineMiniInterface(timeline[timeline.length - 1]),
            );
          }
        } catch (error: unknown) {
          const code = typeof error === "object" && error !== null ? (error as { code?: string }).code : undefined;
          applyApiError(error, "submit-case");
          if (code === "INSTITUTION_GATEWAY_ERROR" && submissionChannel === "MCP_API") {
            pushAiTurn(
              "기관 연동이 지연돼요. 수동 제출을 선택해 주세요.",
              "mini",
              createSubmissionMiniInterface(true),
            );
          } else {
            pushAiTurn(REQUEST_ERROR_FALLBACK, "text", null);
          }
        } finally {
          setIsGeneratingReply(false);
        }
        return;
      }

      if (miniContext === "timeline") {
        if (!selectedPrimary) {
          return;
        }

        if (selectedPrimary.id === TIMELINE_OPTION_RESTART) {
          restartFromChat();
          return;
        }

        setApiErrorMessage(null);
        setIsGeneratingReply(true);
        setIsAiMessageCompleted(false);
        setVisibleSentenceCount(0);

        try {
          const ensuredCaseId = await ensureCaseId();
          moveToFlowStep("tracking");
          appendDebugLog(`action=get-timeline | case=${ensuredCaseId}`, "INFO");
          const timeline = await fetchTimelineState(ensuredCaseId);
          const completedEvent = timeline.find((event) => event.eventType === TIMELINE_COMPLETED_EVENT);

          if (completedEvent) {
            markFlowStepCompleted("tracking");
            markFlowStepCompleted("completion");
            moveToFlowStep("completion");
            pushAiTurn(
              "민원 처리가 완료됐어요.",
              "mini",
              createCompletionMiniInterface(),
            );
          } else {
            const latestEvent = timeline[timeline.length - 1];
            pushAiTurn(
              latestEvent
                ? `진행 중이에요. 현재 상태: ${compactAiText(latestEvent.title)}`
                : "아직 등록된 진행 이벤트가 없어요. 잠시 후 다시 확인해 주세요.",
              "mini",
              createTimelineMiniInterface(latestEvent),
            );
          }
        } catch (error: unknown) {
          applyApiError(error, "get-timeline");
          pushAiTurn(REQUEST_ERROR_FALLBACK, "text", null);
        } finally {
          setIsGeneratingReply(false);
        }
        return;
      }

      if (miniContext === "completion") {
        if (selectedPrimary?.id === COMPLETION_OPTION_RESTART) {
          restartFromChat();
        }
        return;
      }

      if (selectedOptions.some((option) => option.kind === "other")) {
        setApiErrorMessage(null);
        startGeneratingThenRespond("구체적으로 알려주시겠어요?", "text", 3000);
        return;
      }

      const userMessage = selectedOptions.map((option) => option.label).join(", ");
      setApiErrorMessage(null);
      setIsGeneratingReply(true);
      setIsAiMessageCompleted(false);
      setVisibleSentenceCount(0);

      try {
        const intakeResponse = await sendMessageToApi(userMessage);
        syncFlowWithStatus(intakeResponse.status);
        const aiText = resolveAiTurnText(intakeResponse);
        const nextMiniInterface = mapApiFollowUpInterface(intakeResponse.followUpInterface, aiText);
        pushAiTurn(aiText, nextMiniInterface ? "mini" : "text", nextMiniInterface);
      } catch (error: unknown) {
        applyApiError(error, "mini-intake-send");
        pushAiTurn(REQUEST_ERROR_FALLBACK, "text", null);
      } finally {
        setIsGeneratingReply(false);
      }
      return;
    }

    const trimmed = draft.trim();
    if (!trimmed) {
      return;
    }

    setDraft("");
    Keyboard.dismiss();
    setIsInputFocused(false);

    const debugMiniTurn = createDebugMiniInterfaceInput(trimmed.replace(/\s+/g, ""));
    if (debugMiniTurn) {
      setApiErrorMessage(null);
      if (debugMiniTurn.miniInterface?.context === "optionList") {
        const now = new Date();
        const debugOptionListKind = debugMiniTurn.miniInterface.optionListKind ?? "dateTime";
        setOptionListKind(debugOptionListKind);
        setOptionListView("overview");
        setSelectedOptionListDate(null);
        setSelectedOptionListTime(null);
        setOptionListAttachments([]);
        setOptionListPickerMonth(toMonthStart(now));
        setDraftOptionListDate(now);
        setDraftOptionListTime({
          meridiem: "오후",
          hour: 2,
          minute: 30,
        });
        setMeridiemWheelIndex(getMeridiemWheelInitialIndex("오후"));
        setHourWheelIndex(getCyclicWheelCenterIndex(2, OPTION_LIST_TIME_HOURS_BASE, OPTION_LIST_TIME_HOUR_REPEAT));
        setMinuteWheelIndex(
          getCyclicWheelCenterIndex(30, OPTION_LIST_TIME_MINUTES_BASE, OPTION_LIST_TIME_MINUTE_REPEAT),
        );
      }
      pushAiTurn(debugMiniTurn.text, debugMiniTurn.inputMode, debugMiniTurn.miniInterface);
      return;
    }

    setApiErrorMessage(null);
    setIsGeneratingReply(true);
    setIsAiMessageCompleted(false);
    setVisibleSentenceCount(0);

    try {
      const intakeResponse = await sendMessageToApi(trimmed);
      syncFlowWithStatus(intakeResponse.status);
      const aiText = resolveAiTurnText(intakeResponse);
      const nextMiniInterface = mapApiFollowUpInterface(intakeResponse.followUpInterface, aiText);
      pushAiTurn(aiText, nextMiniInterface ? "mini" : "text", nextMiniInterface);
    } catch (error: unknown) {
      applyApiError(error, "text-intake-send");
      pushAiTurn(REQUEST_ERROR_FALLBACK, "text", null);
    } finally {
      setIsGeneratingReply(false);
    }
  }, [
    applyApiError,
    applyCaseDetail,
    appendDebugLog,
    currentMiniOptions,
    draft,
    ensureCaseId,
    fetchTimelineState,
    isGeneratingReply,
    markFlowStepCompleted,
    miniContext,
    moveToFlowStep,
    onRouteConfirmed,
    pushAiTurn,
    restartFromChat,
    selectedMiniOptionIds,
    sendMessageToApi,
    setMediationDecision,
    setSubmissionResponse,
    syncFlowWithStatus,
    shouldShowMiniInterface,
    startGeneratingThenRespond,
    setApiErrorMessage,
    traceId,
  ]);

  const handleSentenceComplete = useCallback((sentenceIndex: number) => {
    if (sentenceIndex >= aiSentences.length - 1) {
      setIsAiMessageCompleted(true);
      return;
    }
    setVisibleSentenceCount((prev) => Math.max(prev, sentenceIndex + 2));
  }, [aiSentences.length]);

  const sentenceCompleteHandlers = useMemo(
    () => aiSentences.map((_, index) => () => handleSentenceComplete(index)),
    [aiSentences, handleSentenceComplete],
  );

  useEffect(() => {
    const instantMiniReveal =
      currentAiTurn.inputMode === "mini" &&
      currentAiTurn.miniInterface?.context !== "intake";

    setIsAiMessageCompleted(instantMiniReveal);
    setVisibleSentenceCount(aiSentences.length > 0 ? (instantMiniReveal ? aiSentences.length : 1) : 0);
    setDraft("");
    setSelectedMiniOptionIds([]);
    setIsInputFocused(false);
    if (currentAiTurn.miniInterface?.context === "optionList") {
      const nextOptionListKind = currentAiTurn.miniInterface.optionListKind ?? "dateTime";
      const now = new Date();
      setOptionListKind(nextOptionListKind);
      setOptionListView("overview");
      if (nextOptionListKind === "dateTime") {
        setOptionListPickerMonth(toMonthStart(selectedOptionListDate ?? now));
        setDraftOptionListDate(selectedOptionListDate ?? now);
        setDraftOptionListTime(
          selectedOptionListTime ?? {
            meridiem: "오후",
            hour: 2,
            minute: 30,
          },
        );
        const initialTime = selectedOptionListTime ?? {
          meridiem: "오후" as const,
          hour: 2,
          minute: 30,
        };
        setMeridiemWheelIndex(getMeridiemWheelInitialIndex(initialTime.meridiem));
        setHourWheelIndex(
          getCyclicWheelCenterIndex(initialTime.hour, OPTION_LIST_TIME_HOURS_BASE, OPTION_LIST_TIME_HOUR_REPEAT),
        );
        setMinuteWheelIndex(
          getCyclicWheelCenterIndex(initialTime.minute, OPTION_LIST_TIME_MINUTES_BASE, OPTION_LIST_TIME_MINUTE_REPEAT),
        );
      }
    }
  }, [
    aiSentences.length,
    currentAiTurn.id,
    currentAiTurn.inputMode,
    currentAiTurn.miniInterface?.context,
    currentAiTurn.miniInterface?.optionListKind,
  ]);

  useEffect(() => {
    appendDebugLog(`chat-screen mounted | traceId=${traceId}`, "INFO");
  }, [appendDebugLog, traceId]);

  useEffect(
    () => () => {
      if (!replyTimerRef.current) {
        return;
      }
      clearTimeout(replyTimerRef.current);
      replyTimerRef.current = null;
    },
    [],
  );

  useEffect(() => {
    if (!isInputDisabled) {
      return;
    }
    Keyboard.dismiss();
    setIsInputFocused(false);
  }, [isInputDisabled]);

  useEffect(() => {
    const animation = Animated.timing(inputFocusAnim, {
      toValue: isInputFocused ? 1 : 0,
      duration: 180,
      easing: Easing.out(Easing.cubic),
      useNativeDriver: false,
    });
    animation.start();
    return () => animation.stop();
  }, [inputFocusAnim, isInputFocused]);

  useEffect(() => {
    const animateToKeyboard = (event: KeyboardEvent) => {
      const keyboardTop =
        event.endCoordinates.screenY > 0
          ? event.endCoordinates.screenY
          : availableHeight - event.endCoordinates.height;
      const desiredInputBottom = keyboardTop - KEYBOARD_GAP;
      const currentInputBottom = availableHeight - inputBaseBottom;
      const deltaScreen = desiredInputBottom - currentInputBottom;
      const target = Math.min(0, deltaScreen);
      const duration = Math.max(16, event.duration ?? 180);
      const easing = keyboardEasingToAnimated(event.easing);

      Animated.timing(inputKeyboardLift, {
        toValue: target,
        duration,
        easing,
        useNativeDriver: false,
      }).start();
    };

    const animateToBase = (event?: KeyboardEvent) => {
      Animated.timing(inputKeyboardLift, {
        toValue: 0,
        duration: Math.max(16, event?.duration ?? 170),
        easing: keyboardEasingToAnimated(event?.easing),
        useNativeDriver: false,
      }).start();
    };

    if (Platform.OS === "ios") {
      const frameSubscription = Keyboard.addListener("keyboardWillChangeFrame", (event) => {
        if (event.endCoordinates.height <= 0) {
          animateToBase(event);
          return;
        }
        animateToKeyboard(event);
      });

      return () => {
        frameSubscription.remove();
      };
    }

    const showSubscription = Keyboard.addListener("keyboardDidShow", animateToKeyboard);
    const hideSubscription = Keyboard.addListener("keyboardDidHide", animateToBase);

    return () => {
      showSubscription.remove();
      hideSubscription.remove();
    };
  }, [availableHeight, inputBaseBottom, inputKeyboardLift]);

  useEffect(() => {
    const animation = Animated.timing(inputRevealAnim, {
      toValue: isInputDisabled ? 0 : 1,
      duration: isInputDisabled ? 180 : 300,
      easing: Easing.out(Easing.cubic),
      useNativeDriver: false,
    });
    animation.start();
    return () => animation.stop();
  }, [inputRevealAnim, isInputDisabled]);

  useEffect(() => {
    const animation = Animated.timing(miniInterfaceRevealAnim, {
      toValue: shouldShowMiniInterface ? 1 : 0,
      duration: shouldShowMiniInterface ? 280 : 140,
      easing: Easing.out(Easing.cubic),
      useNativeDriver: false,
    });
    animation.start();
    return () => animation.stop();
  }, [miniInterfaceRevealAnim, shouldShowMiniInterface]);

  useEffect(() => {
    if (!shouldShowMiniInterface || miniContext !== "optionList") {
      return;
    }
    optionListFadeAnim.setValue(1);
  }, [optionListFadeAnim, miniContext, shouldShowMiniInterface]);

  useEffect(() => {
    if (optionListView !== "timePicker" || optionListKind !== "dateTime") {
      return;
    }
    const targetDraft = draftOptionListTime;
    const meridiemIndex = getMeridiemWheelInitialIndex(targetDraft.meridiem);
    const hourIndex = getCyclicWheelCenterIndex(
      targetDraft.hour,
      OPTION_LIST_TIME_HOURS_BASE,
      OPTION_LIST_TIME_HOUR_REPEAT,
    );
    const minuteIndex = getCyclicWheelCenterIndex(
      targetDraft.minute,
      OPTION_LIST_TIME_MINUTES_BASE,
      OPTION_LIST_TIME_MINUTE_REPEAT,
    );
    setMeridiemWheelIndex(meridiemIndex);
    setHourWheelIndex(hourIndex);
    setMinuteWheelIndex(minuteIndex);

    requestAnimationFrame(() => {
      optionListMeridiemWheelRef.current?.scrollTo({
        y: meridiemIndex * OPTION_LIST_WHEEL_ITEM_HEIGHT,
        animated: false,
      });
      optionListHourWheelRef.current?.scrollTo({
        y: hourIndex * OPTION_LIST_WHEEL_ITEM_HEIGHT,
        animated: false,
      });
      optionListMinuteWheelRef.current?.scrollTo({
        y: minuteIndex * OPTION_LIST_WHEEL_ITEM_HEIGHT,
        animated: false,
      });
    });
  }, [optionListKind, optionListView]);

  useEffect(() => {
    const animation = Animated.sequence([
      Animated.timing(stepSubtitleAnim, {
        toValue: 0.25,
        duration: 100,
        easing: Easing.in(Easing.cubic),
        useNativeDriver: true,
      }),
      Animated.timing(stepSubtitleAnim, {
        toValue: 1,
        duration: 220,
        easing: Easing.out(Easing.cubic),
        useNativeDriver: true,
      }),
    ]);
    animation.start();
    return () => animation.stop();
  }, [currentFlowStep, stepSubtitleAnim]);

  useEffect(() => {
    const animation = Animated.timing(stepTodoRevealAnim, {
      toValue: isStepTodoOpen ? 1 : 0,
      duration: isStepTodoOpen ? 240 : 160,
      easing: Easing.out(Easing.cubic),
      useNativeDriver: true,
    });
    animation.start();
    return () => animation.stop();
  }, [isStepTodoOpen, stepTodoRevealAnim]);

  const inputStateTranslateY = inputRevealAnim.interpolate({
    inputRange: [0, 1],
    outputRange: [6, 0],
  });

  const inputStateOpacity = inputRevealAnim.interpolate({
    inputRange: [0, 1],
    outputRange: [0.76, 1],
  });

  const inputStateScale = inputRevealAnim.interpolate({
    inputRange: [0, 1],
    outputRange: [0.994, 1],
  });

  const miniInterfaceTranslateY = miniInterfaceRevealAnim.interpolate({
    inputRange: [0, 1],
    outputRange: [16, 0],
  });

  const inputBorderColor = inputFocusAnim.interpolate({
    inputRange: [0, 1],
    outputRange: ["#f3f4f6", "#dbe4eb"],
  });

  const inputBackgroundColor = inputFocusAnim.interpolate({
    inputRange: [0, 1],
    outputRange: ["#ffffff", "#ffffff"],
  });

  const inputScale = inputFocusAnim.interpolate({
    inputRange: [0, 1],
    outputRange: [1, 1.01],
  });

  const inputLift = inputFocusAnim.interpolate({
    inputRange: [0, 1],
    outputRange: [0, -2],
  });

  const inputTranslateY = Animated.add(
    Animated.add(inputLift, inputStateTranslateY),
    inputKeyboardLift,
  );
  const miniInterfaceMotionY = Animated.add(inputTranslateY, miniInterfaceTranslateY);

  const hasSelectedMiniOptions = selectedMiniOptionIds.length > 0;
  const isOptionListMiniInterface = shouldShowMiniInterface && isOptionListMiniContext;
  const isDateTimeOptionList = optionListKind === "dateTime";
  const isSendDisabled = isGeneratingReply ||
    (shouldShowMiniInterface ? (isOptionListMiniInterface ? true : !hasSelectedMiniOptions) : !draft.trim());
  const sendIcon = shouldShowMiniInterface ? "↗" : "›";
  const miniSelectionHint =
    currentMiniInterface?.selectionHint ??
    (currentMiniSelectionMode === "multiple" ? "복수 선택 가능" : "단일 선택");
  const miniCardWidth = "100%";
  const optionListMonthLabel = `${optionListPickerMonth.getFullYear()}년 ${optionListPickerMonth.getMonth() + 1}월`;
  const optionListDraftDateLabel = formatOptionListDate(draftOptionListDate);
  const optionListDraftTimeLabel = formatOptionListTime(draftOptionListTime);
  const optionListPrimaryLabel =
    currentMiniOptions[0]?.label ?? (isDateTimeOptionList ? "발생 날짜" : "소음일지");
  const optionListSecondaryLabel =
    currentMiniOptions[1]?.label ?? (isDateTimeOptionList ? "발생 시간" : "녹음 파일");
  const optionListTertiaryLabel = currentMiniOptions[2]?.label ?? "영상 파일";
  const optionListSubmitLabel =
    isDateTimeOptionList
      ? (currentMiniOptions[2]?.label ?? "정보 확인 및 제출")
      : (currentMiniOptions[3]?.label ?? "선택 완료");
  const isOptionListSubmitEnabled = isDateTimeOptionList ? isOptionListDateTimeReady : true;
  const isOptionListPrimarySelected = isDateTimeOptionList
    ? Boolean(selectedOptionListDate)
    : optionListNoiseLogAttachments.length > 0;
  const isOptionListSecondarySelected = isDateTimeOptionList
    ? Boolean(selectedOptionListTime)
    : optionListAudioFileAttachments.length > 0;
  const isOptionListTertiarySelected = optionListVideoFileAttachments.length > 0;
  const optionListCalendarCellSize = Math.max(34, Math.floor((contentWidth - 40) / 7));
  const optionListCalendarGridWidth = optionListCalendarCellSize * 7;
  const debugLogsToRender = debugLogs.slice(0, 8);
  const isDebugMode = __DEV__;
  const inputPlaceholder = isGeneratingReply
    ? "답변을 준비하는 중입니다..."
    : shouldShowMiniInterface
      ? (isOptionListMiniInterface
          ? (isDateTimeOptionList ? "날짜와 시간을 선택해 주세요." : "자료 항목을 선택해 주세요.")
          : "항목을 선택해 주세요.")
      : "답변 입력 또는 음성으로 말하기";
  const isBackgroundDismissEnabled = isInputFocused && !shouldShowMiniInterface;
  const backButtonScale = backButtonPressAnim.interpolate({
    inputRange: [0, 1],
    outputRange: [1, 0.97],
  });
  const backButtonIconOpacity = backButtonPressAnim.interpolate({
    inputRange: [0, 1],
    outputRange: [1, 0.92],
  });
  const backButtonIconScale = backButtonPressAnim.interpolate({
    inputRange: [0, 1],
    outputRange: [1, 0.94],
  });
  const backButtonCircleOpacity = backButtonPressAnim.interpolate({
    inputRange: [0, 1],
    outputRange: [0, 1],
  });
  const backButtonCircleScale = backButtonPressAnim.interpolate({
    inputRange: [0, 1],
    outputRange: [0.86, 1],
  });

  return (
    <View style={styles.safeArea}>
      <Animated.View
        style={[
          styles.frame,
          {
            width: availableWidth,
            height: availableHeight,
          },
        ]}
      >
        {isBackgroundDismissEnabled ? (
          <Pressable
            style={StyleSheet.absoluteFill}
            onPress={dismissKeyboard}
            accessibilityRole="button"
            accessibilityLabel="키보드 닫기"
          />
        ) : null}

        <Animated.View
          style={[
            styles.backButton,
            {
              left: 16,
              top: 17 + topInsetOffset,
              width: 40,
              height: 40,
              borderRadius: 20,
              transform: [{ scale: backButtonScale }],
            },
          ]}
        >
          <Animated.View
            pointerEvents="none"
            style={[
              styles.backButtonCircle,
              {
                opacity: backButtonCircleOpacity,
                transform: [{ scale: backButtonCircleScale }],
              },
            ]}
          />
          <Pressable
            onPress={handleBackPress}
            onPressIn={handleBackPressIn}
            onPressOut={handleBackPressOut}
            hitSlop={12}
            style={styles.backButtonHit}
          >
            <Animated.Text
              style={[
                styles.backIcon,
                {
                  fontSize: 44,
                  lineHeight: 40,
                  opacity: backButtonIconOpacity,
                  transform: [{ scale: backButtonIconScale }],
                },
              ]}
            >
              {"‹"}
            </Animated.Text>
          </Pressable>
        </Animated.View>

        <Text
          pointerEvents="none"
          style={[
            styles.chatTitle,
            {
              left: 0,
              top: 23 + topInsetOffset,
              width: availableWidth,
              fontSize: 18,
              lineHeight: 28,
            },
          ]}
        >
          층간소음 상담
        </Text>

        {isDebugMode ? (
          <>
            <Pressable
              onPress={toggleDebugLog}
              style={[
                styles.debugToggle,
                {
                  right: horizontalPadding,
                  top: 21 + topInsetOffset,
                },
              ]}
            >
              <Text style={styles.debugToggleText}>
                {isDebugLogOpen ? "로그 닫기" : "로그 보기"}
              </Text>
            </Pressable>

            {isDebugLogOpen ? (
              <View
                style={[
                  styles.debugPanel,
                  {
                    right: horizontalPadding,
                    top: 56 + topInsetOffset,
                    width: Math.min(320, contentWidth),
                  },
                ]}
              >
                <Text style={styles.debugPanelTitle}>API 로그</Text>
                {debugLogsToRender.length === 0 ? (
                  <Text style={styles.debugPanelEmpty}>아직 로그가 없어요.</Text>
                ) : (
                  debugLogsToRender.map((entry) => (
                    <Text
                      key={entry.id}
                      style={[
                        styles.debugPanelLine,
                        entry.level === "ERROR" && styles.debugPanelLineError,
                      ]}
                      numberOfLines={2}
                    >
                      [{entry.timestamp}] {entry.message}
                    </Text>
                  ))
                )}
              </View>
            ) : null}
          </>
        ) : null}

        <View
          style={[
            styles.topMessageContainer,
            {
              left: horizontalPadding,
              top: 136 + topInsetOffset,
              width: contentWidth,
              height: 420,
            },
          ]}
        >
          {isGeneratingReply ? (
            <ThinkingWaveText
              text={THINKING_TEXT}
              style={[
                styles.thinkingMessage,
                {
                  fontSize: 28,
                  lineHeight: 38.5,
                },
              ]}
            />
          ) : (
            aiSentences.slice(0, visibleSentenceCount).map((sentence, index) => (
              <TypewriterText
                key={`${currentAiTurn.id}-sentence-${index}`}
                text={sentence}
                animationKey={`${currentAiTurn.id}-sentence-${index}`}
                revealMode="fade"
                fadeBy="full"
                fadeInDurationMs={460}
                onComplete={sentenceCompleteHandlers[index]}
                style={[
                  styles.topMessage,
                  {
                    fontSize: 28,
                    lineHeight: 38.5,
                    marginBottom: index < visibleSentenceCount - 1 ? 8 : 0,
                  },
                ]}
              />
            ))
          )}
        </View>

        {apiErrorMessage ? (
          <Text
            style={[
              styles.apiErrorText,
              {
                left: 28,
                bottom: 170,
                width: 337,
                fontSize: 12,
                lineHeight: 16,
              },
            ]}
          >
            {apiErrorMessage}
          </Text>
        ) : null}

        {shouldShowRouteRecommendationAction ? (
          <Pressable
            onPress={handleRequestRouteRecommendation}
            style={({ pressed }) => [
              styles.routeActionCard,
              {
                left: horizontalPadding,
                bottom: miniPanelBottom,
                width: contentWidth,
                borderRadius: 16,
                opacity: pressed ? 0.88 : 1,
              },
            ]}
          >
            <Text style={[styles.routeActionTitle, { fontSize: 16, lineHeight: 24 }]}>추천 경로 확인하기</Text>
          </Pressable>
        ) : null}

        {shouldShowMiniInterface ? (
          <Animated.View
            style={[
              styles.miniInterfaceWrap,
              isOptionListMiniContext && styles.miniInterfaceWrapEvidence,
              {
                left: horizontalPadding,
                bottom: miniPanelBottom,
                width: contentWidth,
                borderRadius: 24,
                ...(isOptionListMiniContext
                  ? {
                      opacity: 1,
                    }
                  : {
                      opacity: miniInterfaceRevealAnim,
                      transform: [{ translateY: miniInterfaceMotionY }],
                    }),
              },
            ]}
          >
            {miniInterfaceType === "OptionList" ? (
              <Animated.View
                style={{
                  opacity: optionListFadeAnim,
                }}
              >
                <Text style={[styles.miniSelectionHint, { fontSize: 12, lineHeight: 15 }]} allowFontScaling={false}>
                  {optionListView === "overview"
                    ? (isDateTimeOptionList ? "날짜 및 시간 선택" : "자료 선택")
                    : optionListView === "datePicker"
                      ? "날짜 선택"
                      : "시간 선택"}
                </Text>

                {optionListView === "overview" ? (
                  <View style={styles.evidenceChecklistBlock}>
                    <OptionListSelectableRow
                      selected={isOptionListPrimarySelected}
                      onPress={() => {
                        if (isDateTimeOptionList) {
                          handleOpenOptionListDatePicker();
                          return;
                        }
                        void handleOpenOptionListAttachmentPicker("NOISE_LOG");
                      }}
                    >
                      <View style={styles.evidenceDateTimeIconSurface}>
                        <EvidenceCalendarIcon />
                      </View>
                      <View style={styles.evidenceDateTimeTextWrap}>
                        <Text style={styles.evidenceDateTimeLabel} allowFontScaling={false}>
                          {optionListPrimaryLabel}
                        </Text>
                        <Text style={styles.evidenceDateTimeValue} allowFontScaling={false}>
                          {isDateTimeOptionList ? optionListDateLabel : optionListNoiseLogLabel}
                        </Text>
                      </View>
                    </OptionListSelectableRow>
                    {isOptionListPrimarySelected ? (
                      <MiniAnimatedPressable
                        style={styles.evidenceInlineResetButton}
                        onPress={() => {
                          if (isDateTimeOptionList) {
                            setSelectedOptionListDate(null);
                          } else {
                            setOptionListAttachments((previous) =>
                              previous.filter((item) => item.type !== "NOISE_LOG"),
                            );
                          }
                          setApiErrorMessage(null);
                        }}
                      >
                        <Text style={styles.evidenceInlineResetButtonText} allowFontScaling={false}>
                          선택 해제
                        </Text>
                      </MiniAnimatedPressable>
                    ) : null}

                    <View style={styles.evidenceDateTimeDivider} />

                    <OptionListSelectableRow
                      selected={isOptionListSecondarySelected}
                      onPress={() => {
                        if (isDateTimeOptionList) {
                          handleOpenOptionListTimePicker();
                          return;
                        }
                        void handleOpenOptionListAttachmentPicker("AUDIO_FILE");
                      }}
                    >
                      <View style={styles.evidenceDateTimeIconSurface}>
                        {isDateTimeOptionList ? <EvidenceClockIcon /> : <EvidenceMicIcon />}
                      </View>
                      <View style={styles.evidenceDateTimeTextWrap}>
                        <Text style={styles.evidenceDateTimeLabel} allowFontScaling={false}>
                          {optionListSecondaryLabel}
                        </Text>
                        <Text style={styles.evidenceDateTimeValue} allowFontScaling={false}>
                          {isDateTimeOptionList ? optionListTimeLabel : optionListAudioFileLabel}
                        </Text>
                      </View>
                    </OptionListSelectableRow>
                    {isOptionListSecondarySelected ? (
                      <MiniAnimatedPressable
                        style={styles.evidenceInlineResetButton}
                        onPress={() => {
                          if (isDateTimeOptionList) {
                            setSelectedOptionListTime(null);
                          } else {
                            setOptionListAttachments((previous) =>
                              previous.filter((item) => item.type !== "AUDIO_FILE"),
                            );
                          }
                          setApiErrorMessage(null);
                        }}
                      >
                        <Text style={styles.evidenceInlineResetButtonText} allowFontScaling={false}>
                          선택 해제
                        </Text>
                      </MiniAnimatedPressable>
                    ) : null}

                    {!isDateTimeOptionList ? (
                      <>
                        <View style={styles.evidenceDateTimeDivider} />
                        <OptionListSelectableRow
                          selected={isOptionListTertiarySelected}
                          onPress={() => {
                            void handleOpenOptionListAttachmentPicker("VIDEO_FILE");
                          }}
                        >
                          <View style={styles.evidenceDateTimeIconSurface}>
                            <EvidenceVideoIcon />
                          </View>
                          <View style={styles.evidenceDateTimeTextWrap}>
                            <Text style={styles.evidenceDateTimeLabel} allowFontScaling={false}>
                              {optionListTertiaryLabel}
                            </Text>
                            <Text style={styles.evidenceDateTimeValue} allowFontScaling={false}>
                              {optionListVideoFileLabel}
                            </Text>
                          </View>
                        </OptionListSelectableRow>
                        {isOptionListTertiarySelected ? (
                          <MiniAnimatedPressable
                            style={styles.evidenceInlineResetButton}
                            onPress={() => {
                              setOptionListAttachments((previous) =>
                                previous.filter((item) => item.type !== "VIDEO_FILE"),
                              );
                              setApiErrorMessage(null);
                            }}
                          >
                            <Text style={styles.evidenceInlineResetButtonText} allowFontScaling={false}>
                              선택 해제
                            </Text>
                          </MiniAnimatedPressable>
                        ) : null}
                      </>
                    ) : null}

                    <MiniAnimatedPressable
                      style={[
                        styles.evidenceActionButton,
                        isOptionListSubmitEnabled
                          ? styles.evidenceActionButtonActive
                          : styles.evidenceActionButtonSkip,
                      ]}
                      onPress={handleSubmitOptionList}
                      disabled={!isOptionListSubmitEnabled}
                    >
                      <Text
                        style={[
                          styles.evidenceActionButtonText,
                          isOptionListSubmitEnabled
                            ? styles.evidenceActionButtonTextActive
                            : styles.evidenceActionButtonTextSkip,
                        ]}
                        allowFontScaling={false}
                      >
                        {optionListSubmitLabel}
                      </Text>
                    </MiniAnimatedPressable>
                  </View>
                ) : null}

                {isDateTimeOptionList && optionListView === "datePicker" ? (
                  <View style={styles.evidencePickerPanel}>
                    <MiniAnimatedPressable
                      style={styles.evidencePickerBackButton}
                      onPress={() => transitionOptionListView("overview")}
                    >
                      <Text style={styles.evidencePickerBackText} allowFontScaling={false}>
                        {"‹ 이전 단계"}
                      </Text>
                    </MiniAnimatedPressable>

                    <View style={styles.evidencePickerMonthRow}>
                      <MiniAnimatedPressable
                        style={styles.evidenceMonthNavButton}
                        onPress={() => setOptionListPickerMonth((previous) => addMonth(previous, -1))}
                      >
                        <Text style={styles.evidenceMonthNavText} allowFontScaling={false}>
                          {"‹"}
                        </Text>
                      </MiniAnimatedPressable>
                      <Text style={styles.optionListMonthLabel} allowFontScaling={false}>
                        {optionListMonthLabel}
                      </Text>
                      <MiniAnimatedPressable
                        style={styles.evidenceMonthNavButton}
                        onPress={() => setOptionListPickerMonth((previous) => addMonth(previous, 1))}
                      >
                        <Text style={styles.evidenceMonthNavText} allowFontScaling={false}>
                          {"›"}
                        </Text>
                      </MiniAnimatedPressable>
                    </View>

                    <View style={styles.evidenceWeekdayRow}>
                      {KO_WEEKDAYS.map((weekday) => (
                        <Text key={weekday} style={styles.evidenceWeekdayText} allowFontScaling={false}>
                          {weekday}
                        </Text>
                      ))}
                    </View>

                    <View style={[styles.evidenceCalendarGrid, { width: optionListCalendarGridWidth }]}>
                      {optionListCalendarCells.map((cellDate, index) => {
                        if (!cellDate) {
                          return (
                            <View
                              key={`empty-${index}`}
                              style={[
                                styles.evidenceCalendarCellEmpty,
                                {
                                  width: optionListCalendarCellSize,
                                  height: optionListCalendarCellSize,
                                },
                              ]}
                            />
                          );
                        }

                        const isSelected = isSameDate(cellDate, draftOptionListDate);
                        return (
                          <Pressable
                            key={cellDate.toISOString()}
                            onPress={() => setDraftOptionListDate(cellDate)}
                            style={({ pressed }) => [
                              styles.evidenceCalendarCell,
                              isSelected && styles.evidenceCalendarCellSelected,
                              pressed && styles.evidenceCalendarCellPressed,
                              {
                                width: optionListCalendarCellSize,
                                height: optionListCalendarCellSize,
                              },
                            ]}
                          >
                            <Text
                              style={[
                                styles.evidenceCalendarCellText,
                                isSelected && styles.evidenceCalendarCellTextSelected,
                              ]}
                              allowFontScaling={false}
                            >
                              {cellDate.getDate()}
                            </Text>
                          </Pressable>
                        );
                      })}
                    </View>

                    <View style={styles.evidencePickerSummary}>
                      <Text style={styles.evidencePickerSummaryLabel} allowFontScaling={false}>
                        선택된 날짜
                      </Text>
                      <Text style={styles.evidencePickerSummaryValue} allowFontScaling={false}>
                        {optionListDraftDateLabel}
                      </Text>
                    </View>

                    <MiniAnimatedPressable
                      style={[styles.evidenceActionButton, styles.evidenceActionButtonActive]}
                      onPress={() => {
                        setSelectedOptionListDate(draftOptionListDate);
                        transitionOptionListView("overview");
                        setApiErrorMessage(null);
                      }}
                    >
                      <Text
                        style={[styles.evidenceActionButtonText, styles.evidenceActionButtonTextActive]}
                        allowFontScaling={false}
                      >
                        날짜 선택 완료
                      </Text>
                    </MiniAnimatedPressable>
                  </View>
                ) : null}

                {isDateTimeOptionList && optionListView === "timePicker" ? (
                  <View style={styles.evidencePickerPanel}>
                    <MiniAnimatedPressable
                      style={styles.evidencePickerBackButton}
                      onPress={() => transitionOptionListView("overview")}
                    >
                      <Text style={styles.evidencePickerBackText} allowFontScaling={false}>
                        {"‹ 이전 단계"}
                      </Text>
                    </MiniAnimatedPressable>

                    <View style={styles.evidenceTimeWheelRow}>
                      <View style={styles.evidenceTimeWheelColumn}>
                        <View style={styles.evidenceTimeWheelCenterBar} pointerEvents="none" />
                        <ScrollView
                          ref={optionListMeridiemWheelRef}
                          style={styles.evidenceTimeWheelScroll}
                          contentContainerStyle={styles.evidenceTimeWheelContent}
                          scrollEnabled
                          showsVerticalScrollIndicator={false}
                          keyboardShouldPersistTaps="handled"
                          snapToInterval={OPTION_LIST_WHEEL_ITEM_HEIGHT}
                          snapToAlignment="start"
                          decelerationRate="normal"
                          nestedScrollEnabled
                          bounces={false}
                          scrollEventThrottle={16}
                          onScrollEndDrag={(event) =>
                            handleOptionListTimeWheelScrollEndDrag("meridiem", event)
                          }
                          onMomentumScrollEnd={(event) => handleOptionListTimeWheelScrollEnd("meridiem", event)}
                        >
                          {OPTION_LIST_TIME_MERIDIEM_WHEEL.map((meridiem, index) => {
                            const isSelected = index === meridiemWheelIndex;
                            return (
                              <View key={`${meridiem}-${index}`} style={styles.evidenceTimeWheelItem}>
                                <Text
                                  style={[
                                    styles.evidenceTimeWheelDimText,
                                    !meridiem && styles.evidenceTimeWheelSpacerText,
                                    isSelected && styles.evidenceTimeWheelActiveText,
                                  ]}
                                  allowFontScaling={false}
                                >
                                  {meridiem ?? ""}
                                </Text>
                              </View>
                            );
                          })}
                        </ScrollView>
                      </View>

                      <View style={styles.evidenceTimeWheelColumn}>
                        <View style={styles.evidenceTimeWheelCenterBar} pointerEvents="none" />
                        <ScrollView
                          ref={optionListHourWheelRef}
                          style={styles.evidenceTimeWheelScroll}
                          contentContainerStyle={styles.evidenceTimeWheelContent}
                          scrollEnabled
                          showsVerticalScrollIndicator={false}
                          keyboardShouldPersistTaps="handled"
                          snapToInterval={OPTION_LIST_WHEEL_ITEM_HEIGHT}
                          decelerationRate="normal"
                          nestedScrollEnabled
                          bounces={false}
                          scrollEventThrottle={16}
                          onScrollEndDrag={(event) =>
                            handleOptionListTimeWheelScrollEndDrag("hour", event)
                          }
                          onMomentumScrollEnd={(event) => handleOptionListTimeWheelScrollEnd("hour", event)}
                        >
                          {OPTION_LIST_TIME_HOURS_WHEEL.map((hour, index) => {
                            const isSelected = index === hourWheelIndex;
                            return (
                              <View key={`${hour}-${index}`} style={styles.evidenceTimeWheelItem}>
                                <Text
                                  style={[
                                    styles.evidenceTimeWheelDimText,
                                    isSelected && styles.evidenceTimeWheelActiveText,
                                  ]}
                                  allowFontScaling={false}
                                >
                                  {hour.toString().padStart(2, "0")}
                                </Text>
                              </View>
                            );
                          })}
                        </ScrollView>
                      </View>

                      <View style={styles.evidenceTimeWheelColumn}>
                        <View style={styles.evidenceTimeWheelCenterBar} pointerEvents="none" />
                        <ScrollView
                          ref={optionListMinuteWheelRef}
                          style={styles.evidenceTimeWheelScroll}
                          contentContainerStyle={styles.evidenceTimeWheelContent}
                          scrollEnabled
                          showsVerticalScrollIndicator={false}
                          keyboardShouldPersistTaps="handled"
                          snapToInterval={OPTION_LIST_WHEEL_ITEM_HEIGHT}
                          decelerationRate="normal"
                          nestedScrollEnabled
                          bounces={false}
                          scrollEventThrottle={16}
                          onScrollEndDrag={(event) =>
                            handleOptionListTimeWheelScrollEndDrag("minute", event)
                          }
                          onMomentumScrollEnd={(event) => handleOptionListTimeWheelScrollEnd("minute", event)}
                        >
                          {OPTION_LIST_TIME_MINUTES_WHEEL.map((minute, index) => {
                            const isSelected = index === minuteWheelIndex;
                            return (
                              <View key={`${minute}-${index}`} style={styles.evidenceTimeWheelItem}>
                                <Text
                                  style={[
                                    styles.evidenceTimeWheelDimText,
                                    isSelected && styles.evidenceTimeWheelActiveText,
                                  ]}
                                  allowFontScaling={false}
                                >
                                  {minute.toString().padStart(2, "0")}
                                </Text>
                              </View>
                            );
                          })}
                        </ScrollView>
                      </View>
                    </View>

                    <View style={styles.evidencePickerSummary}>
                      <Text style={styles.evidencePickerSummaryLabel} allowFontScaling={false}>
                        선택된 시간
                      </Text>
                      <Text style={styles.evidencePickerSummaryValue} allowFontScaling={false}>
                        {optionListDraftTimeLabel}
                      </Text>
                    </View>

                    <MiniAnimatedPressable
                      style={[styles.evidenceActionButton, styles.evidenceActionButtonActive]}
                      onPress={() => {
                        setSelectedOptionListTime(draftOptionListTime);
                        transitionOptionListView("overview");
                        setApiErrorMessage(null);
                      }}
                    >
                      <Text
                        style={[styles.evidenceActionButtonText, styles.evidenceActionButtonTextActive]}
                        allowFontScaling={false}
                      >
                        시간 선택 완료
                      </Text>
                    </MiniAnimatedPressable>
                  </View>
                ) : null}
              </Animated.View>
            ) : miniInterfaceType === "ListPicker" ? (
              <>
                <Text style={[styles.miniSelectionHint, { fontSize: 12, lineHeight: 15 }]}>
                  {miniSelectionHint}
                </Text>
                <View style={styles.miniCardGrid}>
                  {currentMiniOptions.map((option, index) => {
                    const isSelected = selectedMiniOptionIds.includes(option.id);
                    const appearStart = Math.min(0.7, 0.18 + index * 0.12);
                    const cardOpacity = miniInterfaceRevealAnim.interpolate({
                      inputRange: [0, appearStart, 1],
                      outputRange: [0, 0, 1],
                      extrapolate: "clamp",
                    });
                    const cardTranslateY = miniInterfaceRevealAnim.interpolate({
                      inputRange: [0, 1],
                      outputRange: [12 + index * 4, 0],
                      extrapolate: "clamp",
                    });
                    const cardScale = miniInterfaceRevealAnim.interpolate({
                      inputRange: [0, 1],
                      outputRange: [0.985, 1],
                      extrapolate: "clamp",
                    });
                    return (
                      <Animated.View
                        key={option.id}
                        style={{
                          width: miniCardWidth,
                          opacity: cardOpacity,
                          transform: [{ translateY: cardTranslateY }, { scale: cardScale }],
                        }}
                      >
                        <MiniAnimatedPressable
                          style={[
                            styles.miniTaskCard,
                            isSelected && styles.miniTaskCardSelected,
                          ]}
                          onPress={() => handleMiniOptionPress(option)}
                        >
                          <Text
                            style={[
                              styles.miniTaskCardTitle,
                              isSelected && styles.miniTaskCardTitleSelected,
                              { fontSize: 16, lineHeight: 24 },
                            ]}
                          >
                            {`${index + 1}번 ${option.label}`}
                          </Text>
                        </MiniAnimatedPressable>
                      </Animated.View>
                    );
                  })}
                </View>
              </>
            ) : null}
          </Animated.View>
        ) : null}

        <Animated.View
          style={[
            styles.inputWrap,
            {
              left: horizontalPadding,
              bottom: inputBaseBottom,
              width: contentWidth,
              height: 56,
              borderRadius: 28,
              borderWidth: 1,
              paddingLeft: 24,
              paddingRight: 8,
              borderColor: isInputDisabled ? "#f3f4f6" : inputBorderColor,
              backgroundColor: isInputDisabled ? "#f9fafb" : inputBackgroundColor,
              opacity: inputStateOpacity,
              transform: [{ translateY: inputTranslateY }, { scale: inputScale }, { scale: inputStateScale }],
            },
          ]}
        >
          <TextInput
            style={[
              styles.input,
              isInputDisabled && styles.inputDisabled,
              {
                fontSize: 16,
                lineHeight: 20,
                marginRight: 6,
              },
            ]}
            placeholder={inputPlaceholder}
            placeholderTextColor={isInputDisabled ? "#9ca3af" : "#9ca3af"}
            value={draft}
            onChangeText={setDraft}
            onSubmitEditing={handleSend}
            onFocus={() => setIsInputFocused(true)}
            onBlur={() => setIsInputFocused(false)}
            returnKeyType="send"
            editable={!isInputDisabled}
            allowFontScaling={false}
          />
          <Pressable
            style={({ pressed }) => [
              styles.sendButton,
              {
                width: 40,
                height: 40,
              },
              isSendDisabled && styles.sendButtonDisabled,
              pressed && !isSendDisabled && styles.sendButtonPressed,
            ]}
            onPress={handleSend}
            disabled={isSendDisabled}
          >
            <Text
              style={[
                styles.sendText,
                shouldShowMiniInterface
                  ? { fontSize: 20, lineHeight: 22 }
                  : { fontSize: 26, lineHeight: 28 },
              ]}
              allowFontScaling={false}
            >
              {sendIcon}
            </Text>
          </Pressable>
        </Animated.View>
      </Animated.View>
    </View>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: "#ffffff",
  },
  frame: {
    position: "relative",
    backgroundColor: "#ffffff",
    overflow: "hidden",
  },
  backButton: {
    position: "absolute",
    zIndex: 20,
  },
  backButtonCircle: {
    ...StyleSheet.absoluteFillObject,
    borderRadius: 999,
    borderWidth: 1,
    borderColor: "#e5edf4",
    backgroundColor: "#ffffff",
    shadowColor: "#111827",
    shadowOpacity: 0.08,
    shadowRadius: 6,
    shadowOffset: { width: 0, height: 2 },
    elevation: 6,
  },
  backButtonHit: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
  },
  backIcon: {
    color: "#1f2937",
    fontWeight: "400",
  },
  chatTitle: {
    position: "absolute",
    color: "#111827",
    fontWeight: "700",
    textAlign: "center",
  },
  stepSubtitleWrap: {
    position: "absolute",
    left: 0,
    width: BASE_WIDTH,
    alignItems: "center",
  },
  stepSubtitleButton: {
    flexDirection: "row",
    alignItems: "center",
    borderRadius: 999,
    borderWidth: 1,
    borderColor: "#dbeafe",
    backgroundColor: "#f8fbff",
    paddingHorizontal: 12,
    paddingVertical: 6,
  },
  stepSubtitleText: {
    color: "#1d4ed8",
    fontWeight: "700",
  },
  stepSubtitleAction: {
    color: "#64748b",
    fontWeight: "600",
    marginLeft: 8,
  },
  stepTodoPanel: {
    position: "absolute",
    left: 72,
    width: 249,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: "#dbeafe",
    backgroundColor: "#ffffff",
    paddingHorizontal: 12,
    paddingVertical: 10,
    shadowColor: "#0f172a",
    shadowOpacity: 0.08,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: 4 },
  },
  stepTodoRow: {
    flexDirection: "row",
    alignItems: "center",
    marginVertical: 2,
  },
  stepTodoDot: {
    width: 14,
    color: "#94a3b8",
    fontSize: 12,
    lineHeight: 16,
    fontWeight: "700",
  },
  stepTodoDotDone: {
    color: "#2563eb",
  },
  stepTodoDotCurrent: {
    color: "#0f172a",
  },
  stepTodoText: {
    color: "#64748b",
    fontSize: 12,
    lineHeight: 16,
    fontWeight: "600",
    marginLeft: 6,
  },
  stepTodoTextDone: {
    color: "#2563eb",
  },
  stepTodoTextCurrent: {
    color: "#0f172a",
  },
  topMessageContainer: {
    position: "absolute",
  },
  topMessage: {
    color: "#2d5d7b",
    fontWeight: "500",
  },
  thinkingMessage: {
    color: "#9ca3af",
    fontWeight: "500",
  },
  stepToast: {
    position: "absolute",
    borderRadius: 16,
    borderWidth: 1,
    borderColor: "#bfdbfe",
    backgroundColor: "#eff6ff",
    paddingHorizontal: 14,
    paddingVertical: 10,
    alignItems: "center",
  },
  stepToastText: {
    color: "#1d4ed8",
    fontWeight: "700",
    textAlign: "center",
  },
  apiErrorText: {
    position: "absolute",
    color: "#dc2626",
    fontWeight: "500",
  },
  debugToggle: {
    position: "absolute",
    zIndex: 25,
    borderRadius: 999,
    borderWidth: 1,
    borderColor: "#dbeafe",
    backgroundColor: "#f8fbff",
    paddingHorizontal: 10,
    paddingVertical: 6,
  },
  debugToggleText: {
    color: "#1d4ed8",
    fontSize: 11,
    lineHeight: 14,
    fontWeight: "700",
  },
  debugPanel: {
    position: "absolute",
    zIndex: 24,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: "#dbeafe",
    backgroundColor: "#ffffff",
    paddingHorizontal: 10,
    paddingVertical: 8,
    shadowColor: "#0f172a",
    shadowOpacity: 0.08,
    shadowRadius: 8,
    shadowOffset: { width: 0, height: 3 },
    elevation: 4,
  },
  debugPanelTitle: {
    color: "#1e293b",
    fontSize: 11,
    lineHeight: 14,
    fontWeight: "700",
    marginBottom: 4,
  },
  debugPanelEmpty: {
    color: "#64748b",
    fontSize: 11,
    lineHeight: 14,
    fontWeight: "500",
  },
  debugPanelLine: {
    color: "#334155",
    fontSize: 10,
    lineHeight: 13,
    fontWeight: "500",
    marginTop: 2,
  },
  debugPanelLineError: {
    color: "#b91c1c",
  },
  routeActionCard: {
    position: "absolute",
    borderWidth: 1,
    borderColor: "#eaf1f5",
    backgroundColor: "#ffffff",
    paddingHorizontal: 18,
    paddingVertical: 16,
    justifyContent: "center",
    shadowColor: "#111827",
    shadowOpacity: 0.05,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: 6 },
    elevation: 2,
  },
  routeActionTitle: {
    color: "#1f2937",
    fontWeight: "500",
  },
  routeActionSubtitle: {
    color: "#475569",
    fontWeight: "500",
    marginTop: 4,
  },
  inputWrap: {
    position: "absolute",
    borderColor: "#f3f4f6",
    backgroundColor: "#ffffff",
    flexDirection: "row",
    alignItems: "center",
    shadowColor: "#111827",
    shadowOpacity: 0.06,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: 6 },
    elevation: 3,
  },
  input: {
    flex: 1,
    color: "#374151",
    fontWeight: "400",
  },
  inputDisabled: {
    color: "#9ca3af",
  },
  sendButton: {
    borderRadius: 999,
    backgroundColor: "#2d5d7b",
    alignItems: "center",
    justifyContent: "center",
  },
  sendButtonDisabled: {
    backgroundColor: "#cddae2",
  },
  sendButtonPressed: {
    backgroundColor: "#264f68",
  },
  sendText: {
    color: "#ffffff",
    fontWeight: "500",
  },
  miniInterfaceWrap: {
    position: "absolute",
    borderWidth: 1,
    borderColor: "#eaf1f5",
    backgroundColor: "#ffffff",
    paddingHorizontal: 20,
    paddingTop: 20,
    paddingBottom: 20,
    shadowColor: "#111827",
    shadowOpacity: 0.05,
    shadowRadius: 12,
    shadowOffset: { width: 0, height: 6 },
    elevation: 2,
  },
  miniInterfaceWrapEvidence: {
    borderColor: "rgba(45,93,123,0.1)",
    shadowOpacity: 0.08,
    shadowRadius: 14,
    shadowOffset: { width: 0, height: 8 },
    elevation: 3,
  },
  miniSelectionHint: {
    color: "#9ca3af",
    fontWeight: "500",
    marginBottom: 8,
    marginLeft: 2,
  },
  evidenceChecklistItem: {
    marginTop: 8,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: "#f3f4f6",
    backgroundColor: "#ffffff",
    paddingHorizontal: 14,
    paddingVertical: 12,
    flexDirection: "row",
    alignItems: "center",
  },
  evidenceChecklistBlock: {
    marginTop: 4,
  },
  evidenceDateTimeRow: {
    borderRadius: 12,
    paddingVertical: 8,
    flexDirection: "row",
    alignItems: "center",
    minHeight: 54,
  },
  evidenceDateTimeIconSurface: {
    width: 40,
    height: 40,
    borderRadius: 12,
    backgroundColor: "rgba(45,93,123,0.05)",
    alignItems: "center",
    justifyContent: "center",
  },
  evidenceDateTimeTextWrap: {
    marginLeft: 12,
    flex: 1,
  },
  evidenceDateTimeLabel: {
    color: "#64748b",
    fontSize: 12,
    lineHeight: 16,
    fontWeight: "500",
    letterSpacing: 0.6,
  },
  evidenceDateTimeValue: {
    marginTop: 4,
    color: "#0f172a",
    fontSize: 16,
    lineHeight: 24,
    fontWeight: "700",
  },
  evidenceDateTimeDivider: {
    marginTop: 8,
    marginBottom: 8,
    height: 1,
    backgroundColor: "#f1f5f9",
  },
  evidenceIconCalendarBase: {
    width: 16,
    height: 18,
    borderRadius: 3,
    borderWidth: 2,
    borderColor: "#2d5d7b",
  },
  evidenceIconCalendarTopLine: {
    position: "absolute",
    top: 4,
    left: 0,
    right: 0,
    height: 2,
    backgroundColor: "#2d5d7b",
  },
  evidenceIconCalendarRingLeft: {
    position: "absolute",
    top: -3,
    left: 3,
    width: 2,
    height: 5,
    borderRadius: 1,
    backgroundColor: "#2d5d7b",
  },
  evidenceIconCalendarRingRight: {
    position: "absolute",
    top: -3,
    right: 3,
    width: 2,
    height: 5,
    borderRadius: 1,
    backgroundColor: "#2d5d7b",
  },
  evidenceIconClockBase: {
    width: 18,
    height: 18,
    borderRadius: 9,
    borderWidth: 2,
    borderColor: "#2d5d7b",
    alignItems: "center",
    justifyContent: "center",
  },
  evidenceIconClockHandHour: {
    position: "absolute",
    top: 4,
    width: 2,
    height: 5,
    borderRadius: 1,
    backgroundColor: "#2d5d7b",
  },
  evidenceIconClockHandMinute: {
    position: "absolute",
    top: 8,
    right: 4,
    width: 5,
    height: 2,
    borderRadius: 1,
    backgroundColor: "#2d5d7b",
    transform: [{ rotate: "35deg" }],
  },
  evidenceIconClockDot: {
    width: 3,
    height: 3,
    borderRadius: 1.5,
    backgroundColor: "#2d5d7b",
  },
  evidenceIconMicBase: {
    width: 18,
    height: 20,
    alignItems: "center",
    justifyContent: "flex-start",
    position: "relative",
  },
  evidenceIconMicHead: {
    width: 10,
    height: 13,
    borderRadius: 5,
    borderWidth: 2,
    borderColor: "#2d5d7b",
  },
  evidenceIconMicStem: {
    position: "absolute",
    bottom: 4,
    width: 2,
    height: 5,
    borderRadius: 1,
    backgroundColor: "#2d5d7b",
  },
  evidenceIconMicFoot: {
    position: "absolute",
    bottom: 1,
    width: 9,
    height: 2,
    borderRadius: 1,
    backgroundColor: "#2d5d7b",
  },
  evidenceIconVideoBase: {
    width: 16,
    height: 12,
    borderRadius: 3,
    borderWidth: 2,
    borderColor: "#2d5d7b",
    alignItems: "center",
    justifyContent: "center",
    position: "relative",
  },
  evidenceIconVideoLens: {
    position: "absolute",
    right: -5,
    top: 3,
    width: 4,
    height: 5,
    borderRadius: 1,
    backgroundColor: "#2d5d7b",
  },
  evidenceIconVideoDot: {
    width: 4,
    height: 4,
    borderRadius: 2,
    backgroundColor: "#2d5d7b",
  },
  evidenceChecklistItemChecked: {
    borderColor: "#2d5d7b",
    borderWidth: 2,
    backgroundColor: "#f4f9fc",
  },
  evidenceCheckCircle: {
    width: 20,
    height: 20,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: "#d1d5db",
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: "#ffffff",
  },
  evidenceCheckCircleChecked: {
    borderColor: "#2d5d7b",
    backgroundColor: "#2d5d7b",
  },
  evidenceCheckText: {
    color: "#94a3b8",
    fontSize: 12,
    lineHeight: 12,
    fontWeight: "700",
  },
  evidenceCheckTextChecked: {
    color: "#ffffff",
  },
  evidenceChecklistLabelWrap: {
    marginLeft: 10,
    flex: 1,
  },
  evidenceChecklistTitle: {
    color: "#1f2937",
    fontSize: 15,
    lineHeight: 20,
    fontWeight: "600",
  },
  evidenceChecklistTitleChecked: {
    color: "#2d5d7b",
    fontWeight: "700",
  },
  evidenceChecklistSubtitle: {
    color: "#9ca3af",
    fontSize: 12,
    lineHeight: 16,
    fontWeight: "500",
    marginTop: 2,
  },
  evidenceChecklistSubtitleChecked: {
    color: "#2d5d7b",
    fontWeight: "600",
  },
  evidenceInlineResetButton: {
    alignSelf: "flex-end",
    marginTop: 0,
    marginBottom: 2,
    borderRadius: 999,
    borderWidth: 0,
    backgroundColor: "transparent",
    paddingHorizontal: 2,
    paddingVertical: 2,
  },
  evidenceInlineResetButtonText: {
    color: "#7c8a98",
    fontSize: 12,
    lineHeight: 14,
    fontWeight: "500",
  },
  evidencePickerPanel: {
    marginTop: 4,
  },
  evidencePickerBackButton: {
    alignSelf: "flex-start",
    borderRadius: 999,
    borderWidth: 1,
    borderColor: "#edf2f7",
    backgroundColor: "#f8fafc",
    paddingHorizontal: 10,
    paddingVertical: 5,
    marginBottom: 10,
  },
  evidencePickerBackText: {
    color: "#64748b",
    fontSize: 12,
    lineHeight: 14,
    fontWeight: "700",
  },
  evidencePickerMonthRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    marginBottom: 12,
  },
  evidenceMonthNavButton: {
    width: 26,
    height: 26,
    borderRadius: 13,
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: "#f8fafc",
    borderWidth: 1,
    borderColor: "#edf2f7",
  },
  evidenceMonthNavText: {
    color: "#94a3b8",
    fontSize: 20,
    lineHeight: 20,
    fontWeight: "600",
  },
  optionListMonthLabel: {
    color: "#1f2937",
    fontSize: 18,
    lineHeight: 24,
    fontWeight: "700",
  },
  evidenceWeekdayRow: {
    flexDirection: "row",
    justifyContent: "space-between",
    marginBottom: 8,
    paddingHorizontal: 4,
  },
  evidenceWeekdayText: {
    width: "14.285%",
    textAlign: "center",
    color: "#9ca3af",
    fontSize: 12,
    fontWeight: "600",
  },
  evidenceCalendarGrid: {
    alignSelf: "center",
    flexDirection: "row",
    flexWrap: "wrap",
    justifyContent: "space-between",
  },
  evidenceCalendarCell: {
    alignItems: "center",
    justifyContent: "center",
    borderRadius: 999,
    marginTop: 4,
  },
  evidenceCalendarCellEmpty: {
    marginTop: 4,
  },
  evidenceCalendarCellSelected: {
    backgroundColor: "#2d5d7b",
    shadowColor: "#2d5d7b",
    shadowOpacity: 0.2,
    shadowRadius: 6,
    shadowOffset: { width: 0, height: 3 },
    elevation: 2,
  },
  evidenceCalendarCellPressed: {
    opacity: 0.85,
  },
  evidenceCalendarCellText: {
    color: "#64748b",
    fontSize: 15,
    fontWeight: "600",
  },
  evidenceCalendarCellTextSelected: {
    color: "#ffffff",
    fontWeight: "700",
  },
  evidencePickerSummary: {
    marginTop: 14,
    borderTopWidth: 1,
    borderTopColor: "#f1f5f9",
    paddingTop: 14,
    alignItems: "center",
  },
  evidencePickerSummaryLabel: {
    color: "#9ca3af",
    fontSize: 12,
    lineHeight: 16,
    fontWeight: "600",
  },
  evidencePickerSummaryValue: {
    marginTop: 4,
    color: "#1f2937",
    fontSize: 17,
    lineHeight: 24,
    fontWeight: "700",
    textAlign: "center",
  },
  evidenceTimeWheelRow: {
    marginTop: 2,
    flexDirection: "row",
    alignItems: "stretch",
    justifyContent: "space-between",
    borderRadius: 12,
    backgroundColor: "#f8fafc",
    paddingVertical: 8,
    paddingHorizontal: 8,
  },
  evidenceTimeWheelColumn: {
    flex: 1,
    alignItems: "stretch",
    marginHorizontal: 2,
    height: OPTION_LIST_WHEEL_ITEM_HEIGHT * 3,
    borderRadius: 10,
    overflow: "hidden",
    backgroundColor: "#ffffff",
    borderWidth: 1,
    borderColor: "#edf2f7",
  },
  evidenceTimeWheelScroll: {
    flex: 1,
    zIndex: 1,
  },
  evidenceTimeWheelContent: {
    paddingVertical: OPTION_LIST_WHEEL_ITEM_HEIGHT,
  },
  evidenceTimeWheelItem: {
    height: OPTION_LIST_WHEEL_ITEM_HEIGHT,
    alignItems: "center",
    justifyContent: "center",
  },
  evidenceTimeWheelCenterBar: {
    position: "absolute",
    left: 4,
    right: 4,
    top: OPTION_LIST_WHEEL_ITEM_HEIGHT,
    height: OPTION_LIST_WHEEL_ITEM_HEIGHT,
    borderRadius: 8,
    backgroundColor: "rgba(241,245,249,0.35)",
    borderWidth: 1,
    borderColor: "#dbe4eb",
    zIndex: 0,
  },
  evidenceTimeWheelDimText: {
    color: "#9ca3af",
    fontSize: 16,
    lineHeight: 18,
    fontWeight: "500",
  },
  evidenceTimeWheelSpacerText: {
    opacity: 0,
  },
  evidenceTimeWheelActiveText: {
    color: "#2d5d7b",
    fontSize: 20,
    lineHeight: 24,
    fontWeight: "700",
  },
  evidenceActionButton: {
    marginTop: 16,
    borderRadius: 16,
    borderWidth: 1,
    minHeight: 52,
    alignItems: "center",
    justifyContent: "center",
  },
  evidenceActionButtonSkip: {
    borderColor: "#d7dee6",
    backgroundColor: "#ffffff",
  },
  evidenceActionButtonActive: {
    borderColor: "#2d5d7b",
    backgroundColor: "#2d5d7b",
  },
  evidenceActionButtonPressed: {
    opacity: 0.84,
  },
  evidenceActionButtonText: {
    fontSize: 16,
    lineHeight: 24,
    fontWeight: "700",
  },
  evidenceActionButtonTextSkip: {
    color: "#64748b",
  },
  evidenceActionButtonTextActive: {
    color: "#ffffff",
  },
  miniCardGrid: {
    marginTop: 0,
    flexDirection: "row",
    flexWrap: "wrap",
    justifyContent: "space-between",
  },
  miniTaskCard: {
    borderRadius: 16,
    borderWidth: 1,
    borderColor: "#f3f4f6",
    backgroundColor: "#ffffff",
    paddingVertical: 17,
    paddingHorizontal: 16,
    marginTop: 12,
    minHeight: 58,
    justifyContent: "center",
    shadowColor: "#111827",
    shadowOpacity: 0.04,
    shadowRadius: 6,
    shadowOffset: { width: 0, height: 2 },
    elevation: 1,
  },
  miniTaskCardSelected: {
    borderColor: "#2d5d7b",
    borderWidth: 2,
    backgroundColor: "#f4f9fc",
  },
  miniTaskCardPressed: {
    opacity: 0.84,
  },
  miniTaskCardBadge: {
    color: "#64748b",
    fontSize: 11,
    lineHeight: 14,
    fontWeight: "700",
    marginBottom: 6,
  },
  miniTaskCardBadgeSelected: {
    color: "#1d4ed8",
  },
  miniTaskCardTitle: {
    color: "#1f2937",
    fontWeight: "500",
  },
  miniTaskCardTitleSelected: {
    color: "#2d5d7b",
    fontWeight: "700",
  },
  miniTaskCardDescription: {
    marginTop: 5,
    color: "#64748b",
    fontWeight: "500",
  },
  miniTaskCardDescriptionSelected: {
    color: "#334155",
  },
});
