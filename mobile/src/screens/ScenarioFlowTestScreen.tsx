import { useEffect, useMemo, useRef, useState } from "react";
import type { ReactNode } from "react";
import {
  Animated,
  Easing,
  Image,
  Pressable,
  StyleProp,
  StyleSheet,
  Text,
  TextStyle,
  useWindowDimensions,
  View,
  ViewStyle,
} from "react-native";
import { ChatbotConversationScreen } from "./ChatbotConversationScreen";
import { CompletionSummaryScreen } from "./CompletionSummaryScreen";
import { ConversationListItem, ConversationListScreen } from "./ConversationListScreen";
import { EvidenceCollectionScreen } from "./EvidenceCollectionScreen";
import { MediationSupportScreen } from "./MediationSupportScreen";
import { SubmissionReviewScreen } from "./SubmissionReviewScreen";
import { TimelineScreen } from "./TimelineScreen";
import { useCaseContext } from "../store/caseContext";
import type { CaseStatus } from "../types/api";

const FINAL_STAGE = 18;
const CHAT_STAGE = 13;
const BASE_WIDTH = 393;
const BASE_HEIGHT = 852;
const DEFAULT_TRANSITION_DURATION = 800;
const BUTTON_TRANSITION_DURATION = DEFAULT_TRANSITION_DURATION;
const AUTO_ADVANCE_RULES: Partial<Record<number, { delayMs: number; nextStage: number }>> = {
  3: { delayMs: 1800, nextStage: 4 },
};
const DISABLE_CHAT_INTAKE_STAGES = true;
const DEFAULT_CHAT_PREVIEW = "대화를 시작해 주세요.";
const START_MOBILE_BG = "#f3f4f6";
const START_MOBILE_ACCENT = "#2d5d7b";
const START_MOBILE_TEXT = "#1f2937";
const START_MOBILE_CAPTION = "#9ca3af";

function toStatusLabel(status: CaseStatus | null): string {
  if (!status) {
    return "준비 중";
  }
  switch (status) {
    case "RECEIVED":
      return "접수 중";
    case "CLASSIFIED":
      return "분류 완료";
    case "ROUTE_CONFIRMED":
      return "경로 확정";
    case "EVIDENCE_COLLECTING":
      return "증거 수집";
    case "FORMAL_SUBMISSION_READY":
      return "제출 준비";
    case "INSTITUTION_PROCESSING":
      return "기관 처리 중";
    case "COMPLETED":
      return "처리 완료";
    default:
      return status;
  }
}

function formatSessionUpdatedAt(epochMs: number): string {
  const date = new Date(epochMs);
  if (Number.isNaN(date.getTime())) {
    return "-";
  }
  return date.toLocaleString("ko-KR", {
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
  });
}

type RectProps = {
  x: number;
  y: number;
  width: number;
  height: number;
  fill: string;
  radius?: number;
  stroke?: string;
};

type LabelProps = {
  x: number;
  y: number;
  text: string;
  color: string;
  size: number;
  weight: number;
  width?: number;
  lineHeight?: number;
  align?: TextStyle["textAlign"];
};

type AbsoluteButtonProps = {
  x: number;
  y: number;
  width: number;
  height: number;
  radius: number;
  fill: string;
  stroke?: string;
  label: string;
  labelColor: string;
  labelSize: number;
  labelWeight: number;
  onPress?: () => void;
  pressedFill?: string;
  forcePressed?: boolean;
  disabled?: boolean;
  softShadow?: boolean;
  smoothPress?: boolean;
};

function Rect({ x, y, width, height, fill, radius = 0, stroke }: RectProps) {
  return (
    <View
      pointerEvents="none"
      style={[
        styles.abs,
        {
          left: x,
          top: y,
          width,
          height,
          borderRadius: radius,
          backgroundColor: fill,
          borderWidth: stroke ? 1 : 0,
          borderColor: stroke,
        },
      ]}
    />
  );
}

function Label({
  x,
  y,
  text,
  color,
  size,
  weight,
  width,
  lineHeight,
  align,
}: LabelProps) {
  return (
    <Text
      pointerEvents="none"
      style={[
        styles.absText,
        {
          left: x,
          top: y,
          color,
          fontSize: size,
          fontWeight: `${weight}` as TextStyle["fontWeight"],
          lineHeight: lineHeight ?? Math.round(size * 1.21),
          width,
          textAlign: align,
        },
      ]}
    >
      {text}
    </Text>
  );
}

