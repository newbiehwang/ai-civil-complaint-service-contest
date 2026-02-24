package com.contest.complaint.infrastructure.persistence.repository;

import com.contest.complaint.infrastructure.persistence.entity.CaseEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface CaseEntityRepository extends JpaRepository<CaseEntity, UUID> {
    List<CaseEntity> findAllByOwnerSubjectOrderByUpdatedAtDesc(String ownerSubject);
    Optional<CaseEntity> findByIdAndOwnerSubject(UUID id, String ownerSubject);
}
