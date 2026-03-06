package com.contest.complaint.application.chat;

import com.contest.complaint.api.model.ApiModels;
import com.anthropic.client.AnthropicClient;
import com.anthropic.client.okhttp.AnthropicOkHttpClient;
import com.anthropic.core.RequestOptions;
import com.anthropic.errors.AnthropicIoException;
import com.anthropic.errors.AnthropicServiceException;
import com.anthropic.errors.UnexpectedStatusCodeException;
import com.anthropic.models.messages.Message;
import com.anthropic.models.messages.MessageCreateParams;
import com.anthropic.models.messages.TextBlock;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.time.Duration;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Component
public class ClaudeChatTurnPlannerClient implements LlmChatTurnPlannerClient {

    private static final Logger log = LoggerFactory.getLogger(ClaudeChatTurnPlannerClient.class);
    private static final TypeReference<Map<String, Object>> MAP_TYPE = new TypeReference<>() {
    };
    private static final Pattern TRAILING_COMMA_PATTERN = Pattern.compile(",\\s*([}\\]])");
    private static final String DEFAULT_MODEL = "claude-3-5-sonnet-latest";
    private static final String SYSTEM_PROMPT = """
            You are a conversation orchestrator for floor-noise civil complaint intake.
            Output exactly one JSON object only, with no additional prose.
            Schema:
            {
              "assistantMessage":"string",
              "intent":"COLLECT_SLOT|CONFIRM_ROUTE|ADD_EVIDENCE|SUBMIT_CASE|REFRESH_STATUS|NONE",
              "intentPayload":{},
              "uiHint":{
                "type":"NONE|LIST_PICKER|OPTION_LIST|PATH_CHOOSER|SUMMARY_CARD",
                "selectionMode":"NONE|SINGLE|MULTIPLE",
                "title":"string|null",
                "subtitle":"string|null",
                "options":[{"id":"string","label":"string"}],
                "meta":{"flowStep":"string","requiredFields":[],"submitAllowed":false,"requiresExplicitConfirm":false}
              }
            }
            Rules:
            - Maximum 4 options.
            - 한국어로 답변.
            - If uiHint.options is non-empty, do not enumerate options in assistantMessage (no 1/2/3 or bullet list); keep assistantMessage to short guidance only.
            - Do not assume state-machine transitions directly; only suggest the next user action.
            - Prioritize flowStepHint and currentActionRequired over free-form guessing.
            - Use recentMessages only as short context, and keep the response concise.
            - Keep assistantMessage under 3 short sentences whenever possible.

            Flow templates:
            1) flowStepHint=general_chat
               - Behave like a normal counselor first.
               - If recentMessages is empty, start with:
                 "안녕하세요, 정부24 민원 서비스 도우미입니다. 무엇을 도와드릴까요?"
               - If recentMessages is not empty, NEVER prepend or repeat that greeting.
               - Do not repeat fixed intro phrases across turns.
               - Keep this phase very short: 1 empathy sentence + 1 confirmation sentence only.
               - In this phase, determine whether the user is requesting a complaint intake.
               - If user intent is floor-noise complaint intake, set intent=COLLECT_SLOT and return a short handoff message.
               - If user intent is not floor-noise, clearly state that only floor-noise intake is currently supported.
               - Do NOT ask slot-collection questions (noiseNow/safety/residence/time/frequency/source) in general_chat.
               - End with a gentle transition question when relevant:
                 "접수를 도와드릴 수 있어요. 지금 바로 진행할까요?"
               - Default uiHint.type should be NONE.

            2) flowStepHint=intake
               - Collect required slots one by one with short Korean prompts.
               - Prefer LIST_PICKER/OPTION_LIST when a structured choice is better than free text.
               - Use meta.requiredFields to highlight missing data.

            3) flowStepHint=path_choice
               - Explain recommended route in one short reason line.
               - Use PATH_CHOOSER with concise options.

            4) flowStepHint=evidence_or_submit
               - Guide optional evidence upload first, then explicit submit confirmation.
               - If proposing submission, set meta.requiresExplicitConfirm=true.

            5) flowStepHint=status_tracking
               - Summarize current status briefly.
               - Use STATUS_FEED only if useful for action; otherwise NONE.
            """;

    private final ObjectMapper objectMapper;
    private final AnthropicClient anthropicClient;
    private final boolean useLlm;
    private final String provider;
    private final String apiKey;
    private final String baseUrl;
    private final String model;
    private final int timeoutMs;
    private final int maxOutputTokens;

