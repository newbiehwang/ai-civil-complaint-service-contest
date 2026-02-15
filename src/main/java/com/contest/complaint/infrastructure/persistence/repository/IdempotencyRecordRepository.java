package com.contest.complaint.infrastructure.persistence.repository;

import com.contest.complaint.infrastructure.persistence.entity.IdempotencyRecordEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface IdempotencyRecordRepository extends JpaRepository<IdempotencyRecordEntity, UUID> {

    Optional<IdempotencyRecordEntity> findByOperationAndIdempotencyKey(String operation, String idempotencyKey);
}
