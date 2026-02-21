package com.contest.complaint.application;

import com.contest.complaint.api.ApiException;
import com.contest.complaint.api.model.ApiModels;
import com.contest.complaint.application.intake.IntakeFollowUpAdvisor;
import com.contest.complaint.application.intake.IntakeFollowUpRequest;
import com.contest.complaint.application.intake.IntakeFollowUpSuggestion;
import com.contest.complaint.infrastructure.persistence.entity.CaseEntity;
import com.contest.complaint.infrastructure.persistence.entity.EvidenceEntity;
import com.contest.complaint.infrastructure.persistence.entity.TimelineEventEntity;
import com.contest.complaint.infrastructure.persistence.repository.CaseEntityRepository;
import com.contest.complaint.infrastructure.persistence.repository.EvidenceEntityRepository;
import com.contest.complaint.infrastructure.persistence.repository.TimelineEventEntityRepository;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.EnumMap;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

@Service
public class CaseWorkflowService {

    private static final String SAFETY_DANGER = "위협 징후 있음";
    private static final List<String> REQUIRED_SLOTS = List.of(
            "noiseNow",
            "safety",
            "residence",
            "management",
            "noiseType",
            "frequency",
            "timeBand",
            "sourceCertainty"
    );

    private static final Map<ApiModels.CaseStatus, Set<ApiModels.CaseStatus>> ALLOWED_TRANSITIONS =
            new EnumMap<>(ApiModels.CaseStatus.class);

    static {
        ALLOWED_TRANSITIONS.put(ApiModels.CaseStatus.RECEIVED, Set.of(ApiModels.CaseStatus.CLASSIFIED));
        ALLOWED_TRANSITIONS.put(ApiModels.CaseStatus.CLASSIFIED, Set.of(ApiModels.CaseStatus.ROUTE_CONFIRMED));
        ALLOWED_TRANSITIONS.put(ApiModels.CaseStatus.ROUTE_CONFIRMED, Set.of(ApiModels.CaseStatus.EVIDENCE_COLLECTING));
        ALLOWED_TRANSITIONS.put(ApiModels.CaseStatus.EVIDENCE_COLLECTING, Set.of(ApiModels.CaseStatus.FORMAL_SUBMISSION_READY));
        ALLOWED_TRANSITIONS.put(ApiModels.CaseStatus.FORMAL_SUBMISSION_READY, Set.of(ApiModels.CaseStatus.INSTITUTION_PROCESSING));
        ALLOWED_TRANSITIONS.put(ApiModels.CaseStatus.INSTITUTION_PROCESSING, Set.of(
                ApiModels.CaseStatus.SUPPLEMENT_REQUIRED,
                ApiModels.CaseStatus.COMPLETED
        ));
        ALLOWED_TRANSITIONS.put(ApiModels.CaseStatus.SUPPLEMENT_REQUIRED, Set.of(ApiModels.CaseStatus.INSTITUTION_PROCESSING));
        ALLOWED_TRANSITIONS.put(ApiModels.CaseStatus.COMPLETED, Set.of(ApiModels.CaseStatus.CLOSED));
    }

    private static final TypeReference<Map<String, Object>> MAP_TYPE = new TypeReference<>() {
    };

    private static final TypeReference<List<ApiModels.DecompositionNode>> DECOMPOSITION_LIST_TYPE = new TypeReference<>() {
    };

    private static final TypeReference<List<ApiModels.RoutingOption>> ROUTING_LIST_TYPE = new TypeReference<>() {
    };

    private final CaseEntityRepository caseRepository;
    private final EvidenceEntityRepository evidenceRepository;
    private final TimelineEventEntityRepository timelineRepository;
    private final MockInstitutionSubmissionWorker mockInstitutionSubmissionWorker;
    private final IntakeFollowUpAdvisor intakeFollowUpAdvisor;
    private final ObjectMapper objectMapper;
    private final boolean mockSubmissionAutoProcessEnabled;
    private final boolean institutionGatewayFailDirectApi;

    public CaseWorkflowService(
            CaseEntityRepository caseRepository,
            EvidenceEntityRepository evidenceRepository,
            TimelineEventEntityRepository timelineRepository,
            MockInstitutionSubmissionWorker mockInstitutionSubmissionWorker,
            IntakeFollowUpAdvisor intakeFollowUpAdvisor,
            ObjectMapper objectMapper,
            @Value("${complaint.mock-submission.auto-process-enabled:true}") boolean mockSubmissionAutoProcessEnabled,
            @Value("${complaint.institution-gateway.fail-direct-api:false}") boolean institutionGatewayFailDirectApi
    ) {
        this.caseRepository = caseRepository;
        this.evidenceRepository = evidenceRepository;
        this.timelineRepository = timelineRepository;
        this.mockInstitutionSubmissionWorker = mockInstitutionSubmissionWorker;
        this.intakeFollowUpAdvisor = intakeFollowUpAdvisor;
        this.objectMapper = objectMapper;
        this.mockSubmissionAutoProcessEnabled = mockSubmissionAutoProcessEnabled;
        this.institutionGatewayFailDirectApi = institutionGatewayFailDirectApi;
    }