    public ClaudeChatTurnPlannerClient(
            ObjectMapper objectMapper,
            @Value("${complaint.ai.chat.use-llm:false}") boolean useLlm,
            @Value("${complaint.ai.chat.provider:claude}") String provider,
            @Value("${complaint.ai.chat.claude.base-url:https://api.anthropic.com}") String baseUrl,
            @Value("${complaint.ai.chat.claude.api-key:}") String apiKey,
            @Value("${complaint.ai.chat.claude.model:claude-3-5-sonnet-latest}") String model,
            @Value("${complaint.ai.chat.claude.timeout-ms:30000}") int timeoutMs,
            @Value("${complaint.ai.chat.claude.max-output-tokens:500}") int maxOutputTokens
    ) {
        this.objectMapper = objectMapper;
        this.useLlm = useLlm;
        this.provider = provider == null ? "" : provider.trim().toLowerCase(Locale.ROOT);
        this.apiKey = apiKey == null ? "" : apiKey.trim();
        this.baseUrl = normalizeBaseUrl(baseUrl);
        this.model = model == null || model.isBlank() ? DEFAULT_MODEL : model.trim();
        this.timeoutMs = Math.max(timeoutMs, 500);
        this.maxOutputTokens = Math.max(128, maxOutputTokens);
        this.anthropicClient = createAnthropicClient(this.baseUrl);
    }

    @Override
    public Optional<ChatTurnPlan> plan(ChatTurnPlannerRequest request) {
        if (!useLlm || !"claude".equals(provider) || apiKey.isBlank() || anthropicClient == null) {
            return Optional.empty();
        }

        try {
            String payloadJson = objectMapper.writeValueAsString(buildRequestPayload(request));
            MessageCreateParams params = MessageCreateParams.builder()
                    .model(resolveModel(model))
                    .maxTokens((long) maxOutputTokens)
                    .temperature(0.2)
                    .system(SYSTEM_PROMPT)
                    .addUserMessage(payloadJson)
                    .build();
            RequestOptions requestOptions = RequestOptions.builder()
                    .timeout(Duration.ofMillis(timeoutMs))
                    .build();
            long start = System.currentTimeMillis();
            Message response = anthropicClient.messages().create(params, requestOptions);
            long elapsed = System.currentTimeMillis() - start;
            String text = extractTextContent(response);
            if (text.isBlank()) {
                log.warn("Claude planner returned empty text: latencyMs={}", elapsed);
                return Optional.empty();
            }

            String json = extractFirstCompleteJsonObject(text)
                    .or(() -> tryRepairTruncatedJsonObject(text))
                    .orElse(null);
            if (json == null || json.isBlank()) {
                log.warn("Claude planner returned non-parseable JSON payload: latencyMs={}, text={}", elapsed, truncate(text));
                return Optional.empty();
            }
            JsonNode payload = parsePlannerJson(json).orElse(null);
            if (payload == null) {
                log.warn("Claude planner JSON parse failed after normalization: latencyMs={}, json={}", elapsed, truncate(json));
                return Optional.empty();
            }
            ChatTurnPlan plan = toPlan(payload);
            if (plan.assistantMessage() == null || plan.assistantMessage().isBlank()) {
                log.warn("Claude planner returned blank assistantMessage: latencyMs={}", elapsed);
                return Optional.empty();
            }
            log.info("Claude planner succeeded: latencyMs={}, intent={}, uiType={}",
                    elapsed,
                    plan.intent(),
                    plan.uiHint() == null ? null : plan.uiHint().type());
            return Optional.of(plan);
        } catch (UnexpectedStatusCodeException ex) {
            log.warn(
                    "Claude planner HTTP error: status={} body={} model={} baseUrl={} timeoutMs={}",
                    ex.statusCode(),
                    truncate(ex.body() == null ? "" : ex.body().toString()),
                    model,
                    baseUrl,
                    timeoutMs
            );
            return Optional.empty();
        } catch (AnthropicIoException ex) {
            Throwable cause = ex.getCause();
            log.warn(
                    "Claude planner I/O error: message={} causeType={} causeMessage={} model={} timeoutMs={}",
                    ex.getMessage(),
                    cause == null ? "-" : cause.getClass().getSimpleName(),
                    cause == null ? "-" : cause.getMessage(),
                    model,
                    timeoutMs
            );
            return Optional.empty();
        } catch (AnthropicServiceException ex) {
            log.warn(
                    "Claude planner service error: type={} message={} model={} timeoutMs={}",
                    ex.getClass().getSimpleName(),
                    ex.getMessage(),
                    model,
                    timeoutMs
            );
            return Optional.empty();
        } catch (Exception ex) {
            log.warn("Claude planner error: type={} message={}", ex.getClass().getSimpleName(), ex.getMessage());
            return Optional.empty();
        }
    }