function AbsoluteButton({
  x,
  y,
  width,
  height,
  radius,
  fill,
  stroke,
  label,
  labelColor,
  labelSize,
  labelWeight,
  onPress,
  pressedFill,
  forcePressed,
  disabled,
  softShadow = false,
  smoothPress = false,
}: AbsoluteButtonProps) {
  const pressAnim = useRef(new Animated.Value(forcePressed ? 1 : 0)).current;
  const [isPressedVisual, setIsPressedVisual] = useState(false);
  const textStyle = {
    color: labelColor,
    fontSize: labelSize,
    fontWeight: `${labelWeight}` as TextStyle["fontWeight"],
    lineHeight: Math.round(labelSize * 1.21),
  };

  const frameStyle = {
    left: x,
    top: y,
    width,
    height,
    borderRadius: radius,
  };

  const surfaceStyle = {
    borderWidth: 1,
    borderColor: stroke ?? fill,
    alignItems: "center" as const,
    justifyContent: "center" as const,
  };

  useEffect(() => {
    if (!smoothPress) {
      return;
    }

    const animation = Animated.timing(pressAnim, {
      toValue: forcePressed ? 1 : 0,
      duration: forcePressed ? 110 : 170,
      easing: Easing.out(Easing.cubic),
      useNativeDriver: true,
    });
    animation.start();
    return () => animation.stop();
  }, [forcePressed, pressAnim, smoothPress]);

  if (!onPress) {
    return (
      <View
        style={[
          styles.abs,
          frameStyle,
          surfaceStyle,
          { backgroundColor: fill },
          softShadow && styles.startMobileCtaShadow,
        ]}
      >
        <Text style={textStyle}>{label}</Text>
      </View>
    );
  }

  const animatedPressStyle = smoothPress
    ? {
        transform: [
          {
            scale: pressAnim.interpolate({
              inputRange: [0, 1],
              outputRange: [1, 0.975],
            }),
          },
          {
            translateY: pressAnim.interpolate({
              inputRange: [0, 1],
              outputRange: [0, 1.6],
            }),
          },
        ],
      }
    : null;

  return (
    <Animated.View
      style={[
        styles.abs,
        frameStyle,
        softShadow && styles.startMobileCtaShadow,
        softShadow && (isPressedVisual || forcePressed) && styles.startMobileCtaShadowPressed,
        animatedPressStyle,
      ]}
    >
      <Pressable
        disabled={disabled}
        onPress={onPress}
        onPressIn={() => {
          setIsPressedVisual(true);
          if (!smoothPress) {
            return;
          }
          Animated.timing(pressAnim, {
            toValue: 1,
            duration: 110,
            easing: Easing.out(Easing.cubic),
            useNativeDriver: true,
          }).start();
        }}
        onPressOut={() => {
          setIsPressedVisual(false);
          if (!smoothPress) {
            return;
          }
          Animated.timing(pressAnim, {
            toValue: forcePressed ? 1 : 0,
            duration: 170,
            easing: Easing.out(Easing.cubic),
            useNativeDriver: true,
          }).start();
        }}
        style={({ pressed }) => [
          styles.buttonSurface,
          surfaceStyle,
          {
            borderRadius: radius,
            backgroundColor: pressed || forcePressed ? pressedFill ?? fill : fill,
          },
        ]}
      >
        <Text style={textStyle}>{label}</Text>
      </Pressable>
    </Animated.View>
  );
}

function StartMobileBackdrop() {
  return <Rect x={0} y={0} width={393} height={852} fill={START_MOBILE_BG} />;
}

function StartMobileCard({
  x,
  y,
  width,
  height,
  radius = 32,
  children,
}: {
  x: number;
  y: number;
  width: number;
  height: number;
  radius?: number;
  children?: ReactNode;
}) {
  return (
    <View
      pointerEvents="none"
      style={[
        styles.abs,
        styles.startCardShadow,
        {
          left: x,
          top: y,
          width,
          height,
          borderRadius: radius,
          borderWidth: 1,
          borderColor: "#e5e7eb",
          backgroundColor: "#f3f4f6",
          alignItems: "center",
          justifyContent: "center",
        },
      ]}
    >
      {children}
    </View>
  );
}

function StartFrame1Stage({
  onStartPress,
  buttonPressed,
}: {
  onStartPress: () => void;
  buttonPressed?: boolean;
}) {
  const logoAnim = useRef(new Animated.Value(0)).current;
  const headingAnim = useRef(new Animated.Value(0)).current;
  const ctaAnim = useRef(new Animated.Value(0)).current;
  const [isCtaReady, setIsCtaReady] = useState(false);

  useEffect(() => {
    logoAnim.setValue(0);
    headingAnim.setValue(0);
    ctaAnim.setValue(0);
    setIsCtaReady(false);

    const logo = Animated.timing(logoAnim, {
      toValue: 1,
      duration: 380,
      delay: 200,
      easing: Easing.out(Easing.cubic),
      useNativeDriver: true,
    });
    const heading = Animated.timing(headingAnim, {
      toValue: 1,
      duration: 360,
      delay: 620,
      easing: Easing.out(Easing.cubic),
      useNativeDriver: true,
    });
    const cta = Animated.timing(ctaAnim, {
      toValue: 1,
      duration: 360,
      delay: 1020,
      easing: Easing.out(Easing.cubic),
      useNativeDriver: true,
    });

    const ctaReadyTimer = setTimeout(() => {
      setIsCtaReady(true);
    }, 1380);

    const sequence = Animated.parallel([logo, heading, cta]);
    sequence.start();

    return () => {
      clearTimeout(ctaReadyTimer);
      sequence.stop();
    };
  }, [ctaAnim, headingAnim, logoAnim]);

  const logoTranslateY = logoAnim.interpolate({
    inputRange: [0, 1],
    outputRange: [12, 0],
  });
  const headingTranslateY = headingAnim.interpolate({
    inputRange: [0, 1],
    outputRange: [10, 0],
  });
  const ctaTranslateY = ctaAnim.interpolate({
    inputRange: [0, 1],
    outputRange: [10, 0],
  });

  return (
    <>
      <StartMobileBackdrop />
      <Animated.View
        pointerEvents="none"
        style={[
          styles.abs,
          {
            left: 0,
            top: 0,
            opacity: logoAnim,
            transform: [{ translateY: logoTranslateY }],
          },
        ]}
      >
        <StartMobileCard x={131} y={276} width={128} height={128}>
          <Image
            source={require("../assets/korea_gov24.transparent.png")}
            style={styles.startGov24Logo}
            resizeMode="contain"
          />
        </StartMobileCard>
      </Animated.View>

      <Animated.View
        pointerEvents="none"
        style={[
          styles.abs,
          {
            left: 0,
            top: 0,
            opacity: headingAnim,
            transform: [{ translateY: headingTranslateY }],
          },
        ]}
      >
        <Label
          x={90}
          y={445}
          width={214}
          text="신속한 처리, 정부 24"
          color={START_MOBILE_TEXT}
          size={24}
          weight={700}
          lineHeight={39}
          align="center"
        />
      </Animated.View>

      <Animated.View
        style={[
          styles.abs,
          {
            left: 0,
            top: 0,
            opacity: ctaAnim,
            transform: [{ translateY: ctaTranslateY }],
          },
        ]}
      >
        <AbsoluteButton
          x={40}
          y={678}
          width={310}
          height={60}
          radius={24}
          fill={START_MOBILE_ACCENT}
          stroke={START_MOBILE_ACCENT}
          label="시작하기"
          labelColor="#ffffff"
          labelSize={18}
          labelWeight={700}
          onPress={onStartPress}
          pressedFill="#244c65"
          forcePressed={buttonPressed}
          disabled={buttonPressed || !isCtaReady}
          softShadow
          smoothPress
        />
        <Label
          x={96}
          y={754}
          width={199}
          text="평균 2분 · 언제든 중단 후 이어하기 가능"
          color={START_MOBILE_CAPTION}
          size={12}
          weight={500}
          lineHeight={16}
          align="center"
        />
      </Animated.View>
    </>
  );
}

