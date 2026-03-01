package com.contest.complaint.application.chat;

import com.contest.complaint.api.model.ApiModels;

import java.util.Map;

public record ChatTurnPlan(
        String assistantMessage,
        ApiModels.ChatUiHint uiHint,
        String intent,
        Map<String, Object> intentPayload
) {

    public ChatTurnPlan withAssistantMessage(String message) {
        return new ChatTurnPlan(message, uiHint, intent, intentPayload);
    }

    public static ChatTurnPlan empty() {
        return new ChatTurnPlan(
                "",
                new ApiModels.ChatUiHint(
                        ApiModels.ChatUiType.NONE,
                        ApiModels.ChatUiSelectionMode.NONE,
                        null,
                        null,
                        java.util.List.of(),
                        Map.of()
                ),
                "NONE",
                Map.of()
        );
    }
}
