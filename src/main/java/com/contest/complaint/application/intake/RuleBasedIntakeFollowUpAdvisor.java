package com.contest.complaint.application.intake;

import com.contest.complaint.api.model.ApiModels;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.UUID;

@Component
public class RuleBasedIntakeFollowUpAdvisor implements IntakeFollowUpAdvisor {

    private static final int MAX_OPTIONS = 4;

    @Override
    public IntakeFollowUpSuggestion suggest(IntakeFollowUpRequest request) {
        if (request.missingSlots() == null || request.missingSlots().isEmpty()) {
            return new IntakeFollowUpSuggestion(null, null);
        }

        String targetSlot = request.missingSlots().getFirst();
        String question = followUpQuestionFor(targetSlot);
        ApiModels.FollowUpInterface followUpInterface = followUpInterfaceFor(targetSlot);

        return new IntakeFollowUpSuggestion(question, followUpInterface);
    }

    private String followUpQuestionFor(String slot) {
        return switch (slot) {
            case "incidentTime" -> "소음이 주로 발생하는 시간대를 알려주세요.";
            case "frequency" -> "소음이 얼마나 자주 반복되는지 알려주세요.";
            case "noiseType" -> "어떤 종류의 소음인지 예시와 함께 알려주세요.";
            default -> "추가 정보를 입력해 주세요.";
        };
    }

    private ApiModels.FollowUpInterface followUpInterfaceFor(String slot) {
        return switch (slot) {
            case "incidentTime" -> buildOptionsInterface(
                    ApiModels.FollowUpSelectionMode.MULTIPLE,
                    List.of("새벽(00~06시)", "아침/낮(06~18시)", "저녁(18~22시)", "심야(22~24시)")
            );
            case "frequency" -> buildOptionsInterface(
                    ApiModels.FollowUpSelectionMode.SINGLE,
                    List.of("거의 매일", "주 2~3회", "주 1회 이하", "불규칙")
            );
            case "noiseType" -> buildOptionsInterface(
                    ApiModels.FollowUpSelectionMode.MULTIPLE,
                    List.of("발걸음/뛰는 소리", "가구 끄는 소리", "TV/음악 소리", "기타")
            );
            default -> null;
        };
    }

    private ApiModels.FollowUpInterface buildOptionsInterface(
            ApiModels.FollowUpSelectionMode selectionMode,
            List<String> labels
    ) {
        List<ApiModels.FollowUpOption> options = labels.stream()
                .filter(label -> label != null && !label.isBlank())
                .limit(MAX_OPTIONS)
                .map(String::trim)
                .map(label -> new ApiModels.FollowUpOption("opt-" + UUID.randomUUID().toString().substring(0, 8), label))
                .toList();

        if (options.isEmpty()) {
            return null;
        }

        return new ApiModels.FollowUpInterface(
                ApiModels.FollowUpInterfaceType.OPTIONS,
                selectionMode,
                options
        );
    }
}
