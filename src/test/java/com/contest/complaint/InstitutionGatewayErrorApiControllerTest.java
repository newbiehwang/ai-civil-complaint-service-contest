package com.contest.complaint;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(properties = {
        "complaint.mock-submission.auto-process-enabled=false",
        "complaint.institution-gateway.fail-direct-api=true"
})
@AutoConfigureMockMvc(addFilters = false)
class InstitutionGatewayErrorApiControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void submitCaseReturnsInstitutionGatewayErrorWhenDirectApiIsUnavailable() throws Exception {
        String caseId = prepareCaseReadyForSubmission();

        String errorResponse = mockMvc.perform(post("/api/v1/cases/{caseId}/submission", caseId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "submissionChannel":"DIRECT_API",
                                  "userConsent":true,
                                  "identityVerified":true
                                }
                                """))
                .andExpect(status().isServiceUnavailable())
                .andExpect(jsonPath("$.code").value("INSTITUTION_GATEWAY_ERROR"))
                .andReturn()
                .getResponse()
                .getContentAsString();

        JsonNode node = objectMapper.readTree(errorResponse);
        assertThat(node.path("details").toString()).contains("submissionChannel=DIRECT_API");

        mockMvc.perform(get("/api/v1/cases/{caseId}", caseId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("FORMAL_SUBMISSION_READY"))
                .andExpect(jsonPath("$.currentActionRequired").value("SUBMIT_CASE"));
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
                                  "message":"지금 진행 중이고 위협 징후 없음입니다. 아파트이며 관리사무소 있음. 충격 소음(쿵쿵)이 거의 매일 심야에 발생하고 호수까지 확실합니다."
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
