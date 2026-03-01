package com.contest.complaint.application.intake;

import com.contest.complaint.api.model.ApiModels;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Primary;
import org.springframework.stereotype.Component;

@Component
@Primary
public class HybridIntakeFollowUpAdvisor implements IntakeFollowUpAdvisor {

    private final RuleBasedIntakeFollowUpAdvisor ruleBasedAdvisor;
    private final LlmIntakeFollowUpClient llmClient;
    private final boolean useLlm;

    public HybridIntakeFollowUpAdvisor(
            RuleBasedIntakeFollowUpAdvisor ruleBasedAdvisor,
            LlmIntakeFollowUpClient llmClient,
            @Value("${complaint.ai.followup.use-llm:false}") boolean useLlm
    ) {
        this.ruleBasedAdvisor = ruleBasedAdvisor;
        this.llmClient = llmClient;
        this.useLlm = useLlm;
    }

    @Override
    public IntakeFollowUpSuggestion suggest(IntakeFollowUpRequest request) {
        IntakeFollowUpSuggestion fallback = ruleBasedAdvisor.suggest(request);
        // Keep intake flow deterministic (origin/main compatible) while LLM is used for chat turn planning.
        if (request.caseStatus() == ApiModels.CaseStatus.RECEIVED) {
            return fallback;
        }
        if (!useLlm) {
            return fallback;
        }

        return llmClient.suggest(request).orElse(fallback);
    }
}
