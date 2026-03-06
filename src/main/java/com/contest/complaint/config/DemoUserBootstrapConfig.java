package com.contest.complaint.config;

import com.contest.complaint.infrastructure.persistence.entity.AppUserEntity;
import com.contest.complaint.infrastructure.persistence.repository.AppUserEntityRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.password.PasswordEncoder;

@Configuration
public class DemoUserBootstrapConfig {

    private static final Logger log = LoggerFactory.getLogger(DemoUserBootstrapConfig.class);

    @Bean
    public CommandLineRunner bootstrapDemoUser(
            AppUserEntityRepository userRepository,
            PasswordEncoder passwordEncoder
    ) {
        return args -> {
            String demoUsername = "demo";
            var existing = userRepository.findByUsernameIgnoreCase(demoUsername);
            if (existing.isPresent()) {
                AppUserEntity user = existing.get();
                boolean updated = false;
                if (user.getDisplayName() == null || user.getDisplayName().isBlank()) {
                    user.setDisplayName("데모 사용자");
                    updated = true;
                }
                if (user.getPhone() == null || user.getPhone().isBlank()) {
                    user.setPhone("010-1234-5678");
                    updated = true;
                }
                if (user.getEmail() == null || user.getEmail().isBlank()) {
                    user.setEmail("demo@gov24.local");
                    updated = true;
                }
                if (user.getHousingName() == null || user.getHousingName().isBlank()) {
                    user.setHousingName("행복빌라");
                    updated = true;
                }
                if (user.getAddress() == null || user.getAddress().isBlank()) {
                    user.setAddress("서울특별시 마포구 월드컵북로 123");
                    updated = true;
                }
                if (updated) {
                    userRepository.save(user);
                    log.info("Updated demo user profile fields: {}", demoUsername);
                }
                return;
            }

            AppUserEntity demoUser = new AppUserEntity();
            demoUser.setUsername(demoUsername);
            demoUser.setPasswordHash(passwordEncoder.encode("1234"));
            demoUser.setDisplayName("데모 사용자");
            demoUser.setPhone("010-1234-5678");
            demoUser.setEmail("demo@gov24.local");
            demoUser.setHousingName("행복빌라");
            demoUser.setAddress("서울특별시 마포구 월드컵북로 123");
            demoUser.setActive(true);
            userRepository.save(demoUser);
            log.info("Bootstrapped demo user account: {}", demoUsername);
        };
    }
}
