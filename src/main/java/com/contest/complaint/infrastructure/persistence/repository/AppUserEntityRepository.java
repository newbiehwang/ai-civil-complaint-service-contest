package com.contest.complaint.infrastructure.persistence.repository;

import com.contest.complaint.infrastructure.persistence.entity.AppUserEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface AppUserEntityRepository extends JpaRepository<AppUserEntity, UUID> {
    Optional<AppUserEntity> findByUsernameIgnoreCase(String username);
}