    @Transactional
    public ApiModels.CaseDetail createCase(ApiModels.CreateCaseRequest request) {
        if (!Boolean.TRUE.equals(request.consentAccepted())) {
            throw ApiException.badRequest("VALIDATION_ERROR", "consentAccepted must be true.", List.of("consentAccepted=true required"));
        }

        CaseEntity entity = new CaseEntity();
        entity.setId(UUID.randomUUID());
        entity.setScenarioType(request.scenarioType());
        entity.setHousingType(request.housingType());
        entity.setInitialSummary(request.initialSummary());
        entity.setStatus(ApiModels.CaseStatus.RECEIVED);
        entity.setRiskLevel(ApiModels.RiskLevel.LOW);
        entity.setRiskSignalDetected(false);
        entity.setFilledSlotsJson("{}");
        entity.setDecompositionNodesJson("[]");
        entity.setRoutingOptionsJson("[]");
        entity.setCurrentActionRequired("INTAKE_REQUIRED");

        caseRepository.save(entity);

        CaseAggregate aggregate = new CaseAggregate(
                entity,
                new HashMap<>(),
                new ArrayList<>(),
                new ArrayList<>(),
                new ArrayList<>(),
                new ArrayList<>()
        );

        appendTimeline(
                aggregate,
                ApiModels.TimelineEventType.CASE_CREATED,
                "민원이 생성되었습니다.",
                "사용자가 시나리오 A 민원을 시작했습니다.",
                ApiModels.TimelineActor.USER
        );

        return toCaseDetail(aggregate);
    }

    @Transactional(readOnly = true)
    public ApiModels.CaseDetail getCase(UUID caseId) {
        return toCaseDetail(loadAggregate(caseId));
    }

    @Transactional
    public ApiModels.IntakeUpdateResponse appendIntakeMessage(UUID caseId, ApiModels.AppendIntakeMessageRequest request) {
        CaseAggregate aggregate = loadAggregate(caseId);

        String message = request.message().trim();
        if (request.role() == ApiModels.MessageRole.USER) {
            extractSlots(aggregate.filledSlots, message);
            evaluateRiskSignal(aggregate, message);
        }

        if (aggregate.caseEntity.getStatus() == ApiModels.CaseStatus.RECEIVED
                && isIntakeComplete(aggregate.filledSlots)) {
            transition(aggregate.caseEntity, ApiModels.CaseStatus.CLASSIFIED);
            appendTimeline(
                    aggregate,
                    ApiModels.TimelineEventType.CLASSIFICATION_DONE,
                    "민원 분류가 완료되었습니다.",
                    "필수 슬롯이 모두 채워져 분류가 완료되었습니다.",
                    ApiModels.TimelineActor.SYSTEM
            );
            aggregate.caseEntity.setCurrentActionRequired("REQUEST_DECOMPOSITION");
        }

        persistCase(aggregate);

        List<String> missing = missingSlots(aggregate.filledSlots);
        IntakeFollowUpSuggestion followUpSuggestion = intakeFollowUpAdvisor.suggest(
                new IntakeFollowUpRequest(
                        message,
                        List.copyOf(missing),
                        Map.copyOf(aggregate.filledSlots),
                        aggregate.caseEntity.getStatus(),
                        aggregate.caseEntity.isRiskSignalDetected()
                )
        );

        return new ApiModels.IntakeUpdateResponse(
                aggregate.caseEntity.getId(),
                aggregate.caseEntity.getStatus(),
                new ApiModels.IntakeSnapshot(REQUIRED_SLOTS, Map.copyOf(aggregate.filledSlots), aggregate.caseEntity.isRiskSignalDetected()),
                followUpSuggestion.question(),
                followUpSuggestion.followUpInterface()
        );
    }

    @Transactional
    public ApiModels.DecompositionResult decomposeCase(UUID caseId) {
        CaseAggregate aggregate = loadAggregate(caseId);

        if (aggregate.caseEntity.getStatus() == ApiModels.CaseStatus.RECEIVED) {
            throw ApiException.conflict(
                    "CASE_STATE_CONFLICT",
                    "Cannot decompose before classification.",
                    List.of("currentState=" + aggregate.caseEntity.getStatus(), "requiredState=CLASSIFIED")
            );
        }

        List<ApiModels.DecompositionNode> nodes = new ArrayList<>();
        nodes.add(new ApiModels.DecompositionNode(
                ApiModels.DecompositionNodeType.LIVING_NOISE,
                "생활소음 민원",
                2,
                "층간소음 핵심 이슈를 우선 처리합니다."
        ));

        if (aggregate.caseEntity.isRiskSignalDetected()) {
            nodes.add(new ApiModels.DecompositionNode(
                    ApiModels.DecompositionNodeType.IMMEDIATE_RISK,
                    "즉시위험 민원",
                    1,
                    "폭행/위협 신호가 감지되어 즉시 대응이 필요합니다."
            ));
        }

        if (Boolean.TRUE.equals(aggregate.filledSlots.get("priorMediation"))) {
            nodes.add(new ApiModels.DecompositionNode(
                    ApiModels.DecompositionNodeType.LONG_TERM_DISPUTE,
                    "장기 미해결 분쟁",
                    3,
                    "기존 조정 시도가 있어 장기 분쟁 경로 검토가 필요합니다."
            ));
        }

        nodes.sort(Comparator.comparingInt(ApiModels.DecompositionNode::priority));
        aggregate.decompositionNodes = nodes;
        aggregate.caseEntity.setCurrentActionRequired("REQUEST_ROUTING_RECOMMENDATION");

        persistCase(aggregate);

        return new ApiModels.DecompositionResult(aggregate.caseEntity.getId(), List.copyOf(nodes));
    }

