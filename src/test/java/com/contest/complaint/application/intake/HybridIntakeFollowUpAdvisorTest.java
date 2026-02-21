package com.contest.complaint.application.intake;

import com.contest.complaint.api.model.ApiModels;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

class HybridIntakeFollowUpAdvisorTest {

    @Test
    void returnsRuleBasedSuggestionWhenLlmIsDisabled() {
        RuleBasedIntakeFollowUpAdvisor ruleBased = new RuleBasedIntakeFollowUpAdvisor();
        StubLlmClient llmClient = new StubLlmClient(Optional.empty());
        HybridIntakeFollowUpAdvisor advisor = new HybridIntakeFollowUpAdvisor(ruleBased, llmClient, false);

        IntakeFollowUpSuggestion suggestion = advisor.suggest(defaultRequest());

        assertThat(suggestion.question()).isEqualTo("지금도 소음이 나나요?");
        assertThat(suggestion.followUpInterface()).isNotNull();
        assertThat(llmClient.called).isFalse();
    }

    @Test
    void returnsLlmSuggestionWhenLlmIsEnabledAndAvailable() {
        RuleBasedIntakeFollowUpAdvisor ruleBased = new RuleBasedIntakeFollowUpAdvisor();
        StubLlmClient llmClient = new StubLlmClient(Optional.empty());
        HybridIntakeFollowUpAdvisor advisor = new HybridIntakeFollowUpAdvisor(ruleBased, llmClient, true);

        IntakeFollowUpSuggestion llmSuggestion = new IntakeFollowUpSuggestion(
                "LLM이 생성한 질문입니다.",
                new ApiModels.FollowUpInterface(
                        ApiModels.FollowUpInterfaceType.OPTIONS,
                        ApiModels.FollowUpSelectionMode.SINGLE,
                        List.of(new ApiModels.FollowUpOption("opt-a", "선택지 A"))
                )
        );
        llmClient.nextSuggestion = Optional.of(llmSuggestion);

        IntakeFollowUpSuggestion suggestion = advisor.suggest(defaultRequest());

        assertThat(suggestion).isEqualTo(llmSuggestion);
        assertThat(llmClient.called).isTrue();
        assertThat(llmClient.lastRequest).isNotNull();
    }

    @Test
    void fallsBackToRuleBasedWhenLlmReturnsEmpty() {
        RuleBasedIntakeFollowUpAdvisor ruleBased = new RuleBasedIntakeFollowUpAdvisor();
        StubLlmClient llmClient = new StubLlmClient(Optional.empty());
        HybridIntakeFollowUpAdvisor advisor = new HybridIntakeFollowUpAdvisor(ruleBased, llmClient, true);

        IntakeFollowUpSuggestion suggestion = advisor.suggest(defaultRequest());

        assertThat(suggestion.question()).isEqualTo("지금도 소음이 나나요?");
        assertThat(suggestion.followUpInterface()).isNotNull();
        assertThat(llmClient.called).isTrue();
    }

    private IntakeFollowUpRequest defaultRequest() {
        return new IntakeFollowUpRequest(
                "소음이 너무 심합니다.",
                List.of("noiseNow", "safety", "residence"),
                Map.of(),
                ApiModels.CaseStatus.RECEIVED,
                false
        );
    }

    private static final class StubLlmClient implements LlmIntakeFollowUpClient {
        private Optional<IntakeFollowUpSuggestion> nextSuggestion;
        private boolean called;
        private IntakeFollowUpRequest lastRequest;

        private StubLlmClient(Optional<IntakeFollowUpSuggestion> nextSuggestion) {
            this.nextSuggestion = nextSuggestion;
        }

        @Override
        public Optional<IntakeFollowUpSuggestion> suggest(IntakeFollowUpRequest request) {
            this.called = true;
            this.lastRequest = request;
            return nextSuggestion;
        }
    }
}