function StartFrame2Stage({
  onNext,
  buttonPressed,
}: {
  onNext: () => void;
  buttonPressed?: boolean;
}) {
  return (
    <>
      <StartMobileBackdrop />
      <StartMobileCard x={131} y={276} width={128} height={128}>
        <Image
          source={require("../assets/korea_gov24.transparent.png")}
          style={styles.startGov24Logo}
          resizeMode="contain"
        />
      </StartMobileCard>

      <Label
        x={71}
        y={425}
        width={248}
        text={"본인 확인 후 민원 신청을\n이어서 진행합니다."}
        color={START_MOBILE_TEXT}
        size={24}
        weight={700}
        lineHeight={39}
        align="center"
      />

      <AbsoluteButton
        x={40}
        y={678}
        width={310}
        height={60}
        radius={24}
        fill={START_MOBILE_ACCENT}
        stroke={START_MOBILE_ACCENT}
        label="정부24에서 계속"
        labelColor="#ffffff"
        labelSize={18}
        labelWeight={700}
        onPress={onNext}
        pressedFill="#244c65"
        forcePressed={buttonPressed}
        disabled={buttonPressed}
        softShadow
        smoothPress
      />
      <Label
        x={108}
        y={754}
        width={174}
        text="소요 1~2분 · 암호화된 안전한 인증"
        color={START_MOBILE_CAPTION}
        size={12}
        weight={500}
        lineHeight={16}
        align="center"
      />
    </>
  );
}

function AuthenticationLoadingRing() {
  const spinAnim = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    spinAnim.setValue(0);
    const loop = Animated.loop(
      Animated.sequence([
        Animated.timing(spinAnim, {
          toValue: 0.4,
          duration: 1100,
          easing: Easing.linear,
          useNativeDriver: true,
        }),
        Animated.timing(spinAnim, {
          toValue: 0.7,
          duration: 580,
          easing: Easing.linear,
          useNativeDriver: true,
        }),
        Animated.timing(spinAnim, {
          toValue: 1,
          duration: 1100,
          easing: Easing.linear,
          useNativeDriver: true,
        }),
      ]),
    );
    loop.start();

    return () => {
      loop.stop();
      spinAnim.stopAnimation();
    };
  }, [spinAnim]);

  const rotate = spinAnim.interpolate({
    inputRange: [0, 1],
    outputRange: ["-36deg", "324deg"],
  });

  return (
    <View
      pointerEvents="none"
      style={styles.loadingRingWrap}
    >
      <View style={styles.loadingRingBase} />
      <Animated.View style={[styles.loadingRingAccent, { transform: [{ rotate }] }]} />
    </View>
  );
}

function StartFrame3Stage() {
  return (
    <>
      <StartMobileBackdrop />
      <View
        pointerEvents="none"
        style={[
          styles.abs,
          {
            left: 167,
            top: 305,
          },
        ]}
      >
        <AuthenticationLoadingRing />
      </View>

      <Label
        x={122}
        y={437}
        width={147}
        text={"본인 확인\n진행 중입니다."}
        color={START_MOBILE_TEXT}
        size={24}
        weight={700}
        lineHeight={39}
        align="center"
      />
      <Label
        x={108}
        y={754}
        width={174}
        text="소요 1~2분 · 암호화된 안전한 인증"
        color={START_MOBILE_CAPTION}
        size={12}
        weight={500}
        lineHeight={16}
        align="center"
      />
    </>
  );
}

function StartFrame4Stage({
  onNext,
  buttonPressed,
}: {
  onNext: () => void;
  buttonPressed?: boolean;
}) {
  const badgeAnim = useRef(new Animated.Value(0)).current;
  const checkAnim = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    badgeAnim.setValue(0);
    checkAnim.setValue(0);

    const badge = Animated.timing(badgeAnim, {
      toValue: 1,
      duration: 360,
      delay: 140,
      easing: Easing.out(Easing.cubic),
      useNativeDriver: true,
    });
    const check = Animated.timing(checkAnim, {
      toValue: 1,
      duration: 220,
      delay: 420,
      easing: Easing.out(Easing.cubic),
      useNativeDriver: true,
    });

    const sequence = Animated.parallel([badge, check]);
    sequence.start();
    return () => sequence.stop();
  }, [badgeAnim, checkAnim]);

  const badgeScale = badgeAnim.interpolate({
    inputRange: [0, 1],
    outputRange: [0.72, 1],
  });
  const badgeTranslateY = badgeAnim.interpolate({
    inputRange: [0, 1],
    outputRange: [8, 0],
  });
  const checkTranslateY = checkAnim.interpolate({
    inputRange: [0, 1],
    outputRange: [4, 0],
  });

  return (
    <>
      <StartMobileBackdrop />
      <Animated.View
        pointerEvents="none"
        style={[
          styles.abs,
          styles.checkCircle,
          {
            left: 169,
            top: 307,
            opacity: badgeAnim,
            transform: [{ scale: badgeScale }, { translateY: badgeTranslateY }],
          },
        ]}
      >
        <Animated.Text
          style={[
            styles.checkIcon,
            {
              opacity: checkAnim,
              transform: [{ translateY: checkTranslateY }],
            },
          ]}
        >
          ✓
        </Animated.Text>
      </Animated.View>

      <Label
        x={114}
        y={425}
        width={162}
        text={"본인 확인이\n완료되었습니다."}
        color={START_MOBILE_TEXT}
        size={24}
        weight={700}
        lineHeight={39}
        align="center"
      />

      <AbsoluteButton
        x={40}
        y={678}
        width={310}
        height={60}
        radius={24}
        fill={START_MOBILE_ACCENT}
        stroke={START_MOBILE_ACCENT}
        label="계속하기"
        labelColor="#ffffff"
        labelSize={18}
        labelWeight={700}
        onPress={onNext}
        pressedFill="#244c65"
        forcePressed={buttonPressed}
        disabled={buttonPressed}
        softShadow
        smoothPress
      />
      <Label
        x={122}
        y={754}
        width={146}
        text="민원 신고를 계속 진행합니다."
        color={START_MOBILE_CAPTION}
        size={12}
        weight={500}
        lineHeight={16}
        align="center"
      />
    </>
  );
}