    @Transactional
    public ApiModels.RoutingRecommendation recommendRoute(UUID caseId) {
        CaseAggregate aggregate = loadAggregate(caseId);

        if (aggregate.decompositionNodes.isEmpty()) {
            throw ApiException.conflict(
                    "CASE_STATE_CONFLICT",
                    "Cannot recommend route before decomposition.",
                    List.of("decompositionRequired=true")
            );
        }

        List<ApiModels.RoutingOption> options = new ArrayList<>();

        if (aggregate.caseEntity.isRiskSignalDetected()) {
            options.add(new ApiModels.RoutingOption(
                    "opt-emergency-112",
                    ApiModels.RoutingChannelType.EMERGENCY_112,
                    "112 긴급 신고",
                    1,
                    "즉시위험 신호가 감지되어 긴급 대응이 필요합니다.",
                    List.of("위험 상황 설명")
            ));
        }

        if ("APARTMENT".equalsIgnoreCase(aggregate.caseEntity.getHousingType())) {
            options.add(new ApiModels.RoutingOption(
                    "opt-management-office",
                    ApiModels.RoutingChannelType.MANAGEMENT_OFFICE,
                    "관리사무소 조정 요청",
                    2,
                    "아파트 거주 형태에서 1차 조정 채널입니다.",
                    List.of("소음 일지", "녹음 파일")
            ));
            options.add(new ApiModels.RoutingOption(
                    "opt-neighbor-center",
                    ApiModels.RoutingChannelType.NEIGHBOR_CENTER,
                    "이웃사이센터 연계",
                    3,
                    "생활소음 전문 중재 채널을 활용합니다.",
                    List.of("소음 일지", "발생 빈도 기록")
            ));
        }

        options.add(new ApiModels.RoutingOption(
                "opt-epeople",
                ApiModels.RoutingChannelType.E_PEOPLE,
                "국민신문고 접수",
                4,
                "공식 민원 채널로 전환 가능한 경로입니다.",
                List.of("사건 요약", "증빙 자료")
        ));

        if (Boolean.TRUE.equals(aggregate.filledSlots.get("priorMediation"))) {
            options.add(new ApiModels.RoutingOption(
                    "opt-dispute-mediation",
                    ApiModels.RoutingChannelType.DISPUTE_MEDIATION,
                    "분쟁조정 경로",
                    5,
                    "기존 조정 불발 이력이 있어 분쟁조정 절차를 제안합니다.",
                    List.of("조정 이력", "추가 증빙")
            ));
        }

        options.sort(Comparator.comparingInt(ApiModels.RoutingOption::priority));
        aggregate.routingOptions = options;
        aggregate.caseEntity.setCurrentActionRequired("CONFIRM_ROUTE");

        appendTimeline(
                aggregate,
                ApiModels.TimelineEventType.ROUTE_RECOMMENDED,
                "경로 추천이 생성되었습니다.",
                "추천 경로를 확인하고 선택해 주세요.",
                ApiModels.TimelineActor.SYSTEM
        );

        persistCase(aggregate);

        return new ApiModels.RoutingRecommendation(
                aggregate.caseEntity.getId(),
                List.copyOf(options),
                aggregate.caseEntity.getSelectedOptionId()
        );
    }

    @Transactional
    public ApiModels.CaseDetail confirmRouteDecision(UUID caseId, ApiModels.RouteDecisionRequest request) {
        CaseAggregate aggregate = loadAggregate(caseId);

        if (!Boolean.TRUE.equals(request.userConfirmed())) {
            throw ApiException.conflict(
                    "CASE_STATE_CONFLICT",
                    "Route decision requires explicit user confirmation.",
                    List.of("userConfirmed=true required")
            );
        }

        boolean exists = aggregate.routingOptions.stream().anyMatch(opt -> opt.optionId().equals(request.optionId()));
        if (!exists) {
            throw ApiException.notFound("ROUTE_OPTION_NOT_FOUND", "Selected route option not found.");
        }

        if (aggregate.caseEntity.getStatus() == ApiModels.CaseStatus.RECEIVED) {
            throw ApiException.conflict(
                    "CASE_STATE_CONFLICT",
                    "Cannot confirm route before classification.",
                    List.of("currentState=" + aggregate.caseEntity.getStatus(), "requiredState=CLASSIFIED")
            );
        }

        if (aggregate.caseEntity.getStatus() == ApiModels.CaseStatus.CLASSIFIED) {
            transition(aggregate.caseEntity, ApiModels.CaseStatus.ROUTE_CONFIRMED);
        }

        aggregate.caseEntity.setSelectedOptionId(request.optionId());
        aggregate.caseEntity.setCurrentActionRequired("UPLOAD_EVIDENCE");

        appendTimeline(
                aggregate,
                ApiModels.TimelineEventType.ROUTE_CONFIRMED,
                "사용자가 경로를 확정했습니다.",
                "선택된 경로: " + request.optionId(),
                ApiModels.TimelineActor.USER
        );

        persistCase(aggregate);

        return toCaseDetail(aggregate);
    }

