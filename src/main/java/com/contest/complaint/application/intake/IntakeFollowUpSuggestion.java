package com.contest.complaint.application.intake;

import com.contest.complaint.api.model.ApiModels;

public record IntakeFollowUpSuggestion(
        String question,
        ApiModels.FollowUpInterface followUpInterface
) {
}

