import { useCallback, useEffect, useMemo, useRef, useState } from "react";
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
} from "../types/api";

const BASE_WIDTH = 393;
const BASE_HEIGHT = 852;
const INPUT_ANCHOR_BOTTOM = 816;
const KEYBOARD_GAP = 12;

type ResponseInputMode = "text" | "mini";
type MiniSelectionMode = "single" | "multiple";
type MiniInterfaceContext = "intake" | "routing";

type MiniOptionKind = "choice" | "other";

type MiniOption = {
  id: string;
  label: string;
  kind?: MiniOptionKind;
  description?: string;
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

const INITIAL_AI_TURN: AiTurn = {
  id: "chatbot-turn-1",
  text: "안녕하세요.\n무엇을 도와드릴까요?\n불편하신 상황을 편하게 말씀해 주세요.",
  inputMode: "text",
  miniInterface: null,
};

type ChatbotConversationScreenProps = {
  onBack?: () => void;
  onRouteConfirmed?: () => void;
};

type ThinkingWaveTextProps = {
  text: string;
  style?: StyleProp<TextStyle>;
};

const THINKING_TEXT = "답변을 준비하고 있어요.";
const REQUEST_ERROR_FALLBACK = "요청 처리 중 문제가 발생했어요. 다시 시도해 주세요.";

const STATUS_FALLBACK_TEXT: Partial<Record<CaseStatus, string>> = {
  RECEIVED: "내용을 잘 받았어요. 핵심 정보를 더 알려주시면 분류를 진행할게요.",
  CLASSIFIED: "상황 분류를 마쳤어요. 다음 단계를 안내해 드릴게요.",
  ROUTE_CONFIRMED: "접수 경로를 확정했어요. 필요한 자료를 준비해볼게요.",
  EVIDENCE_COLLECTING: "증빙 자료를 등록하면 제출 준비를 이어서 진행할 수 있어요.",
  FORMAL_SUBMISSION_READY: "제출 준비가 완료됐어요. 정부24 제출 단계를 진행해 주세요.",
};

function resolveAiTurnText(response: IntakeUpdateResponse): string {
  const followUp = response.recommendedFollowUpQuestion?.trim();
  if (followUp) {
    return followUp;
  }

  return (
    STATUS_FALLBACK_TEXT[response.status] ??
    "입력해 주신 내용을 확인했어요. 이어서 필요한 정보를 안내할게요."
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
    options: optionLabels.map((label, index) => ({
      id: `mini-option-${index + 1}-${label}`,
      label,
      kind: label === "기타" ? "other" : "choice",
    })),
  };
}

function mapRoutingRecommendationToMiniInterface(
  recommendation: RoutingRecommendation,
): MiniInterfaceConfig | null {
  const options = (recommendation.options ?? [])
    .slice(0, 4)
    .map((option) => ({
      id: option.optionId,
      label: option.label,
      kind: "choice" as const,
      description: option.reason?.trim() || undefined,
    }));

  if (options.length === 0) {
    return null;
  }

  return {
    prompt: "추천 경로를 준비했어요. 아래에서 가장 적합한 경로를 선택해 주세요.",
    selectionMode: "single",
    context: "routing",
    selectionHint: "단일 선택",
    options,
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

export function ChatbotConversationScreen({ onBack, onRouteConfirmed }: ChatbotConversationScreenProps) {
  const [draft, setDraft] = useState("");
  const [selectedMiniOptionIds, setSelectedMiniOptionIds] = useState<string[]>([]);
  const [isInputFocused, setIsInputFocused] = useState(false);
  const [isAiMessageCompleted, setIsAiMessageCompleted] = useState(false);
  const [isGeneratingReply, setIsGeneratingReply] = useState(false);
  const [apiErrorMessage, setApiErrorMessage] = useState<string | null>(null);
  const [visibleSentenceCount, setVisibleSentenceCount] = useState(1);
  const [currentAiTurn, setCurrentAiTurn] = useState<AiTurn>(INITIAL_AI_TURN);
  const {
    caseId,
    status,
    traceId,
    applyCaseDetail,
    applyIntakeUpdate,
    setCaseFromCreate,
    setRoutingRecommendation,
  } = useCaseContext();
  const { width, height } = useWindowDimensions();
  const insets = useSafeAreaInsets();
  const turnSequenceRef = useRef(2);
  const createCaseIdempotencyKeyRef = useRef(`mobile-create-case-${Date.now()}`);
  const replyTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
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
  const currentMiniInterface = currentAiTurn.miniInterface ?? null;
  const currentMiniOptions = currentMiniInterface?.options ?? [];
  const currentMiniSelectionMode = currentMiniInterface?.selectionMode ?? "single";
  const isRoutingMiniInterface = currentMiniInterface?.context === "routing";
  const isMiniInterfaceMode = currentAiTurn.inputMode === "mini";
  const shouldShowMiniInterface =
    isAiMessageCompleted && !isGeneratingReply && isMiniInterfaceMode && currentMiniOptions.length > 0;
  const shouldShowRouteRecommendationAction =
    status === "CLASSIFIED" && isAiMessageCompleted && !isGeneratingReply && !shouldShowMiniInterface;
  const isInputDisabled = isGeneratingReply || shouldShowMiniInterface;

  const availableWidth = width;
  const availableHeight = height;
  const widthScale = availableWidth / BASE_WIDTH;
  const heightScale = availableHeight / BASE_HEIGHT;
  const useWidthFit = heightScale >= 0.9;
  const scale = useWidthFit ? widthScale : Math.min(widthScale, heightScale);
  const offsetX = (availableWidth - BASE_WIDTH * scale) / 2;
  const offsetY = useWidthFit ? 0 : (availableHeight - BASE_HEIGHT * scale) / 2;
  const topInsetOffset = Math.max(insets.top - 20, 0);

  const dismissKeyboard = useCallback(() => {
    Keyboard.dismiss();
    setIsInputFocused(false);
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

  const ensureCaseId = useCallback(async () => {
    if (caseId) {
      return caseId;
    }

    const requestBody: CreateCaseRequest = {
      scenarioType: "INTER_FLOOR_NOISE",
      housingType: "APARTMENT",
      consentAccepted: true,
    };

    const createdCase = await apiClient.createCase(requestBody, {
      traceId,
      idempotencyKey: createCaseIdempotencyKeyRef.current,
    });

    if (!createdCase.caseId) {
      throw new Error("민원 케이스 생성에 실패했습니다. 잠시 후 다시 시도해 주세요.");
    }

    setCaseFromCreate(createdCase);
    return createdCase.caseId;
  }, [caseId, setCaseFromCreate, traceId]);

  const sendMessageToApi = useCallback(
    async (message: string) => {
      const ensuredCaseId = await ensureCaseId();

      const intakeResponse = await apiClient.appendIntakeMessage(
        ensuredCaseId,
        {
          role: "USER",
          message,
        },
        { traceId },
      );

      applyIntakeUpdate(intakeResponse);
      return intakeResponse;
    },
    [applyIntakeUpdate, ensureCaseId, traceId],
  );

  const handleRequestRouteRecommendation = useCallback(async () => {
    if (isGeneratingReply) {
      return;
    }

    Keyboard.dismiss();
    setIsInputFocused(false);
    setApiErrorMessage(null);
    setIsGeneratingReply(true);
    setIsAiMessageCompleted(false);
    setVisibleSentenceCount(0);

    try {
      const ensuredCaseId = await ensureCaseId();
      await apiClient.decomposeCase(ensuredCaseId, { traceId });
      const recommendation = await apiClient.recommendRoute(ensuredCaseId, { traceId });
      setRoutingRecommendation(recommendation);

      const miniInterface = mapRoutingRecommendationToMiniInterface(recommendation);
      if (!miniInterface) {
        pushAiTurn("추천 경로를 아직 정리하지 못했어요. 잠시 후 다시 시도해 주세요.", "text", null);
        return;
      }

      pushAiTurn(miniInterface.prompt, "mini", miniInterface);
    } catch (error: unknown) {
      setApiErrorMessage(toKoreanErrorMessage(error));
      pushAiTurn(REQUEST_ERROR_FALLBACK, "text", null);
    } finally {
      setIsGeneratingReply(false);
    }
  }, [ensureCaseId, isGeneratingReply, pushAiTurn, setRoutingRecommendation, traceId]);

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

      if (isRoutingMiniInterface) {
        const selectedRouteOption = selectedOptions[0];
        if (!selectedRouteOption) {
          return;
        }

        setApiErrorMessage(null);
        setIsGeneratingReply(true);
        setIsAiMessageCompleted(false);
        setVisibleSentenceCount(0);

        try {
          const ensuredCaseId = await ensureCaseId();
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

          const routeConfirmedText =
            confirmedCase.status === "ROUTE_CONFIRMED"
              ? `${selectedRouteOption.label} 경로로 확정했어요.\n이제 증빙 자료를 등록하면 제출 단계로 넘어갈 수 있어요.`
              : "경로를 반영했어요. 다음 단계를 이어서 진행해 주세요.";

          pushAiTurn(routeConfirmedText, "text", null);
          onRouteConfirmed?.();
        } catch (error: unknown) {
          setApiErrorMessage(toKoreanErrorMessage(error));
          pushAiTurn(REQUEST_ERROR_FALLBACK, "text", null);
        } finally {
          setIsGeneratingReply(false);
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
        const aiText = resolveAiTurnText(intakeResponse);
        const nextMiniInterface = mapApiFollowUpInterface(intakeResponse.followUpInterface, aiText);
        pushAiTurn(aiText, nextMiniInterface ? "mini" : "text", nextMiniInterface);
      } catch (error: unknown) {
        setApiErrorMessage(toKoreanErrorMessage(error));
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
      const aiText = resolveAiTurnText(intakeResponse);
      const nextMiniInterface = mapApiFollowUpInterface(intakeResponse.followUpInterface, aiText);
      pushAiTurn(aiText, nextMiniInterface ? "mini" : "text", nextMiniInterface);
    } catch (error: unknown) {
      setApiErrorMessage(toKoreanErrorMessage(error));
      pushAiTurn(REQUEST_ERROR_FALLBACK, "text", null);
    } finally {
      setIsGeneratingReply(false);
    }
  }, [
    applyCaseDetail,
    currentMiniOptions,
    draft,
    ensureCaseId,
    isRoutingMiniInterface,
    isGeneratingReply,
    pushAiTurn,
    selectedMiniOptionIds,
    sendMessageToApi,
    shouldShowMiniInterface,
    startGeneratingThenRespond,
    setApiErrorMessage,
    onRouteConfirmed,
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
      const currentInputBottom = offsetY + INPUT_ANCHOR_BOTTOM * scale;
      const deltaScreen = desiredInputBottom - currentInputBottom;
      const target = Math.min(0, deltaScreen / Math.max(scale, 0.01));
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
  }, [availableHeight, inputKeyboardLift, offsetY, scale]);

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
    outputRange: ["#cbd5e1", "#60a5fa"],
  });

  const inputBackgroundColor = inputFocusAnim.interpolate({
    inputRange: [0, 1],
    outputRange: ["#ffffff", "#f8fbff"],
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
  const isSendDisabled = isGeneratingReply || (shouldShowMiniInterface ? !hasSelectedMiniOptions : !draft.trim());
  const sendIcon = shouldShowMiniInterface ? "↗" : ">";
  const miniSelectionHint =
    currentMiniInterface?.selectionHint ??
    (currentMiniSelectionMode === "multiple" ? "복수 선택 가능" : "단일 선택");
  const inputPlaceholder = isGeneratingReply
    ? "답변을 준비하는 중입니다..."
    : shouldShowMiniInterface
      ? isRoutingMiniInterface
        ? "위 항목에서 접수 경로를 선택해 주세요."
        : currentMiniSelectionMode === "multiple"
        ? "위 항목에서 해당되는 내용을 모두 선택해 주세요."
        : "위 항목에서 가장 가까운 내용을 선택해 주세요."
      : "답변 입력 또는 음성으로 말하기";

  return (
    <Pressable style={styles.safeArea} onPress={dismissKeyboard}>
      <Animated.View
        style={[
          styles.frame,
          {
            left: offsetX,
            top: offsetY,
            transform: [{ scale }],
          },
        ]}
      >
        <Pressable
          onPress={onBack}
          style={({ pressed }) => [
            styles.backButton,
            {
              left: 20,
              top: 24 + topInsetOffset,
              width: 44,
              height: 44,
              borderRadius: 22,
              borderWidth: 1,
              opacity: pressed ? 0.6 : 1,
            },
          ]}
        >
          <Text style={[styles.backIcon, { fontSize: 30, lineHeight: 34 }]}>{"‹"}</Text>
        </Pressable>

        <Text
          style={[
            styles.chatTitle,
            {
              left: 145,
              top: 35 + topInsetOffset,
              width: 104,
              fontSize: 18,
              lineHeight: 22,
            },
          ]}
        >
          층간소음 상담
        </Text>

        <View
          style={[
            styles.topMessageContainer,
            {
              left: 24,
              top: 101 + topInsetOffset,
              width: 341,
              height: 429,
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
                  lineHeight: 34,
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
                    lineHeight: 34,
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
                left: 24,
                bottom: 118,
                width: 345,
                borderRadius: 18,
                opacity: pressed ? 0.88 : 1,
              },
            ]}
          >
            <Text style={[styles.routeActionTitle, { fontSize: 16, lineHeight: 20 }]}>추천 경로 확인하기</Text>
            <Text style={[styles.routeActionSubtitle, { fontSize: 12, lineHeight: 16 }]}>
              분류된 민원을 바탕으로 접수 채널을 추천해 드릴게요.
            </Text>
          </Pressable>
        ) : null}

        {shouldShowMiniInterface ? (
          <Animated.View
            style={[
              styles.miniInterfaceWrap,
              {
                left: 24,
                bottom: 108,
                width: 345,
                borderRadius: 20,
                opacity: miniInterfaceRevealAnim,
                transform: [{ translateY: miniInterfaceMotionY }],
              },
            ]}
          >
            <Text style={[styles.miniSelectionHint, { fontSize: 12, lineHeight: 15 }]}>
              {miniSelectionHint}
            </Text>
            {currentMiniOptions.map((option, index) => {
              const isSelected = selectedMiniOptionIds.includes(option.id);
              return (
                <Pressable
                  key={option.id}
                  style={({ pressed }) => [
                    styles.miniOptionButton,
                    isSelected && styles.miniOptionSelected,
                    pressed && styles.miniOptionPressed,
                  ]}
                  onPress={() => handleMiniOptionPress(option)}
                >
                  <Text
                    style={[
                      styles.miniOptionText,
                      isSelected && styles.miniOptionTextSelected,
                      { fontSize: 16, lineHeight: 20 },
                    ]}
                  >
                    {`${index + 1}번 ${option.label}`}
                  </Text>
                  {option.description ? (
                    <Text style={[styles.miniOptionDescription, { fontSize: 12, lineHeight: 15 }]}>
                      {option.description}
                    </Text>
                  ) : null}
                </Pressable>
              );
            })}
          </Animated.View>
        ) : null}

        <Animated.View
          style={[
            styles.inputWrap,
            {
              left: 24,
              top: 762,
              width: 341,
              height: 54,
              borderRadius: 27,
              borderWidth: 1,
              paddingLeft: 22.07,
              paddingRight: 11.04,
              borderColor: isInputDisabled ? "#dbe4ef" : inputBorderColor,
              backgroundColor: isInputDisabled ? "#f8fafc" : inputBackgroundColor,
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
                fontSize: 14,
                lineHeight: 17,
                marginRight: 8,
              },
            ]}
            placeholder={inputPlaceholder}
            placeholderTextColor={isInputDisabled ? "#a3afbf" : "#94a3b8"}
            value={draft}
            onChangeText={setDraft}
            onSubmitEditing={handleSend}
            onFocus={() => setIsInputFocused(true)}
            onBlur={() => setIsInputFocused(false)}
            returnKeyType="send"
            editable={!isInputDisabled}
          />
          <Pressable
            style={({ pressed }) => [
              styles.sendButton,
              {
                width: 39.73,
                height: 36,
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
                  ? { fontSize: 15, lineHeight: 18 }
                  : { fontSize: 16, lineHeight: 19 },
              ]}
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
    position: "absolute",
    width: BASE_WIDTH,
    height: BASE_HEIGHT,
    backgroundColor: "#ffffff",
    overflow: "hidden",
  },
  backButton: {
    position: "absolute",
    borderColor: "#d7deea",
    backgroundColor: "#ffffff",
    alignItems: "center",
    justifyContent: "center",
  },
  backIcon: {
    color: "#334155",
    fontWeight: "600",
  },
  chatTitle: {
    position: "absolute",
    color: "#0f172a",
    fontWeight: "700",
    textAlign: "center",
  },
  topMessageContainer: {
    position: "absolute",
  },
  topMessage: {
    color: "#2589ff",
    fontWeight: "400",
  },
  thinkingMessage: {
    color: "#9ca3af",
    fontWeight: "500",
  },
  apiErrorText: {
    position: "absolute",
    color: "#dc2626",
    fontWeight: "500",
  },
  routeActionCard: {
    position: "absolute",
    borderWidth: 1,
    borderColor: "#bfdbfe",
    backgroundColor: "#f8fbff",
    paddingHorizontal: 16,
    paddingVertical: 12,
  },
  routeActionTitle: {
    color: "#1d4ed8",
    fontWeight: "700",
  },
  routeActionSubtitle: {
    color: "#475569",
    fontWeight: "500",
    marginTop: 4,
  },
  inputWrap: {
    position: "absolute",
    borderColor: "#cbd5e1",
    backgroundColor: "#ffffff",
    flexDirection: "row",
    alignItems: "center",
  },
  input: {
    flex: 1,
    color: "#0f172a",
    fontWeight: "500",
  },
  inputDisabled: {
    color: "#94a3b8",
  },
  sendButton: {
    borderRadius: 999,
    backgroundColor: "#1d4ed8",
    alignItems: "center",
    justifyContent: "center",
  },
  sendButtonDisabled: {
    backgroundColor: "#bfd0f5",
  },
  sendButtonPressed: {
    backgroundColor: "#1e40af",
  },
  sendText: {
    color: "#ffffff",
    fontWeight: "700",
  },
  miniInterfaceWrap: {
    position: "absolute",
    borderWidth: 1,
    borderColor: "#bfdbfe",
    backgroundColor: "#f8fbff",
    paddingHorizontal: 14,
    paddingVertical: 12,
  },
  miniInterfaceTitle: {
    color: "#1e40af",
    fontWeight: "700",
  },
  miniInterfaceSubtitle: {
    marginTop: 4,
    color: "#64748b",
    fontWeight: "500",
  },
  miniOptionButton: {
    borderRadius: 14,
    borderWidth: 1,
    borderColor: "#dbeafe",
    backgroundColor: "#ffffff",
    paddingVertical: 12,
    paddingHorizontal: 14,
    marginVertical: 5,
    minHeight: 52,
    justifyContent: "center",
  },
  miniSelectionHint: {
    color: "#9ca3af",
    fontWeight: "500",
    marginBottom: 4,
    marginLeft: 4,
  },
  miniOptionSelected: {
    borderColor: "#93c5fd",
    backgroundColor: "#eaf2ff",
  },
  miniOptionPressed: {
    opacity: 0.72,
  },
  miniOptionText: {
    color: "#1e293b",
    fontWeight: "600",
  },
  miniOptionTextSelected: {
    color: "#1d4ed8",
    fontWeight: "700",
  },
  miniOptionDescription: {
    marginTop: 5,
    color: "#64748b",
    fontWeight: "500",
  },
});