    @Transactional
    public ApiModels.EvidenceItem registerEvidence(UUID caseId, ApiModels.RegisterEvidenceRequest request) {
        CaseAggregate aggregate = loadAggregate(caseId);

        if (aggregate.caseEntity.getStatus() == ApiModels.CaseStatus.RECEIVED
                || aggregate.caseEntity.getStatus() == ApiModels.CaseStatus.CLASSIFIED) {
            throw ApiException.conflict(
                    "CASE_STATE_CONFLICT",
                    "Cannot add evidence before route confirmation.",
                    List.of("currentState=" + aggregate.caseEntity.getStatus(), "requiredState=ROUTE_CONFIRMED")
            );
        }

        if (aggregate.caseEntity.getStatus() == ApiModels.CaseStatus.ROUTE_CONFIRMED) {
            transition(aggregate.caseEntity, ApiModels.CaseStatus.EVIDENCE_COLLECTING);
        }

        EvidenceEntity evidenceEntity = new EvidenceEntity();
        evidenceEntity.setId(UUID.randomUUID());
        evidenceEntity.setCaseId(caseId);
        evidenceEntity.setEvidenceType(request.evidenceType());
        evidenceEntity.setStorageKey(request.storageKey());
        evidenceEntity.setOriginalFileName(request.originalFileName());
        evidenceEntity.setMimeType(request.mimeType());
        evidenceEntity.setSizeBytes(request.sizeBytes());
        evidenceEntity.setCapturedAt(request.capturedAt());
        evidenceEntity.setNotes(request.notes());
        evidenceEntity.setAdequacyScore(adequacyScore(request.evidenceType()));
        evidenceEntity.setUploadedAt(Instant.now());

        EvidenceEntity saved = evidenceRepository.save(evidenceEntity);
        ApiModels.EvidenceItem item = toEvidenceItem(saved);
        aggregate.evidenceItems.add(item);

        ApiModels.EvidenceChecklist checklist = computeChecklist(aggregate.evidenceItems);
        if (checklist.isSufficient() && aggregate.caseEntity.getStatus() == ApiModels.CaseStatus.EVIDENCE_COLLECTING) {
            transition(aggregate.caseEntity, ApiModels.CaseStatus.FORMAL_SUBMISSION_READY);
            aggregate.caseEntity.setCurrentActionRequired("SUBMIT_CASE");
        } else {
            aggregate.caseEntity.setCurrentActionRequired("OPTIONAL_EVIDENCE_OR_SUBMIT");
        }

        appendTimeline(
                aggregate,
                ApiModels.TimelineEventType.EVIDENCE_ADDED,
                "증거가 등록되었습니다.",
                "evidenceId=" + item.evidenceId(),
                ApiModels.TimelineActor.USER
        );

        persistCase(aggregate);

        return item;
    }

    @Transactional(readOnly = true)
    public ApiModels.EvidenceChecklist getEvidenceChecklist(UUID caseId) {
        CaseAggregate aggregate = loadAggregate(caseId);
        return computeChecklist(aggregate.evidenceItems);
    }

    @Transactional
    public ApiModels.SubmissionResponse submitCase(UUID caseId, ApiModels.SubmitCaseRequest request) {
        CaseAggregate aggregate = loadAggregate(caseId);

        ApiModels.CaseStatus currentState = aggregate.caseEntity.getStatus();
        if (currentState == ApiModels.CaseStatus.ROUTE_CONFIRMED) {
            transition(aggregate.caseEntity, ApiModels.CaseStatus.EVIDENCE_COLLECTING);
            aggregate.caseEntity.setCurrentActionRequired("OPTIONAL_EVIDENCE_OR_SUBMIT");
            currentState = aggregate.caseEntity.getStatus();
        }

        if (currentState == ApiModels.CaseStatus.EVIDENCE_COLLECTING) {
            transition(aggregate.caseEntity, ApiModels.CaseStatus.FORMAL_SUBMISSION_READY);
            aggregate.caseEntity.setCurrentActionRequired("SUBMIT_CASE");
            currentState = aggregate.caseEntity.getStatus();
        }

        if (currentState != ApiModels.CaseStatus.FORMAL_SUBMISSION_READY) {
            throw ApiException.conflict(
                    "CASE_STATE_CONFLICT",
                    "Cannot submit before route confirmation.",
                    List.of("currentState=" + currentState, "requiredState=ROUTE_CONFIRMED")
            );
        }

        if (!Boolean.TRUE.equals(request.userConsent()) || !Boolean.TRUE.equals(request.identityVerified())) {
            throw ApiException.badRequest(
                    "VALIDATION_ERROR",
                    "Submission requires userConsent=true and identityVerified=true.",
                    List.of("userConsent=true required", "identityVerified=true required")
            );
        }

        if (shouldFailInstitutionGateway(request.submissionChannel())) {
            throw ApiException.serviceUnavailable(
                    "INSTITUTION_GATEWAY_ERROR",
                    "Institution gateway is temporarily unavailable.",
                    List.of("submissionChannel=" + request.submissionChannel(), "retryable=true")
            );
        }

        transition(aggregate.caseEntity, ApiModels.CaseStatus.INSTITUTION_PROCESSING);
        aggregate.caseEntity.setSubmissionId("SUB-" + UUID.randomUUID().toString().substring(0, 8));
        aggregate.caseEntity.setSubmissionStatus(ApiModels.SubmissionStatus.QUEUED);
        aggregate.caseEntity.setCurrentActionRequired("WAIT_INSTITUTION_RESULT");

        appendTimeline(
                aggregate,
                ApiModels.TimelineEventType.SUBMISSION_STARTED,
                "기관 제출이 시작되었습니다.",
                "submissionChannel=" + request.submissionChannel(),
                ApiModels.TimelineActor.SYSTEM
        );

        persistCase(aggregate);
        triggerMockSubmissionProcessing(aggregate.caseEntity.getId(), aggregate.caseEntity.getSubmissionId());

        return new ApiModels.SubmissionResponse(
                aggregate.caseEntity.getId(),
                aggregate.caseEntity.getSubmissionId(),
                aggregate.caseEntity.getSubmissionStatus(),
                Instant.now()
        );
    }

