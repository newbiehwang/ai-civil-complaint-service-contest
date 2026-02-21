package com.contest.complaint.application.intake;

import com.contest.complaint.api.model.ApiModels;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.UUID;

@Component
public class RuleBasedIntakeFollowUpAdvisor implements IntakeFollowUpAdvisor {

    private static final int MAX_OPTIONS = 4;
    private static final String SAFETY_DANGER = "위협 징후 있음";

    @Override
    public IntakeFollowUpSuggestion suggest(IntakeFollowUpRequest request) {
        List<String> missingSlots = request.missingSlots() == null ? List.of() : request.missingSlots();
        Object safety = request.filledSlots() == null ? null : request.filledSlots().get("safety");
        Object safetyContinue = request.filledSlots() == null ? null : request.filledSlots().get("safetyContinue");

        if (SAFETY_DANGER.equals(safety) && !Boolean.TRUE.equals(safetyContinue)) {
            return new IntakeFollowUpSuggestion(
                    "위협 징후가 감지되었습니다. 안전을 위해 112 우선 안내를 드렸어요.\n생활소음 접수를 계속할까요?",
                    buildOptionsInterface(
                            ApiModels.FollowUpSelectionMode.SINGLE,
                            List.of("생활소음 접수 계속")
                    )
            );
        }

        if (missingSlots.isEmpty()) {
            return new IntakeFollowUpSuggestion("기본 정보가 충분해요. 추천 경로를 확인해 주세요.", null);
        }

        String targetSlot = missingSlots.getFirst();
        String question = followUpQuestionFor(targetSlot);
        ApiModels.FollowUpInterface followUpInterface = followUpInterfaceFor(targetSlot);

        return new IntakeFollowUpSuggestion(question, followUpInterface);
    }

    private String followUpQuestionFor(String slot) {
        return switch (slot) {
            case "noiseNow" -> "지금도 소음이 나나요?";
            case "safety" -> "위협·폭행·기물파손 우려가 있나요?";
            case "residence" -> "거주 형태를 선택해 주세요.";
            case "management" -> "관리사무소(관리주체)가 있나요?";
            case "noiseType" -> "어떤 소음인가요?";
            case "frequency" -> "얼마나 자주 반복되나요?";
            case "timeBand" -> "주로 언제 발생하나요?";
            case "sourceCertainty" -> "발생원을 어느 정도 특정할 수 있나요?";
            default -> "추가 정보를 입력해 주세요.";
        };
    }

    private ApiModels.FollowUpInterface followUpInterfaceFor(String slot) {
        return switch (slot) {
            case "noiseNow" -> buildOptionsInterface(
                    ApiModels.FollowUpSelectionMode.SINGLE,
                    List.of("지금 진행 중", "방금 멈춤", "자주 반복")
            );
            case "safety" -> buildOptionsInterface(
                    ApiModels.FollowUpSelectionMode.SINGLE,
                    List.of("위협 징후 없음", "잘 모르겠음", "위협 징후 있음")
            );
            case "residence" -> buildOptionsInterface(
                    ApiModels.FollowUpSelectionMode.SINGLE,
                    List.of("아파트", "빌라", "오피스텔", "기타")
            );
            case "management" -> buildOptionsInterface(
                    ApiModels.FollowUpSelectionMode.SINGLE,
                    List.of("있음", "없음", "모름")
            );
            case "frequency" -> buildOptionsInterface(
                    ApiModels.FollowUpSelectionMode.SINGLE,
                    List.of("거의 매일", "주 2~3회", "주 1회 이하", "불규칙")
            );
            case "noiseType" -> buildOptionsInterface(
                    ApiModels.FollowUpSelectionMode.SINGLE,
                    List.of("충격 소음(쿵쿵)", "공기전달 소음(TV/음악)", "둘 다", "잘 모르겠음")
            );
            case "timeBand" -> buildOptionsInterface(
                    ApiModels.FollowUpSelectionMode.SINGLE,
                    List.of("저녁", "심야", "새벽", "불규칙")
            );
            case "sourceCertainty" -> buildOptionsInterface(
                    ApiModels.FollowUpSelectionMode.SINGLE,
                    List.of("호수까지 확실", "층은 확실(호수 불명)", "모름")
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