function Backdrop({ bgColor }: { bgColor: string }) {
  return (
    <>
      <Rect x={0} y={0} width={393} height={852} fill={bgColor} />
      <Rect
        x={242}
        y={-96}
        width={250}
        height={250}
        radius={999}
        fill="rgba(124, 197, 255, 0.35)"
      />
      <Rect
        x={-108}
        y={652}
        width={260}
        height={260}
        radius={999}
        fill="rgba(181, 227, 255, 0.45)"
      />
    </>
  );
}

function ChatIntakeStartStage({ onNext }: { onNext: () => void }) {
  return (
    <>
      <Backdrop bgColor="#f8fafc" />
      <Rect x={24} y={96} width={345} height={670} radius={30} fill="#ffffff" stroke="#d9e2f2" />

      <Rect x={42} y={128} width={112} height={30} radius={15} fill="#eaf1ff" stroke="#bfdbfe" />
      <Label x={72} y={136} text="챗봇 접수" color="#1e40af" size={13} weight={700} />

      <Label
        x={42}
        y={180}
        text={"층간소음 민원,\n대화로 쉽게 접수해요"}
        color="#0f172a"
        size={32}
        weight={700}
        lineHeight={39}
      />
      <Label
        x={42}
        y={276}
        text={"AI가 질문을 이끌어 주고\n정부24 제출용 문안을 자동으로 정리합니다."}
        color="#475569"
        size={16}
        weight={500}
        lineHeight={22}
      />

      <Rect x={42} y={350} width={250} height={74} radius={20} fill="#eef4ff" stroke="#d7e7ff" />
      <Label
        x={58}
        y={369}
        text={"안녕하세요. 어떤 소음이\n가장 불편하신가요?"}
        color="#1e293b"
        size={15}
        weight={600}
      />

      <Rect x={129} y={438} width={198} height={62} radius={20} fill="#1d4ed8" />
      <Label x={149} y={460} text="밤마다 쿵쿵 소리가 나요." color="#ffffff" size={15} weight={600} />

      <Rect x={42} y={524} width={148} height={40} radius={20} fill="#ffffff" stroke="#d9e2f2" />
      <Label x={63} y={536} text="답변시간 평균 2분" color="#334155" size={13} weight={600} />

      <Rect x={202} y={524} width={125} height={40} radius={20} fill="#ffffff" stroke="#d9e2f2" />
      <Label x={225} y={536} text="중간 저장 가능" color="#334155" size={13} weight={600} />

      <AbsoluteButton
        x={42}
        y={676}
        width={309}
        height={58}
        radius={30}
        fill="#1d4ed8"
        stroke="#1d4ed8"
        label="대화 시작하기"
        labelColor="#ffffff"
        labelSize={22}
        labelWeight={700}
        onPress={onNext}
        pressedFill="#1e40af"
      />
      <Label
        x={100}
        y={747}
        text="이후 단계에서 내용을 수정할 수 있어요"
        color="#64748b"
        size={12}
        weight={500}
      />
    </>
  );
}

function ChatIntakeConversationStage({ onNext }: { onNext: () => void }) {
  return (
    <>
      <Backdrop bgColor="#f8fafc" />
      <Rect x={24} y={96} width={345} height={670} radius={30} fill="#ffffff" stroke="#d9e2f2" />

      <Rect x={42} y={128} width={132} height={30} radius={15} fill="#eaf1ff" stroke="#bfdbfe" />
      <Label x={58} y={136} text="1단계 · 상황 파악" color="#1e40af" size={13} weight={700} />
      <Label x={42} y={176} text="AI와 실시간 대화" color="#0f172a" size={32} weight={700} />
      <Label
        x={42}
        y={224}
        text="핵심 질문에 답하면 접수 초안을 자동 작성해요."
        color="#475569"
        size={15}
        weight={500}
      />

      <Rect x={42} y={268} width={309} height={8} radius={999} fill="#e2e8f0" />
      <Rect x={42} y={268} width={124} height={8} radius={999} fill="#1d4ed8" />

      <Rect x={42} y={292} width={244} height={66} radius={20} fill="#eef4ff" stroke="#d7e7ff" />
      <Label x={58} y={315} text="언제부터 소음이 시작됐나요?" color="#1e293b" size={15} weight={600} />

      <Rect x={119} y={370} width={208} height={62} radius={20} fill="#1d4ed8" />
      <Label
        x={138}
        y={392}
        text="지난달부터 거의 매일 밤이에요."
        color="#ffffff"
        size={15}
        weight={600}
      />

      <Rect x={42} y={446} width={272} height={74} radius={20} fill="#eef4ff" stroke="#d7e7ff" />
      <Label
        x={58}
        y={466}
        text={"주로 발생하는 시간대를\n알려주시면 다음 단계로 갈게요."}
        color="#1e293b"
        size={15}
        weight={600}
      />

      <Rect x={42} y={546} width={309} height={54} radius={27} fill="#ffffff" stroke="#cbd5e1" />
      <Label x={62} y={564} text="답변 입력 또는 음성으로 말하기" color="#94a3b8" size={14} weight={500} />
      <Rect x={305} y={555} width={36} height={36} radius={999} fill="#1d4ed8" />
      <Label x={319} y={564} text=">" color="#ffffff" size={16} weight={700} />

      <AbsoluteButton
        x={42}
        y={676}
        width={309}
        height={58}
        radius={30}
        fill="#1d4ed8"
        stroke="#1d4ed8"
        label="다음 질문으로"
        labelColor="#ffffff"
        labelSize={22}
        labelWeight={700}
        onPress={onNext}
        pressedFill="#1e40af"
      />
      <Label x={112} y={747} text="대화 내용은 자동으로 저장됩니다" color="#64748b" size={12} weight={500} />
    </>
  );
}

