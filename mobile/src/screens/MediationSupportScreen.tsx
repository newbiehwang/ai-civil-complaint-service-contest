import { useMemo } from "react";
import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { MediationDecision, useCaseContext } from "../store/caseContext";

type MediationSupportScreenProps = {
  onNext?: () => void;
  onBack?: () => void;
};

type RecommendationCard = {
  title: string;
  reason: string;
  details: string[];
  severity: "info" | "warning" | "critical";
};

function buildRecommendation(params: {
  riskSignalDetected: boolean;
  priorMediation: boolean;
  mediationFailed: boolean;
  evidenceSufficient: boolean;
}): RecommendationCard {
  const { riskSignalDetected, priorMediation, mediationFailed, evidenceSufficient } = params;

  if (riskSignalDetected) {
    return {
      title: "즉시 신고/보호 안내 우선",
      reason: "위험 신호가 감지되어 안전 조치를 먼저 권고합니다.",
      details: [
        "긴급 상황이면 즉시 112 연결을 우선하세요.",
        "동시에 정식 민원 제출 경로를 병행할 수 있습니다.",
      ],
      severity: "critical",
    };
  }

  if (!evidenceSufficient) {
    return {
      title: "증거 보강 우선 권고",
      reason: "필수 증거가 부족하면 제출 단계에서 보완 요청 가능성이 높습니다.",
      details: [
        "AUDIO + LOG를 먼저 충족한 뒤 제출하면 안정적입니다.",
        "원하면 지금 제출로 바로 진행할 수 있습니다.",
      ],
      severity: "warning",
    };
  }

  if (priorMediation || mediationFailed) {
    return {
      title: "정식 제출 권고",
      reason: "기존 조정 시도 이력이 있어 공식 채널 제출 전환을 권고합니다.",
      details: [
        "국민신문고/기관 연계 제출로 다음 단계를 진행하세요.",
        "필요 시 조정 시도 이력을 근거로 함께 첨부합니다.",
      ],
      severity: "info",
    };
  }

  return {
    title: "조정 우선 권고",
    reason: "초기 단계에서는 단지 내 조정 절차가 해결 가능성이 높습니다.",
    details: [
      "관리사무소/중재 요청 메시지를 먼저 발송해 볼 수 있습니다.",
      "원하면 즉시 정식 제출로 전환할 수 있습니다.",
    ],
    severity: "info",
  };
}

