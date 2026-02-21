package com.contest.complaint.application;

import com.contest.complaint.api.ApiException;
import com.contest.complaint.api.model.ApiModels;
import org.springframework.http.HttpStatus;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.util.List;

@Service
public class DemoAuthService {

    private static final Duration TOKEN_TTL = Duration.ofHours(12);

    private final JwtEncoder jwtEncoder;

    public DemoAuthService(JwtEncoder jwtEncoder) {
        this.jwtEncoder = jwtEncoder;
    }

    public ApiModels.DemoLoginResponse login(ApiModels.DemoLoginRequest request) {
        String username = request.username() == null ? "" : request.username().trim();
        String password = request.password() == null ? "" : request.password().trim();

        if (username.isBlank() || password.isBlank()) {
            throw ApiException.badRequest(
                    "DEMO_LOGIN_INVALID",
                    "아이디와 비밀번호를 입력해 주세요.",
                    List.of("username/password required")
            );
        }

        // 데모 정책: demo / 1234 고정
        if (!"demo".equals(username) || !"1234".equals(password)) {
            throw new ApiException(
                    HttpStatus.UNAUTHORIZED,
                    "DEMO_LOGIN_FAILED",
                    "데모 계정 정보가 올바르지 않습니다.",
                    List.of()
            );
        }

        Instant now = Instant.now();
        Instant expiresAt = now.plus(TOKEN_TTL);

        JwtClaimsSet claims = JwtClaimsSet.builder()
                .subject("demo-user")
                .issuedAt(now)
                .expiresAt(expiresAt)
                .claim("scope", "ROLE_USER")
                .claim("username", username)
                .build();

        JwsHeader header = JwsHeader.with(MacAlgorithm.HS256)
                .type("JWT")
                .build();

        String token = jwtEncoder.encode(JwtEncoderParameters.from(header, claims)).getTokenValue();

        return new ApiModels.DemoLoginResponse(token, "Bearer", expiresAt);
    }
}