function ChatIntakeQuestionsStage({ onNext }: { onNext: () => void }) {
  return (
    <>
      <Backdrop bgColor="#f8fafc" />
      <Rect x={24} y={96} width={345} height={670} radius={30} fill="#ffffff" stroke="#d9e2f2" />

      <Rect x={42} y={128} width={136} height={30} radius={15} fill="#eaf1ff" stroke="#bfdbfe" />
      <Label x={58} y={136} text="2단계 · 핵심 질문" color="#1e40af" size={13} weight={700} />
      <Label x={42} y={176} text="질문에 체크로 답변" color="#0f172a" size={32} weight={700} />
      <Label
        x={42}
        y={224}
        text="정확한 분류를 위해 필요한 정보예요."
        color="#475569"
        size={15}
        weight={500}
      />

      <Rect x={42} y={268} width={309} height={8} radius={999} fill="#e2e8f0" />
      <Rect x={42} y={268} width={185} height={8} radius={999} fill="#1d4ed8" />

      <Rect x={42} y={298} width={309} height={84} radius={20} fill="#ffffff" stroke="#d9e2f2" />
      <Label x={58} y={316} text="Q1. 주로 소음이 발생하는 시간대는?" color="#1e293b" size={15} weight={700} />
      <Rect x={58} y={350} width={86} height={28} radius={14} fill="#eaf1ff" stroke="#bfdbfe" />
      <Label x={74} y={357} text="22시~24시" color="#1e40af" size={12} weight={600} />
      <Rect x={154} y={350} width={92} height={28} radius={14} fill="#f8fafc" stroke="#cbd5e1" />
      <Label x={171} y={357} text="자정~새벽" color="#475569" size={12} weight={600} />

      <Rect x={42} y={392} width={309} height={84} radius={20} fill="#ffffff" stroke="#d9e2f2" />
      <Label x={58} y={410} text="Q2. 주당 발생 횟수는 어느 정도인가요?" color="#1e293b" size={15} weight={700} />
      <Rect x={58} y={444} width={202} height={6} radius={999} fill="#e2e8f0" />
      <Rect x={58} y={444} width={124} height={6} radius={999} fill="#1d4ed8" />
      <Label x={269} y={437} text="주 5회" color="#1e40af" size={13} weight={700} />

      <Rect x={42} y={486} width={309} height={116} radius={20} fill="#ffffff" stroke="#d9e2f2" />
      <Label x={58} y={504} text="Q3. 이미 관리사무소에 알렸나요?" color="#1e293b" size={15} weight={700} />
      <Rect x={58} y={538} width={120} height={40} radius={20} fill="#1d4ed8" />
      <Label x={82} y={550} text="네, 알렸어요" color="#ffffff" size={14} weight={600} />
      <Rect x={190} y={538} width={120} height={40} radius={20} fill="#ffffff" stroke="#cbd5e1" />
      <Label x={223} y={550} text="아직이에요" color="#475569" size={14} weight={600} />
      <Label
        x={58}
        y={586}
        text="추후 증빙자료 첨부 단계에서 내용을 추가할 수 있어요."
        color="#64748b"
        size={12}
        weight={500}
      />

      <AbsoluteButton
        x={42}
        y={676}
        width={309}
        height={58}
        radius={30}
        fill="#1d4ed8"
        stroke="#1d4ed8"
        label="다음: 증거 준비"
        labelColor="#ffffff"
        labelSize={22}
        labelWeight={700}
        onPress={onNext}
        pressedFill="#1e40af"
      />
      <Label
        x={92}
        y={747}
        text="문항은 자동 저장되며 언제든 수정 가능합니다"
        color="#64748b"
        size={12}
        weight={500}
      />
    </>
  );
}

function ChatIntakeEvidenceStage({ onNext }: { onNext: () => void }) {
  return (
    <>
      <Backdrop bgColor="#f8fafc" />
      <Rect x={24} y={96} width={345} height={670} radius={30} fill="#ffffff" stroke="#d9e2f2" />

      <Rect x={42} y={128} width={140} height={30} radius={15} fill="#eaf1ff" stroke="#bfdbfe" />
      <Label x={58} y={136} text="3단계 · 증거 자료" color="#1e40af" size={13} weight={700} />
      <Label x={42} y={176} text="증거 자료를 모아볼게요" color="#0f172a" size={30} weight={700} />
      <Label
        x={42}
        y={222}
        text="없어도 접수 가능, 있으면 처리 속도가 빨라져요."
        color="#475569"
        size={15}
        weight={500}
      />

      <Rect x={42} y={264} width={309} height={8} radius={999} fill="#e2e8f0" />
      <Rect x={42} y={264} width={247} height={8} radius={999} fill="#1d4ed8" />

      <Rect x={42} y={294} width={309} height={126} radius={20} fill="#f8fafc" stroke="#cbd5e1" />
      <Rect x={58} y={334} width={44} height={44} radius={22} fill="#eaf1ff" stroke="#bfdbfe" />
      <Label x={75} y={343} text="+" color="#1e40af" size={22} weight={700} />
      <Label x={114} y={332} text="소음 녹음 파일" color="#1e293b" size={16} weight={700} />
      <Label x={114} y={354} text="mp3, m4a, wav · 최대 3개" color="#64748b" size={13} weight={500} />
      <Rect x={114} y={380} width={96} height={30} radius={15} fill="#1d4ed8" />
      <Label x={140} y={387} text="파일 추가" color="#ffffff" size={13} weight={700} />

      <Rect x={42} y={432} width={309} height={150} radius={20} fill="#ffffff" stroke="#d9e2f2" />
      <Label x={58} y={450} text="현재 첨부 상태" color="#1e293b" size={15} weight={700} />
      <Rect x={58} y={478} width={14} height={14} radius={7} fill="#1d4ed8" />
      <Label x={80} y={475} text="소음 발생 시간 메모" color="#334155" size={14} weight={600} />
      <Rect x={58} y={510} width={14} height={14} radius={7} fill="#1d4ed8" />
      <Label x={80} y={507} text="소음 유형 선택" color="#334155" size={14} weight={600} />
      <Rect x={58} y={542} width={14} height={14} radius={7} fill="#cbd5e1" />
      <Label x={80} y={539} text="연락 가능한 시간대" color="#64748b" size={14} weight={500} />
      <Label
        x={58}
        y={566}
        text="팁: 관리사무소 안내 문자 캡처도 도움이 됩니다."
        color="#64748b"
        size={12}
        weight={500}
      />

      <AbsoluteButton
        x={42}
        y={618}
        width={309}
        height={44}
        radius={22}
        fill="#ffffff"
        stroke="#cbd5e1"
        label="지금은 건너뛰기"
        labelColor="#475569"
        labelSize={16}
        labelWeight={600}
        onPress={onNext}
        pressedFill="#f8fafc"
      />
      <AbsoluteButton
        x={42}
        y={676}
        width={309}
        height={58}
        radius={30}
        fill="#1d4ed8"
        stroke="#1d4ed8"
        label="다음: 제출 전 검토"
        labelColor="#ffffff"
        labelSize={22}
        labelWeight={700}
        onPress={onNext}
        pressedFill="#1e40af"
      />
      <Label
        x={97}
        y={747}
        text="제출 전에 첨부 항목을 다시 확인할 수 있어요"
        color="#64748b"
        size={12}
        weight={500}
      />
    </>
  );
}