    @Transactional
    public ApiModels.CaseDetail applyInstitutionMockEvent(UUID caseId, ApiModels.InstitutionMockEventRequest request) {
        CaseAggregate aggregate = loadAggregate(caseId);

        if (aggregate.caseEntity.getStatus() != ApiModels.CaseStatus.INSTITUTION_PROCESSING) {
            throw ApiException.conflict(
                    "CASE_STATE_CONFLICT",
                    "Institution mock event can be applied only while institution is processing.",
                    List.of("currentState=" + aggregate.caseEntity.getStatus(), "requiredState=INSTITUTION_PROCESSING")
            );
        }

        switch (request.eventType()) {
            case SUPPLEMENT_REQUIRED -> {
                transition(aggregate.caseEntity, ApiModels.CaseStatus.SUPPLEMENT_REQUIRED);
                aggregate.caseEntity.setSubmissionStatus(ApiModels.SubmissionStatus.SUBMITTED);
                aggregate.caseEntity.setCurrentActionRequired("RESPOND_SUPPLEMENT");

                appendTimeline(
                        aggregate,
                        ApiModels.TimelineEventType.SUPPLEMENT_REQUESTED,
                        "기관에서 보완자료를 요청했습니다.",
                        defaultMessage(request.message(), "추가 보완자료 제출이 필요합니다."),
                        ApiModels.TimelineActor.INSTITUTION
                );
            }
            case COMPLETED -> {
                transition(aggregate.caseEntity, ApiModels.CaseStatus.COMPLETED);
                aggregate.caseEntity.setSubmissionStatus(ApiModels.SubmissionStatus.SUBMITTED);
                aggregate.caseEntity.setCurrentActionRequired("CLOSE_CASE");

                String submissionDescription = aggregate.caseEntity.getSubmissionId() == null
                        ? "submissionId=N/A"
                        : "submissionId=" + aggregate.caseEntity.getSubmissionId();

                appendTimeline(
                        aggregate,
                        ApiModels.TimelineEventType.SUBMISSION_COMPLETED,
                        "기관 제출이 완료되었습니다.",
                        submissionDescription,
                        ApiModels.TimelineActor.INSTITUTION
                );

                appendTimeline(
                        aggregate,
                        ApiModels.TimelineEventType.CASE_COMPLETED,
                        "민원 처리가 완료되었습니다.",
                        defaultMessage(request.message(), "기관 처리 완료로 케이스가 종료 단계로 전환되었습니다."),
                        ApiModels.TimelineActor.SYSTEM
                );
            }
        }

        persistCase(aggregate);
        return toCaseDetail(aggregate);
    }

    @Transactional
    public ApiModels.CaseDetail respondSupplement(UUID caseId, ApiModels.SupplementResponseRequest request) {
        CaseAggregate aggregate = loadAggregate(caseId);

        if (aggregate.caseEntity.getStatus() != ApiModels.CaseStatus.SUPPLEMENT_REQUIRED) {
            throw ApiException.conflict(
                    "CASE_STATE_CONFLICT",
                    "No supplement request exists for this case.",
                    List.of("currentState=" + aggregate.caseEntity.getStatus(), "requiredState=SUPPLEMENT_REQUIRED")
            );
        }

        transition(aggregate.caseEntity, ApiModels.CaseStatus.INSTITUTION_PROCESSING);
        aggregate.caseEntity.setCurrentActionRequired("WAIT_INSTITUTION_RESULT");

        appendTimeline(
                aggregate,
                ApiModels.TimelineEventType.SUPPLEMENT_RESPONDED,
                "보완 요청에 응답했습니다.",
                request.message(),
                ApiModels.TimelineActor.USER
        );

        persistCase(aggregate);
        triggerMockSubmissionProcessing(aggregate.caseEntity.getId(), aggregate.caseEntity.getSubmissionId());

        return toCaseDetail(aggregate);
    }

    @Transactional(readOnly = true)
    public ApiModels.TimelineResponse getTimeline(UUID caseId) {
        CaseAggregate aggregate = loadAggregate(caseId);
        List<ApiModels.TimelineEvent> events = aggregate.timeline.stream()
                .sorted(Comparator.comparing(ApiModels.TimelineEvent::occurredAt))
                .toList();
        return new ApiModels.TimelineResponse(caseId, events);
    }

