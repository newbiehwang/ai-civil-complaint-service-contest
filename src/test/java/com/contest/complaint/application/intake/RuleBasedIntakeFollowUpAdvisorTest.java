package com.contest.complaint.application.intake;

import com.contest.complaint.api.model.ApiModels;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class RuleBasedIntakeFollowUpAdvisorTest {

    private final RuleBasedIntakeFollowUpAdvisor advisor = new RuleBasedIntakeFollowUpAdvisor();

    @Test
    void returnsEmptySuggestionWhenMissingSlotsAreEmpty() {
        IntakeFollowUpSuggestion suggestion = advisor.suggest(requestFor(List.of()));

        assertThat(suggestion.question()).isNull();
        assertThat(suggestion.followUpInterface()).isNull();
    }

    @Test
    void returnsIncidentTimeQuestionAndMultipleChoiceInterface() {
        IntakeFollowUpSuggestion suggestion = advisor.suggest(requestFor(List.of("incidentTime", "frequency")));

        assertThat(suggestion.question()).isEqualTo("소음이 주로 발생하는 시간대를 알려주세요.");
        assertThat(suggestion.followUpInterface()).isNotNull();
        assertThat(suggestion.followUpInterface().interfaceType()).isEqualTo(ApiModels.FollowUpInterfaceType.OPTIONS);
        assertThat(suggestion.followUpInterface().selectionMode()).isEqualTo(ApiModels.FollowUpSelectionMode.MULTIPLE);
        assertThat(suggestion.followUpInterface().options())
                .hasSize(4)
                .extracting(ApiModels.FollowUpOption::label)
                .containsExactly("새벽(00~06시)", "아침/낮(06~18시)", "저녁(18~22시)", "심야(22~24시)");
    }

    @Test
    void returnsGenericQuestionForUnknownSlotWithoutInterface() {
        IntakeFollowUpSuggestion suggestion = advisor.suggest(requestFor(List.of("unknownSlot")));

        assertThat(suggestion.question()).isEqualTo("추가 정보를 입력해 주세요.");
        assertThat(suggestion.followUpInterface()).isNull();
    }

    private IntakeFollowUpRequest requestFor(List<String> missingSlots) {
        return new IntakeFollowUpRequest(
                "테스트 메시지",
                missingSlots,
                Map.of(),
                ApiModels.CaseStatus.RECEIVED,
                false
        );
    }
}