function ChatIntakeReviewStage({ onNext }: { onNext: () => void }) {
  return (
    <>
      <Backdrop bgColor="#f8fafc" />
      <Rect x={24} y={96} width={345} height={670} radius={30} fill="#ffffff" stroke="#d9e2f2" />

      <Rect x={42} y={128} width={142} height={30} radius={15} fill="#eaf1ff" stroke="#bfdbfe" />
      <Label x={58} y={136} text="4단계 · 제출 검토" color="#1e40af" size={13} weight={700} />
      <Label x={42} y={176} text="제출 전 최종 검토" color="#0f172a" size={30} weight={700} />
      <Label
        x={42}
        y={222}
        text="AI가 정리한 민원 초안을 확인하고 바로 제출하세요."
        color="#475569"
        size={15}
        weight={500}
      />

      <Rect x={42} y={264} width={309} height={8} radius={999} fill="#e2e8f0" />
      <Rect x={42} y={264} width={309} height={8} radius={999} fill="#1d4ed8" />

      <Rect x={42} y={294} width={309} height={122} radius={20} fill="#ffffff" stroke="#d9e2f2" />
      <Label x={58} y={312} text="민원 요약" color="#1e293b" size={15} weight={700} />
      <Label x={58} y={338} text="• 밤 10시 이후 반복되는 충격음 발생" color="#334155" size={13} weight={500} />
      <Label x={58} y={358} text="• 주 5회 이상, 수면 방해 수준으로 지속" color="#334155" size={13} weight={500} />
      <Label x={58} y={378} text="• 관리사무소에 1차 통보 완료" color="#334155" size={13} weight={500} />

      <Rect x={42} y={430} width={309} height={116} radius={20} fill="#f8fafc" stroke="#cbd5e1" />
      <Label x={58} y={448} text="첨부 예정 자료" color="#1e293b" size={15} weight={700} />
      <Rect x={58} y={480} width={110} height={32} radius={16} fill="#eaf1ff" stroke="#bfdbfe" />
      <Label x={81} y={489} text="녹음파일 1개" color="#1e40af" size={13} weight={600} />
      <Rect x={178} y={480} width={96} height={32} radius={16} fill="#eaf1ff" stroke="#bfdbfe" />
      <Label x={203} y={489} text="시간 메모" color="#1e40af" size={13} weight={600} />
      <Label
        x={58}
        y={520}
        text="필요 시 제출 전 파일을 추가/교체할 수 있어요."
        color="#64748b"
        size={12}
        weight={500}
      />

      <Rect x={42} y={558} width={309} height={44} radius={22} fill="#ffffff" stroke="#cbd5e1" />
      <Rect x={58} y={571} width={18} height={18} radius={9} fill="#1d4ed8" />
      <Label x={86} y={571} text="제출 전 내용 확인을 완료했습니다." color="#334155" size={14} weight={600} />

      <AbsoluteButton
        x={42}
        y={618}
        width={309}
        height={44}
        radius={22}
        fill="#ffffff"
        stroke="#cbd5e1"
        label="수정하기"
        labelColor="#475569"
        labelSize={16}
        labelWeight={600}
      />
      <AbsoluteButton
        x={42}
        y={676}
        width={309}
        height={58}
        radius={30}
        fill="#1d4ed8"
        stroke="#1d4ed8"
        label="정부24로 제출하기"
        labelColor="#ffffff"
        labelSize={22}
        labelWeight={700}
        onPress={onNext}
        pressedFill="#1e40af"
      />
      <Label x={119} y={747} text="제출 후 접수번호를 안내해드려요" color="#64748b" size={12} weight={500} />
    </>
  );
}

