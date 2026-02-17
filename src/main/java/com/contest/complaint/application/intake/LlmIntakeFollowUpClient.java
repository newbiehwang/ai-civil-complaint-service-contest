package com.contest.complaint.application.intake;

import java.util.Optional;

public interface LlmIntakeFollowUpClient {

    Optional<IntakeFollowUpSuggestion> suggest(IntakeFollowUpRequest request);
}
