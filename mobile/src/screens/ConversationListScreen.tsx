import { useEffect, useMemo, useRef } from "react";
import { Animated, Easing, Pressable, StyleSheet, Text, View } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

export type ConversationListItem = {
  id: string;
  title: string;
  preview: string;
  statusLabel: string;
  caseId: string | null;
  updatedAtText: string;
};

type ConversationListScreenProps = {
  session: ConversationListItem;
  onSelectSession: (sessionId: string) => void;
  isVisible?: boolean;
};

export function ConversationListScreen({ session, onSelectSession, isVisible = true }: ConversationListScreenProps) {
  const insets = useSafeAreaInsets();
  const reveal = useRef(new Animated.Value(0)).current;
  const previewText = session.preview.replace(/\s+/g, " ").trim() || "대화를 시작해 주세요.";
  const secondaryPreview = "상담이 종료되었습니다. 추가 문의가 있으면 새 세션을 시작해 주세요.";

  useEffect(() => {
    const animation = Animated.timing(reveal, {
      toValue: isVisible ? 1 : 0,
      duration: isVisible ? 300 : 160,
      easing: Easing.out(Easing.cubic),
      useNativeDriver: true,
    });
    animation.start();
    return () => animation.stop();
  }, [isVisible, reveal]);

  const headerMotion = useMemo(
    () => ({
      opacity: reveal.interpolate({
        inputRange: [0, 0.25, 1],
        outputRange: [0, 0, 1],
        extrapolate: "clamp",
      }),
      transform: [
        {
          translateY: reveal.interpolate({
            inputRange: [0, 1],
            outputRange: [14, 0],
            extrapolate: "clamp",
          }),
        },
      ],
    }),
    [reveal],
  );

  const firstCardMotion = useMemo(
    () => ({
      opacity: reveal.interpolate({
        inputRange: [0.18, 0.42, 1],
        outputRange: [0, 0, 1],
        extrapolate: "clamp",
      }),
      transform: [
        {
          translateY: reveal.interpolate({
            inputRange: [0, 1],
            outputRange: [18, 0],
            extrapolate: "clamp",
          }),
        },
        {
          scale: reveal.interpolate({
            inputRange: [0, 1],
            outputRange: [0.988, 1],
            extrapolate: "clamp",
          }),
        },
      ],
    }),
    [reveal],
  );

  const secondCardMotion = useMemo(
    () => ({
      opacity: reveal.interpolate({
        inputRange: [0.3, 0.62, 1],
        outputRange: [0, 0, 1],
        extrapolate: "clamp",
      }),
      transform: [
        {
          translateY: reveal.interpolate({
            inputRange: [0, 1],
            outputRange: [20, 0],
            extrapolate: "clamp",
          }),
        },
        {
          scale: reveal.interpolate({
            inputRange: [0, 1],
            outputRange: [0.988, 1],
            extrapolate: "clamp",
          }),
        },
      ],
    }),
    [reveal],
  );

  return (
    <View style={[styles.screen, { paddingTop: insets.top + 32 }]}>
      <Animated.View style={[styles.headerBlock, headerMotion]}>
        <Text style={styles.headerTitle}>대화 목록</Text>
        <Text style={styles.headerSubtitle}>최근 세션을 눌러 상담으로 복귀하세요.</Text>
      </Animated.View>

      <Animated.View style={firstCardMotion}>
        <Pressable
          onPress={() => onSelectSession(session.id)}
          style={({ pressed }) => [styles.sessionCardPrimary, pressed && styles.sessionCardPressed]}
        >
          <View style={styles.sessionTopRow}>
            <Text style={styles.sessionTitlePrimary}>{session.title}</Text>
            <Text style={styles.sessionUpdatedAt}>{session.updatedAtText}</Text>
          </View>

          <Text style={styles.sessionPreview} numberOfLines={2}>
            {previewText}
          </Text>

          <View style={styles.sessionMetaRow}>
            <View style={styles.statusBadgePrimary}>
              <Text style={styles.statusBadgePrimaryText}>{session.statusLabel}</Text>
            </View>
            <Text style={styles.caseIdTextPrimary} numberOfLines={1}>
              {session.caseId ? `case: ${session.caseId}` : "case: 생성 전"}
            </Text>
          </View>
        </Pressable>
      </Animated.View>

      <Animated.View style={secondCardMotion}>
        <View style={styles.sessionCardSecondary}>
          <View style={styles.sessionTopRow}>
            <Text style={styles.sessionTitleSecondary}>주차 문제 신고</Text>
            <Text style={styles.sessionUpdatedAt}>02. 10. 오전 9:12</Text>
          </View>

          <Text style={styles.sessionPreviewSecondary} numberOfLines={2}>
            {secondaryPreview}
          </Text>

          <View style={styles.sessionMetaRow}>
            <View style={styles.statusBadgeSecondary}>
              <Text style={styles.statusBadgeSecondaryText}>완료됨</Text>
            </View>
            <Text style={styles.caseIdTextSecondary} numberOfLines={1}>
              case: b21f99c-a204-551d...
            </Text>
          </View>
        </View>
      </Animated.View>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: "#f9fafb",
    paddingHorizontal: 24,
  },
  headerBlock: {
    marginBottom: 24,
  },
  headerTitle: {
    color: "#2d5d7b",
    fontSize: 30,
    lineHeight: 36,
    fontWeight: "700",
    letterSpacing: -0.75,
  },
  headerSubtitle: {
    marginTop: 8,
    color: "#6b7280",
    fontSize: 16,
    lineHeight: 24,
    fontWeight: "400",
  },
  sessionCardPrimary: {
    borderRadius: 16,
    borderWidth: 1,
    borderColor: "#dbeafe",
    backgroundColor: "#ffffff",
    paddingHorizontal: 20,
    paddingVertical: 20,
    marginBottom: 16,
    shadowColor: "#2d5d7b",
    shadowOpacity: 0.06,
    shadowRadius: 8,
    shadowOffset: { width: 0, height: 4 },
    elevation: 2,
  },
  sessionCardSecondary: {
    borderRadius: 16,
    borderWidth: 1,
    borderColor: "#f3f4f6",
    backgroundColor: "#ffffff",
    paddingHorizontal: 20,
    paddingVertical: 20,
    opacity: 0.92,
  },
  sessionTopRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    gap: 10,
  },
  sessionTitlePrimary: {
    flex: 1,
    color: "#2d5d7b",
    fontSize: 18,
    lineHeight: 28,
    fontWeight: "700",
  },
  sessionTitleSecondary: {
    flex: 1,
    color: "#6b7280",
    fontSize: 18,
    lineHeight: 28,
    fontWeight: "700",
  },
  sessionUpdatedAt: {
    color: "#94a3b8",
    fontSize: 12,
    lineHeight: 16,
    fontWeight: "500",
  },
  sessionPreview: {
    marginTop: 8,
    color: "#374151",
    fontSize: 15,
    lineHeight: 21,
    fontWeight: "400",
  },
  sessionPreviewSecondary: {
    marginTop: 8,
    color: "#6b7280",
    fontSize: 15,
    lineHeight: 21,
    fontWeight: "400",
  },
  sessionMetaRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 10,
    marginTop: 8,
  },
  statusBadgePrimary: {
    borderRadius: 8,
    borderWidth: 1,
    borderColor: "#bfdbfe",
    backgroundColor: "#eff6ff",
    paddingHorizontal: 10,
    paddingVertical: 5,
  },
  statusBadgePrimaryText: {
    color: "#2d5d7b",
    fontSize: 12,
    lineHeight: 16,
    fontWeight: "700",
  },
  statusBadgeSecondary: {
    borderRadius: 8,
    borderWidth: 1,
    borderColor: "#e5e7eb",
    backgroundColor: "#f3f4f6",
    paddingHorizontal: 10,
    paddingVertical: 5,
  },
  statusBadgeSecondaryText: {
    color: "#6b7280",
    fontSize: 12,
    lineHeight: 16,
    fontWeight: "700",
  },
  caseIdTextPrimary: {
    flex: 1,
    color: "#96a2b1",
    fontSize: 12,
    lineHeight: 16,
    fontWeight: "400",
    fontFamily: "monospace",
  },
  caseIdTextSecondary: {
    flex: 1,
    color: "#a9b2bf",
    fontSize: 12,
    lineHeight: 16,
    fontWeight: "400",
    fontFamily: "monospace",
  },
  sessionCardPressed: {
    transform: [{ scale: 0.995 }],
    opacity: 0.9,
  },
});
