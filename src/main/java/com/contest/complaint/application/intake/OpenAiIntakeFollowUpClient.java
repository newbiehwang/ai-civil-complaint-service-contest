package com.contest.complaint.application.intake;

import com.contest.complaint.api.model.ApiModels;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@Component
public class OpenAiIntakeFollowUpClient implements LlmIntakeFollowUpClient {

    private static final Logger log = LoggerFactory.getLogger(OpenAiIntakeFollowUpClient.class);
    private static final int MAX_OPTIONS = 4;

    private final ObjectMapper objectMapper;
    private final HttpClient httpClient;
    private final String baseUrl;
    private final String apiKey;
    private final String model;
    private final int timeoutMs;

    public OpenAiIntakeFollowUpClient(
            ObjectMapper objectMapper,
            @Value("${complaint.ai.followup.openai.base-url:https://api.openai.com/v1}") String baseUrl,
            @Value("${complaint.ai.followup.openai.api-key:}") String apiKey,
            @Value("${complaint.ai.followup.openai.model:gpt-4o-mini}") String model,
            @Value("${complaint.ai.followup.openai.timeout-ms:4000}") int timeoutMs
    ) {
        this.objectMapper = objectMapper;
        this.httpClient = HttpClient.newBuilder().connectTimeout(Duration.ofMillis(Math.max(timeoutMs, 500))).build();
        this.baseUrl = stripTrailingSlash(baseUrl);
        this.apiKey = apiKey == null ? "" : apiKey.trim();
        this.model = model;
        this.timeoutMs = Math.max(timeoutMs, 500);
    }

    @Override
    public Optional<IntakeFollowUpSuggestion> suggest(IntakeFollowUpRequest request) {
        if (apiKey.isBlank()) {
            return Optional.empty();
        }

        try {
            String promptPayload = buildUserPayload(request);
            String requestBody = objectMapper.writeValueAsString(buildChatCompletionRequest(promptPayload));

            HttpRequest httpRequest = HttpRequest.newBuilder()
                    .uri(URI.create(baseUrl + "/chat/completions"))
                    .timeout(Duration.ofMillis(timeoutMs))
                    .header("Authorization", "Bearer " + apiKey)
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(requestBody))
                    .build();

            HttpResponse<String> response = httpClient.send(httpRequest, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() < 200 || response.statusCode() >= 300) {
                log.warn("OpenAI follow-up request failed: status={}, body={}", response.statusCode(), truncate(response.body()));
                return Optional.empty();
            }

            JsonNode root = objectMapper.readTree(response.body());
            String content = root.path("choices").path(0).path("message").path("content").asText("");
            if (content.isBlank()) {
                return Optional.empty();
            }

            String json = extractJsonObject(content).orElse(content);
            JsonNode payload = objectMapper.readTree(json);
            String question = payload.path("question").asText("").trim();
            if (question.isBlank()) {
                return Optional.empty();
            }

            ApiModels.FollowUpInterface followUpInterface = toFollowUpInterface(payload);
            return Optional.of(new IntakeFollowUpSuggestion(question, followUpInterface));
        } catch (IOException | InterruptedException ex) {
            if (ex instanceof InterruptedException) {
                Thread.currentThread().interrupt();
            }
            log.warn("OpenAI follow-up request error: {}", ex.getMessage());
            return Optional.empty();
        }
    }

    private Map<String, Object> buildChatCompletionRequest(String userPayload) {
        List<Map<String, String>> messages = List.of(
                Map.of(
                        "role", "system",
                        "content", """
                                당신은 층간소음 민원 접수 도우미입니다.
                                반드시 JSON만 출력하세요. 설명 문장은 금지입니다.
                                출력 스키마:
                                {
                                  "question": "string",
                                  "interfaceType": "OPTIONS|DATE|NONE",
                                  "selectionMode": "SINGLE|MULTIPLE|NONE",
                                  "options": ["string", "... 최대 4개"]
                                }
                                - 질문은 한국어로 작성
                                - interfaceType=OPTIONS면 options는 1~4개
                                - interfaceType=DATE면 options는 빈 배열
                                - interfaceType=NONE면 selectionMode=NONE, options=[]
                                """
                ),
                Map.of("role", "user", "content", userPayload)
        );

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("model", model);
        body.put("temperature", 0.2);
        body.put("response_format", Map.of("type", "json_object"));
        body.put("messages", messages);
        return body;
    }

    private String buildUserPayload(IntakeFollowUpRequest request) throws IOException {
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("latestUserMessage", request.latestUserMessage());
        payload.put("missingSlots", request.missingSlots());
        payload.put("filledSlots", request.filledSlots());
        payload.put("caseStatus", request.caseStatus().name());
        payload.put("riskSignalDetected", request.riskSignalDetected());
        payload.put("context", "층간소음 민원 접수 단계");
        return objectMapper.writeValueAsString(payload);
    }

    private ApiModels.FollowUpInterface toFollowUpInterface(JsonNode payload) {
        String interfaceTypeRaw = payload.path("interfaceType").asText("NONE").trim().toUpperCase(Locale.ROOT);
        if ("NONE".equals(interfaceTypeRaw)) {
            return null;
        }

        ApiModels.FollowUpInterfaceType interfaceType;
        try {
            interfaceType = ApiModels.FollowUpInterfaceType.valueOf(interfaceTypeRaw);
        } catch (IllegalArgumentException ex) {
            return null;
        }

        String selectionModeRaw = payload.path("selectionMode").asText("SINGLE").trim().toUpperCase(Locale.ROOT);
        ApiModels.FollowUpSelectionMode selectionMode;
        try {
            selectionMode = ApiModels.FollowUpSelectionMode.valueOf(selectionModeRaw);
        } catch (IllegalArgumentException ex) {
            selectionMode = ApiModels.FollowUpSelectionMode.SINGLE;
        }

        List<ApiModels.FollowUpOption> options = new ArrayList<>();
        if (interfaceType == ApiModels.FollowUpInterfaceType.OPTIONS && payload.path("options").isArray()) {
            int index = 0;
            for (JsonNode optionNode : payload.path("options")) {
                if (options.size() >= MAX_OPTIONS) {
                    break;
                }
                String label = optionNode.asText("").trim();
                if (label.isBlank()) {
                    continue;
                }
                options.add(new ApiModels.FollowUpOption("opt-" + UUID.randomUUID().toString().substring(0, 8), label));
                index++;
            }
            if (options.isEmpty()) {
                return null;
            }
        }

        return new ApiModels.FollowUpInterface(interfaceType, selectionMode, List.copyOf(options));
    }

    private Optional<String> extractJsonObject(String raw) {
        int start = raw.indexOf('{');
        int end = raw.lastIndexOf('}');
        if (start < 0 || end <= start) {
            return Optional.empty();
        }
        return Optional.of(raw.substring(start, end + 1));
    }

    private String stripTrailingSlash(String value) {
        return value == null ? "" : value.replaceAll("/+$", "");
    }

    private String truncate(String value) {
        if (value == null) {
            return "";
        }
        return value.length() <= 400 ? value : value.substring(0, 400) + "...";
    }
}