    private CaseAggregate loadAggregate(UUID caseId) {
        CaseEntity caseEntity = caseRepository.findById(caseId)
                .orElseThrow(() -> ApiException.notFound("CASE_NOT_FOUND", "Case not found: " + caseId));

        return new CaseAggregate(
                caseEntity,
                readMap(caseEntity.getFilledSlotsJson()),
                readList(caseEntity.getDecompositionNodesJson(), DECOMPOSITION_LIST_TYPE),
                readList(caseEntity.getRoutingOptionsJson(), ROUTING_LIST_TYPE),
                evidenceRepository.findAllByCaseIdOrderByUploadedAtAsc(caseId).stream()
                        .map(this::toEvidenceItem)
                        .collect(ArrayList::new, ArrayList::add, ArrayList::addAll),
                timelineRepository.findAllByCaseIdOrderByOccurredAtAsc(caseId).stream()
                        .map(this::toTimelineEvent)
                        .collect(ArrayList::new, ArrayList::add, ArrayList::addAll)
        );
    }

    private void persistCase(CaseAggregate aggregate) {
        aggregate.caseEntity.setFilledSlotsJson(writeJson(aggregate.filledSlots));
        aggregate.caseEntity.setDecompositionNodesJson(writeJson(aggregate.decompositionNodes));
        aggregate.caseEntity.setRoutingOptionsJson(writeJson(aggregate.routingOptions));
        caseRepository.save(aggregate.caseEntity);
    }

    private void extractSlots(Map<String, Object> filledSlots, String message) {
        String trimmed = message == null ? "" : message.trim();
        if (trimmed.isEmpty()) {
            return;
        }

        if (equalsAny(trimmed, "생활소음 접수 계속")
                || containsAny(trimmed, "접수 계속", "계속 진행")) {
            filledSlots.put("safetyContinue", true);
        }

        if (equalsAny(trimmed, "지금 진행 중")) {
            filledSlots.put("noiseNow", "지금 진행 중");
        } else if (equalsAny(trimmed, "방금 멈춤")) {
            filledSlots.put("noiseNow", "방금 멈춤");
        } else if (equalsAny(trimmed, "자주 반복")) {
            filledSlots.put("noiseNow", "자주 반복");
        } else if (containsAny(trimmed, "지금도", "현재도", "진행 중")) {
            filledSlots.put("noiseNow", "지금 진행 중");
        }

        if (equalsAny(trimmed, "위협 징후 없음", "없음(생활소음)")) {
            filledSlots.put("safety", "위협 징후 없음");
        } else if (containsAny(trimmed, "위협 징후 없음", "안전 문제 없음")) {
            filledSlots.put("safety", "위협 징후 없음");
        } else if (equalsAny(trimmed, "잘 모르겠음")) {
            filledSlots.put("safety", "잘 모르겠음");
        } else if (containsAny(trimmed, "안전은 잘 모르겠", "위험 여부는 잘 모르겠")) {
            filledSlots.put("safety", "잘 모르겠음");
        } else if (equalsAny(trimmed, "위협 징후 있음", "있음(위험)")) {
            filledSlots.put("safety", SAFETY_DANGER);
        } else if (containsAny(trimmed, "폭행", "스토킹", "칼", "죽이", "협박", "기물파손")
                || containsAny(trimmed, "위협 징후 있음")) {
            filledSlots.put("safety", SAFETY_DANGER);
        }

        if (equalsAny(trimmed, "아파트", "빌라", "오피스텔", "기타")) {
            filledSlots.put("residence", trimmed);
        } else if (containsAny(trimmed, "아파트")) {
            filledSlots.put("residence", "아파트");
        } else if (containsAny(trimmed, "빌라", "다세대", "연립")) {
            filledSlots.put("residence", "빌라");
        } else if (containsAny(trimmed, "오피스텔")) {
            filledSlots.put("residence", "오피스텔");
        }

        if (equalsAny(trimmed, "있음", "없음", "모름")) {
            filledSlots.put("management", trimmed);
        } else if (containsAny(trimmed, "관리사무소")) {
            if (containsAny(trimmed, "관리사무소 없음", "관리사무소가 없", "관리주체 없음", "관리주체가 없")) {
                filledSlots.put("management", "없음");
            } else if (containsAny(trimmed, "관리사무소 모름", "관리주체 모름", "불명")) {
                filledSlots.put("management", "모름");
            } else if (containsAny(trimmed, "관리사무소 있음", "관리사무소가 있", "관리주체 있음", "관리주체가 있")) {
                filledSlots.put("management", "있음");
            } else {
                filledSlots.put("management", "있음");
            }
        }

        if (equalsAny(trimmed, "충격 소음(쿵쿵)", "공기전달 소음(TV/음악)", "둘 다", "잘 모르겠음")) {
            filledSlots.put("noiseType", trimmed);
        } else if (containsAny(trimmed, "쿵", "발망치", "뛰", "의자", "가구")) {
            filledSlots.put("noiseType", "충격 소음(쿵쿵)");
        } else if (containsAny(trimmed, "tv", "음악", "오디오", "스피커")) {
            filledSlots.put("noiseType", "공기전달 소음(TV/음악)");
        }

        if (equalsAny(trimmed, "거의 매일", "주 2~3회", "주 1회 이하", "불규칙")) {
            filledSlots.put("frequency", trimmed);
        } else if (containsAny(trimmed, "거의 매일", "매일")) {
            filledSlots.put("frequency", "거의 매일");
        } else if (containsAny(trimmed, "주 2", "주2", "주 3", "주3")) {
            filledSlots.put("frequency", "주 2~3회");
        } else if (containsAny(trimmed, "주 1", "주1", "가끔")) {
            filledSlots.put("frequency", "주 1회 이하");
        } else if (containsAny(trimmed, "불규칙")) {
            filledSlots.put("frequency", "불규칙");
        }

        if (equalsAny(trimmed, "저녁", "심야", "새벽", "불규칙")) {
            filledSlots.put("timeBand", trimmed);
        } else if (containsAny(trimmed, "심야")) {
            filledSlots.put("timeBand", "심야");
        } else if (containsAny(trimmed, "새벽")) {
            filledSlots.put("timeBand", "새벽");
        } else if (containsAny(trimmed, "저녁", "밤")) {
            filledSlots.put("timeBand", "저녁");
        }

        if (equalsAny(trimmed, "호수까지 확실", "층은 확실(호수 불명)", "모름")) {
            filledSlots.put("sourceCertainty", trimmed);
        } else if (containsAny(trimmed, "호수", "몇 호", "동 ")) {
            filledSlots.put("sourceCertainty", "호수까지 확실");
        } else if (containsAny(trimmed, "층", "윗집")) {
            filledSlots.put("sourceCertainty", "층은 확실(호수 불명)");
        }

        if (containsAny(trimmed, "관리사무소", "조정", "중재")) {
            filledSlots.put("priorMediation", true);
        }
    }

