import { useMemo, useState } from "react";
import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { apiClient } from "../services/apiClient";
import { toKoreanErrorMessage } from "../services/errorMap";
import { useCaseContext } from "../store/caseContext";
import type { SubmitCaseRequest } from "../types/api";

type SubmissionReviewScreenProps = {
  onSubmitted?: () => void;
  onBack?: () => void;
};

type SubmitChannel = SubmitCaseRequest["submissionChannel"];

function CheckRow({
  label,
  checked,
  onPress,
}: {
  label: string;
  checked: boolean;
  onPress: () => void;
}) {
  return (
    <Pressable style={styles.checkRow} onPress={onPress}>
      <View style={[styles.checkDot, checked && styles.checkDotChecked]}>
        {checked ? <Text style={styles.checkMark}>✓</Text> : null}
      </View>
      <Text style={styles.checkLabel}>{label}</Text>
    </Pressable>
  );
}

export function SubmissionReviewScreen({ onSubmitted, onBack }: SubmissionReviewScreenProps) {
  const {
    caseId,
    traceId,
    routingRecommendation,
    evidenceChecklist,
    submissionResponse,
    setSubmissionResponse,
    applyCaseDetail,
  } = useCaseContext();
  const [consentChecked, setConsentChecked] = useState(false);
  const [identityChecked, setIdentityChecked] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [showFallback, setShowFallback] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const selectedRouteLabel = useMemo(() => {
    if (!routingRecommendation?.selectedOptionId) {
      return "선택 경로 없음";
    }
    const selected = routingRecommendation.options.find(
      (option) => option.optionId === routingRecommendation.selectedOptionId,
    );
    return selected?.label ?? "선택 경로 없음";
  }, [routingRecommendation]);

  const submitWithChannel = async (submissionChannel: SubmitChannel) => {
    if (!caseId || isSubmitting) {
      return;
    }

    setErrorMessage(null);
    setIsSubmitting(true);

    try {
      const response = await apiClient.submitCase(
        caseId,
        {
          submissionChannel,
          userConsent: consentChecked,
          identityVerified: identityChecked,
        },
        {
          traceId,
          idempotencyKey: `mobile-submit-${caseId}-${submissionChannel}`,
        },
      );

      setSubmissionResponse(response);
      const detail = await apiClient.getCase(caseId, { traceId });
      applyCaseDetail(detail);
      setShowFallback(false);
      onSubmitted?.();
    } catch (error: unknown) {
      const code = typeof error === "object" && error !== null ? (error as { code?: string }).code : undefined;
      setErrorMessage(toKoreanErrorMessage(error));
      setShowFallback(code === "INSTITUTION_GATEWAY_ERROR" && submissionChannel === "MCP_API");
    } finally {
      setIsSubmitting(false);
    }
  };

  const canSubmit = Boolean(caseId) && consentChecked && identityChecked && !isSubmitting;

  return (
    <View style={styles.screen}>
      <View style={styles.panel}>
        <ScrollView contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
          <Text style={styles.stepBadge}>STEP 6 · 정식 신고</Text>
          <Text style={styles.title}>제출 전 확인</Text>
          <Text style={styles.subtitle}>
            제출 버튼을 누르면 실제 API로 접수가 진행됩니다. 기관 연동 실패 시 MANUAL_PDF로 폴백할 수 있습니다.
          </Text>

          <View style={styles.summaryCard}>
            <Text style={styles.summaryTitle}>제출 요약</Text>
            <Text style={styles.summaryItem}>• 확정 경로: {selectedRouteLabel}</Text>
            <Text style={styles.summaryItem}>
              • 증거 충분도: {evidenceChecklist?.isSufficient ? "충분" : "추가 필요"}
            </Text>
            <Text style={styles.summaryItem}>
              • 제출 상태: {submissionResponse?.submissionStatus ?? "미제출"}
            </Text>
          </View>

          <View style={styles.checklistCard}>
            <Text style={styles.checklistTitle}>필수 확인</Text>
            <CheckRow
              label="내용을 확인했고 제출에 동의합니다."
              checked={consentChecked}
              onPress={() => setConsentChecked((prev) => !prev)}
            />
            <CheckRow
              label="본인 확인을 완료했습니다."
              checked={identityChecked}
              onPress={() => setIdentityChecked((prev) => !prev)}
            />
          </View>

          {errorMessage ? <Text style={styles.errorText}>{errorMessage}</Text> : null}

          {showFallback ? (
            <View style={styles.fallbackCard}>
              <Text style={styles.fallbackTitle}>기관 연동 오류 감지</Text>
              <Text style={styles.fallbackBody}>
                기본 채널(MCP_API) 제출이 실패했습니다. MANUAL_PDF 채널로 재시도할 수 있습니다.
              </Text>
              <Pressable
                onPress={() => submitWithChannel("MANUAL_PDF")}
                disabled={!canSubmit}
                style={({ pressed }) => [
                  styles.fallbackButton,
                  !canSubmit && styles.fallbackButtonDisabled,
                  pressed && canSubmit && styles.fallbackButtonPressed,
                ]}
              >
                <Text style={styles.fallbackButtonLabel}>MANUAL_PDF로 재시도</Text>
              </Pressable>
            </View>
          ) : null}
        </ScrollView>

        <View style={styles.footer}>
          <Pressable onPress={onBack} style={({ pressed }) => [styles.ghostButton, pressed && styles.ghostButtonPressed]}>
            <Text style={styles.ghostButtonLabel}>이전</Text>
          </Pressable>
          <Pressable
            onPress={() => submitWithChannel("MCP_API")}
            disabled={!canSubmit}
            style={({ pressed }) => [
              styles.primaryButton,
              !canSubmit && styles.primaryButtonDisabled,
              pressed && canSubmit && styles.primaryButtonPressed,
            ]}
          >
            <Text style={styles.primaryButtonLabel}>MCP_API로 제출</Text>
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
  checklistCard: {
    borderRadius: 16,
    borderWidth: 1,
    borderColor: "#d9e2f2",
    backgroundColor: "#ffffff",
    paddingHorizontal: 14,
    paddingVertical: 12,
    gap: 8,
  },
  checklistTitle: {
    color: "#1e293b",
    fontSize: 14,
    lineHeight: 18,
    fontWeight: "700",
    marginBottom: 2,
  },
  checkRow: {
    minHeight: 36,
    flexDirection: "row",
    alignItems: "center",
    gap: 10,
  },
  checkDot: {
    width: 20,
    height: 20,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: "#94a3b8",
    backgroundColor: "#ffffff",
    alignItems: "center",
    justifyContent: "center",
  },
  checkDotChecked: {
    borderColor: "#1d4ed8",
    backgroundColor: "#1d4ed8",
  },
  checkMark: {
    color: "#ffffff",
    fontSize: 12,
    lineHeight: 14,
    fontWeight: "700",
  },
  checkLabel: {
    flex: 1,
    color: "#334155",
    fontSize: 14,
    lineHeight: 20,
    fontWeight: "500",
  },
  errorText: {
    color: "#dc2626",
    fontSize: 13,
    lineHeight: 18,
    fontWeight: "600",
  },
  fallbackCard: {
    borderRadius: 16,
    borderWidth: 1,
    borderColor: "#fdba74",
    backgroundColor: "#fff7ed",
    paddingHorizontal: 14,
    paddingVertical: 12,
    gap: 8,
  },
  fallbackTitle: {
    color: "#9a3412",
    fontSize: 14,
    lineHeight: 18,
    fontWeight: "700",
  },
  fallbackBody: {
    color: "#9a3412",
    fontSize: 13,
    lineHeight: 18,
    fontWeight: "500",
  },
  fallbackButton: {
    borderRadius: 12,
    borderWidth: 1,
    borderColor: "#ea580c",
    backgroundColor: "#ea580c",
    alignItems: "center",
    justifyContent: "center",
    minHeight: 42,
  },
  fallbackButtonDisabled: {
    borderColor: "#fdba74",
    backgroundColor: "#fdba74",
  },
  fallbackButtonPressed: {
    backgroundColor: "#c2410c",
    borderColor: "#c2410c",
  },
  fallbackButtonLabel: {
    color: "#ffffff",
    fontSize: 14,
    lineHeight: 18,
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
  primaryButtonDisabled: {
    borderColor: "#9cb7ef",
    backgroundColor: "#9cb7ef",
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
