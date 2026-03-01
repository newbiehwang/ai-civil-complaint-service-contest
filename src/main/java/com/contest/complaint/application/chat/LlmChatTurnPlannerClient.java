package com.contest.complaint.application.chat;

import java.util.Optional;

public interface LlmChatTurnPlannerClient {

    Optional<ChatTurnPlan> plan(ChatTurnPlannerRequest request);
}
