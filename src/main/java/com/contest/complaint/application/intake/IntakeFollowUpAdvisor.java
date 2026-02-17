package com.contest.complaint.application.intake;

public interface IntakeFollowUpAdvisor {

    IntakeFollowUpSuggestion suggest(IntakeFollowUpRequest request);
}

