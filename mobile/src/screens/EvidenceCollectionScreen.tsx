import { useCallback, useEffect, useMemo, useState } from "react";
import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { apiClient } from "../services/apiClient";
import { toKoreanErrorMessage } from "../services/errorMap";
import { useCaseContext } from "../store/caseContext";
import type { EvidenceType, RegisterEvidenceRequest } from "../types/api";

type EvidenceCollectionScreenProps = {
  onNext?: () => void;
  onBack?: () => void;
};

type LocalEvidenceLog = {
  evidenceId: string;
  evidenceType: EvidenceType;
  uploadedAt: string;
};

function createEvidenceRequest(evidenceType: EvidenceType): RegisterEvidenceRequest {
  const now = new Date();
  const timestamp = now.getTime();

  if (evidenceType === "AUDIO") {
    return {
      evidenceType,
      storageKey: `demo/audio/${timestamp}.m4a`,
      originalFileName: `sample-${timestamp}.m4a`,
      mimeType: "audio/m4a",
      sizeBytes: 320_000,
      capturedAt: now.toISOString(),
      notes: "데모용 녹음 증거",
    };
  }

  return {
    evidenceType,
    storageKey: `demo/log/${timestamp}.json`,
    originalFileName: `noise-log-${timestamp}.json`,
    mimeType: "application/json",
    sizeBytes: 8_192,
    capturedAt: now.toISOString(),
    notes: "데모용 소음일지",
  };
}

