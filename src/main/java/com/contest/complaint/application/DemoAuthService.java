package com.contest.complaint.application;

import com.contest.complaint.api.ApiException;
import com.contest.complaint.api.model.ApiModels;
import com.contest.complaint.infrastructure.persistence.entity.AppUserEntity;
import com.contest.complaint.infrastructure.persistence.repository.AppUserEntityRepository;
import org.springframework.http.HttpStatus;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.util.List;

@Service
public class DemoAuthService {

    private static final Duration TOKEN_TTL = Duration.ofHours(12);

    private final JwtEncoder jwtEncoder;
    private final AppUserEntityRepository appUserEntityRepository;
    private final PasswordEncoder passwordEncoder;

    public DemoAuthService(
            JwtEncoder jwtEncoder,
            AppUserEntityRepository appUserEntityRepository,
            PasswordEncoder passwordEncoder
    ) {
        this.jwtEncoder = jwtEncoder;
        this.appUserEntityRepository = appUserEntityRepository;
        this.passwordEncoder = passwordEncoder;
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

        AppUserEntity user = appUserEntityRepository.findByUsernameIgnoreCase(username)
                .filter(AppUserEntity::isActive)
                .orElseThrow(() -> new ApiException(
                        HttpStatus.UNAUTHORIZED,
                        "DEMO_LOGIN_FAILED",
                        "데모 계정 정보가 올바르지 않습니다.",
                        List.of()
                ));

        if (!passwordEncoder.matches(password, user.getPasswordHash())) {
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
                .subject(user.getId().toString())
                .issuedAt(now)
                .expiresAt(expiresAt)
                .claim("scope", "ROLE_USER")
                .claim("username", user.getUsername())
                .claim("displayName", user.getDisplayName())
                .build();

        JwsHeader header = JwsHeader.with(MacAlgorithm.HS256)
                .type("JWT")
                .build();

        String token = jwtEncoder.encode(JwtEncoderParameters.from(header, claims)).getTokenValue();

        ApiModels.UserProfile profile = new ApiModels.UserProfile(
                user.getDisplayName(),
                user.getPhone(),
                user.getEmail(),
                user.getHousingName(),
                user.getAddress()
        );

        return new ApiModels.DemoLoginResponse(token, "Bearer", expiresAt, profile);
    }
}
