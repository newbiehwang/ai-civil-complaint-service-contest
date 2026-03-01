package com.contest.complaint.application.chat;

import com.contest.complaint.api.model.ApiModels;
import org.springframework.stereotype.Component;

import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.regex.Pattern;

@Component
public class ChatTurnPlanValidator {

    private static final int MAX_OPTIONS = 4;
    private static final Pattern LIST_LINE_PATTERN = Pattern.compile(
            "^\\s*(?:[0-9]+[\\).]|[①-⑳]|[-*•]\\s+).*$"
    );
    private static final Set<String> ALLOWED_UI_TYPES = Set.of(
            "NONE",
            "LIST_PICKER",
            "OPTION_LIST",
            "PATH_CHOOSER",
            "SUMMARY_CARD",
            "STATUS_FEED"
    );

    public ChatTurnPlan sanitize(
            ChatTurnPlan plan,
            ApiModels.CaseDetail detail,
            List<String> uiCapabilities
    ) {
        if (plan == null) {
            return ChatTurnPlan.empty();
        }

        String assistantMessage = plan.assistantMessage() == null ? "" : plan.assistantMessage().trim();

        ApiModels.ChatUiHint uiHint = sanitizeUiHint(plan.uiHint(), uiCapabilities);
        if (isGeneralChatMode(detail)) {
            uiHint = noneHint();
        }
        assistantMessage = sanitizeAssistantMessage(assistantMessage, uiHint);
        String intent = sanitizeIntent(plan.intent(), detail);

        return new ChatTurnPlan(
                assistantMessage,
                uiHint,
                intent,
                plan.intentPayload() == null ? Map.of() : plan.intentPayload()
        );
    }

    public boolean isUsable(ChatTurnPlan plan) {
        return plan != null && plan.assistantMessage() != null && !plan.assistantMessage().isBlank();
    }

    private ApiModels.ChatUiHint sanitizeUiHint(ApiModels.ChatUiHint uiHint, List<String> uiCapabilities) {
        ApiModels.ChatUiHint safeHint = uiHint == null
                ? new ApiModels.ChatUiHint(
                ApiModels.ChatUiType.NONE,
                ApiModels.ChatUiSelectionMode.NONE,
                null,
                null,
                List.of(),
                Map.of()
        )
                : uiHint;

        String normalizedType = safeHint.type() == null
                ? "NONE"
                : safeHint.type().name().toUpperCase(Locale.ROOT);
        if (!ALLOWED_UI_TYPES.contains(normalizedType)) {
            return noneHint();
        }

        if (safeHint.type() != ApiModels.ChatUiType.NONE && !isUiTypeAllowedByClient(safeHint.type(), uiCapabilities)) {
            return noneHint();
        }

        List<ApiModels.ChatUiOption> options = safeHint.options() == null
                ? List.of()
                : safeHint.options().stream()
                .filter(option -> option != null
                        && option.id() != null && !option.id().isBlank()
                        && option.label() != null && !option.label().isBlank())
                .limit(MAX_OPTIONS)
                .map(option -> new ApiModels.ChatUiOption(option.id().trim(), option.label().trim()))
                .toList();

        ApiModels.ChatUiSelectionMode selectionMode = safeHint.selectionMode() == null
                ? ApiModels.ChatUiSelectionMode.NONE
                : safeHint.selectionMode();

        if (safeHint.type() == ApiModels.ChatUiType.NONE) {
            selectionMode = ApiModels.ChatUiSelectionMode.NONE;
        } else if (options.isEmpty()) {
            selectionMode = ApiModels.ChatUiSelectionMode.NONE;
        }

        Map<String, Object> normalizedMeta = new LinkedHashMap<>(
                safeHint.meta() == null ? Map.of() : safeHint.meta()
        );
        normalizedMeta.putIfAbsent("flowStep", inferFlowStep(safeHint.type()));
        normalizedMeta.putIfAbsent("requiredFields", List.of());
        normalizedMeta.putIfAbsent("submitAllowed", false);
        normalizedMeta.putIfAbsent("requiresExplicitConfirm", false);

        return new ApiModels.ChatUiHint(
                safeHint.type(),
                selectionMode,
                normalizeNullableText(safeHint.title()),
                normalizeNullableText(safeHint.subtitle()),
                options,
                Map.copyOf(normalizedMeta)
        );
    }

