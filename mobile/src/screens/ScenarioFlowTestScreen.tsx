import { useEffect, useRef, useState } from "react";
import {
  Animated,
  Easing,
  Pressable,
  StyleSheet,
  Text,
  TextStyle,
  useWindowDimensions,
  View,
} from "react-native";
import { ChatbotConversationScreen } from "./ChatbotConversationScreen";

const FINAL_STAGE = 13;
const BASE_WIDTH = 393;
const BASE_HEIGHT = 852;
const DEFAULT_TRANSITION_DURATION = 800;
const BUTTON_TRANSITION_DURATION = DEFAULT_TRANSITION_DURATION;
const AUTO_ADVANCE_RULES: Partial<Record<number, { delayMs: number; nextStage: number }>> = {
  1: { delayMs: 1200, nextStage: 2 },
  2: { delayMs: 1200, nextStage: 3 },
  5: { delayMs: 3000, nextStage: 8 },
};

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
}: AbsoluteButtonProps) {
  const textStyle = {
    color: labelColor,
    fontSize: labelSize,
    fontWeight: `${labelWeight}` as TextStyle["fontWeight"],
    lineHeight: Math.round(labelSize * 1.21),
  };

  const baseStyle = {
    left: x,
    top: y,
    width,
    height,
    borderRadius: radius,
    borderWidth: 1,
    borderColor: stroke ?? fill,
    alignItems: "center" as const,
    justifyContent: "center" as const,
  };

  if (!onPress) {
    return (
      <View style={[styles.abs, baseStyle, { backgroundColor: fill }]}>
        <Text style={textStyle}>{label}</Text>
      </View>
    );
  }

  return (
    <Pressable
      disabled={disabled}
      onPress={onPress}
      style={({ pressed }) => [
        styles.abs,
        baseStyle,
        { backgroundColor: pressed || forcePressed ? pressedFill ?? fill : fill },
      ]}
    >
      <Text style={textStyle}>{label}</Text>
    </Pressable>
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

function GovernmentIconMock() {
  return (
    <>
      <Rect
        x={145}
        y={168}
        width={102}
        height={102}
        radius={22}
        fill="#ffffff"
        stroke="#d9e2f2"
      />
      <Label x={169} y={201} text="정부24" color="#1d4ed8" size={22} weight={700} />
      <Label x={180} y={229} text="연동" color="#64748b" size={13} weight={600} />
    </>
  );
}

function StartStage({
  onStartPress,
  buttonPressed,
  showHeadline = true,
  showPrimaryCta = true,
}: {
  onStartPress?: () => void;
  buttonPressed?: boolean;
  showHeadline?: boolean;
  showPrimaryCta?: boolean;
}) {
  const iconAnim = useRef(new Animated.Value(0)).current;
  const headlineAnim = useRef(new Animated.Value(showHeadline ? 1 : 0)).current;
  const ctaAnim = useRef(new Animated.Value(showPrimaryCta ? 1 : 0)).current;

  useEffect(() => {
    iconAnim.setValue(0);
    const animation = Animated.timing(iconAnim, {
      toValue: 1,
      duration: 520,
      easing: Easing.out(Easing.cubic),
      useNativeDriver: true,
    });
    animation.start();
    return () => animation.stop();
  }, [iconAnim]);

  useEffect(() => {
    if (!showHeadline) {
      headlineAnim.stopAnimation();
      headlineAnim.setValue(0);
      return;
    }

    headlineAnim.setValue(0);
    const animation = Animated.timing(headlineAnim, {
      toValue: 1,
      duration: 460,
      easing: Easing.out(Easing.cubic),
      useNativeDriver: true,
    });
    animation.start();
    return () => animation.stop();
  }, [showHeadline, headlineAnim]);

  useEffect(() => {
    if (!showPrimaryCta) {
      ctaAnim.stopAnimation();
      ctaAnim.setValue(0);
      return;
    }

    ctaAnim.setValue(0);
    const animation = Animated.timing(ctaAnim, {
      toValue: 1,
      duration: 460,
      easing: Easing.out(Easing.cubic),
      useNativeDriver: true,
    });
    animation.start();
    return () => animation.stop();
  }, [showPrimaryCta, ctaAnim]);

  const iconTranslateY = iconAnim.interpolate({
    inputRange: [0, 1],
    outputRange: [12, 0],
  });

  const headlineTranslateY = headlineAnim.interpolate({
    inputRange: [0, 1],
    outputRange: [10, 0],
  });

  const ctaTranslateY = ctaAnim.interpolate({
    inputRange: [0, 1],
    outputRange: [14, 0],
  });

  return (
    <>
      <Backdrop bgColor="#eef7ff" />
      <Rect
        x={24}
        y={114}
        width={345}
        height={642}
        radius={30}
        fill="rgba(255, 255, 255, 0.94)"
        stroke="rgba(77, 171, 247, 0.22)"
      />
      <Animated.View
        style={[
          styles.abs,
          {
            left: 0,
            top: 0,
            opacity: iconAnim,
            transform: [{ translateY: iconTranslateY }],
          },
        ]}
      >
        <GovernmentIconMock />
      </Animated.View>
      {showHeadline ? (
        <Animated.View
          pointerEvents="none"
          style={[
            styles.abs,
            {
              left: 0,
              top: 0,
              opacity: headlineAnim,
              transform: [{ translateY: headlineTranslateY }],
            },
          ]}
        >
          <Label
            x={88}
            y={377}
            text="신속한 처리, "
            color="#0f172a"
            size={24}
            weight={400}
            lineHeight={42}
          />
          <Label
            x={211}
            y={377}
            text="정부 24"
            color="#0f172a"
            size={24}
            weight={400}
            lineHeight={42}
          />
        </Animated.View>
      ) : null}
      {showPrimaryCta ? (
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
            x={42}
            y={558}
            width={309}
            height={58}
            radius={30}
            fill="#2589ff"
            stroke="#1d74ed"
            label="시작하기"
            labelColor="#ffffff"
            labelSize={22}
            labelWeight={700}
            onPress={onStartPress}
            pressedFill="#1d74ed"
            forcePressed={buttonPressed}
            disabled={buttonPressed}
          />
          <Label
            x={96}
            y={634}
            text="평균 2분 · 언제든 중단 후 이어하기 가능"
            color="#64748b"
            size={12}
            weight={500}
          />
        </Animated.View>
      ) : null}
    </>
  );
}

function BridgeStage({
  onNext,
  buttonPressed,
}: {
  onNext: () => void;
  buttonPressed?: boolean;
}) {
  return (
    <>
      <Backdrop bgColor="#f8fafc" />
      <Rect x={24} y={114} width={345} height={642} radius={30} fill="#ffffff" stroke="#d9e2f2" />

      <Label x={73} y={242} text="정부24 로그인" color="#0f172a" size={24} weight={700} />
      <Label
        x={73}
        y={294}
        text="본인 확인 후 민원 신청을 이어서 진행합니다."
        color="#1e293b"
        size={16}
        weight={500}
      />
      <Label
        x={73}
        y={343}
        text="소요 1~2분 · 암호화된 안전한 인증"
        color="#475569"
        size={14}
        weight={500}
      />

      <AbsoluteButton
        x={42}
        y={558}
        width={309}
        height={58}
        radius={30}
        fill="#1d4ed8"
        stroke="#1d4ed8"
        label="정부24에서 계속"
        labelColor="#ffffff"
        labelSize={22}
        labelWeight={700}
        onPress={onNext}
        pressedFill="#1e40af"
        forcePressed={buttonPressed}
        disabled={buttonPressed}
      />
      <Label x={181} y={637} text="나중에" color="#64748b" size={16} weight={600} />
    </>
  );
}

function CircularLoadingSpinner({ running }: { running: boolean }) {
  const spin = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    if (!running) {
      spin.stopAnimation();
      spin.setValue(0);
      return;
    }

    spin.setValue(0);

    const spinLoop = Animated.loop(
      Animated.sequence([
        Animated.timing(spin, {
          toValue: 0.35,
          duration: 1400,
          easing: Easing.linear,
          useNativeDriver: true,
        }),
        Animated.timing(spin, {
          toValue: 0.65,
          duration: 650,
          easing: Easing.linear,
          useNativeDriver: true,
        }),
        Animated.timing(spin, {
          toValue: 1,
          duration: 1400,
          easing: Easing.linear,
          useNativeDriver: true,
        }),
      ]),
    );

    spinLoop.start();

    return () => {
      spinLoop.stop();
      spin.stopAnimation();
    };
  }, [running, spin]);

  const rotate = spin.interpolate({
    inputRange: [0, 1],
    outputRange: ["0deg", "360deg"],
  });

  return (
    <View
      style={[
        styles.abs,
        {
          left: 166,
          top: 438,
          width: 60,
          height: 60,
          alignItems: "center",
          justifyContent: "center",
        },
      ]}
    >
      <View
        pointerEvents="none"
        style={{
          position: "absolute",
          width: 58,
          height: 58,
          borderRadius: 29,
          borderWidth: 5,
          borderColor: "#d6dbe4",
        }}
      />
      <Animated.View
        pointerEvents="none"
        style={{
          position: "absolute",
          width: 58,
          height: 58,
          borderRadius: 29,
          borderWidth: 5,
          borderColor: "transparent",
          borderTopColor: "#7f8898",
          borderRightColor: "#7f8898",
          transform: [{ rotate }],
        }}
      />
    </View>
  );
}

