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
import java.util.Optional;
import java.util.regex.Pattern;

@Service
public class DemoAuthService {

    private static final Duration TOKEN_TTL = Duration.ofHours(12);
    private static final Pattern DEMO_ALIAS_PATTERN =
            Pattern.compile("^(?<base>[a-zA-Z0-9._-]+)_(?<suffix>\\d{8})$");

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

        String baseUsername = resolveBaseUsername(username);
        AppUserEntity baseUser = appUserEntityRepository.findByUsernameIgnoreCase(baseUsername)
                .filter(AppUserEntity::isActive)
                .orElseThrow(() -> new ApiException(
                        HttpStatus.UNAUTHORIZED,
                        "DEMO_LOGIN_FAILED",
                        "데모 계정 정보가 올바르지 않습니다.",
                        List.of()
                ));

        if (!passwordEncoder.matches(password, baseUser.getPasswordHash())) {
            throw new ApiException(
                    HttpStatus.UNAUTHORIZED,
                    "DEMO_LOGIN_FAILED",
                    "데모 계정 정보가 올바르지 않습니다.",
                    List.of()
            );
        }

        AppUserEntity user = username.equalsIgnoreCase(baseUsername)
                ? baseUser
                : getOrCreateAliasUser(username, baseUser);

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

    private String resolveBaseUsername(String username) {
        var matcher = DEMO_ALIAS_PATTERN.matcher(username);
        if (matcher.matches()) {
            return matcher.group("base");
        }
        return username;
    }

    private AppUserEntity getOrCreateAliasUser(String aliasUsername, AppUserEntity baseUser) {
        Optional<AppUserEntity> existingAlias = appUserEntityRepository.findByUsernameIgnoreCase(aliasUsername);
        if (existingAlias.isPresent()) {
            AppUserEntity user = existingAlias.get();
            if (!user.isActive()) {
                throw new ApiException(
                        HttpStatus.UNAUTHORIZED,
                        "DEMO_LOGIN_FAILED",
                        "데모 계정 정보가 올바르지 않습니다.",
                        List.of()
                );
            }
            return user;
        }

        AppUserEntity alias = new AppUserEntity();
        alias.setUsername(aliasUsername);
        alias.setPasswordHash(baseUser.getPasswordHash());
        alias.setDisplayName(baseUser.getDisplayName());
        alias.setPhone(baseUser.getPhone());
        alias.setEmail(baseUser.getEmail());
        alias.setHousingName(baseUser.getHousingName());
        alias.setAddress(baseUser.getAddress());
        alias.setActive(true);
        return appUserEntityRepository.save(alias);
    }
}