    private String sanitizeIntent(String intentRaw, ApiModels.CaseDetail detail) {
        String intent = intentRaw == null ? "NONE" : intentRaw.trim().toUpperCase(Locale.ROOT);
        if (intent.isBlank()) {
            intent = "NONE";
        }

        return switch (intent) {
            case "COLLECT_SLOT" -> detail.status() == ApiModels.CaseStatus.RECEIVED ? intent : "NONE";
            case "CONFIRM_ROUTE" -> "CONFIRM_ROUTE".equals(detail.currentActionRequired()) ? intent : "NONE";
            case "ADD_EVIDENCE" -> switch (detail.status()) {
                case ROUTE_CONFIRMED, EVIDENCE_COLLECTING, FORMAL_SUBMISSION_READY -> intent;
                default -> "NONE";
            };
            case "SUBMIT_CASE" -> detail.status() == ApiModels.CaseStatus.FORMAL_SUBMISSION_READY ? intent : "NONE";
            case "REFRESH_STATUS" -> switch (detail.status()) {
                case INSTITUTION_PROCESSING, SUPPLEMENT_REQUIRED, COMPLETED, CLOSED -> intent;
                default -> "NONE";
            };
            case "NONE" -> "NONE";
            default -> "NONE";
        };
    }

    private boolean isUiTypeAllowedByClient(ApiModels.ChatUiType type, List<String> uiCapabilities) {
        if (uiCapabilities == null || uiCapabilities.isEmpty()) {
            return true;
        }
        Set<String> capabilitySet = new HashSet<>();
        for (String capability : uiCapabilities) {
            if (capability == null) continue;
            capabilitySet.add(capability.trim().toUpperCase(Locale.ROOT));
        }
        return capabilitySet.contains(type.name().toUpperCase(Locale.ROOT));
    }

    private ApiModels.ChatUiHint noneHint() {
        return new ApiModels.ChatUiHint(
                ApiModels.ChatUiType.NONE,
                ApiModels.ChatUiSelectionMode.NONE,
                null,
                null,
                List.of(),
                Map.of()
        );
    }

    private String normalizeNullableText(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private String inferFlowStep(ApiModels.ChatUiType type) {
        if (type == null) {
            return "none";
        }
        return switch (type) {
            case LIST_PICKER -> "intake";
            case OPTION_LIST -> "evidence";
            case PATH_CHOOSER -> "pathChooser";
            case SUMMARY_CARD -> "summary";
            case STATUS_FEED -> "statusFeed";
            default -> "none";
        };
    }

    private String sanitizeAssistantMessage(String message, ApiModels.ChatUiHint uiHint) {
        String normalized = normalizeMarkdownArtifacts(message);
        boolean hasStructuredOptions = uiHint != null
                && uiHint.type() != null
                && uiHint.type() != ApiModels.ChatUiType.NONE
                && uiHint.options() != null
                && !uiHint.options().isEmpty();
        if (!hasStructuredOptions) {
            return normalized;
        }

        String[] lines = normalized.split("\\R");
        StringBuilder compact = new StringBuilder();
        for (String rawLine : lines) {
            String line = rawLine == null ? "" : rawLine.trim();
            if (line.isEmpty()) {
                continue;
            }
            if (LIST_LINE_PATTERN.matcher(line).matches()) {
                continue;
            }
            if (!compact.isEmpty()) {
                compact.append('\n');
            }
            compact.append(line);
        }

        String cleaned = compact.toString().trim();
        if (cleaned.isEmpty()) {
            return fallbackAssistantMessage(uiHint.type());
        }

        return keepFirstTwoLines(cleaned);
    }

    private String normalizeMarkdownArtifacts(String value) {
        if (value == null || value.isBlank()) {
            return "";
        }
        String normalized = value
                .replace("**", "")
                .replace("*", "")
                .replace("`", "")
                .trim();
        return normalized;
    }

    private String keepFirstTwoLines(String value) {
        String[] lines = value.split("\\R");
        StringBuilder sb = new StringBuilder();
        int count = 0;
        for (String raw : lines) {
            String line = raw == null ? "" : raw.trim();
            if (line.isEmpty()) {
                continue;
            }
            if (count > 0) {
                sb.append('\n');
            }
            sb.append(line);
            count += 1;
            if (count >= 2) {
                break;
            }
        }
        return sb.toString().trim();
    }

    private String fallbackAssistantMessage(ApiModels.ChatUiType type) {
        if (type == null) {
            return "선택 항목을 확인해 주세요.";
        }
        return switch (type) {
            case LIST_PICKER -> "원하시는 항목을 선택해 주세요.";
            case OPTION_LIST -> "필요한 항목을 선택해 주세요.";
            case PATH_CHOOSER -> "진행할 경로를 선택해 주세요.";
            case SUMMARY_CARD -> "정리된 내용을 확인해 주세요.";
            case STATUS_FEED -> "현재 진행 상태를 확인해 주세요.";
            default -> "선택 항목을 확인해 주세요.";
        };
    }

    private boolean isGeneralChatMode(ApiModels.CaseDetail detail) {
        if (detail == null || detail.status() != ApiModels.CaseStatus.RECEIVED) {
            return false;
        }
        String action = detail.currentActionRequired();
        return action != null && "GENERAL_CHAT".equalsIgnoreCase(action.trim());
    }
}
