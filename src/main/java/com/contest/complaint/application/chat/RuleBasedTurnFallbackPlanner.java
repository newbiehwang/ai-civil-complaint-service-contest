package com.contest.complaint.application.chat;

import com.contest.complaint.api.model.ApiModels;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Component
public class RuleBasedTurnFallbackPlanner {

    private static final String ACTION_NEIGHBOR_CENTER_FORM_REQUIRED = "NEIGHBOR_CENTER_FORM_REQUIRED";
    private static final String ACTION_NEIGHBOR_CENTER_DOCS_OPTIONAL = "NEIGHBOR_CENTER_DOCS_OPTIONAL";
    private static final String ACTION_NEIGHBOR_CENTER_DRAFT_REVIEW_REQUIRED = "NEIGHBOR_CENTER_DRAFT_REVIEW_REQUIRED";
    private static final String ACTION_NEIGHBOR_CENTER_CONSENT_REQUIRED = "NEIGHBOR_CENTER_CONSENT_REQUIRED";

    private static final List<String> NEIGHBOR_CENTER_REQUIRED_FIELDS = List.of(
            "name",
            "phone",
            "email",
            "housingName",
            "address"
    );

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
            case ROUTE_CONFIRMED -> {
                String action = detail.currentActionRequired() == null ? "" : detail.currentActionRequired();
                if (ACTION_NEIGHBOR_CENTER_FORM_REQUIRED.equals(action)) {
                    yield "이웃사이센터 접수에 필요한 신청 정보를 입력해 주세요.";
                }
                if (ACTION_NEIGHBOR_CENTER_DOCS_OPTIONAL.equals(action)) {
                    yield "참고자료는 선택사항입니다. 첨부하거나 건너뛸 수 있어요.";
                }
                if (ACTION_NEIGHBOR_CENTER_DRAFT_REVIEW_REQUIRED.equals(action)) {
                    yield "신청서 초안을 작성했어요. 확인 후 제출해 주세요.";
                }
                if (ACTION_NEIGHBOR_CENTER_CONSENT_REQUIRED.equals(action)) {
                    yield "개인정보 및 제출 동의를 확인해 주세요.";
                }
                yield "증거를 첨부하거나 제출 확인을 진행할 수 있어요.";
            }
            case EVIDENCE_COLLECTING -> "증거를 첨부하거나 제출 확인을 진행할 수 있어요.";
            case FORMAL_SUBMISSION_READY -> "제출 준비가 완료됐어요. 제출 확인을 진행해 주세요.";
            case INSTITUTION_PROCESSING -> "접수가 완료됐어요. 처리 결과를 계속 안내해 드릴게요.";
            case SUPPLEMENT_REQUIRED -> "보완 요청이 있을 수 있어요. 처리 결과를 계속 안내해 드릴게요.";
            case COMPLETED, CLOSED -> "처리가 마무리됐어요. 안내 내용을 확인해 주세요.";
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
            case ROUTE_CONFIRMED -> {
                String action = detail.currentActionRequired() == null ? "" : detail.currentActionRequired();
                if (ACTION_NEIGHBOR_CENTER_FORM_REQUIRED.equals(action)) {
                    yield buildNeighborCenterFormHint(detail);
                }
                if (ACTION_NEIGHBOR_CENTER_DOCS_OPTIONAL.equals(action)) {
                    yield buildNeighborCenterDocsOptionalHint();
                }
                if (ACTION_NEIGHBOR_CENTER_DRAFT_REVIEW_REQUIRED.equals(action)) {
                    yield buildNeighborCenterDraftReviewHint(detail);
                }
                if (ACTION_NEIGHBOR_CENTER_CONSENT_REQUIRED.equals(action)) {
                    yield buildNeighborCenterConsentHint();
                }
                yield buildEvidenceAndSubmitHint(detail);
            }
            case EVIDENCE_COLLECTING, FORMAL_SUBMISSION_READY -> buildEvidenceAndSubmitHint(detail);
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
        Map<String, String> optionReasons = new LinkedHashMap<>();
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
                if (option.reason() != null && !option.reason().isBlank()) {
                    optionReasons.put(option.optionId(), option.reason());
                }
            }
        }
        String recommendedOptionId = options.isEmpty() ? null : options.getFirst().id();

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
                        "requiresExplicitConfirm", false,
                        "optionReasons", Map.copyOf(optionReasons),
                        "recommendedOptionId", recommendedOptionId == null ? "" : recommendedOptionId
                )
        );
    }

    private ApiModels.ChatUiHint buildNeighborCenterFormHint(ApiModels.CaseDetail detail) {
        Map<String, Object> filled = detail.intake() == null || detail.intake().filledSlots() == null
                ? Map.of()
                : detail.intake().filledSlots();
        Map<String, Object> prefill = new LinkedHashMap<>();
        copyIfPresent(prefill, "name", filled.get("name"));
        copyIfPresent(prefill, "phone", filled.get("phone"));
        copyIfPresent(prefill, "email", filled.get("email"));
        copyIfPresent(prefill, "housingName", filled.get("housingName"));
        copyIfPresent(prefill, "address", filled.get("address"));
        copyIfPresent(prefill, "residence", filled.get("residence"));
        copyIfPresent(prefill, "management", filled.get("management"));
        copyIfPresent(prefill, "sourceCertainty", filled.get("sourceCertainty"));
        copyIfPresent(prefill, "noiseType", filled.get("noiseType"));
        copyIfPresent(prefill, "frequency", filled.get("frequency"));
        copyIfPresent(prefill, "timeBand", filled.get("timeBand"));
        copyIfPresent(prefill, "startedAt", filled.get("startedAt"));

        boolean submitAllowed = NEIGHBOR_CENTER_REQUIRED_FIELDS.stream()
                .allMatch(field -> {
                    Object value = prefill.get(field);
                    return value != null && !String.valueOf(value).trim().isBlank();
                });

        return new ApiModels.ChatUiHint(
                ApiModels.ChatUiType.OPTION_LIST,
                ApiModels.ChatUiSelectionMode.SINGLE,
                "이웃사이센터 신청 정보",
                "프로필 불러오기 또는 직접 입력으로 진행할 수 있어요.",
                List.of(
                        new ApiModels.ChatUiOption("neighbor-form-load-profile", "프로필 불러오기"),
                        new ApiModels.ChatUiOption("neighbor-form-submit", "입력 완료 후 제출")
                ),
                Map.of(
                        "flowStep", "neighborCenterForm",
                        "widgetType", "NEIGHBOR_CENTER_FORM",
                        "formMode", "HYBRID",
                        "prefill", Map.copyOf(prefill),
                        "requiredFields", List.copyOf(NEIGHBOR_CENTER_REQUIRED_FIELDS),
                        "submitAllowed", submitAllowed,
                        "requiresExplicitConfirm", true
                )
        );
    }

    private ApiModels.ChatUiHint buildNeighborCenterDocsOptionalHint() {
        return new ApiModels.ChatUiHint(
                ApiModels.ChatUiType.LIST_PICKER,
                ApiModels.ChatUiSelectionMode.MULTIPLE,
                "증거 제출",
                "참고자료는 선택사항입니다.",
                List.of(
                        new ApiModels.ChatUiOption("docs-visit-record", "방문상담 관련 문서"),
                        new ApiModels.ChatUiOption("docs-civil-status", "민원현황 관련 문서"),
                        new ApiModels.ChatUiOption("docs-reference", "기타 참고자료"),
                        new ApiModels.ChatUiOption("docs-skip", "첨부 없이 건너뛰기")
                ),
                Map.of(
                        "flowStep", "neighborCenterDocsOptional",
                        "widgetType", "NEIGHBOR_CENTER_DOCS_OPTIONAL",
                        "requiredFields", List.of(),
                        "submitAllowed", true,
                        "requiresExplicitConfirm", false
                )
        );
    }

    private ApiModels.ChatUiHint buildNeighborCenterDraftReviewHint(ApiModels.CaseDetail detail) {
        return new ApiModels.ChatUiHint(
                ApiModels.ChatUiType.LIST_PICKER,
                ApiModels.ChatUiSelectionMode.SINGLE,
                "신청서 초안",
                "한글파일 미리보기 후 제출 여부를 선택해 주세요.",
                List.of(
                        new ApiModels.ChatUiOption("draft-preview", "한글파일 미리보기"),
                        new ApiModels.ChatUiOption("draft-submit", "제출하기"),
                        new ApiModels.ChatUiOption("draft-edit", "수정 요청")
                ),
                Map.of(
                        "flowStep", "neighborCenterDraftReview",
                        "widgetType", "NEIGHBOR_CENTER_DRAFT",
                        "previewLines", List.copyOf(buildNeighborCenterDraftPreviewLines(detail)),
                        "requiredFields", List.of(),
                        "submitAllowed", true,
                        "requiresExplicitConfirm", true
                )
        );
    }

    private List<String> buildNeighborCenterDraftPreviewLines(ApiModels.CaseDetail detail) {
        Map<String, Object> filled = detail.intake() == null || detail.intake().filledSlots() == null
                ? Map.of()
                : detail.intake().filledSlots();
        List<String> lines = new ArrayList<>();
        lines.add("제목: 층간소음 측정 신청서 초안");
        lines.add("성명: " + valueOrDefault(filled.get("name")));
        lines.add("연락처: " + valueOrDefault(filled.get("phone")));
        lines.add("이메일: " + valueOrDefault(filled.get("email")));
        lines.add("주택명: " + valueOrDefault(filled.get("housingName")));
        lines.add("주소: " + valueOrDefault(filled.get("address")));
        lines.add("소음 유형: " + valueOrDefault(filled.get("noiseType")));
        lines.add("시간대: " + valueOrDefault(filled.get("timeBand")));
        lines.add("반복 빈도: " + valueOrDefault(filled.get("frequency")));
        lines.add("시작 시점: " + valueOrDefault(filled.get("startedAt")));
        if (detail.routing() != null && detail.routing().selectedOptionId() != null) {
            lines.add("선택 경로: " + detail.routing().selectedOptionId());
        }
        return List.copyOf(lines);
    }

    private String valueOrDefault(Object raw) {
        if (raw == null) return "미입력";
        String value = String.valueOf(raw).trim();
        return value.isEmpty() ? "미입력" : value;
    }

    private ApiModels.ChatUiHint buildNeighborCenterConsentHint() {
        return new ApiModels.ChatUiHint(
                ApiModels.ChatUiType.LIST_PICKER,
                ApiModels.ChatUiSelectionMode.MULTIPLE,
                "동의 확인",
                "필수 동의 항목을 모두 선택해 주세요.",
                List.of(
                        new ApiModels.ChatUiOption("consent-privacy", "개인정보 수집·이용 동의"),
                        new ApiModels.ChatUiOption("consent-third-party", "제3자 제공 동의"),
                        new ApiModels.ChatUiOption("consent-email", "이메일 제출 동의")
                ),
                Map.of(
                        "flowStep", "neighborCenterConsent",
                        "widgetType", "NEIGHBOR_CENTER_CONSENT",
                        "requiredFields", List.of("consent-privacy", "consent-third-party", "consent-email"),
                        "submitAllowed", true,
                        "requiresExplicitConfirm", true
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

    private void copyIfPresent(Map<String, Object> target, String key, Object rawValue) {
        if (rawValue == null) {
            return;
        }
        String value = String.valueOf(rawValue).trim();
        if (!value.isEmpty()) {
            target.put(key, value);
        }
    }
}