    private Map<String, Object> buildRequestPayload(ChatTurnPlannerRequest request) {
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("traceId", request.traceId());
        payload.put("caseId", request.caseId() == null ? null : request.caseId().toString());
        payload.put("latestUserMessage", request.latestUserMessage());
        payload.put("caseStatus", request.caseStatus() == null ? null : request.caseStatus().name());
        payload.put("currentActionRequired", request.currentActionRequired());
        payload.put("flowStepHint", request.flowStepHint());
        payload.put("riskLevel", request.riskLevel() == null ? null : request.riskLevel().name());
        payload.put("filledSlots", request.filledSlots() == null ? Map.of() : request.filledSlots());
        payload.put("missingSlots", request.missingSlots() == null ? List.of() : request.missingSlots());
        payload.put("riskSignalDetected", request.riskSignalDetected());
        payload.put("routingOptions", request.routingOptions() == null ? List.of() : request.routingOptions());
        payload.put("evidenceChecklist", request.evidenceChecklist());
        payload.put("uiCapabilities", request.uiCapabilities() == null ? List.of() : request.uiCapabilities());
        payload.put("lastUiHintType", request.lastUiHintType());
        payload.put("recentMessages", request.recentMessages() == null ? List.of() : request.recentMessages());
        payload.put("interaction", request.interaction());
        return payload;
    }

    private ChatTurnPlan toPlan(JsonNode payload) {
        String assistantMessage = payload.path("assistantMessage").asText("").trim();
        String intent = payload.path("intent").asText("NONE").trim().toUpperCase(Locale.ROOT);

        ApiModels.ChatUiHint uiHint = toUiHint(payload.path("uiHint"));

        Map<String, Object> intentPayload = Map.of();
        if (payload.path("intentPayload").isObject()) {
            intentPayload = objectMapper.convertValue(payload.path("intentPayload"), MAP_TYPE);
        }

        return new ChatTurnPlan(assistantMessage, uiHint, intent, intentPayload);
    }

    private ApiModels.ChatUiHint toUiHint(JsonNode node) {
        if (node == null || !node.isObject()) {
            return new ApiModels.ChatUiHint(
                    ApiModels.ChatUiType.NONE,
                    ApiModels.ChatUiSelectionMode.NONE,
                    null,
                    null,
                    List.of(),
                    Map.of()
            );
        }

        ApiModels.ChatUiType type = parseUiType(node.path("type").asText("NONE"));
        ApiModels.ChatUiSelectionMode selectionMode = parseSelectionMode(node.path("selectionMode").asText("NONE"));
        String title = nullableText(node.path("title").asText(null));
        String subtitle = nullableText(node.path("subtitle").asText(null));

        List<ApiModels.ChatUiOption> options = new ArrayList<>();
        JsonNode optionsNode = node.path("options");
        if (optionsNode.isArray()) {
            for (JsonNode optionNode : optionsNode) {
                String id = nullableText(optionNode.path("id").asText(null));
                String label = nullableText(optionNode.path("label").asText(null));
                if (label == null) {
                    continue;
                }
                if (id == null) {
                    id = "opt-" + UUID.randomUUID().toString().substring(0, 8);
                }
                options.add(new ApiModels.ChatUiOption(id, label));
            }
        }

        Map<String, Object> meta = Map.of();
        JsonNode metaNode = node.path("meta");
        if (metaNode.isObject()) {
            meta = objectMapper.convertValue(metaNode, MAP_TYPE);
        }

        return new ApiModels.ChatUiHint(
                type,
                selectionMode,
                title,
                subtitle,
                List.copyOf(options),
                meta
        );
    }

    private ApiModels.ChatUiType parseUiType(String raw) {
        try {
            return ApiModels.ChatUiType.valueOf(raw.trim().toUpperCase(Locale.ROOT));
        } catch (Exception ex) {
            return ApiModels.ChatUiType.NONE;
        }
    }

    private ApiModels.ChatUiSelectionMode parseSelectionMode(String raw) {
        try {
            return ApiModels.ChatUiSelectionMode.valueOf(raw.trim().toUpperCase(Locale.ROOT));
        } catch (Exception ex) {
            return ApiModels.ChatUiSelectionMode.NONE;
        }
    }

    private String extractTextContent(Message response) {
        if (response == null || response.content() == null || response.content().isEmpty()) {
            return "";
        }
        return response.content().stream()
                .flatMap(contentBlock -> contentBlock.text().stream())
                .map(TextBlock::text)
                .map(String::trim)
                .filter(value -> !value.isBlank())
                .collect(Collectors.joining("\n"))
                .trim();
    }

    private Optional<String> extractJsonObject(String raw) {
        int start = raw.indexOf('{');
        int end = raw.lastIndexOf('}');
        if (start < 0 || end <= start) {
            return Optional.empty();
        }
        return Optional.of(raw.substring(start, end + 1));
    }

