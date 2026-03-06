package com.contest.complaint.application.chat;

import com.contest.complaint.api.model.ApiModels;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Component
public class RuleBasedTurnFallbackPlanner {

    public ChatTurnPlan plan(
            ApiModels.IntakeUpdateResponse intakeUpdate,
            ApiModels.CaseDetail detail,
            List<String> requiredSlots,
            List<ApiModels.ChatTurnHistoryMessage> recentMessages
    ) {
        String assistantMessage = resolveAssistantMessage(intakeUpdate, detail);
        ApiModels.ChatUiHint uiHint = resolveUiHint(intakeUpdate, detail, requiredSlots);
        return new ChatTurnPlan(assistantMessage, uiHint, "NONE", Map.of());
    }

    private String resolveAssistantMessage(
            ApiModels.IntakeUpdateResponse intakeUpdate,
            ApiModels.CaseDetail detail
    ) {
        if (intakeUpdate != null
                && intakeUpdate.recommendedFollowUpQuestion() != null
                && !intakeUpdate.recommendedFollowUpQuestion().isBlank()) {
            return intakeUpdate.recommendedFollowUpQuestion();
        }

        return switch (detail.status()) {
            case RECEIVED -> {
                if (isGeneralChatMode(detail)) {
                    yield "어떤 민원인지 편하게 말씀해 주세요.";
                }
                yield "현재 상황을 단계별로 확인할게요. 필요한 항목을 선택해 주세요.";
            }
            case CLASSIFIED -> "추천 경로를 준비했어요. 진행 방식을 선택해 주세요.";
            case ROUTE_CONFIRMED, EVIDENCE_COLLECTING -> "증거를 첨부하거나 제출 확인을 진행할 수 있어요.";
            case FORMAL_SUBMISSION_READY -> "제출 준비가 완료됐어요. 제출 확인을 진행해 주세요.";
            case INSTITUTION_PROCESSING -> "접수가 완료되어 기관에서 처리 중이에요.";
            case SUPPLEMENT_REQUIRED -> "보완자료 요청이 있어요. 보완 후 다시 제출해 주세요.";
            case COMPLETED, CLOSED -> "처리가 완료되었습니다.";
            default -> "다음 단계를 진행해 주세요.";
        };
    }

    private ApiModels.ChatUiHint resolveUiHint(
            ApiModels.IntakeUpdateResponse intakeUpdate,
            ApiModels.CaseDetail detail,
            List<String> requiredSlots
    ) {
        if (detail.status() == ApiModels.CaseStatus.RECEIVED && isGeneralChatMode(detail)) {
            return new ApiModels.ChatUiHint(
                    ApiModels.ChatUiType.NONE,
                    ApiModels.ChatUiSelectionMode.NONE,
                    null,
                    null,
                    List.of(),
                    Map.of(
                            "flowStep", "general_chat",
                            "requiredFields", List.of(),
                            "submitAllowed", false,
                            "requiresExplicitConfirm", false
                    )
            );
        }

        if (detail.status() == ApiModels.CaseStatus.RECEIVED && intakeUpdate != null && intakeUpdate.followUpInterface() != null) {
            ApiModels.FollowUpInterface followUpInterface = intakeUpdate.followUpInterface();
            List<ApiModels.ChatUiOption> options = new ArrayList<>();
            if (followUpInterface.options() != null) {
                for (ApiModels.FollowUpOption option : followUpInterface.options()) {
                    options.add(new ApiModels.ChatUiOption(option.optionId(), option.label()));
                }
            }
            return new ApiModels.ChatUiHint(
                    followUpInterface.interfaceType() == ApiModels.FollowUpInterfaceType.DATE
                            ? ApiModels.ChatUiType.OPTION_LIST
                            : ApiModels.ChatUiType.LIST_PICKER,
                    switch (followUpInterface.selectionMode()) {
                        case MULTIPLE -> ApiModels.ChatUiSelectionMode.MULTIPLE;
                        case SINGLE -> ApiModels.ChatUiSelectionMode.SINGLE;
                    },
                    null,
                    null,
                    List.copyOf(options),
                    Map.of(
                            "flowStep", "intake",
                            "requiredFields", resolveMissingSlots(detail, requiredSlots),
                            "submitAllowed", false,
                            "requiresExplicitConfirm", false
                    )
            );
        }

        return switch (detail.status()) {
            case CLASSIFIED -> buildPathChooserHint(detail);
            case ROUTE_CONFIRMED, EVIDENCE_COLLECTING, FORMAL_SUBMISSION_READY -> buildEvidenceAndSubmitHint(detail);
            case INSTITUTION_PROCESSING, SUPPLEMENT_REQUIRED, COMPLETED, CLOSED -> buildStatusFeedHint(detail);
            default -> new ApiModels.ChatUiHint(
                    ApiModels.ChatUiType.NONE,
                    ApiModels.ChatUiSelectionMode.NONE,
                    null,
                    null,
                    List.of(),
                    Map.of()
            );
        };
    }

