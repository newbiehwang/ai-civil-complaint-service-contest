package com.contest.complaint.infrastructure.persistence.repository;

import com.contest.complaint.infrastructure.persistence.entity.EvidenceEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface EvidenceEntityRepository extends JpaRepository<EvidenceEntity, UUID> {

    List<EvidenceEntity> findAllByCaseIdOrderByUploadedAtAsc(UUID caseId);
}
