import { useEffect, useMemo, useRef, useState } from "react";
import { Animated, Easing, StyleProp, Text, TextStyle } from "react-native";

type RevealMode = "typewriter" | "word" | "fade";
type FadeByMode = "full" | "word" | "char" | "sentence";

type TypewriterTextProps = {
  text: string;
  animationKey: string | number;
  revealMode?: RevealMode;
  fadeBy?: FadeByMode;
  charDelayMs?: number;
  wordDelayMs?: number;
  sentenceDelayMs?: number;
  jitterMs?: number;
  startDelayMs?: number;
  preserveSpaces?: boolean;
  charFadeInDurationMs?: number;
  fadeInDurationMs?: number;
  onComplete?: () => void;
  style?: StyleProp<TextStyle>;
};

function splitToUnits(
  text: string,
  revealMode: RevealMode,
  fadeBy: FadeByMode,
  preserveSpaces: boolean,
) {
  const useWordUnits = revealMode === "word" || (revealMode === "fade" && fadeBy === "word");
  const useCharUnits = revealMode === "typewriter" || (revealMode === "fade" && fadeBy === "char");
  const useSentenceUnits = revealMode === "fade" && fadeBy === "sentence";

  if (useSentenceUnits) {
    const sentenceUnits = text.match(/[^.!?\n]+[.!?]?[\s\n]*/g) ?? [];
    return sentenceUnits.filter((unit) => unit.length > 0);
  }

  if (useWordUnits) {
    if (preserveSpaces) {
      return text.match(/\S+|\s+/g) ?? [];
    }
    const trimmed = text.trim();
    return trimmed.length ? trimmed.split(/\s+/) : [];
  }

  if (useCharUnits) {
    return Array.from(text);
  }

  return Array.from(text);
}

export function TypewriterText({
  text,
  animationKey,
  revealMode = "typewriter",
  fadeBy = "full",
  charDelayMs = 28,
  wordDelayMs = 90,
  sentenceDelayMs = 420,
  jitterMs = 40,
  startDelayMs = 0,
  preserveSpaces = false,
  charFadeInDurationMs = 260,
  fadeInDurationMs = 360,
  onComplete,
  style,
}: TypewriterTextProps) {
  const isFullFade = revealMode === "fade" && fadeBy === "full";
  const useWordUnits = revealMode === "word" || (revealMode === "fade" && fadeBy === "word");
  const useSentenceUnits = revealMode === "fade" && fadeBy === "sentence";

  const units = useMemo(
    () => splitToUnits(text, revealMode, fadeBy, preserveSpaces),
    [fadeBy, preserveSpaces, revealMode, text],
  );
  const [visibleCount, setVisibleCount] = useState(0);
  const containerOpacity = useRef(new Animated.Value(1)).current;
  const unitOpacityRef = useRef<Animated.Value[]>([]);
  const stepTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const completionNotifiedRef = useRef(false);

  const clearStepTimer = () => {
    if (!stepTimerRef.current) {
      return;
    }
    clearTimeout(stepTimerRef.current);
    stepTimerRef.current = null;
  };

  useEffect(() => {
    completionNotifiedRef.current = false;
    clearStepTimer();

    if (units.length === 0) {
      setVisibleCount(0);
      completionNotifiedRef.current = true;
      onComplete?.();
      return;
    }

    if (isFullFade) {
      setVisibleCount(units.length);
      unitOpacityRef.current = [];
      containerOpacity.setValue(0);

      const fadeAnimation = Animated.timing(containerOpacity, {
        toValue: 1,
        duration: fadeInDurationMs,
        easing: Easing.out(Easing.cubic),
        useNativeDriver: true,
      });
      fadeAnimation.start(({ finished }) => {
        if (!finished || completionNotifiedRef.current) {
          return;
        }
        completionNotifiedRef.current = true;
        onComplete?.();
      });

      return () => {
        fadeAnimation.stop();
        containerOpacity.stopAnimation();
      };
    }

    setVisibleCount(0);
    containerOpacity.setValue(1);
    unitOpacityRef.current = units.map(() => new Animated.Value(0));

    return () => {
      clearStepTimer();
      containerOpacity.stopAnimation();
      unitOpacityRef.current.forEach((value) => value.stopAnimation());
    };
  }, [animationKey, containerOpacity, fadeInDurationMs, isFullFade, onComplete, units]);

  useEffect(() => {
    if (isFullFade || units.length === 0) {
      return;
    }

    const stepDelay = useSentenceUnits ? sentenceDelayMs : useWordUnits ? wordDelayMs : charDelayMs;

    const schedule = (i: number) => {
      if (i >= units.length) {
        return;
      }

      const jitter = jitterMs > 0 ? Math.floor(Math.random() * jitterMs) : 0;
      stepTimerRef.current = setTimeout(() => {
        setVisibleCount((prev) => Math.min(prev + 1, units.length));
        schedule(i + 1);
      }, stepDelay + jitter);
    };

    stepTimerRef.current = setTimeout(() => schedule(0), startDelayMs);

    return () => clearStepTimer();
  }, [
    animationKey,
    charDelayMs,
    isFullFade,
    jitterMs,
    sentenceDelayMs,
    startDelayMs,
    units.length,
    useSentenceUnits,
    useWordUnits,
    wordDelayMs,
  ]);

  useEffect(() => {
    if (isFullFade || visibleCount <= 0 || units.length === 0) {
      return;
    }

    const index = visibleCount - 1;
    const currentOpacity = unitOpacityRef.current[index];
    if (!currentOpacity) {
      return;
    }

    currentOpacity.setValue(0);
    const fadeAnimation = Animated.timing(currentOpacity, {
      toValue: 1,
      duration: charFadeInDurationMs,
      easing: Easing.out(Easing.cubic),
      useNativeDriver: true,
    });
    fadeAnimation.start(({ finished }) => {
      if (!finished || completionNotifiedRef.current) {
        return;
      }

      if (index >= units.length - 1) {
        completionNotifiedRef.current = true;
        onComplete?.();
      }
    });

    return () => fadeAnimation.stop();
  }, [charFadeInDurationMs, isFullFade, onComplete, units.length, visibleCount]);

  if (isFullFade) {
    return <Animated.Text style={[style, { opacity: containerOpacity }]}>{text}</Animated.Text>;
  }

  const visibleUnits = units.slice(0, visibleCount);

  return (
    <Text style={style}>
      {visibleUnits.map((unit, index) => (
        <Animated.Text
          key={`${String(animationKey)}-${index}`}
          style={{ opacity: unitOpacityRef.current[index] ?? 1 }}
        >
          {unit}
          {useWordUnits && !preserveSpaces && index < visibleUnits.length - 1 ? " " : ""}
        </Animated.Text>
      ))}
    </Text>
  );
}