    private ApiModels.ChatUiHint buildPathChooserHint(ApiModels.CaseDetail detail) {
        List<ApiModels.ChatUiOption> options = new ArrayList<>();
        ApiModels.RoutingRecommendation routing = detail.routing();
        if (routing != null && routing.options() != null) {
            for (ApiModels.RoutingOption option : routing.options()) {
                if (option.optionId() == null || option.optionId().isBlank()) {
                    continue;
                }
                if (option.label() == null || option.label().isBlank()) {
                    continue;
                }
                options.add(new ApiModels.ChatUiOption(option.optionId(), option.label()));
            }
        }

        return new ApiModels.ChatUiHint(
                ApiModels.ChatUiType.PATH_CHOOSER,
                ApiModels.ChatUiSelectionMode.SINGLE,
                "추천 경로",
                "진행 방식을 선택해 주세요.",
                List.copyOf(options),
                Map.of(
                        "flowStep", "pathChooser",
                        "requiredFields", List.of(),
                        "submitAllowed", false,
                        "requiresExplicitConfirm", false
                )
        );
    }

    private ApiModels.ChatUiHint buildEvidenceAndSubmitHint(ApiModels.CaseDetail detail) {
        List<ApiModels.ChatUiOption> options = List.of(
                new ApiModels.ChatUiOption("evidence-audio", "녹음 파일 첨부"),
                new ApiModels.ChatUiOption("evidence-video", "동영상 첨부"),
                new ApiModels.ChatUiOption("evidence-log", "소음 일지 첨부"),
                new ApiModels.ChatUiOption("submit-confirm", "제출 진행 확인")
        );

        boolean submitAllowed = detail.status() == ApiModels.CaseStatus.FORMAL_SUBMISSION_READY
                || detail.status() == ApiModels.CaseStatus.EVIDENCE_COLLECTING
                || detail.status() == ApiModels.CaseStatus.ROUTE_CONFIRMED;
        List<String> required = detail.evidenceChecklist() == null
                ? List.of()
                : detail.evidenceChecklist().missingItems();

        return new ApiModels.ChatUiHint(
                ApiModels.ChatUiType.OPTION_LIST,
                ApiModels.ChatUiSelectionMode.SINGLE,
                "증거 제출",
                "필요한 항목을 선택해 주세요.",
                options,
                Map.of(
                        "flowStep", "evidence",
                        "status", detail.status().name(),
                        "requiredFields", required,
                        "submitAllowed", submitAllowed,
                        "requiresExplicitConfirm", true
                )
        );
    }

    private ApiModels.ChatUiHint buildStatusFeedHint(ApiModels.CaseDetail detail) {
        List<ApiModels.ChatUiOption> options = List.of(
                new ApiModels.ChatUiOption("status-refresh", "상태 새로고침"),
                new ApiModels.ChatUiOption("status-restart", "처음으로 돌아가기")
        );

        return new ApiModels.ChatUiHint(
                ApiModels.ChatUiType.STATUS_FEED,
                ApiModels.ChatUiSelectionMode.SINGLE,
                "진행 상태",
                "현재 처리 상태를 확인할 수 있어요.",
                options,
                Map.of(
                        "flowStep", "statusFeed",
                        "status", detail.status().name(),
                        "requiredFields", List.of(),
                        "submitAllowed", false,
                        "requiresExplicitConfirm", false
                )
        );
    }

    private List<String> resolveMissingSlots(ApiModels.CaseDetail detail, List<String> requiredSlots) {
        ApiModels.IntakeSnapshot intake = detail.intake();
        if (intake == null || intake.filledSlots() == null || requiredSlots == null || requiredSlots.isEmpty()) {
            return List.of();
        }
        Map<String, Object> filledSlots = intake.filledSlots();
        List<String> missing = new ArrayList<>();
        for (String slot : requiredSlots) {
            if (!filledSlots.containsKey(slot)) {
                missing.add(slot);
            }
        }
        if ("위협 징후 있음".equals(filledSlots.get("safety"))
                && !Boolean.TRUE.equals(filledSlots.get("safetyContinue"))) {
            missing.addFirst("safetyContinue");
        }
        return List.copyOf(missing);
    }

    private boolean isGeneralChatMode(ApiModels.CaseDetail detail) {
        return detail.status() == ApiModels.CaseStatus.RECEIVED
                && "GENERAL_CHAT".equalsIgnoreCase(detail.currentActionRequired());
    }
}
