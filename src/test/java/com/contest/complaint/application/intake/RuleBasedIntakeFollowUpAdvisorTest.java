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

        assertThat(suggestion.question()).isEqualTo("기본 정보가 충분해요. 추천 경로를 확인해 주세요.");
        assertThat(suggestion.followUpInterface()).isNull();
    }

    @Test
    void returnsNoiseNowQuestionAndSingleChoiceInterface() {
        IntakeFollowUpSuggestion suggestion = advisor.suggest(requestFor(List.of("noiseNow", "safety")));

        assertThat(suggestion.question()).isEqualTo("지금도 소음이 나나요?");
        assertThat(suggestion.followUpInterface()).isNotNull();
        assertThat(suggestion.followUpInterface().interfaceType()).isEqualTo(ApiModels.FollowUpInterfaceType.OPTIONS);
        assertThat(suggestion.followUpInterface().selectionMode()).isEqualTo(ApiModels.FollowUpSelectionMode.SINGLE);
        assertThat(suggestion.followUpInterface().options())
                .hasSize(3)
                .extracting(ApiModels.FollowUpOption::label)
                .containsExactly("지금 진행 중", "방금 멈춤", "자주 반복");
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