function renderStage(
  stage: number,
  onNext: () => void,
  onStartPress: () => void,
  onBridgePress: () => void,
  onFinishAuthPress: () => void,
  startButtonPressed: boolean,
  bridgeButtonPressed: boolean,
  finishAuthButtonPressed: boolean,
) {
  switch (stage) {
    case 1:
      return <StartFrame1Stage onStartPress={onStartPress} buttonPressed={startButtonPressed} />;
    case 2:
      return <StartFrame2Stage onNext={onBridgePress} buttonPressed={bridgeButtonPressed} />;
    case 3:
      return <StartFrame3Stage />;
    case 4:
      return <StartFrame4Stage onNext={onFinishAuthPress} buttonPressed={finishAuthButtonPressed} />;
    case 5:
    case 6:
    case 7:
      return <StartFrame4Stage onNext={onFinishAuthPress} buttonPressed={finishAuthButtonPressed} />;
    case 8:
      return DISABLE_CHAT_INTAKE_STAGES ? null : <ChatIntakeStartStage onNext={onNext} />;
    case 9:
      return DISABLE_CHAT_INTAKE_STAGES ? null : <ChatIntakeConversationStage onNext={onNext} />;
    case 10:
      return DISABLE_CHAT_INTAKE_STAGES ? null : <ChatIntakeQuestionsStage onNext={onNext} />;
    case 11:
      return DISABLE_CHAT_INTAKE_STAGES ? null : <ChatIntakeEvidenceStage onNext={onNext} />;
    case 12:
      return DISABLE_CHAT_INTAKE_STAGES ? null : <ChatIntakeReviewStage onNext={onNext} />;
    default:
      return null;
  }
}

