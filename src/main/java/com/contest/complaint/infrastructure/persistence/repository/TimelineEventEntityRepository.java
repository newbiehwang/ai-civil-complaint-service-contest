package com.contest.complaint.infrastructure.persistence.repository;

import com.contest.complaint.infrastructure.persistence.entity.TimelineEventEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface TimelineEventEntityRepository extends JpaRepository<TimelineEventEntity, UUID> {

    List<TimelineEventEntity> findAllByCaseIdOrderByOccurredAtAsc(UUID caseId);
}
