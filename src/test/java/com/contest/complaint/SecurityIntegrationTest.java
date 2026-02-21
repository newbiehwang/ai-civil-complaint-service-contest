package com.contest.complaint;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class SecurityIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void createCaseWithoutTokenReturnsUnauthorized() throws Exception {
        mockMvc.perform(post("/api/v1/cases")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "scenarioType":"INTER_FLOOR_NOISE",
                                  "housingType":"APARTMENT",
                                  "consentAccepted":true
                                }
                                """))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("UNAUTHORIZED"));
    }

    @Test
    void createCaseWithJwtAuthenticationSucceeds() throws Exception {
        mockMvc.perform(post("/api/v1/cases")
                        .with(jwt())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "scenarioType":"INTER_FLOOR_NOISE",
                                  "housingType":"APARTMENT",
                                  "consentAccepted":true
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.status").value("RECEIVED"));
    }

    @Test
    void appendIntakeMessageWithoutTokenReturnsUnauthorized() throws Exception {
        String caseId = createCaseWithJwt();

        mockMvc.perform(post("/api/v1/cases/{caseId}/intake/messages", caseId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "role":"USER",
                                  "message":"밤마다 소음이 들립니다."
                                }
                                """))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("UNAUTHORIZED"));
    }

    @Test
    void appendIntakeMessageWithJwtReturnsFollowUpQuestion() throws Exception {
        String caseId = createCaseWithJwt();

        mockMvc.perform(post("/api/v1/cases/{caseId}/intake/messages", caseId)
                        .with(jwt())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "role":"USER",
                                  "message":"소음이 거의 매일 반복됩니다."
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.caseId").value(caseId))
                .andExpect(jsonPath("$.status").value("RECEIVED"))
                .andExpect(jsonPath("$.recommendedFollowUpQuestion").value("지금도 소음이 나나요?"));
    }

    @Test
    void routingFlowWithJwtSucceedsAfterClassification() throws Exception {
        String caseId = createClassifiedCaseWithJwt();

        mockMvc.perform(post("/api/v1/cases/{caseId}/decomposition", caseId)
                        .with(jwt()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.caseId").value(caseId))
                .andExpect(jsonPath("$.nodes[0].nodeType").exists());

        MvcResult recommendationResult = mockMvc.perform(post("/api/v1/cases/{caseId}/routing/recommendation", caseId)
                        .with(jwt()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.caseId").value(caseId))
                .andExpect(jsonPath("$.options[0].optionId").exists())
                .andReturn();

        JsonNode recommendation = objectMapper.readTree(recommendationResult.getResponse().getContentAsString());
        String optionId = recommendation.path("options").get(0).path("optionId").asText();

        mockMvc.perform(post("/api/v1/cases/{caseId}/routing/decision", caseId)
                        .with(jwt())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "optionId":"%s",
                                  "userConfirmed":true
                                }
                                """.formatted(optionId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.caseId").value(caseId))
                .andExpect(jsonPath("$.status").value("ROUTE_CONFIRMED"))
                .andExpect(jsonPath("$.routing.selectedOptionId").value(optionId));
    }

    private String createCaseWithJwt() throws Exception {
        MvcResult result = mockMvc.perform(post("/api/v1/cases")
                        .with(jwt())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "scenarioType":"INTER_FLOOR_NOISE",
                                  "housingType":"APARTMENT",
                                  "consentAccepted":true
                                }
                                """))
                .andExpect(status().isCreated())
                .andReturn();

        return objectMapper.readTree(result.getResponse().getContentAsString()).path("caseId").asText();
    }

    private String createClassifiedCaseWithJwt() throws Exception {
        String caseId = createCaseWithJwt();

        mockMvc.perform(post("/api/v1/cases/{caseId}/intake/messages", caseId)
                        .with(jwt())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "role":"USER",
                                  "message":"지금 진행 중이고 위협 징후 없음입니다. 아파트이며 관리사무소 있음. 충격 소음(쿵쿵)이 거의 매일 심야에 발생하고 호수까지 확실합니다."
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("CLASSIFIED"));

        return caseId;
    }
}
