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
            if (userRepository.findByUsernameIgnoreCase(demoUsername).isPresent()) {
                return;
            }

            AppUserEntity demoUser = new AppUserEntity();
            demoUser.setUsername(demoUsername);
            demoUser.setPasswordHash(passwordEncoder.encode("1234"));
            demoUser.setDisplayName("데모 사용자");
            demoUser.setActive(true);
            userRepository.save(demoUser);
            log.info("Bootstrapped demo user account: {}", demoUsername);
        };
    }
}
