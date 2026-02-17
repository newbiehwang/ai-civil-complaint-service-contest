import { useEffect, useMemo, useState } from "react";
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

function MiniOptionButton({
  label,
  onPress,
  disabled,
  primary = false,
}: {
  label: string;
  onPress: () => void;
  disabled?: boolean;
  primary?: boolean;
}) {
  return (
    <Pressable
      onPress={onPress}
      disabled={disabled}
      style={({ pressed }) => [
        styles.miniOptionButton,
        primary && styles.miniOptionButtonPrimary,
        disabled && styles.miniOptionButtonDisabled,
        pressed && !disabled && styles.miniOptionButtonPressed,
      ]}
    >
      <Text
        style={[
          styles.miniOptionLabel,
          primary && styles.miniOptionLabelPrimary,
          disabled && styles.miniOptionLabelDisabled,
        ]}
      >
        {label}
      </Text>
    </Pressable>
  );
}

export function EvidenceCollectionScreen({ onNext, onBack }: EvidenceCollectionScreenProps) {
  const { caseId, traceId, evidenceChecklist, setEvidenceChecklist, applyCaseDetail } = useCaseContext();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isChecklistLoading, setIsChecklistLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [evidenceLogs, setEvidenceLogs] = useState<LocalEvidenceLog[]>([]);

  const refreshEvidenceState = async () => {
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
      setErrorMessage(null);
    } catch (error: unknown) {
      setErrorMessage(toKoreanErrorMessage(error));
    } finally {
      setIsChecklistLoading(false);
    }
  };

  useEffect(() => {
    if (!caseId) {
      return;
    }
    refreshEvidenceState();
  }, [caseId, traceId]);

  const handleRegisterEvidence = async (evidenceType: EvidenceType) => {
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
  };

  const missingItems = evidenceChecklist?.missingItems ?? [];
  const hasAudio = !missingItems.some((item) => item.includes("AUDIO"));
  const hasLog = !missingItems.some((item) => item.includes("LOG"));
  const canProceed = Boolean(caseId) && !isSubmitting && !isChecklistLoading;

  const checklistStatusText = useMemo(() => {
    if (isChecklistLoading) {
      return "상태를 확인하는 중이에요...";
    }
    if (evidenceChecklist?.isSufficient) {
      return "증빙 자료가 첨부되었어요. 바로 다음 단계로 이동할 수 있어요.";
    }
    return "증빙 자료는 선택사항이에요. 필요하면 첨부하고 다음 단계로 이동해 주세요.";
  }, [evidenceChecklist?.isSufficient, isChecklistLoading]);

  return (
    <View style={styles.screen}>
      <View style={styles.panel}>
        <ScrollView contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
          <Text style={styles.stepBadge}>STEP 4 · 증거 수집</Text>
          <Text style={styles.title}>쉽게 증거 준비하기</Text>
          <Text style={styles.subtitle}>
            어렵게 파일을 고를 필요 없어요. 아래 버튼 1번, 2번만 누르면 데모용 자료가 자동 등록됩니다.
          </Text>

          {!caseId ? (
            <View style={styles.warningCard}>
              <Text style={styles.warningTitle}>먼저 챗봇에서 경로를 확정해 주세요.</Text>
              <Text style={styles.warningBody}>케이스가 만들어지면 여기서 바로 이어서 진행됩니다.</Text>
            </View>
          ) : null}

          <View style={styles.progressCard}>
            <Text style={styles.progressTitle}>현재 준비 상태</Text>
            <Text style={styles.progressStatus}>{checklistStatusText}</Text>
            <View style={styles.progressRow}>
              <Text style={styles.progressLabel}>녹음 파일</Text>
              <Text style={[styles.progressValue, hasAudio && styles.progressValueDone]}>
                {hasAudio ? "첨부됨" : "선택"}
              </Text>
            </View>
            <View style={styles.progressRow}>
              <Text style={styles.progressLabel}>소음 일지</Text>
              <Text style={[styles.progressValue, hasLog && styles.progressValueDone]}>
                {hasLog ? "첨부됨" : "선택"}
              </Text>
            </View>
          </View>

          <View style={styles.miniWrap}>
            <Text style={styles.miniHint}>선택형 미니 인터페이스</Text>
            <MiniOptionButton
              label="1번 녹음 파일 추가하기"
              onPress={() => handleRegisterEvidence("AUDIO")}
              disabled={!caseId || isSubmitting}
            />
            <MiniOptionButton
              label="2번 소음 일지 추가하기"
              onPress={() => handleRegisterEvidence("LOG")}
              disabled={!caseId || isSubmitting}
            />
            <MiniOptionButton
              label="3번 지금 상태 다시 확인"
              onPress={refreshEvidenceState}
              disabled={!caseId || isSubmitting || isChecklistLoading}
            />
            <MiniOptionButton
              label="4번 다음 단계로 이동"
              onPress={() => onNext?.()}
              disabled={!canProceed}
              primary
            />
          </View>

          <View style={styles.logCard}>
            <Text style={styles.logTitle}>방금 등록한 항목</Text>
            {evidenceLogs.length === 0 ? (
              <Text style={styles.logEmpty}>아직 등록한 항목이 없어요.</Text>
            ) : (
              evidenceLogs.slice(-4).map((item) => (
                <Text key={item.evidenceId} style={styles.logItem}>
                  • {item.evidenceType} ({new Date(item.uploadedAt).toLocaleTimeString()})
                </Text>
              ))
            )}
          </View>

          {errorMessage ? <Text style={styles.errorText}>{errorMessage}</Text> : null}
        </ScrollView>

        <View style={styles.footer}>
          <Pressable onPress={onBack} style={({ pressed }) => [styles.backButton, pressed && styles.backButtonPressed]}>
            <Text style={styles.backButtonLabel}>이전 단계</Text>
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
  progressCard: {
    borderRadius: 16,
    borderWidth: 1,
    borderColor: "#d9e2f2",
    backgroundColor: "#f8fafc",
    paddingHorizontal: 14,
    paddingVertical: 12,
    gap: 8,
  },
  progressTitle: {
    color: "#1e293b",
    fontSize: 15,
    lineHeight: 20,
    fontWeight: "700",
  },
  progressStatus: {
    color: "#334155",
    fontSize: 14,
    lineHeight: 19,
    fontWeight: "600",
  },
  progressRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
  },
  progressLabel: {
    color: "#334155",
    fontSize: 14,
    lineHeight: 18,
    fontWeight: "600",
  },
  progressValue: {
    color: "#b91c1c",
    fontSize: 13,
    lineHeight: 18,
    fontWeight: "700",
  },
  progressValueDone: {
    color: "#15803d",
  },
  miniWrap: {
    borderRadius: 16,
    borderWidth: 1,
    borderColor: "#bfdbfe",
    backgroundColor: "#f8fbff",
    paddingHorizontal: 12,
    paddingVertical: 12,
    gap: 8,
  },
  miniHint: {
    color: "#94a3b8",
    fontSize: 12,
    lineHeight: 16,
    fontWeight: "600",
    marginLeft: 4,
    marginBottom: 2,
  },
  miniOptionButton: {
    borderRadius: 14,
    borderWidth: 1,
    borderColor: "#dbeafe",
    backgroundColor: "#ffffff",
    paddingVertical: 12,
    paddingHorizontal: 12,
  },
  miniOptionButtonPrimary: {
    borderColor: "#1d4ed8",
    backgroundColor: "#1d4ed8",
  },
  miniOptionButtonDisabled: {
    borderColor: "#dbe4ef",
    backgroundColor: "#f8fafc",
  },
  miniOptionButtonPressed: {
    opacity: 0.78,
  },
  miniOptionLabel: {
    color: "#1e293b",
    fontSize: 15,
    lineHeight: 20,
    fontWeight: "700",
  },
  miniOptionLabelPrimary: {
    color: "#ffffff",
  },
  miniOptionLabelDisabled: {
    color: "#94a3b8",
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
  },
  backButton: {
    borderRadius: 14,
    borderWidth: 1,
    borderColor: "#cbd5e1",
    backgroundColor: "#ffffff",
    minHeight: 44,
    alignItems: "center",
    justifyContent: "center",
  },
  backButtonPressed: {
    backgroundColor: "#f8fafc",
  },
  backButtonLabel: {
    color: "#475569",
    fontSize: 15,
    lineHeight: 19,
    fontWeight: "700",
  },
});
