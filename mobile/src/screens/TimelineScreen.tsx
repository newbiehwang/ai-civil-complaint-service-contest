import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { apiClient } from "../services/apiClient";
import { toKoreanErrorMessage } from "../services/errorMap";
import { useCaseContext } from "../store/caseContext";
import type { TimelineEvent } from "../types/api";

const POLL_INTERVAL_MS = 5_000;
const TIMEOUT_MS = 90_000;

type TimelineScreenProps = {
  onCompleted?: () => void;
  onBack?: () => void;
};

function formatEventTime(value: string): string {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return value;
  }
  return date.toLocaleString();
}

export function TimelineScreen({ onCompleted, onBack }: TimelineScreenProps) {
  const { caseId, traceId, timelineEvents, setTimelineEvents } = useCaseContext();
  const [isLoading, setIsLoading] = useState(true);
  const [isPollingActive, setIsPollingActive] = useState(true);
  const [isTimeoutReached, setIsTimeoutReached] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [timeoutCycle, setTimeoutCycle] = useState(0);
  const completedRef = useRef(false);

  const fetchTimeline = useCallback(async () => {
    if (!caseId) {
      return;
    }

    try {
      const response = await apiClient.getTimeline(caseId, { traceId });
      const sorted = [...response.events].sort(
        (a, b) => new Date(a.occurredAt).getTime() - new Date(b.occurredAt).getTime(),
      );
      setTimelineEvents(sorted);
      setErrorMessage(null);

      const hasCompleted = sorted.some((event) => event.eventType === "CASE_COMPLETED");
      if (hasCompleted && !completedRef.current) {
        completedRef.current = true;
        setIsPollingActive(false);
        onCompleted?.();
      }
    } catch (error: unknown) {
      setErrorMessage(toKoreanErrorMessage(error));
    } finally {
      setIsLoading(false);
    }
  }, [caseId, onCompleted, setTimelineEvents, traceId]);

  useEffect(() => {
    if (!isPollingActive) {
      return;
    }
    fetchTimeline();
    const id = setInterval(fetchTimeline, POLL_INTERVAL_MS);
    return () => clearInterval(id);
  }, [fetchTimeline, isPollingActive]);

  useEffect(() => {
    if (!isPollingActive) {
      return;
    }
    const id = setTimeout(() => {
      if (completedRef.current) {
        return;
      }
      setIsTimeoutReached(true);
    }, TIMEOUT_MS);
    return () => clearTimeout(id);
  }, [isPollingActive, timeoutCycle]);

  const orderedEvents = useMemo(() => {
    return [...timelineEvents].sort(
      (a, b) => new Date(a.occurredAt).getTime() - new Date(b.occurredAt).getTime(),
    );
  }, [timelineEvents]);

  const hasSubmissionCompleted = orderedEvents.some((event) => event.eventType === "SUBMISSION_COMPLETED");

  const handleContinueWait = () => {
    setIsTimeoutReached(false);
    setTimeoutCycle((prev) => prev + 1);
    setIsPollingActive(true);
  };

  const handleLater = () => {
    setIsPollingActive(false);
    setIsTimeoutReached(false);
  };

  return (
    <View style={styles.screen}>
      <View style={styles.panel}>
        <ScrollView contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
          <Text style={styles.stepBadge}>STEP 7 · 진행 추적</Text>
          <Text style={styles.title}>처리 진행 상태</Text>
          <Text style={styles.subtitle}>
            5초 간격으로 타임라인을 갱신합니다. 완료 이벤트가 확인되면 자동으로 다음 단계로 이동합니다.
          </Text>

          <View style={styles.statusCard}>
            <Text style={styles.statusTitle}>현재 상태</Text>
            <Text style={styles.statusItem}>• 제출 완료: {hasSubmissionCompleted ? "확인됨" : "대기 중"}</Text>
            <Text style={styles.statusItem}>
              • 최종 완료 이벤트: {completedRef.current ? "확인됨" : "미확인"}
            </Text>
          </View>

          <View style={styles.timelineCard}>
            <Text style={styles.timelineTitle}>이벤트 타임라인</Text>
            {isLoading ? <Text style={styles.timelineEmpty}>타임라인을 불러오는 중입니다...</Text> : null}
            {!isLoading && orderedEvents.length === 0 ? (
              <Text style={styles.timelineEmpty}>아직 수신된 이벤트가 없습니다.</Text>
            ) : null}
            {orderedEvents.map((event: TimelineEvent) => (
              <View key={event.eventId} style={styles.timelineItem}>
                <View style={styles.timelineDot} />
                <View style={styles.timelineBody}>
                  <Text style={styles.timelineItemTitle}>{event.title}</Text>
                  <Text style={styles.timelineItemMeta}>
                    {formatEventTime(event.occurredAt)} · {event.actor ?? "SYSTEM"} · {event.eventType}
                  </Text>
                  {event.description ? <Text style={styles.timelineItemDesc}>{event.description}</Text> : null}
                </View>
              </View>
            ))}
          </View>

          {errorMessage ? <Text style={styles.errorText}>{errorMessage}</Text> : null}

          {isTimeoutReached ? (
            <View style={styles.timeoutCard}>
              <Text style={styles.timeoutTitle}>아직 처리 완료 이벤트가 오지 않았습니다.</Text>
              <Text style={styles.timeoutBody}>
                계속 대기하거나, 나중에 다시 확인할 수 있습니다.
              </Text>
              <View style={styles.timeoutActions}>
                <Pressable onPress={handleContinueWait} style={({ pressed }) => [styles.timeoutGhost, pressed && styles.timeoutGhostPressed]}>
                  <Text style={styles.timeoutGhostLabel}>계속 대기</Text>
                </Pressable>
                <Pressable onPress={handleLater} style={({ pressed }) => [styles.timeoutPrimary, pressed && styles.timeoutPrimaryPressed]}>
                  <Text style={styles.timeoutPrimaryLabel}>나중에 확인</Text>
                </Pressable>
              </View>
            </View>
          ) : null}
        </ScrollView>

        <View style={styles.footer}>
          <Pressable onPress={onBack} style={({ pressed }) => [styles.ghostButton, pressed && styles.ghostButtonPressed]}>
            <Text style={styles.ghostButtonLabel}>이전</Text>
          </Pressable>
          <Pressable
            onPress={fetchTimeline}
            style={({ pressed }) => [styles.primaryButton, pressed && styles.primaryButtonPressed]}
          >
            <Text style={styles.primaryButtonLabel}>지금 새로고침</Text>
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
  statusCard: {
    borderRadius: 16,
    borderWidth: 1,
    borderColor: "#d9e2f2",
    backgroundColor: "#f8fafc",
    paddingHorizontal: 14,
    paddingVertical: 12,
    gap: 6,
  },
  statusTitle: {
    color: "#1e293b",
    fontSize: 14,
    lineHeight: 18,
    fontWeight: "700",
  },
  statusItem: {
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
    gap: 10,
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
    flexDirection: "row",
    alignItems: "flex-start",
    gap: 10,
  },
  timelineDot: {
    marginTop: 6,
    width: 9,
    height: 9,
    borderRadius: 999,
    backgroundColor: "#3b82f6",
  },
  timelineBody: {
    flex: 1,
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
    fontSize: 11,
    lineHeight: 15,
    fontWeight: "500",
  },
  timelineItemDesc: {
    color: "#334155",
    fontSize: 12,
    lineHeight: 17,
    fontWeight: "500",
  },
  errorText: {
    color: "#dc2626",
    fontSize: 13,
    lineHeight: 18,
    fontWeight: "600",
  },
  timeoutCard: {
    borderRadius: 16,
    borderWidth: 1,
    borderColor: "#fdba74",
    backgroundColor: "#fff7ed",
    paddingHorizontal: 14,
    paddingVertical: 12,
    gap: 8,
  },
  timeoutTitle: {
    color: "#9a3412",
    fontSize: 14,
    lineHeight: 18,
    fontWeight: "700",
  },
  timeoutBody: {
    color: "#9a3412",
    fontSize: 13,
    lineHeight: 18,
    fontWeight: "500",
  },
  timeoutActions: {
    flexDirection: "row",
    gap: 8,
  },
  timeoutGhost: {
    flex: 1,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: "#fdba74",
    backgroundColor: "#ffffff",
    minHeight: 40,
    alignItems: "center",
    justifyContent: "center",
  },
  timeoutGhostPressed: {
    backgroundColor: "#fff7ed",
  },
  timeoutGhostLabel: {
    color: "#9a3412",
    fontSize: 13,
    lineHeight: 17,
    fontWeight: "700",
  },
  timeoutPrimary: {
    flex: 1,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: "#ea580c",
    backgroundColor: "#ea580c",
    minHeight: 40,
    alignItems: "center",
    justifyContent: "center",
  },
  timeoutPrimaryPressed: {
    backgroundColor: "#c2410c",
    borderColor: "#c2410c",
  },
  timeoutPrimaryLabel: {
    color: "#ffffff",
    fontSize: 13,
    lineHeight: 17,
    fontWeight: "700",
  },
  footer: {
    borderTopWidth: 1,
    borderTopColor: "#e2e8f0",
    paddingHorizontal: 18,
    paddingTop: 12,
    paddingBottom: 14,
    flexDirection: "row",
    gap: 10,
  },
  ghostButton: {
    flex: 1,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: "#cbd5e1",
    backgroundColor: "#ffffff",
    alignItems: "center",
    justifyContent: "center",
    minHeight: 44,
  },
  ghostButtonPressed: {
    backgroundColor: "#f8fafc",
  },
  ghostButtonLabel: {
    color: "#475569",
    fontSize: 15,
    lineHeight: 19,
    fontWeight: "700",
  },
  primaryButton: {
    flex: 2,
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