export function EvidenceCollectionScreen({ onNext, onBack }: EvidenceCollectionScreenProps) {
  const {
    caseId,
    traceId,
    evidenceChecklist,
    setEvidenceChecklist,
    applyCaseDetail,
  } = useCaseContext();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isChecklistLoading, setIsChecklistLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [evidenceLogs, setEvidenceLogs] = useState<LocalEvidenceLog[]>([]);

  const refreshEvidenceState = useCallback(async () => {
    if (!caseId) {
      return;
    }
    setIsChecklistLoading(true);
    try {
      const [checklist, caseDetail] = await Promise.all([
        apiClient.getEvidenceChecklist(caseId, { traceId }),
        apiClient.getCase(caseId, { traceId }),
      ]);
      setEvidenceChecklist(checklist);
      applyCaseDetail(caseDetail);
    } catch (error: unknown) {
      setErrorMessage(toKoreanErrorMessage(error));
    } finally {
      setIsChecklistLoading(false);
    }
  }, [applyCaseDetail, caseId, setEvidenceChecklist, traceId]);

  useEffect(() => {
    refreshEvidenceState();
  }, [refreshEvidenceState]);

  const handleRegisterEvidence = useCallback(
    async (evidenceType: EvidenceType) => {
      if (!caseId || isSubmitting) {
        return;
      }

      setErrorMessage(null);
      setIsSubmitting(true);

      try {
        const created = await apiClient.registerEvidence(
          caseId,
          createEvidenceRequest(evidenceType),
          { traceId },
        );
        setEvidenceLogs((prev) => [
          ...prev,
          {
            evidenceId: created.evidenceId,
            evidenceType,
            uploadedAt: created.uploadedAt,
          },
        ]);
        await refreshEvidenceState();
      } catch (error: unknown) {
        setErrorMessage(toKoreanErrorMessage(error));
      } finally {
        setIsSubmitting(false);
      }
    },
    [caseId, isSubmitting, refreshEvidenceState, traceId],
  );

  const canProceed = Boolean(evidenceChecklist?.isSufficient) && !isSubmitting && !isChecklistLoading;
  const checklistStateText = useMemo(() => {
    if (isChecklistLoading) {
      return "체크리스트를 확인 중입니다...";
    }
    if (evidenceChecklist?.isSufficient) {
      return "증거가 충분합니다. 다음 단계로 진행할 수 있어요.";
    }
    return "필수 증거를 더 등록해 주세요.";
  }, [evidenceChecklist?.isSufficient, isChecklistLoading]);

  return (
    <View style={styles.screen}>
      <View style={styles.panel}>
        <ScrollView contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
          <Text style={styles.stepBadge}>STEP 4 · 증거 수집</Text>
          <Text style={styles.title}>증거를 추가해 제출 준비를 완료하세요</Text>
          <Text style={styles.subtitle}>
            데모에서는 샘플 AUDIO, LOG를 각각 등록하고 체크리스트 충족 여부를 확인합니다.
          </Text>

          {!caseId ? (
            <View style={styles.warningCard}>
              <Text style={styles.warningTitle}>케이스 ID가 없습니다.</Text>
              <Text style={styles.warningBody}>챗봇 단계에서 경로를 먼저 확정해 주세요.</Text>
            </View>
          ) : null}

          <View style={styles.buttonRow}>
            <Pressable
              onPress={() => handleRegisterEvidence("AUDIO")}
              disabled={!caseId || isSubmitting}
              style={({ pressed }) => [
                styles.actionButton,
                (!caseId || isSubmitting) && styles.actionButtonDisabled,
                pressed && caseId && !isSubmitting && styles.actionButtonPressed,
              ]}
            >
              <Text style={styles.actionButtonLabel}>샘플 AUDIO 추가</Text>
            </Pressable>
            <Pressable
              onPress={() => handleRegisterEvidence("LOG")}
              disabled={!caseId || isSubmitting}
              style={({ pressed }) => [
                styles.actionButton,
                (!caseId || isSubmitting) && styles.actionButtonDisabled,
                pressed && caseId && !isSubmitting && styles.actionButtonPressed,
              ]}
            >
              <Text style={styles.actionButtonLabel}>샘플 LOG 추가</Text>
            </Pressable>
          </View>

          <View style={styles.checklistCard}>
            <Text style={styles.checklistTitle}>증거 충분도</Text>
            <Text style={[styles.checklistState, evidenceChecklist?.isSufficient && styles.checklistStateReady]}>
              {checklistStateText}
            </Text>
            {evidenceChecklist?.missingItems?.length ? (
              <View style={styles.missingListWrap}>
                {evidenceChecklist.missingItems.map((item) => (
                  <Text key={item} style={styles.missingItemText}>
                    • {item}
                  </Text>
                ))}
              </View>
            ) : null}
            {evidenceChecklist?.guidance ? <Text style={styles.guidance}>{evidenceChecklist.guidance}</Text> : null}
          </View>

          <View style={styles.logCard}>
            <Text style={styles.logTitle}>등록 로그</Text>
            {evidenceLogs.length === 0 ? (
              <Text style={styles.logEmpty}>아직 등록된 데모 증거가 없습니다.</Text>
            ) : (
              evidenceLogs.map((item) => (
                <Text key={item.evidenceId} style={styles.logItem}>
                  • {item.evidenceType} ({new Date(item.uploadedAt).toLocaleTimeString()})
                </Text>
              ))
            )}
          </View>

          {errorMessage ? <Text style={styles.errorText}>{errorMessage}</Text> : null}
        </ScrollView>

        <View style={styles.footer}>
          <Pressable onPress={onBack} style={({ pressed }) => [styles.ghostButton, pressed && styles.ghostButtonPressed]}>
            <Text style={styles.ghostButtonLabel}>이전</Text>
          </Pressable>
          <Pressable
            onPress={onNext}
            disabled={!canProceed}
            style={({ pressed }) => [
              styles.primaryButton,
              !canProceed && styles.primaryButtonDisabled,
              pressed && canProceed && styles.primaryButtonPressed,
            ]}
          >
            <Text style={styles.primaryButtonLabel}>다음: 조정 지원</Text>
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
    fontSize: 23,
    lineHeight: 30,
    fontWeight: "700",
  },
  subtitle: {
    color: "#475569",
    fontSize: 14,
    lineHeight: 20,
    fontWeight: "500",
  },
  warningCard: {
    borderRadius: 16,
    borderWidth: 1,
    borderColor: "#fed7aa",
    backgroundColor: "#fff7ed",
    paddingHorizontal: 14,
    paddingVertical: 12,
  },
  warningTitle: {
    color: "#9a3412",
    fontSize: 14,
    lineHeight: 18,
    fontWeight: "700",
  },
  warningBody: {
    marginTop: 4,
    color: "#9a3412",
    fontSize: 13,
    lineHeight: 18,
    fontWeight: "500",
  },
  buttonRow: {
    gap: 10,
  },
  actionButton: {
    borderRadius: 16,
    borderWidth: 1,
    borderColor: "#1d4ed8",
    backgroundColor: "#1d4ed8",
    paddingVertical: 14,
    alignItems: "center",
  },
  actionButtonDisabled: {
    borderColor: "#9cb7ef",
    backgroundColor: "#9cb7ef",
  },
  actionButtonPressed: {
    backgroundColor: "#1e40af",
    borderColor: "#1e40af",
  },
  actionButtonLabel: {
    color: "#ffffff",
    fontSize: 16,
    lineHeight: 20,
    fontWeight: "700",
  },
  checklistCard: {
    borderRadius: 16,
    borderWidth: 1,
    borderColor: "#d9e2f2",
    backgroundColor: "#f8fafc",
    paddingHorizontal: 14,
    paddingVertical: 12,
    gap: 8,
  },
  checklistTitle: {
    color: "#1e293b",
    fontSize: 15,
    lineHeight: 20,
    fontWeight: "700",
  },
  checklistState: {
    color: "#334155",
    fontSize: 14,
    lineHeight: 20,
    fontWeight: "600",
  },
  checklistStateReady: {
    color: "#15803d",
  },
  missingListWrap: {
    gap: 4,
  },
  missingItemText: {
    color: "#b91c1c",
    fontSize: 13,
    lineHeight: 18,
    fontWeight: "600",
  },
  guidance: {
    color: "#64748b",
    fontSize: 13,
    lineHeight: 18,
    fontWeight: "500",
  },
  logCard: {
    borderRadius: 16,
    borderWidth: 1,
    borderColor: "#d9e2f2",
    backgroundColor: "#ffffff",
    paddingHorizontal: 14,
    paddingVertical: 12,
    gap: 6,
  },
  logTitle: {
    color: "#1e293b",
    fontSize: 14,
    lineHeight: 18,
    fontWeight: "700",
  },
  logEmpty: {
    color: "#64748b",
    fontSize: 13,
    lineHeight: 18,
    fontWeight: "500",
  },
  logItem: {
    color: "#334155",
    fontSize: 13,
    lineHeight: 18,
    fontWeight: "600",
  },
  errorText: {
    color: "#dc2626",
    fontSize: 13,
    lineHeight: 18,
    fontWeight: "600",
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