    private void evaluateRiskSignal(CaseAggregate aggregate, String message) {
        boolean dangerDetected = containsAny(message, "폭행", "스토킹", "죽", "칼", "협박", "기물파손")
                || SAFETY_DANGER.equals(aggregate.filledSlots.get("safety"));

        if (!aggregate.caseEntity.isRiskSignalDetected() && dangerDetected) {
            aggregate.caseEntity.setRiskSignalDetected(true);
            aggregate.caseEntity.setRiskLevel(ApiModels.RiskLevel.CRITICAL);
            appendTimeline(
                    aggregate,
                    ApiModels.TimelineEventType.RISK_DETECTED,
                    "즉시위험 신호가 감지되었습니다.",
                    "고위험 키워드 기반 룰이 감지되었습니다.",
                    ApiModels.TimelineActor.SYSTEM
            );
        }
    }

    private boolean isIntakeComplete(Map<String, Object> filledSlots) {
        return missingSlots(filledSlots).isEmpty();
    }

    private static boolean containsAny(String text, String... keywords) {
        String normalizedText = text.toLowerCase();
        for (String keyword : keywords) {
            if (normalizedText.contains(keyword.toLowerCase())) {
                return true;
            }
        }
        return false;
    }

    private static boolean equalsAny(String text, String... candidates) {
        if (text == null) {
            return false;
        }
        String normalized = text.trim();
        if (normalized.isEmpty()) {
            return false;
        }
        for (String candidate : candidates) {
            if (normalized.equals(candidate)) {
                return true;
            }
        }
        return false;
    }

    private List<String> missingSlots(Map<String, Object> filledSlots) {
        List<String> missing = REQUIRED_SLOTS.stream()
                .filter(slot -> !filledSlots.containsKey(slot))
                .collect(ArrayList::new, ArrayList::add, ArrayList::addAll);

        if (SAFETY_DANGER.equals(filledSlots.get("safety"))
                && !Boolean.TRUE.equals(filledSlots.get("safetyContinue"))) {
            missing.add(0, "safetyContinue");
        }

        return List.copyOf(missing);
    }

    private double adequacyScore(ApiModels.EvidenceType type) {
        return switch (type) {
            case AUDIO -> 0.75;
            case LOG -> 0.60;
            case IMAGE -> 0.50;
            case DOCUMENT -> 0.70;
        };
    }

    private ApiModels.EvidenceChecklist computeChecklist(List<ApiModels.EvidenceItem> evidenceItems) {
        boolean hasAudio = evidenceItems.stream().anyMatch(item -> item.evidenceType() == ApiModels.EvidenceType.AUDIO);
        boolean hasLog = evidenceItems.stream().anyMatch(item -> item.evidenceType() == ApiModels.EvidenceType.LOG);

        List<String> missing = new ArrayList<>();
        if (!hasAudio) {
            missing.add("녹음 파일(AUDIO)");
        }
        if (!hasLog) {
            missing.add("소음 일지(LOG)");
        }

        boolean sufficient = missing.isEmpty();
        String guidance = sufficient
                ? "증거가 준비되었습니다. 바로 제출하거나 추가 첨부할 수 있어요."
                : "증빙 자료는 선택사항입니다. 필요하면 첨부하고 제출을 진행해 주세요.";

        return new ApiModels.EvidenceChecklist(sufficient, missing, guidance);
    }

    private String defaultMessage(String message, String fallback) {
        return message == null || message.isBlank() ? fallback : message;
    }

    private boolean shouldFailInstitutionGateway(ApiModels.SubmissionChannel channel) {
        return institutionGatewayFailDirectApi && channel == ApiModels.SubmissionChannel.DIRECT_API;
    }