export function MediationSupportScreen({ onNext, onBack }: MediationSupportScreenProps) {
  const {
    intakeSnapshot,
    routingRecommendation,
    evidenceChecklist,
    status,
    mediationDecision,
    setMediationDecision,
  } = useCaseContext();

  const riskSignalDetected = Boolean(intakeSnapshot?.riskSignalDetected);
  const priorMediation = intakeSnapshot?.filledSlots?.priorMediation === true;
  const mediationFailed = status === "MEDIATION_FAILED";
  const evidenceSufficient = Boolean(evidenceChecklist?.isSufficient);

  const recommendation = useMemo(
    () =>
      buildRecommendation({
        riskSignalDetected,
        priorMediation,
        mediationFailed,
        evidenceSufficient,
      }),
    [evidenceSufficient, mediationFailed, priorMediation, riskSignalDetected],
  );

  const selectedOptionLabel = useMemo(() => {
    if (routingRecommendation?.selectedOptionId) {
      const selected = routingRecommendation.options.find(
        (option) => option.optionId === routingRecommendation.selectedOptionId,
      );
      return selected?.label ?? "선택된 경로 없음";
    }
    return "선택된 경로 없음";
  }, [routingRecommendation]);

  const mediationDraft = useMemo(() => {
    return [
      "안녕하세요. 최근 반복되는 층간소음으로 생활에 불편이 발생해 조정을 요청드립니다.",
      "주요 발생 시간대와 빈도는 민원 내용에 정리해 두었습니다.",
      "가능한 조정 절차와 안내 일정을 회신 부탁드립니다.",
    ].join("\n");
  }, []);

  const pickDecision = (decision: MediationDecision) => {
    setMediationDecision(decision);
  };

  return (
    <View style={styles.screen}>
      <View style={styles.panel}>
        <ScrollView contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
          <Text style={styles.stepBadge}>STEP 5 · 조정 지원</Text>
          <Text style={styles.title}>Step 5 → 6 전환 판단</Text>
          <Text style={styles.subtitle}>
            권고는 참고 정보이며, 최종 결정은 사용자 선택(HITL)로 진행됩니다.
          </Text>

          <View
            style={[
              styles.recommendCard,
              recommendation.severity === "critical" && styles.recommendCardCritical,
              recommendation.severity === "warning" && styles.recommendCardWarning,
            ]}
          >
            <Text style={styles.recommendTitle}>{recommendation.title}</Text>
            <Text style={styles.recommendReason}>{recommendation.reason}</Text>
            {recommendation.details.map((detail) => (
              <Text key={detail} style={styles.recommendDetail}>
                • {detail}
              </Text>
            ))}
          </View>

          <View style={styles.metaCard}>
            <Text style={styles.metaTitle}>현재 상태 요약</Text>
            <Text style={styles.metaItem}>• 선택 경로: {selectedOptionLabel}</Text>
            <Text style={styles.metaItem}>• 위험 신호: {riskSignalDetected ? "감지됨" : "없음"}</Text>
            <Text style={styles.metaItem}>• 기존 조정 시도: {priorMediation ? "있음" : "없음"}</Text>
            <Text style={styles.metaItem}>• 조정 실패 상태: {mediationFailed ? "감지됨" : "없음"}</Text>
            <Text style={styles.metaItem}>
              • 증거 충분도: {evidenceSufficient ? "충분" : "부족"}
            </Text>
          </View>

          <View style={styles.choiceWrap}>
            <Text style={styles.choiceTitle}>진행 방식을 선택해 주세요</Text>
            <Pressable
              onPress={() => pickDecision("TRY_MEDIATION_FIRST")}
              style={({ pressed }) => [
                styles.choiceButton,
                mediationDecision === "TRY_MEDIATION_FIRST" && styles.choiceButtonSelected,
                pressed && styles.choiceButtonPressed,
              ]}
            >
              <Text
                style={[
                  styles.choiceLabel,
                  mediationDecision === "TRY_MEDIATION_FIRST" && styles.choiceLabelSelected,
                ]}
              >
                조정 먼저 시도
              </Text>
            </Pressable>
            <Pressable
              onPress={() => pickDecision("PROCEED_FORMAL_SUBMISSION")}
              style={({ pressed }) => [
                styles.choiceButton,
                mediationDecision === "PROCEED_FORMAL_SUBMISSION" && styles.choiceButtonSelected,
                pressed && styles.choiceButtonPressed,
              ]}
            >
              <Text
                style={[
                  styles.choiceLabel,
                  mediationDecision === "PROCEED_FORMAL_SUBMISSION" && styles.choiceLabelSelected,
                ]}
              >
                정식 제출 진행
              </Text>
            </Pressable>
          </View>

          <View style={styles.draftCard}>
            <Text style={styles.draftTitle}>조정 요청 메시지 초안</Text>
            <Text style={styles.draftBody}>{mediationDraft}</Text>
          </View>
        </ScrollView>

        <View style={styles.footer}>
          <Pressable onPress={onBack} style={({ pressed }) => [styles.ghostButton, pressed && styles.ghostButtonPressed]}>
            <Text style={styles.ghostButtonLabel}>이전</Text>
          </Pressable>
          <Pressable onPress={onNext} style={({ pressed }) => [styles.primaryButton, pressed && styles.primaryButtonPressed]}>
            <Text style={styles.primaryButtonLabel}>다음: 정식 제출</Text>
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
  recommendCard: {
    borderRadius: 16,
    borderWidth: 1,
    borderColor: "#bfdbfe",
    backgroundColor: "#f8fbff",
    paddingHorizontal: 14,
    paddingVertical: 12,
    gap: 6,
  },
  recommendCardWarning: {
    borderColor: "#fdba74",
    backgroundColor: "#fff7ed",
  },
  recommendCardCritical: {
    borderColor: "#fca5a5",
    backgroundColor: "#fef2f2",
  },
  recommendTitle: {
    color: "#0f172a",
    fontSize: 16,
    lineHeight: 20,
    fontWeight: "700",
  },
  recommendReason: {
    color: "#334155",
    fontSize: 14,
    lineHeight: 20,
    fontWeight: "600",
  },
  recommendDetail: {
    color: "#475569",
    fontSize: 13,
    lineHeight: 18,
    fontWeight: "500",
  },
  metaCard: {
    borderRadius: 16,
    borderWidth: 1,
    borderColor: "#d9e2f2",
    backgroundColor: "#ffffff",
    paddingHorizontal: 14,
    paddingVertical: 12,
    gap: 6,
  },
  metaTitle: {
    color: "#1e293b",
    fontSize: 14,
    lineHeight: 18,
    fontWeight: "700",
  },
  metaItem: {
    color: "#334155",
    fontSize: 13,
    lineHeight: 18,
    fontWeight: "600",
  },
  choiceWrap: {
    borderRadius: 16,
    borderWidth: 1,
    borderColor: "#d9e2f2",
    backgroundColor: "#f8fafc",
    paddingHorizontal: 14,
    paddingVertical: 12,
    gap: 8,
  },
  choiceTitle: {
    color: "#1e293b",
    fontSize: 14,
    lineHeight: 18,
    fontWeight: "700",
  },
  choiceButton: {
    borderRadius: 14,
    borderWidth: 1,
    borderColor: "#cbd5e1",
    backgroundColor: "#ffffff",
    minHeight: 44,
    alignItems: "center",
    justifyContent: "center",
  },
  choiceButtonSelected: {
    borderColor: "#93c5fd",
    backgroundColor: "#eaf2ff",
  },
  choiceButtonPressed: {
    opacity: 0.78,
  },
  choiceLabel: {
    color: "#334155",
    fontSize: 15,
    lineHeight: 19,
    fontWeight: "700",
  },
  choiceLabelSelected: {
    color: "#1d4ed8",
  },
  draftCard: {
    borderRadius: 16,
    borderWidth: 1,
    borderColor: "#d9e2f2",
    backgroundColor: "#ffffff",
    paddingHorizontal: 14,
    paddingVertical: 12,
    gap: 8,
  },
  draftTitle: {
    color: "#1e293b",
    fontSize: 14,
    lineHeight: 18,
    fontWeight: "700",
  },
  draftBody: {
    color: "#334155",
    fontSize: 13,
    lineHeight: 20,
    fontWeight: "500",
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