    private Optional<String> extractFirstCompleteJsonObject(String raw) {
        if (raw == null || raw.isBlank()) {
            return Optional.empty();
        }
        int start = -1;
        int depth = 0;
        boolean inString = false;
        boolean escaped = false;

        for (int i = 0; i < raw.length(); i++) {
            char ch = raw.charAt(i);

            if (inString) {
                if (escaped) {
                    escaped = false;
                    continue;
                }
                if (ch == '\\') {
                    escaped = true;
                    continue;
                }
                if (ch == '"') {
                    inString = false;
                }
                continue;
            }

            if (ch == '"') {
                inString = true;
                continue;
            }

            if (ch == '{') {
                if (depth == 0) {
                    start = i;
                }
                depth++;
                continue;
            }

            if (ch == '}' && depth > 0) {
                depth--;
                if (depth == 0 && start >= 0) {
                    return Optional.of(raw.substring(start, i + 1));
                }
            }
        }

        return Optional.empty();
    }

    private Optional<String> tryRepairTruncatedJsonObject(String raw) {
        if (raw == null || raw.isBlank()) {
            return Optional.empty();
        }
        int start = raw.indexOf('{');
        if (start < 0) {
            return Optional.empty();
        }

        String candidate = raw.substring(start);
        int depth = 0;
        boolean inString = false;
        boolean escaped = false;

        for (int i = 0; i < candidate.length(); i++) {
            char ch = candidate.charAt(i);

            if (inString) {
                if (escaped) {
                    escaped = false;
                    continue;
                }
                if (ch == '\\') {
                    escaped = true;
                    continue;
                }
                if (ch == '"') {
                    inString = false;
                }
                continue;
            }

            if (ch == '"') {
                inString = true;
                continue;
            }
            if (ch == '{') {
                depth++;
            } else if (ch == '}') {
                depth--;
                if (depth < 0) {
                    return Optional.empty();
                }
            }
        }

        if (inString) {
            return Optional.empty();
        }
        if (depth <= 0) {
            return Optional.of(candidate);
        }

        StringBuilder repaired = new StringBuilder(candidate);
        for (int i = 0; i < depth; i++) {
            repaired.append('}');
        }
        return Optional.of(repaired.toString());
    }

    private Optional<JsonNode> parsePlannerJson(String json) {
        try {
            return Optional.of(objectMapper.readTree(json));
        } catch (IOException first) {
            String normalized = normalizePlannerJson(json);
            if (normalized.equals(json)) {
                return Optional.empty();
            }
            try {
                return Optional.of(objectMapper.readTree(normalized));
            } catch (IOException second) {
                log.warn(
                        "Claude planner JSON normalization failed: first={} second={}",
                        first.getMessage(),
                        second.getMessage()
                );
                return Optional.empty();
            }
        }
    }

    private String normalizePlannerJson(String raw) {
        if (raw == null) {
            return "";
        }
        String normalized = raw
                .replace("\uFEFF", "")
                .replace('“', '"')
                .replace('”', '"')
                .replace('‘', '\'')
                .replace('’', '\'')
                .trim();

        String prev;
        do {
            prev = normalized;
            normalized = TRAILING_COMMA_PATTERN.matcher(normalized).replaceAll("$1");
        } while (!prev.equals(normalized));

        return normalized;
    }

    private AnthropicClient createAnthropicClient(String baseUrl) {
        if (!useLlm || !"claude".equals(provider) || apiKey.isBlank()) {
            return null;
        }
        String normalizedBaseUrl = normalizeBaseUrl(baseUrl);
        try {
            return AnthropicOkHttpClient.builder()
                    .apiKey(apiKey)
                    .baseUrl(normalizedBaseUrl)
                    .timeout(Duration.ofMillis(timeoutMs))
                    .maxRetries(0)
                    .build();
        } catch (Exception ex) {
            log.warn("Claude SDK client init failed: {}", ex.getMessage());
            return null;
        }
    }

    private String normalizeBaseUrl(String value) {
        String trimmed = value == null ? "" : value.trim().replaceAll("/+$", "");
        if (trimmed.isEmpty()) {
            return "https://api.anthropic.com";
        }
        if (trimmed.endsWith("/v1")) {
            return trimmed.substring(0, trimmed.length() - 3);
        }
        return trimmed;
    }

    private String resolveModel(String value) {
        String candidate = value == null || value.isBlank() ? DEFAULT_MODEL : value.trim();
        return candidate.isBlank() ? DEFAULT_MODEL : candidate;
    }

    private String nullableText(String raw) {
        if (raw == null) {
            return null;
        }
        String trimmed = raw.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private String truncate(String value) {
        if (value == null) {
            return "";
        }
        return value.length() <= 500 ? value : value.substring(0, 500) + "...";
    }
}