    private void triggerMockSubmissionProcessing(UUID caseId, String submissionId) {
        if (!mockSubmissionAutoProcessEnabled) {
            return;
        }
        mockInstitutionSubmissionWorker.processSubmission(caseId, submissionId);
    }

    private ApiModels.CaseDetail toCaseDetail(CaseAggregate aggregate) {
        ApiModels.IntakeSnapshot intake = new ApiModels.IntakeSnapshot(
                REQUIRED_SLOTS,
                Map.copyOf(aggregate.filledSlots),
                aggregate.caseEntity.isRiskSignalDetected()
        );

        ApiModels.DecompositionResult decomposition = aggregate.decompositionNodes.isEmpty()
                ? null
                : new ApiModels.DecompositionResult(aggregate.caseEntity.getId(), List.copyOf(aggregate.decompositionNodes));

        ApiModels.RoutingRecommendation routing = aggregate.routingOptions.isEmpty()
                ? null
                : new ApiModels.RoutingRecommendation(
                aggregate.caseEntity.getId(),
                List.copyOf(aggregate.routingOptions),
                aggregate.caseEntity.getSelectedOptionId()
        );

        ApiModels.EvidenceChecklist checklist = computeChecklist(aggregate.evidenceItems);

        return new ApiModels.CaseDetail(
                aggregate.caseEntity.getId(),
                aggregate.caseEntity.getStatus(),
                aggregate.caseEntity.getRiskLevel(),
                aggregate.caseEntity.getCreatedAt(),
                aggregate.caseEntity.getUpdatedAt(),
                intake,
                decomposition,
                routing,
                checklist,
                aggregate.caseEntity.getCurrentActionRequired()
        );
    }

    private void transition(CaseEntity entity, ApiModels.CaseStatus next) {
        if (entity.getStatus() == next) {
            return;
        }

        Set<ApiModels.CaseStatus> allowed = ALLOWED_TRANSITIONS.getOrDefault(entity.getStatus(), Set.of());
        if (!allowed.contains(next)) {
            throw ApiException.conflict(
                    "CASE_STATE_CONFLICT",
                    "Invalid case status transition.",
                    List.of("currentState=" + entity.getStatus(), "nextState=" + next)
            );
        }

        entity.setStatus(next);
    }

    private void appendTimeline(
            CaseAggregate aggregate,
            ApiModels.TimelineEventType type,
            String title,
            String description,
            ApiModels.TimelineActor actor
    ) {
        TimelineEventEntity eventEntity = new TimelineEventEntity();
        eventEntity.setId(UUID.randomUUID());
        eventEntity.setCaseId(aggregate.caseEntity.getId());
        eventEntity.setEventType(type);
        eventEntity.setOccurredAt(Instant.now());
        eventEntity.setTitle(title);
        eventEntity.setDescription(description);
        eventEntity.setActor(actor);

        TimelineEventEntity saved = timelineRepository.save(eventEntity);
        aggregate.timeline.add(toTimelineEvent(saved));
    }

    private ApiModels.EvidenceItem toEvidenceItem(EvidenceEntity entity) {
        return new ApiModels.EvidenceItem(
                entity.getId(),
                entity.getEvidenceType(),
                entity.getStorageKey(),
                entity.getUploadedAt(),
                entity.getAdequacyScore()
        );
    }

    private ApiModels.TimelineEvent toTimelineEvent(TimelineEventEntity entity) {
        return new ApiModels.TimelineEvent(
                entity.getId(),
                entity.getEventType(),
                entity.getOccurredAt(),
                entity.getTitle(),
                entity.getDescription(),
                entity.getActor()
        );
    }

    private Map<String, Object> readMap(String json) {
        if (json == null || json.isBlank()) {
            return new HashMap<>();
        }
        try {
            return objectMapper.readValue(json, MAP_TYPE);
        } catch (Exception ex) {
            throw new IllegalStateException("Failed to parse filledSlotsJson", ex);
        }
    }

    private <T> List<T> readList(String json, TypeReference<List<T>> typeReference) {
        if (json == null || json.isBlank()) {
            return new ArrayList<>();
        }
        try {
            return objectMapper.readValue(json, typeReference);
        } catch (Exception ex) {
            throw new IllegalStateException("Failed to parse json list", ex);
        }
    }

    private String writeJson(Object value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (Exception ex) {
            throw new IllegalStateException("Failed to serialize json", ex);
        }
    }

    private static final class CaseAggregate {
        private final CaseEntity caseEntity;
        private Map<String, Object> filledSlots;
        private List<ApiModels.DecompositionNode> decompositionNodes;
        private List<ApiModels.RoutingOption> routingOptions;
        private List<ApiModels.EvidenceItem> evidenceItems;
        private List<ApiModels.TimelineEvent> timeline;

        private CaseAggregate(
                CaseEntity caseEntity,
                Map<String, Object> filledSlots,
                List<ApiModels.DecompositionNode> decompositionNodes,
                List<ApiModels.RoutingOption> routingOptions,
                List<ApiModels.EvidenceItem> evidenceItems,
                List<ApiModels.TimelineEvent> timeline
        ) {
            this.caseEntity = caseEntity;
            this.filledSlots = filledSlots;
            this.decompositionNodes = decompositionNodes;
            this.routingOptions = routingOptions;
            this.evidenceItems = evidenceItems;
            this.timeline = timeline;
        }
    }
}
