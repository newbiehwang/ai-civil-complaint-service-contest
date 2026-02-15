package com.contest.complaint;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class SecurityIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

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
}
