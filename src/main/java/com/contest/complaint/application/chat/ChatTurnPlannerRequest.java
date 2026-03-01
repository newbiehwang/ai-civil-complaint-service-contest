package com.contest.complaint.application.chat;

import com.contest.complaint.api.model.ApiModels;

import java.util.List;
import java.util.Map;
import java.util.UUID;

public record ChatTurnPlannerRequest(
        String traceId,
        UUID caseId,
        String latestUserMessage,
        ApiModels.CaseStatus caseStatus,
        String currentActionRequired,
        String flowStepHint,
        ApiModels.RiskLevel riskLevel,
        Map<String, Object> filledSlots,
        List<String> missingSlots,
        boolean riskSignalDetected,
        List<ApiModels.RoutingOption> routingOptions,
        ApiModels.EvidenceChecklist evidenceChecklist,
        List<String> uiCapabilities,
        String lastUiHintType,
        List<ApiModels.ChatTurnHistoryMessage> recentMessages,
        ApiModels.ChatTurnInteraction interaction
) {
}
