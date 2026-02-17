import { ReactNode, useCallback, useEffect, useMemo, useRef, useState } from "react";
import {
  Animated,
  Easing,
  Keyboard,
  KeyboardEvent,
  Platform,
  Pressable,
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
  | "evidence"
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

type MiniInterfaceConfig = {
  prompt: string;
  selectionMode: MiniSelectionMode;
  context: MiniInterfaceContext;
  selectionHint?: string;
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

type LocalEvidenceKind = "AUDIO" | "LOG";

type LocalEvidenceAttachment = {
  id: string;
  kind: LocalEvidenceKind;
  name: string;
  uri: string;
  pickedAt: number;
};

type EvidenceSummary = {
  audioCount: number;
  logCount: number;
  totalCount: number;
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

const EVIDENCE_OPTION_ADD_AUDIO = "evidence-add-audio";
const EVIDENCE_OPTION_ADD_LOG = "evidence-add-log";
const EVIDENCE_OPTION_REFRESH = "evidence-refresh";
const EVIDENCE_OPTION_NEXT = "evidence-next";

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
    selectionHint: followUpInterface.selectionMode === "MULTIPLE" ? "복수 선택 가능" : "단일 선택",
    options,
  };
}

function createMiniInterface(
  prompt: string,
  optionLabels: string[],
  selectionMode: MiniSelectionMode = "single",
  context: MiniInterfaceContext = "intake",
): MiniInterfaceConfig {
  return {
    prompt,
    selectionMode,
    context,
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
    selectionHint: "단일 선택",
    options,
  };
}

function summarizeEvidenceAttachments(items: LocalEvidenceAttachment[]): EvidenceSummary {
  const audioCount = items.filter((item) => item.kind === "AUDIO").length;
  const logCount = items.filter((item) => item.kind === "LOG").length;
  return {
    audioCount,
    logCount,
    totalCount: items.length,
  };
}

function createEvidenceMiniInterface(summary: EvidenceSummary): MiniInterfaceConfig {
  const hasAnyEvidence = summary.totalCount > 0;
  const prompt = hasAnyEvidence
    ? `첨부 ${summary.totalCount}건을 확인했어요. 필요하면 더 추가해 주세요.`
    : "증거 자료는 선택사항이에요. 필요하면 첨부해 주세요.";

  return {
    prompt,
    selectionMode: "single",
    context: "evidence",
    selectionHint: "선택사항",
    options: [
      {
        id: EVIDENCE_OPTION_ADD_AUDIO,
        label: "녹음 파일 첨부",
        description: "라이브러리에서 선택",
        badge: summary.audioCount > 0 ? `첨부 ${summary.audioCount}` : "선택",
      },
      {
        id: EVIDENCE_OPTION_ADD_LOG,
        label: "소음 일지 첨부",
        description: "라이브러리에서 선택",
        badge: summary.logCount > 0 ? `첨부 ${summary.logCount}` : "선택",
      },
      {
        id: EVIDENCE_OPTION_REFRESH,
        label: "첨부 현황 확인",
        description: "지금 선택한 항목 보기",
        badge: hasAnyEvidence ? `${summary.totalCount}건` : "없음",
      },
      {
        id: EVIDENCE_OPTION_NEXT,
        label: "다음 단계로 이동",
        description: "증거 없이도 계속 진행 가능",
        badge: "계속",
      },
    ],
  };
}

function createMediationMiniInterface(): MiniInterfaceConfig {
  return {
    prompt: "다음 진행 방식을 선택해 주세요.",
    selectionMode: "single",
    context: "mediation",
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
    const miniInterface = createMiniInterface(
      "테스트(복수 선택)입니다. 해당되는 시간대를 모두 선택해 주세요.",
      ["아침", "낮", "저녁", "기타"],
      "multiple",
    );
    return { text: miniInterface.prompt, inputMode: "mini", miniInterface };
  }

  if (compactUserInput === "3") {
    const miniInterface = createMiniInterface(
      "테스트(단일 선택)입니다. 가장 불편한 시간대를 하나 선택해 주세요.",
      ["아침", "낮", "저녁", "기타"],
      "single",
    );
    return { text: miniInterface.prompt, inputMode: "mini", miniInterface };
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

function getExpoImagePickerModule():
  | null
  | {
      requestMediaLibraryPermissionsAsync: () => Promise<{ granted: boolean }>;
      launchImageLibraryAsync: (options?: Record<string, unknown>) => Promise<{
        canceled: boolean;
        assets?: Array<{ uri: string; fileName?: string | null }>;
      }>;
      MediaTypeOptions?: { All?: unknown };
    } {
  try {
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    return require("expo-image-picker");
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
  const [localEvidenceAttachments, setLocalEvidenceAttachments] = useState<LocalEvidenceAttachment[]>([]);
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
  const isMiniInterfaceMode = currentAiTurn.inputMode === "mini";
  const shouldShowMiniInterface =
    isAiMessageCompleted && !isGeneratingReply && isMiniInterfaceMode && currentMiniOptions.length > 0;
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
  const evidenceSummary = useMemo(
    () => summarizeEvidenceAttachments(localEvidenceAttachments),
    [localEvidenceAttachments],
  );
  const audioEvidenceAttachments = useMemo(
    () => localEvidenceAttachments.filter((item) => item.kind === "AUDIO"),
    [localEvidenceAttachments],
  );
  const logEvidenceAttachments = useMemo(
    () => localEvidenceAttachments.filter((item) => item.kind === "LOG"),
    [localEvidenceAttachments],
  );

  const dismissKeyboard = useCallback(() => {
    Keyboard.dismiss();
    setIsInputFocused(false);
  }, []);

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

  const handleEvidenceMiniOptionDirect = useCallback(
    async (option: MiniOption) => {
      if (isGeneratingReply) {
        return;
      }

      setSelectedMiniOptionIds([]);

      if (option.id === EVIDENCE_OPTION_NEXT) {
        setApiErrorMessage(null);
        appendDebugLog("action=evidence-next | 증거 첨부 단계 종료", "INFO");
        markFlowStepCompleted("evidence");
        moveToFlowStep("mediation");
        pushAiTurn(
          "증거는 선택사항이에요. 다음 진행 방식을 선택해 주세요.",
          "mini",
          createMediationMiniInterface(),
        );
        return;
      }

      if (option.id === EVIDENCE_OPTION_REFRESH) {
        setApiErrorMessage(null);
        return;
      }

      if (option.id !== EVIDENCE_OPTION_ADD_AUDIO && option.id !== EVIDENCE_OPTION_ADD_LOG) {
        return;
      }

      const evidenceKind: LocalEvidenceKind =
        option.id === EVIDENCE_OPTION_ADD_AUDIO ? "AUDIO" : "LOG";

      Keyboard.dismiss();
      setIsInputFocused(false);
      setApiErrorMessage(null);

      try {
        appendDebugLog(`action=evidence-pick | type=${evidenceKind} | 라이브러리 열기`, "INFO");
        const imagePicker = getExpoImagePickerModule();
        if (!imagePicker) {
          throw new Error("라이브러리 기능을 불러오지 못했어요. 앱을 다시 실행해 주세요.");
        }

        const permission = await imagePicker.requestMediaLibraryPermissionsAsync();
        if (!permission.granted) {
          setApiErrorMessage("라이브러리 권한이 필요해요. 권한을 허용한 뒤 다시 시도해 주세요.");
          appendDebugLog("action=evidence-pick | 권한 거부", "ERROR");
          return;
        }

        const pickerResult = await imagePicker.launchImageLibraryAsync({
          mediaTypes: imagePicker.MediaTypeOptions?.All,
          allowsMultipleSelection: true,
          quality: 1,
        });

        if (pickerResult.canceled || !pickerResult.assets?.length) {
          setApiErrorMessage(null);
          appendDebugLog("action=evidence-pick | 사용자가 선택 취소", "INFO");
          return;
        }

        const existingAttachmentKeys = new Set(
          localEvidenceAttachments.map((item) => `${item.kind}:${item.uri}`),
        );
        const now = Date.now();
        const nextAttachments = pickerResult.assets.reduce<LocalEvidenceAttachment[]>((acc, asset, index) => {
          if (!asset.uri) {
            return acc;
          }

          const attachmentKey = `${evidenceKind}:${asset.uri}`;
          if (existingAttachmentKeys.has(attachmentKey)) {
            return acc;
          }

          const pickedName =
            asset.fileName?.trim() ||
            asset.uri.split("/").filter(Boolean).pop() ||
            "선택한 파일";
          acc.push({
            id: `local-evidence-${now}-${index}`,
            kind: evidenceKind,
            name: pickedName,
            uri: asset.uri,
            pickedAt: now + index,
          });
          return acc;
        }, []);

        if (nextAttachments.length === 0) {
          setApiErrorMessage("이미 첨부된 파일이에요. 아래 목록에서 해제할 수 있어요.");
          appendDebugLog(`action=evidence-pick | 중복 파일 선택`, "ERROR");
          return;
        }

        setLocalEvidenceAttachments((previous) => [...previous, ...nextAttachments]);
        setApiErrorMessage(null);
        appendDebugLog(`action=evidence-pick | 첨부 완료 ${nextAttachments.length}건`, "INFO");
      } catch (error: unknown) {
        applyApiError(error, "evidence-pick");
      }
    },
    [
      applyApiError,
      appendDebugLog,
      isGeneratingReply,
      localEvidenceAttachments,
      markFlowStepCompleted,
      moveToFlowStep,
      pushAiTurn,
    ],
  );

  const handleRemoveLocalEvidenceAttachment = useCallback((attachmentId: string) => {
    setLocalEvidenceAttachments((previous) =>
      previous.filter((attachment) => attachment.id !== attachmentId),
    );
    setApiErrorMessage(null);
  }, []);

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
    setLocalEvidenceAttachments([]);
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
          setLocalEvidenceAttachments([]);
          pushAiTurn(
            `${routeConfirmedText}\n필요하면 증거를 첨부해 주세요.`,
            "mini",
            createEvidenceMiniInterface(summarizeEvidenceAttachments([])),
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

      if (miniContext === "evidence") {
        if (!selectedPrimary) {
          return;
        }
        await handleEvidenceMiniOptionDirect(selectedPrimary);
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
    handleEvidenceMiniOptionDirect,
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
    setIsAiMessageCompleted(false);
    setVisibleSentenceCount(aiSentences.length > 0 ? 1 : 0);
    setDraft("");
    setSelectedMiniOptionIds([]);
    setIsInputFocused(false);
  }, [aiSentences.length, currentAiTurn.id]);

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
  const isEvidenceMiniInterface = shouldShowMiniInterface && miniContext === "evidence";
  const isSendDisabled = isGeneratingReply ||
    (shouldShowMiniInterface ? (isEvidenceMiniInterface ? true : !hasSelectedMiniOptions) : !draft.trim());
  const sendIcon = shouldShowMiniInterface ? "↗" : "›";
  const miniSelectionHint =
    currentMiniInterface?.selectionHint ??
    (currentMiniSelectionMode === "multiple" ? "복수 선택 가능" : "단일 선택");
  const miniCardWidth = "100%";
  const hasAudioAttachment = evidenceSummary.audioCount > 0;
  const hasLogAttachment = evidenceSummary.logCount > 0;
  const evidenceActionLabel = evidenceSummary.totalCount > 0 ? "선택 완료" : "건너뛰기";
  const evidenceStatusText =
    evidenceSummary.totalCount > 0
      ? `첨부 ${evidenceSummary.totalCount}건 · 파일 탭으로 해제 가능`
      : "아직 첨부한 파일이 없어요.";
  const debugLogsToRender = debugLogs.slice(0, 8);
  const isDebugMode = __DEV__;
  const inputPlaceholder = isGeneratingReply
    ? "답변을 준비하는 중입니다..."
    : shouldShowMiniInterface
      ? (isEvidenceMiniInterface ? "카드를 눌러 첨부하거나 다음 단계로 이동하세요." : "항목을 선택해 주세요.")
      : "답변 입력 또는 음성으로 말하기";
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
    <Pressable style={styles.safeArea} onPress={dismissKeyboard}>
      <Animated.View
        style={[
          styles.frame,
          {
            width: availableWidth,
            height: availableHeight,
          },
        ]}
      >
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
              {
                left: horizontalPadding,
                bottom: miniPanelBottom,
                width: contentWidth,
                borderRadius: 24,
                opacity: miniInterfaceRevealAnim,
                transform: [{ translateY: miniInterfaceMotionY }],
              },
            ]}
          >
            {miniContext === "evidence" ? (
              <>
                <Text style={[styles.miniSelectionHint, { fontSize: 12, lineHeight: 15 }]}>
                  {miniSelectionHint}
                </Text>
                <Text style={styles.evidenceStatusText}>{evidenceStatusText}</Text>

                <View style={styles.evidenceChecklistBlock}>
                  <MiniAnimatedPressable
                    style={[
                      styles.evidenceChecklistItem,
                      hasAudioAttachment && styles.evidenceChecklistItemChecked,
                    ]}
                    onPress={() =>
                      void handleEvidenceMiniOptionDirect({
                        id: EVIDENCE_OPTION_ADD_AUDIO,
                        label: "녹음 파일 첨부",
                      })
                    }
                  >
                    <View style={[styles.evidenceCheckCircle, hasAudioAttachment && styles.evidenceCheckCircleChecked]}>
                      <Text style={[styles.evidenceCheckText, hasAudioAttachment && styles.evidenceCheckTextChecked]}>
                        {hasAudioAttachment ? "✓" : ""}
                      </Text>
                    </View>
                    <View style={styles.evidenceChecklistLabelWrap}>
                      <Text
                        style={[
                          styles.evidenceChecklistTitle,
                          hasAudioAttachment && styles.evidenceChecklistTitleChecked,
                        ]}
                      >
                        녹음 파일 첨부
                      </Text>
                      <Text
                        style={[
                          styles.evidenceChecklistSubtitle,
                          hasAudioAttachment && styles.evidenceChecklistSubtitleChecked,
                        ]}
                      >
                        {hasAudioAttachment ? `${evidenceSummary.audioCount}건 첨부됨` : "누르면 라이브러리 열기"}
                      </Text>
                    </View>
                  </MiniAnimatedPressable>

                  {audioEvidenceAttachments.length > 0 ? (
                    <View style={styles.evidenceAttachmentList}>
                      {audioEvidenceAttachments.map((attachment) => (
                        <MiniAnimatedPressable
                          key={attachment.id}
                          style={styles.evidenceAttachmentItem}
                          onPress={() => handleRemoveLocalEvidenceAttachment(attachment.id)}
                        >
                          <Text style={styles.evidenceAttachmentName} numberOfLines={1}>
                            {attachment.name}
                          </Text>
                          <Text style={styles.evidenceAttachmentRemove}>선택 해제</Text>
                        </MiniAnimatedPressable>
                      ))}
                    </View>
                  ) : null}
                </View>

                <View style={styles.evidenceChecklistBlock}>
                  <MiniAnimatedPressable
                    style={[
                      styles.evidenceChecklistItem,
                      hasLogAttachment && styles.evidenceChecklistItemChecked,
                    ]}
                    onPress={() =>
                      void handleEvidenceMiniOptionDirect({
                        id: EVIDENCE_OPTION_ADD_LOG,
                        label: "소음 일지 첨부",
                      })
                    }
                  >
                    <View style={[styles.evidenceCheckCircle, hasLogAttachment && styles.evidenceCheckCircleChecked]}>
                      <Text style={[styles.evidenceCheckText, hasLogAttachment && styles.evidenceCheckTextChecked]}>
                        {hasLogAttachment ? "✓" : ""}
                      </Text>
                    </View>
                    <View style={styles.evidenceChecklistLabelWrap}>
                      <Text
                        style={[
                          styles.evidenceChecklistTitle,
                          hasLogAttachment && styles.evidenceChecklistTitleChecked,
                        ]}
                      >
                        소음 일지 첨부
                      </Text>
                      <Text
                        style={[
                          styles.evidenceChecklistSubtitle,
                          hasLogAttachment && styles.evidenceChecklistSubtitleChecked,
                        ]}
                      >
                        {hasLogAttachment ? `${evidenceSummary.logCount}건 첨부됨` : "누르면 라이브러리 열기"}
                      </Text>
                    </View>
                  </MiniAnimatedPressable>

                  {logEvidenceAttachments.length > 0 ? (
                    <View style={styles.evidenceAttachmentList}>
                      {logEvidenceAttachments.map((attachment) => (
                        <MiniAnimatedPressable
                          key={attachment.id}
                          style={styles.evidenceAttachmentItem}
                          onPress={() => handleRemoveLocalEvidenceAttachment(attachment.id)}
                        >
                          <Text style={styles.evidenceAttachmentName} numberOfLines={1}>
                            {attachment.name}
                          </Text>
                          <Text style={styles.evidenceAttachmentRemove}>선택 해제</Text>
                        </MiniAnimatedPressable>
                      ))}
                    </View>
                  ) : null}
                </View>

                <MiniAnimatedPressable
                  style={[
                    styles.evidenceActionButton,
                    evidenceSummary.totalCount > 0
                      ? styles.evidenceActionButtonActive
                      : styles.evidenceActionButtonSkip,
                  ]}
                  onPress={() =>
                    void handleEvidenceMiniOptionDirect({
                      id: EVIDENCE_OPTION_NEXT,
                      label: evidenceActionLabel,
                    })
                  }
                >
                  <Text
                    style={[
                      styles.evidenceActionButtonText,
                      evidenceSummary.totalCount > 0
                        ? styles.evidenceActionButtonTextActive
                        : styles.evidenceActionButtonTextSkip,
                    ]}
                  >
                    {evidenceActionLabel}
                  </Text>
                </MiniAnimatedPressable>
              </>
            ) : (
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
            )}
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
    </Pressable>
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
  miniSelectionHint: {
    color: "#9ca3af",
    fontWeight: "500",
    marginBottom: 8,
    marginLeft: 2,
  },
  evidenceStatusText: {
    color: "#9ca3af",
    fontSize: 12,
    lineHeight: 16,
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
    marginTop: 2,
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
    color: "#ffffff",
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
  evidenceAttachmentList: {
    marginTop: 6,
    marginLeft: 8,
    marginRight: 8,
  },
  evidenceAttachmentItem: {
    minHeight: 34,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: "#e2e8f0",
    backgroundColor: "#ffffff",
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    paddingHorizontal: 10,
    marginTop: 6,
  },
  evidenceAttachmentName: {
    flex: 1,
    color: "#475569",
    fontSize: 12,
    lineHeight: 16,
    fontWeight: "500",
    marginRight: 10,
  },
  evidenceAttachmentRemove: {
    color: "#2d5d7b",
    fontSize: 12,
    lineHeight: 16,
    fontWeight: "700",
  },
  evidenceActionButton: {
    marginTop: 12,
    borderRadius: 14,
    borderWidth: 1,
    minHeight: 46,
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
    fontSize: 15,
    lineHeight: 20,
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
