import { useMemo } from "react";
import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { useCaseContext } from "../store/caseContext";
import type { TimelineEvent } from "../types/api";

type CompletionSummaryScreenProps = {
  onRestart?: () => void;
};

const HIGHLIGHT_EVENT_TYPES = new Set(["ROUTE_CONFIRMED", "SUBMISSION_COMPLETED", "CASE_COMPLETED"]);

function formatDateTime(value?: string): string {
  if (!value) {
    return "-";
  }
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return value;
  }
  return date.toLocaleString();
}

export function CompletionSummaryScreen({ onRestart }: CompletionSummaryScreenProps) {
  const { caseId, routingRecommendation, submissionResponse, timelineEvents, mediationDecision } = useCaseContext();

  const selectedRouteLabel = useMemo(() => {
    if (!routingRecommendation?.selectedOptionId) {
      return "선택 경로 없음";
    }
    const selected = routingRecommendation.options.find(
      (option) => option.optionId === routingRecommendation.selectedOptionId,
    );
    return selected?.label ?? "선택 경로 없음";
  }, [routingRecommendation]);

  const highlightEvents = useMemo(() => {
    return timelineEvents
      .filter((event) => HIGHLIGHT_EVENT_TYPES.has(event.eventType))
      .sort((a, b) => new Date(a.occurredAt).getTime() - new Date(b.occurredAt).getTime())
      .slice(-3);
  }, [timelineEvents]);

  const mediationDecisionLabel = useMemo(() => {
    if (mediationDecision === "TRY_MEDIATION_FIRST") {
      return "조정 먼저 시도";
    }
    if (mediationDecision === "PROCEED_FORMAL_SUBMISSION") {
      return "정식 제출 진행";
    }
    return "미선택";
  }, [mediationDecision]);

  return (
    <View style={styles.screen}>
      <View style={styles.panel}>
        <ScrollView contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
          <Text style={styles.stepBadge}>STEP 8 · 종결</Text>
          <Text style={styles.title}>민원 플로우 데모 완료</Text>
          <Text style={styles.subtitle}>접수부터 종결까지의 결과를 요약했습니다.</Text>

          <View style={styles.summaryCard}>
            <Text style={styles.summaryTitle}>결과 요약</Text>
            <Text style={styles.summaryItem}>• 케이스 ID: {caseId ?? "-"}</Text>
            <Text style={styles.summaryItem}>• 확정 경로: {selectedRouteLabel}</Text>
            <Text style={styles.summaryItem}>• Step 5 선택: {mediationDecisionLabel}</Text>
            <Text style={styles.summaryItem}>
              • 제출 상태: {submissionResponse?.submissionStatus ?? "미확인"}
            </Text>
            <Text style={styles.summaryItem}>
              • 제출 시각: {formatDateTime(submissionResponse?.submittedAt)}
            </Text>
          </View>

          <View style={styles.timelineCard}>
            <Text style={styles.timelineTitle}>핵심 타임라인</Text>
            {highlightEvents.length === 0 ? (
              <Text style={styles.timelineEmpty}>아직 요약 가능한 이벤트가 없습니다.</Text>
            ) : (
              highlightEvents.map((event: TimelineEvent) => (
                <View key={event.eventId} style={styles.timelineItem}>
                  <Text style={styles.timelineItemTitle}>{event.title}</Text>
                  <Text style={styles.timelineItemMeta}>
                    {formatDateTime(event.occurredAt)} · {event.eventType}
                  </Text>
                </View>
              ))
            )}
          </View>

          <View style={styles.preventCard}>
            <Text style={styles.preventTitle}>재발 방지 안내</Text>
            <Text style={styles.preventItem}>1. 소음 발생 시간/유형을 간단히 일지로 기록해 두세요.</Text>
            <Text style={styles.preventItem}>2. 초기 단계에서 관리주체와 사실 중심으로 소통 기록을 남기세요.</Text>
            <Text style={styles.preventItem}>3. 동일 문제가 반복되면 증거 패키지를 보강해 즉시 재접수하세요.</Text>
          </View>
        </ScrollView>

        <View style={styles.footer}>
          <Pressable onPress={onRestart} style={({ pressed }) => [styles.primaryButton, pressed && styles.primaryButtonPressed]}>
            <Text style={styles.primaryButtonLabel}>처음으로 돌아가기</Text>
          </Pressable>
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: "#f8fafc",
    paddingHorizontal: 24,
    paddingTop: 96,
    paddingBottom: 24,
  },
  panel: {
    flex: 1,
    borderRadius: 30,
    borderWidth: 1,
    borderColor: "#d9e2f2",
    backgroundColor: "#ffffff",
    overflow: "hidden",
  },
  content: {
    paddingHorizontal: 18,
    paddingTop: 20,
    paddingBottom: 18,
    gap: 14,
  },
  stepBadge: {
    alignSelf: "flex-start",
    borderRadius: 999,
    borderWidth: 1,
    borderColor: "#bfdbfe",
    backgroundColor: "#eaf1ff",
    paddingHorizontal: 10,
    paddingVertical: 6,
    fontSize: 12,
    lineHeight: 16,
    color: "#1e40af",
    fontWeight: "700",
  },
  title: {
    color: "#0f172a",
    fontSize: 24,
    lineHeight: 30,
    fontWeight: "700",
  },
  subtitle: {
    color: "#475569",
    fontSize: 14,
    lineHeight: 20,
    fontWeight: "500",
  },
  summaryCard: {
    borderRadius: 16,
    borderWidth: 1,
    borderColor: "#d9e2f2",
    backgroundColor: "#f8fafc",
    paddingHorizontal: 14,
    paddingVertical: 12,
    gap: 6,
  },
  summaryTitle: {
    color: "#1e293b",
    fontSize: 14,
    lineHeight: 18,
    fontWeight: "700",
  },
  summaryItem: {
    color: "#334155",
    fontSize: 13,
    lineHeight: 18,
    fontWeight: "600",
  },
  timelineCard: {
    borderRadius: 16,
    borderWidth: 1,
    borderColor: "#d9e2f2",
    backgroundColor: "#ffffff",
    paddingHorizontal: 14,
    paddingVertical: 12,
    gap: 8,
  },
  timelineTitle: {
    color: "#1e293b",
    fontSize: 14,
    lineHeight: 18,
    fontWeight: "700",
  },
  timelineEmpty: {
    color: "#64748b",
    fontSize: 13,
    lineHeight: 18,
    fontWeight: "500",
  },
  timelineItem: {
    borderRadius: 10,
    backgroundColor: "#f8fafc",
    paddingHorizontal: 10,
    paddingVertical: 8,
    gap: 2,
  },
  timelineItemTitle: {
    color: "#0f172a",
    fontSize: 13,
    lineHeight: 18,
    fontWeight: "700",
  },
  timelineItemMeta: {
    color: "#64748b",
    fontSize: 12,
    lineHeight: 16,
    fontWeight: "500",
  },
  preventCard: {
    borderRadius: 16,
    borderWidth: 1,
    borderColor: "#d9e2f2",
    backgroundColor: "#ffffff",
    paddingHorizontal: 14,
    paddingVertical: 12,
    gap: 7,
  },
  preventTitle: {
    color: "#1e293b",
    fontSize: 14,
    lineHeight: 18,
    fontWeight: "700",
  },
  preventItem: {
    color: "#334155",
    fontSize: 13,
    lineHeight: 19,
    fontWeight: "500",
  },
  footer: {
    borderTopWidth: 1,
    borderTopColor: "#e2e8f0",
    paddingHorizontal: 18,
    paddingTop: 12,
    paddingBottom: 14,
  },
  primaryButton: {
    borderRadius: 14,
    borderWidth: 1,
    borderColor: "#1d4ed8",
    backgroundColor: "#1d4ed8",
    alignItems: "center",
    justifyContent: "center",
    minHeight: 44,
  },
  primaryButtonPressed: {
    backgroundColor: "#1e40af",
    borderColor: "#1e40af",
  },
  primaryButtonLabel: {
    color: "#ffffff",
    fontSize: 15,
    lineHeight: 19,
    fontWeight: "700",
  },
});
