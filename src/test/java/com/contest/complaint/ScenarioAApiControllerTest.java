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
}