export function ScenarioFlowTestScreen() {
  const [stage, setStage] = useState(1);
  const [startButtonPressed, setStartButtonPressed] = useState(false);
  const [bridgeButtonPressed, setBridgeButtonPressed] = useState(false);
  const [finishAuthButtonPressed, setFinishAuthButtonPressed] = useState(false);
  const [isConversationListVisible, setIsConversationListVisible] = useState(false);
  const [chatSession, setChatSession] = useState<ConversationListItem>({
    id: "session-current",
    title: "층간소음 상담",
    preview: DEFAULT_CHAT_PREVIEW,
    statusLabel: "준비 중",
    caseId: null,
    updatedAtText: formatSessionUpdatedAt(Date.now()),
  });
  const { resetCase, caseId, status, lastFollowUpQuestion } = useCaseContext();
  const { width, height } = useWindowDimensions();
  const transition = useRef(new Animated.Value(1)).current;
  const conversationListTransition = useRef(new Animated.Value(0)).current;
  const transitionDurationRef = useRef(DEFAULT_TRANSITION_DURATION);

  const availableWidth = width;
  const availableHeight = height;
  const widthScale = availableWidth / BASE_WIDTH;
  const heightScale = availableHeight / BASE_HEIGHT;
  const useWidthFit = heightScale >= 0.9;
  const scale = useWidthFit ? widthScale : Math.min(widthScale, heightScale);
  const scaledWidth = BASE_WIDTH * scale;
  const scaledHeight = BASE_HEIGHT * scale;
  const offsetX = (availableWidth - scaledWidth) / 2;
  const offsetY = useWidthFit ? 0 : (availableHeight - scaledHeight) / 2;

  const activeSessionPreview = useMemo(() => {
    const followUp = lastFollowUpQuestion?.trim();
    if (followUp && followUp.length > 0) {
      return followUp;
    }
    return chatSession.preview || DEFAULT_CHAT_PREVIEW;
  }, [chatSession.preview, lastFollowUpQuestion]);

  useEffect(() => {
    const rule = AUTO_ADVANCE_RULES[stage];
    if (!rule) {
      return;
    }

    const timer = setTimeout(() => {
      transitionDurationRef.current = DEFAULT_TRANSITION_DURATION;
      setStage(rule.nextStage);
    }, rule.delayMs);

    return () => clearTimeout(timer);
  }, [stage]);

  useEffect(() => {
    if (!DISABLE_CHAT_INTAKE_STAGES) {
      return;
    }
    if (stage >= 8 && stage < CHAT_STAGE) {
      transitionDurationRef.current = BUTTON_TRANSITION_DURATION;
      setStage(CHAT_STAGE);
    }
  }, [stage]);

  useEffect(() => {
    const duration = transitionDurationRef.current;
    transitionDurationRef.current = DEFAULT_TRANSITION_DURATION;

    transition.setValue(0);
    const animation = Animated.timing(transition, {
      toValue: 1,
      duration,
      easing: Easing.out(Easing.cubic),
      useNativeDriver: true,
    });
    animation.start();

    return () => animation.stop();
  }, [stage, transition]);

  useEffect(() => {
    if (stage !== CHAT_STAGE && isConversationListVisible) {
      setIsConversationListVisible(false);
    }
  }, [isConversationListVisible, stage]);

  useEffect(() => {
    const animation = Animated.timing(conversationListTransition, {
      toValue: isConversationListVisible ? 1 : 0,
      duration: 260,
      easing: Easing.out(Easing.cubic),
      useNativeDriver: true,
    });
    animation.start();
    return () => animation.stop();
  }, [conversationListTransition, isConversationListVisible]);

  useEffect(() => {
    setChatSession((prev) => ({
      ...prev,
      caseId: caseId ?? prev.caseId,
      preview: activeSessionPreview,
      statusLabel: toStatusLabel(status),
      updatedAtText: formatSessionUpdatedAt(Date.now()),
    }));
  }, [activeSessionPreview, caseId, status]);

  const handleNext = () => {
    transitionDurationRef.current = BUTTON_TRANSITION_DURATION;
    setStage((prev) => Math.min(prev + 1, CHAT_STAGE));
  };

  const handleStartPress = () => {
    if (startButtonPressed) {
      return;
    }
    resetCase();
    setChatSession({
      id: "session-current",
      title: "층간소음 상담",
      preview: DEFAULT_CHAT_PREVIEW,
      statusLabel: "준비 중",
      caseId: null,
      updatedAtText: formatSessionUpdatedAt(Date.now()),
    });
    setIsConversationListVisible(false);
    setStartButtonPressed(true);
    setTimeout(() => {
      setStartButtonPressed(false);
      transitionDurationRef.current = BUTTON_TRANSITION_DURATION;
      setStage(2);
    }, 180);
  };

  const handleBridgePress = () => {
    if (bridgeButtonPressed) {
      return;
    }
    setBridgeButtonPressed(true);
    setTimeout(() => {
      setBridgeButtonPressed(false);
      transitionDurationRef.current = BUTTON_TRANSITION_DURATION;
      setStage(3);
    }, 180);
  };

  const handleFinishAuthPress = () => {
    if (finishAuthButtonPressed) {
      return;
    }
    setFinishAuthButtonPressed(true);
    setTimeout(() => {
      setFinishAuthButtonPressed(false);
      transitionDurationRef.current = BUTTON_TRANSITION_DURATION;
      setStage(CHAT_STAGE);
    }, 180);
  };

  const moveToStage = (nextStage: number) => {
    transitionDurationRef.current = BUTTON_TRANSITION_DURATION;
    setStage(nextStage);
  };

  if (stage === CHAT_STAGE) {
    const chatLayerStyle: StyleProp<ViewStyle> = [
      styles.chatLayer,
      {
        opacity: conversationListTransition.interpolate({
          inputRange: [0, 1],
          outputRange: [1, 0.24],
        }),
        transform: [
          {
            translateX: conversationListTransition.interpolate({
              inputRange: [0, 1],
              outputRange: [0, -18],
            }),
          },
        ],
      },
    ];
    const listLayerStyle: StyleProp<ViewStyle> = [
      styles.listLayer,
      {
        opacity: conversationListTransition,
        transform: [
          {
            translateX: conversationListTransition.interpolate({
              inputRange: [0, 1],
              outputRange: [26, 0],
            }),
          },
          {
            scale: conversationListTransition.interpolate({
              inputRange: [0, 1],
              outputRange: [0.988, 1],
            }),
          },
        ],
      },
    ];

    return (
      <View style={styles.chatRoot}>
        <Animated.View pointerEvents={isConversationListVisible ? "none" : "auto"} style={chatLayerStyle}>
          <ChatbotConversationScreen
            onBack={() => setIsConversationListVisible(true)}
            onRestartFlow={() => {
              resetCase();
              setIsConversationListVisible(false);
              moveToStage(1);
            }}
          />
        </Animated.View>
        <Animated.View pointerEvents={isConversationListVisible ? "auto" : "none"} style={listLayerStyle}>
          <ConversationListScreen
            session={chatSession}
            isVisible={isConversationListVisible}
            onSelectSession={() => setIsConversationListVisible(false)}
          />
        </Animated.View>
      </View>
    );
  }

  if (stage === 14) {
    return (
      <EvidenceCollectionScreen
        onBack={() => moveToStage(13)}
        onNext={() => moveToStage(15)}
      />
    );
  }

  if (stage === 15) {
    return (
      <MediationSupportScreen
        onBack={() => moveToStage(14)}
        onNext={() => moveToStage(16)}
      />
    );
  }

  if (stage === 16) {
    return (
      <SubmissionReviewScreen
        onBack={() => moveToStage(15)}
        onSubmitted={() => moveToStage(17)}
      />
    );
  }

  if (stage === 17) {
    return (
      <TimelineScreen
        onBack={() => moveToStage(16)}
        onCompleted={() => moveToStage(18)}
      />
    );
  }

  if (stage === FINAL_STAGE) {
    return (
      <CompletionSummaryScreen
        onRestart={() => {
          resetCase();
          moveToStage(1);
        }}
      />
    );
  }

  return (
    <View style={styles.safeArea}>
      <Animated.View
        style={[
          styles.frame,
          {
            left: offsetX,
            top: offsetY,
            opacity: transition,
            transform: [
              {
                translateY: transition.interpolate({
                  inputRange: [0, 1],
                  outputRange: [10, 0],
                }),
              },
              { scale },
            ],
          },
        ]}
      >
        {renderStage(
          stage,
          handleNext,
          handleStartPress,
          handleBridgePress,
          handleFinishAuthPress,
          startButtonPressed,
          bridgeButtonPressed,
          finishAuthButtonPressed,
        )}
      </Animated.View>
    </View>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: "#f8fafc",
  },
  frame: {
    position: "absolute",
    width: 393,
    height: 852,
    backgroundColor: "#ffffff",
    overflow: "hidden",
  },
  chatRoot: {
    flex: 1,
    backgroundColor: "#f8fafc",
  },
  chatLayer: {
    ...StyleSheet.absoluteFillObject,
  },
  listLayer: {
    ...StyleSheet.absoluteFillObject,
  },
  abs: {
    position: "absolute",
  },
  absText: {
    position: "absolute",
  },
  buttonSurface: {
    width: "100%",
    height: "100%",
  },
  startCardShadow: {
    shadowColor: "#0f172a",
    shadowOpacity: 0.06,
    shadowRadius: 18,
    shadowOffset: { width: 0, height: 10 },
    elevation: 5,
  },
  startGov24Logo: {
    width: 102,
    height: 102,
  },
  startLoginTitle: {
    color: START_MOBILE_ACCENT,
    fontSize: 24,
    lineHeight: 32,
    fontWeight: "700",
    textAlign: "center",
  },
  startMobileCtaShadow: {
    shadowColor: "#22384a",
    shadowOpacity: 0.22,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: 8 },
    elevation: 6,
  },
  startMobileCtaShadowPressed: {
    shadowOpacity: 0.12,
    shadowRadius: 5,
    shadowOffset: { width: 0, height: 3 },
    elevation: 3,
  },
  loadingRingWrap: {
    width: 56,
    height: 56,
    alignItems: "center",
    justifyContent: "center",
  },
  loadingRingBase: {
    position: "absolute",
    width: 56,
    height: 56,
    borderRadius: 28,
    borderWidth: 7,
    borderColor: "#bfd0da",
  },
  loadingRingAccent: {
    position: "absolute",
    width: 56,
    height: 56,
    borderRadius: 28,
    borderWidth: 7,
    borderColor: "transparent",
    borderTopColor: START_MOBILE_ACCENT,
    borderLeftColor: START_MOBILE_ACCENT,
    transform: [{ rotate: "-36deg" }],
  },
  checkCircle: {
    width: 52,
    height: 52,
    borderRadius: 26,
    backgroundColor: START_MOBILE_ACCENT,
    alignItems: "center",
    justifyContent: "center",
  },
  checkIcon: {
    color: "#ffffff",
    fontSize: 28,
    lineHeight: 30,
    fontWeight: "700",
  },
});
