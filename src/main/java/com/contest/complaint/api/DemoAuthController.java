package com.contest.complaint.api;

import com.contest.complaint.api.model.ApiModels;
import com.contest.complaint.application.DemoAuthService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/auth")
public class DemoAuthController {

    private final DemoAuthService demoAuthService;

    public DemoAuthController(DemoAuthService demoAuthService) {
        this.demoAuthService = demoAuthService;
    }

    @PostMapping("/demo-login")
    public ResponseEntity<ApiModels.DemoLoginResponse> demoLogin(
            @RequestHeader(value = "X-Trace-Id", required = false) String traceId,
            @Valid @RequestBody ApiModels.DemoLoginRequest request
    ) {
        return ResponseEntity.ok(demoAuthService.login(request));
    }
}
