package com.contest.complaint.application;

import com.contest.complaint.api.model.ApiModels;
import com.contest.complaint.infrastructure.persistence.entity.CaseEntity;
import com.contest.complaint.infrastructure.persistence.entity.TimelineEventEntity;
import com.contest.complaint.infrastructure.persistence.repository.CaseEntityRepository;
import com.contest.complaint.infrastructure.persistence.repository.TimelineEventEntityRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.UUID;

@Component
public class MockInstitutionSubmissionWorker {

    private static final Logger log = LoggerFactory.getLogger(MockInstitutionSubmissionWorker.class);

    private final CaseEntityRepository caseRepository;
    private final TimelineEventEntityRepository timelineRepository;
    private final long processingDelayMs;

    public MockInstitutionSubmissionWorker(
            CaseEntityRepository caseRepository,
            TimelineEventEntityRepository timelineRepository,
            @Value("${complaint.mock-submission.processing-delay-ms:1500}") long processingDelayMs
    ) {
        this.caseRepository = caseRepository;
        this.timelineRepository = timelineRepository;
        this.processingDelayMs = processingDelayMs;
    }

    @Async
    public void processSubmission(UUID caseId, String submissionId) {
        if (submissionId == null || submissionId.isBlank()) {
            return;
        }

        try {
            Thread.sleep(processingDelayMs);
            completeSubmission(caseId, submissionId);
        } catch (InterruptedException ex) {
            Thread.currentThread().interrupt();
            log.warn("Mock submission worker interrupted: caseId={}", caseId);
        } catch (Exception ex) {
            log.error("Mock submission worker failed: caseId={}", caseId, ex);
        }
    }

    @Transactional
    protected void completeSubmission(UUID caseId, String submissionId) {
        CaseEntity caseEntity = caseRepository.findById(caseId).orElse(null);
        if (caseEntity == null) {
            return;
        }

        if (!submissionId.equals(caseEntity.getSubmissionId())) {
            return;
        }

        if (caseEntity.getStatus() != ApiModels.CaseStatus.INSTITUTION_PROCESSING) {
            return;
        }

        caseEntity.setSubmissionStatus(ApiModels.SubmissionStatus.SUBMITTED);
        caseEntity.setStatus(ApiModels.CaseStatus.COMPLETED);
        caseEntity.setCurrentActionRequired("CLOSE_CASE");
        caseRepository.save(caseEntity);

        timelineRepository.save(createTimelineEvent(
                caseId,
                ApiModels.TimelineEventType.SUBMISSION_COMPLETED,
                "기관 제출이 완료되었습니다.",
                "submissionId=" + submissionId,
                ApiModels.TimelineActor.INSTITUTION
        ));

        timelineRepository.save(createTimelineEvent(
                caseId,
                ApiModels.TimelineEventType.CASE_COMPLETED,
                "민원 처리가 완료되었습니다.",
                "기관 제출이 정상 완료되어 케이스가 완료 상태로 전환되었습니다.",
                ApiModels.TimelineActor.SYSTEM
        ));
    }

    private TimelineEventEntity createTimelineEvent(
            UUID caseId,
            ApiModels.TimelineEventType eventType,
            String title,
            String description,
            ApiModels.TimelineActor actor
    ) {
        TimelineEventEntity eventEntity = new TimelineEventEntity();
        eventEntity.setId(UUID.randomUUID());
        eventEntity.setCaseId(caseId);
        eventEntity.setEventType(eventType);
        eventEntity.setOccurredAt(Instant.now());
        eventEntity.setTitle(title);
        eventEntity.setDescription(description);
        eventEntity.setActor(actor);
        return eventEntity;
    }
}
