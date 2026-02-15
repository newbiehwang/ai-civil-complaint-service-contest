package com.contest.complaint.infrastructure.persistence.repository;

import com.contest.complaint.infrastructure.persistence.entity.CaseEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface CaseEntityRepository extends JpaRepository<CaseEntity, UUID> {
}
