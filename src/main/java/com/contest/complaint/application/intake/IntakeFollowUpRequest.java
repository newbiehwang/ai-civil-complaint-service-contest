package com.contest.complaint.application.intake;

import com.contest.complaint.api.model.ApiModels;

import java.util.List;
import java.util.Map;

public record IntakeFollowUpRequest(
        String latestUserMessage,
        List<String> missingSlots,
        Map<String, Object> filledSlots,
        ApiModels.CaseStatus caseStatus,
        boolean riskSignalDetected
) {
}