function LoadingStage() {

  return (
    <>
      <Backdrop bgColor="#f8fafc" />
      <Rect x={24} y={114} width={345} height={642} radius={30} fill="#ffffff" stroke="#d9e2f2" />
      <Label
        x={60}
        y={236}
        text="정부24 인증 페이지로 이동 중입니다"
        color="#0f172a"
        size={28}
        weight={700}
        width={280}
      />
      <Label x={102} y={346} text="잠시만 기다려주세요." color="#475569" size={18} weight={500} />

      <CircularLoadingSpinner running />
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
  startButtonPressed: boolean,
  bridgeButtonPressed: boolean,
) {
  switch (stage) {
    case 1:
      return <StartStage showHeadline={false} showPrimaryCta={false} />;
    case 2:
      return <StartStage showPrimaryCta={false} />;
    case 3:
      return <StartStage onStartPress={onStartPress} buttonPressed={startButtonPressed} />;
    case 4:
      return <BridgeStage onNext={onBridgePress} buttonPressed={bridgeButtonPressed} />;
    case 5:
      return <LoadingStage />;
    case 6:
    case 7:
      return <LoadingStage />;
    case 8:
      return <ChatIntakeStartStage onNext={onNext} />;
    case 9:
      return <ChatIntakeConversationStage onNext={onNext} />;
    case 10:
      return <ChatIntakeQuestionsStage onNext={onNext} />;
    case 11:
      return <ChatIntakeEvidenceStage onNext={onNext} />;
    case 12:
      return <ChatIntakeReviewStage onNext={onNext} />;
    default:
      return null;
  }
}

export function ScenarioFlowTestScreen() {
  const [stage, setStage] = useState(1);
  const [startButtonPressed, setStartButtonPressed] = useState(false);
  const [bridgeButtonPressed, setBridgeButtonPressed] = useState(false);
  const { width, height } = useWindowDimensions();
  const transition = useRef(new Animated.Value(1)).current;
  const previousStageRef = useRef(1);
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
    const previousStage = previousStageRef.current;
    const skipIntroTransition = previousStage <= 3 && stage <= 3;
    previousStageRef.current = stage;

    if (skipIntroTransition) {
      transition.stopAnimation();
      transition.setValue(1);
      transitionDurationRef.current = DEFAULT_TRANSITION_DURATION;
      return;
    }

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

  const handleNext = () => {
    transitionDurationRef.current = BUTTON_TRANSITION_DURATION;
    setStage((prev) => Math.min(prev + 1, FINAL_STAGE));
  };

  const handleStartPress = () => {
    if (startButtonPressed) {
      return;
    }
    setStartButtonPressed(true);
    setTimeout(() => {
      setStartButtonPressed(false);
      transitionDurationRef.current = BUTTON_TRANSITION_DURATION;
      setStage(4);
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
      setStage(5);
    }, 180);
  };

  if (stage === FINAL_STAGE) {
    return <ChatbotConversationScreen onBack={() => setStage(12)} />;
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
          startButtonPressed,
          bridgeButtonPressed,
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
  abs: {
    position: "absolute",
  },
  absText: {
    position: "absolute",
  },
});
