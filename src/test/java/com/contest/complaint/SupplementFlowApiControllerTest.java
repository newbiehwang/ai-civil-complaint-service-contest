package com.contest.complaint;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.ArrayList;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(properties = "complaint.mock-submission.auto-process-enabled=false")
@AutoConfigureMockMvc(addFilters = false)
class SupplementFlowApiControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void institutionMockEventSupportsSupplementRoundTrip() throws Exception {
        String caseId = prepareCaseReadyForSubmission();

        mockMvc.perform(post("/api/v1/cases/{caseId}/submission", caseId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "submissionChannel":"MCP_API",
                                  "userConsent":true,
                                  "identityVerified":true
                                }
                                """))
                .andExpect(status().isAccepted());

        mockMvc.perform(post("/api/v1/cases/{caseId}/institution/mock-event", caseId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "eventType":"SUPPLEMENT_REQUIRED",
                                  "message":"최근 7일 소음일지를 추가 제출해주세요."
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("SUPPLEMENT_REQUIRED"))
                .andExpect(jsonPath("$.currentActionRequired").value("RESPOND_SUPPLEMENT"));

        mockMvc.perform(post("/api/v1/cases/{caseId}/supplement-response", caseId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "message":"요청하신 소음일지와 추가 녹음 파일을 제출했습니다."
                                }
                                """))
                .andExpect(status().isAccepted())
                .andExpect(jsonPath("$.status").value("INSTITUTION_PROCESSING"))
                .andExpect(jsonPath("$.currentActionRequired").value("WAIT_INSTITUTION_RESULT"));

        mockMvc.perform(post("/api/v1/cases/{caseId}/institution/mock-event", caseId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "eventType":"COMPLETED",
                                  "message":"기관 검토가 완료되어 민원 처리가 종결되었습니다."
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("COMPLETED"))
                .andExpect(jsonPath("$.currentActionRequired").value("CLOSE_CASE"));

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

        assertThat(eventTypes).containsSubsequence(
                "SUBMISSION_STARTED",
                "SUPPLEMENT_REQUESTED",
                "SUPPLEMENT_RESPONDED",
                "SUBMISSION_COMPLETED",
                "CASE_COMPLETED"
        );
    }

    @Test
    void institutionMockEventRequiresInstitutionProcessingState() throws Exception {
        String caseId = prepareCaseReadyForSubmission();

        mockMvc.perform(post("/api/v1/cases/{caseId}/institution/mock-event", caseId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "eventType":"SUPPLEMENT_REQUIRED"
                                }
                                """))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("CASE_STATE_CONFLICT"));
    }

    private String prepareCaseReadyForSubmission() throws Exception {
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

        return caseId;
    }
}
