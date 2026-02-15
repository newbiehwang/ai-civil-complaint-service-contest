package com.contest.complaint;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.awaitility.Awaitility;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.time.Duration;
import java.util.ArrayList;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class ScenarioAApiControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void createCaseReturnsCreated() throws Exception {
        String response = mockMvc.perform(post("/api/v1/cases")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "scenarioType":"INTER_FLOOR_NOISE",
                                  "housingType":"APARTMENT",
                                  "consentAccepted":true,
                                  "initialSummary":"밤마다 쿵쿵 소음이 납니다"
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.status").value("RECEIVED"))
                .andReturn()
                .getResponse()
                .getContentAsString();

        JsonNode node = objectMapper.readTree(response);
        assertThat(node.get("caseId").asText()).isNotBlank();
    }

    @Test
    void registerEvidenceBeforeRouteConfirmationReturnsConflict() throws Exception {
        String createResponse = mockMvc.perform(post("/api/v1/cases")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "scenarioType":"INTER_FLOOR_NOISE",
                                  "housingType":"APARTMENT",
                                  "consentAccepted":true
                                }
                                """))
                .andExpect(status().isCreated())
                .andReturn()
                .getResponse()
                .getContentAsString();

        String caseId = objectMapper.readTree(createResponse).get("caseId").asText();

        mockMvc.perform(post("/api/v1/cases/{caseId}/evidence", caseId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "evidenceType":"AUDIO",
                                  "storageKey":"evidence/test/audio-1.m4a",
                                  "capturedAt":"2026-02-15T10:00:00Z"
                                }
                                """))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("CASE_STATE_CONFLICT"));
    }

    @Test
    void submitCaseCompletesAsynchronouslyByMockWorker() throws Exception {
        String createResponse = mockMvc.perform(post("/api/v1/cases")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "scenarioType":"INTER_FLOOR_NOISE",
                                  "housingType":"APARTMENT",
                                  "consentAccepted":true
                                }
                                """))
                .andExpect(status().isCreated())
                .andReturn()
                .getResponse()
                .getContentAsString();

        String caseId = objectMapper.readTree(createResponse).get("caseId").asText();

        mockMvc.perform(post("/api/v1/cases/{caseId}/intake/messages", caseId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "role":"USER",
                                  "message":"밤마다 매일 쿵쿵 소음이 반복됩니다."
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("CLASSIFIED"));

        mockMvc.perform(post("/api/v1/cases/{caseId}/decomposition", caseId))
                .andExpect(status().isOk());

        String recommendationResponse = mockMvc.perform(post("/api/v1/cases/{caseId}/routing/recommendation", caseId))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString();

        String optionId = objectMapper.readTree(recommendationResponse)
                .path("options")
                .get(0)
                .path("optionId")
                .asText();
        assertThat(optionId).isNotBlank();

        mockMvc.perform(post("/api/v1/cases/{caseId}/routing/decision", caseId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "optionId":"%s",
                                  "userConfirmed":true
                                }
                                """.formatted(optionId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("ROUTE_CONFIRMED"));

        mockMvc.perform(post("/api/v1/cases/{caseId}/evidence", caseId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "evidenceType":"AUDIO",
                                  "storageKey":"evidence/test/audio-1.m4a",
                                  "capturedAt":"2026-02-15T10:00:00Z"
                                }
                                """))
                .andExpect(status().isCreated());

        mockMvc.perform(post("/api/v1/cases/{caseId}/evidence", caseId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "evidenceType":"LOG",
                                  "storageKey":"evidence/test/log-1.json",
                                  "capturedAt":"2026-02-15T10:01:00Z"
                                }
                                """))
                .andExpect(status().isCreated());

        mockMvc.perform(post("/api/v1/cases/{caseId}/submission", caseId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "submissionChannel":"MCP_API",
                                  "userConsent":true,
                                  "identityVerified":true
                                }
                                """))
                .andExpect(status().isAccepted())
                .andExpect(jsonPath("$.submissionStatus").value("QUEUED"));

        Awaitility.await()
                .atMost(Duration.ofSeconds(5))
                .untilAsserted(() -> mockMvc.perform(get("/api/v1/cases/{caseId}", caseId))
                        .andExpect(status().isOk())
                        .andExpect(jsonPath("$.status").value("COMPLETED"))
                        .andExpect(jsonPath("$.currentActionRequired").value("CLOSE_CASE")));

        String timelineResponse = mockMvc.perform(get("/api/v1/cases/{caseId}/timeline", caseId))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString();

        JsonNode eventsNode = objectMapper.readTree(timelineResponse).path("events");
        List<String> eventTypes = new ArrayList<>();
        for (JsonNode eventNode : eventsNode) {
            eventTypes.add(eventNode.path("eventType").asText());
        }

        assertThat(eventTypes).contains("SUBMISSION_COMPLETED", "CASE_COMPLETED");
    }
}
