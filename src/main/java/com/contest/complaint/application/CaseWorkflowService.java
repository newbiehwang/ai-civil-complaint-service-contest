package com.contest.complaint.application;

import com.contest.complaint.api.ApiException;
import com.contest.complaint.api.model.ApiModels;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.EnumMap;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class CaseWorkflowService {

    private static final List<String> REQUIRED_SLOTS = List.of("incidentTime", "frequency", "noiseType");

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

    private final Map<UUID, CaseState> store = new ConcurrentHashMap<>();

    public ApiModels.CaseDetail createCase(ApiModels.CreateCaseRequest request) {
        if (!Boolean.TRUE.equals(request.consentAccepted())) {
            throw ApiException.badRequest("VALIDATION_ERROR", "consentAccepted must be true.", List.of("consentAccepted=true required"));
        }

        Instant now = Instant.now();
        UUID caseId = UUID.randomUUID();

        CaseState state = new CaseState(
                caseId,
                ApiModels.CaseStatus.RECEIVED,
                ApiModels.RiskLevel.LOW,
                now,
                now,
                request.scenarioType(),
                request.housingType(),
                request.initialSummary(),
                false,
                new HashMap<>(),
                new ArrayList<>(),
                new ArrayList<>(),
                null,
                new ArrayList<>(),
                "INTAKE_REQUIRED",
                null,
                null,
                new ArrayList<>()
        );

        appendTimeline(
                state,
                ApiModels.TimelineEventType.CASE_CREATED,
                "민원이 생성되었습니다.",
                "사용자가 시나리오 A 민원을 시작했습니다.",
                ApiModels.TimelineActor.USER
        );

        store.put(caseId, state);
        return toCaseDetail(state);
    }

    public ApiModels.CaseDetail getCase(UUID caseId) {
        return toCaseDetail(getCaseState(caseId));
    }

    public ApiModels.IntakeUpdateResponse appendIntakeMessage(UUID caseId, ApiModels.AppendIntakeMessageRequest request) {
        CaseState state = getCaseState(caseId);

        String message = request.message().trim();
        if (request.role() == ApiModels.MessageRole.USER) {
            extractSlots(state, message);
            evaluateRiskSignal(state, message);
        }

        if (state.status == ApiModels.CaseStatus.RECEIVED && REQUIRED_SLOTS.stream().allMatch(state.filledSlots::containsKey)) {
            transition(state, ApiModels.CaseStatus.CLASSIFIED);
            appendTimeline(
                    state,
                    ApiModels.TimelineEventType.CLASSIFICATION_DONE,
                    "민원 분류가 완료되었습니다.",
                    "필수 슬롯이 모두 채워져 분류가 완료되었습니다.",
                    ApiModels.TimelineActor.SYSTEM
            );
            state.currentActionRequired = "REQUEST_DECOMPOSITION";
        }

        List<String> missing = missingSlots(state);
        String followUp = missing.isEmpty() ? null : followUpQuestionFor(missing.getFirst());

        return new ApiModels.IntakeUpdateResponse(
                state.caseId,
                state.status,
                new ApiModels.IntakeSnapshot(REQUIRED_SLOTS, Map.copyOf(state.filledSlots), state.riskSignalDetected),
                followUp
        );
    }

    public ApiModels.DecompositionResult decomposeCase(UUID caseId) {
        CaseState state = getCaseState(caseId);

        if (state.status == ApiModels.CaseStatus.RECEIVED) {
            throw ApiException.conflict(
                    "CASE_STATE_CONFLICT",
                    "Cannot decompose before classification.",
                    List.of("currentState=" + state.status, "requiredState=CLASSIFIED")
            );
        }

        List<ApiModels.DecompositionNode> nodes = new ArrayList<>();
        nodes.add(new ApiModels.DecompositionNode(
                ApiModels.DecompositionNodeType.LIVING_NOISE,
                "생활소음 민원",
                2,
                "층간소음 핵심 이슈를 우선 처리합니다."
        ));

        if (state.riskSignalDetected) {
            nodes.add(new ApiModels.DecompositionNode(
                    ApiModels.DecompositionNodeType.IMMEDIATE_RISK,
                    "즉시위험 민원",
                    1,
                    "폭행/위협 신호가 감지되어 즉시 대응이 필요합니다."
            ));
        }

        if (Boolean.TRUE.equals(state.filledSlots.get("priorMediation"))) {
            nodes.add(new ApiModels.DecompositionNode(
                    ApiModels.DecompositionNodeType.LONG_TERM_DISPUTE,
                    "장기 미해결 분쟁",
                    3,
                    "기존 조정 시도가 있어 장기 분쟁 경로 검토가 필요합니다."
            ));
        }

        nodes.sort(Comparator.comparingInt(ApiModels.DecompositionNode::priority));
        state.decompositionNodes = nodes;
        state.updatedAt = Instant.now();
        state.currentActionRequired = "REQUEST_ROUTING_RECOMMENDATION";

        return new ApiModels.DecompositionResult(state.caseId, List.copyOf(nodes));
    }

    public ApiModels.RoutingRecommendation recommendRoute(UUID caseId) {
        CaseState state = getCaseState(caseId);

        if (state.decompositionNodes.isEmpty()) {
            throw ApiException.conflict(
                    "CASE_STATE_CONFLICT",
                    "Cannot recommend route before decomposition.",
                    List.of("decompositionRequired=true")
            );
        }

        List<ApiModels.RoutingOption> options = new ArrayList<>();

        if (state.riskSignalDetected) {
            options.add(new ApiModels.RoutingOption(
                    "opt-emergency-112",
                    ApiModels.RoutingChannelType.EMERGENCY_112,
                    "112 긴급 신고",
                    1,
                    "즉시위험 신호가 감지되어 긴급 대응이 필요합니다.",
                    List.of("위험 상황 설명")
            ));
        }

        if ("APARTMENT".equalsIgnoreCase(state.housingType)) {
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

        if (Boolean.TRUE.equals(state.filledSlots.get("priorMediation"))) {
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
        state.routingOptions = options;
        state.updatedAt = Instant.now();
        state.currentActionRequired = "CONFIRM_ROUTE";

        appendTimeline(
                state,
                ApiModels.TimelineEventType.ROUTE_RECOMMENDED,
                "경로 추천이 생성되었습니다.",
                "추천 경로를 확인하고 선택해 주세요.",
                ApiModels.TimelineActor.SYSTEM
        );

        return new ApiModels.RoutingRecommendation(state.caseId, List.copyOf(options), state.selectedOptionId);
    }

    public ApiModels.CaseDetail confirmRouteDecision(UUID caseId, ApiModels.RouteDecisionRequest request) {
        CaseState state = getCaseState(caseId);

        if (!Boolean.TRUE.equals(request.userConfirmed())) {
            throw ApiException.conflict(
                    "CASE_STATE_CONFLICT",
                    "Route decision requires explicit user confirmation.",
                    List.of("userConfirmed=true required")
            );
        }

        boolean exists = state.routingOptions.stream().anyMatch(opt -> opt.optionId().equals(request.optionId()));
        if (!exists) {
            throw ApiException.notFound("ROUTE_OPTION_NOT_FOUND", "Selected route option not found.");
        }

        if (state.status == ApiModels.CaseStatus.RECEIVED) {
            throw ApiException.conflict(
                    "CASE_STATE_CONFLICT",
                    "Cannot confirm route before classification.",
                    List.of("currentState=" + state.status, "requiredState=CLASSIFIED")
            );
        }

        if (state.status == ApiModels.CaseStatus.CLASSIFIED) {
            transition(state, ApiModels.CaseStatus.ROUTE_CONFIRMED);
        }

        state.selectedOptionId = request.optionId();
        state.updatedAt = Instant.now();
        state.currentActionRequired = "UPLOAD_EVIDENCE";

        appendTimeline(
                state,
                ApiModels.TimelineEventType.ROUTE_CONFIRMED,
                "사용자가 경로를 확정했습니다.",
                "선택된 경로: " + request.optionId(),
                ApiModels.TimelineActor.USER
        );

        return toCaseDetail(state);
    }

    public ApiModels.EvidenceItem registerEvidence(UUID caseId, ApiModels.RegisterEvidenceRequest request) {
        CaseState state = getCaseState(caseId);

        if (state.status == ApiModels.CaseStatus.RECEIVED || state.status == ApiModels.CaseStatus.CLASSIFIED) {
            throw ApiException.conflict(
                    "CASE_STATE_CONFLICT",
                    "Cannot add evidence before route confirmation.",
                    List.of("currentState=" + state.status, "requiredState=ROUTE_CONFIRMED")
            );
        }

        if (state.status == ApiModels.CaseStatus.ROUTE_CONFIRMED) {
            transition(state, ApiModels.CaseStatus.EVIDENCE_COLLECTING);
        }

        double score = adequacyScore(request.evidenceType());
        ApiModels.EvidenceItem item = new ApiModels.EvidenceItem(
                UUID.randomUUID(),
                request.evidenceType(),
                request.storageKey(),
                Instant.now(),
                score
        );

        state.evidenceItems.add(item);
        state.updatedAt = Instant.now();

        ApiModels.EvidenceChecklist checklist = computeChecklist(state);
        if (checklist.isSufficient() && state.status == ApiModels.CaseStatus.EVIDENCE_COLLECTING) {
            transition(state, ApiModels.CaseStatus.FORMAL_SUBMISSION_READY);
            state.currentActionRequired = "SUBMIT_CASE";
        } else {
            state.currentActionRequired = "ADD_MORE_EVIDENCE";
        }

        appendTimeline(
                state,
                ApiModels.TimelineEventType.EVIDENCE_ADDED,
                "증거가 등록되었습니다.",
                "evidenceId=" + item.evidenceId(),
                ApiModels.TimelineActor.USER
        );

        return item;
    }

    public ApiModels.EvidenceChecklist getEvidenceChecklist(UUID caseId) {
        return computeChecklist(getCaseState(caseId));
    }

    public ApiModels.SubmissionResponse submitCase(UUID caseId, ApiModels.SubmitCaseRequest request) {
        CaseState state = getCaseState(caseId);

        if (state.status != ApiModels.CaseStatus.FORMAL_SUBMISSION_READY) {
            throw ApiException.conflict(
                    "CASE_STATE_CONFLICT",
                    "Cannot submit before evidence becomes sufficient.",
                    List.of("currentState=" + state.status, "requiredState=FORMAL_SUBMISSION_READY")
            );
        }

        if (!Boolean.TRUE.equals(request.userConsent()) || !Boolean.TRUE.equals(request.identityVerified())) {
            throw ApiException.badRequest(
                    "VALIDATION_ERROR",
                    "Submission requires userConsent=true and identityVerified=true.",
                    List.of("userConsent=true required", "identityVerified=true required")
            );
        }

        transition(state, ApiModels.CaseStatus.INSTITUTION_PROCESSING);
        state.submissionId = "SUB-" + UUID.randomUUID().toString().substring(0, 8);
        state.submissionStatus = ApiModels.SubmissionStatus.SUBMITTED;
        state.updatedAt = Instant.now();
        state.currentActionRequired = "WAIT_INSTITUTION_RESULT";

        appendTimeline(
                state,
                ApiModels.TimelineEventType.SUBMISSION_STARTED,
                "기관 제출이 시작되었습니다.",
                "submissionChannel=" + request.submissionChannel(),
                ApiModels.TimelineActor.SYSTEM
        );

        return new ApiModels.SubmissionResponse(
                state.caseId,
                state.submissionId,
                state.submissionStatus,
                Instant.now()
        );
    }

    public ApiModels.CaseDetail respondSupplement(UUID caseId, ApiModels.SupplementResponseRequest request) {
        CaseState state = getCaseState(caseId);

        if (state.status != ApiModels.CaseStatus.SUPPLEMENT_REQUIRED) {
            throw ApiException.conflict(
                    "CASE_STATE_CONFLICT",
                    "No supplement request exists for this case.",
                    List.of("currentState=" + state.status, "requiredState=SUPPLEMENT_REQUIRED")
            );
        }

        transition(state, ApiModels.CaseStatus.INSTITUTION_PROCESSING);
        state.currentActionRequired = "WAIT_INSTITUTION_RESULT";

        appendTimeline(
                state,
                ApiModels.TimelineEventType.SUPPLEMENT_RESPONDED,
                "보완 요청에 응답했습니다.",
                request.message(),
                ApiModels.TimelineActor.USER
        );

        return toCaseDetail(state);
    }

    public ApiModels.TimelineResponse getTimeline(UUID caseId) {
        CaseState state = getCaseState(caseId);
        List<ApiModels.TimelineEvent> events = state.timeline.stream()
                .sorted(Comparator.comparing(ApiModels.TimelineEvent::occurredAt))
                .toList();
        return new ApiModels.TimelineResponse(state.caseId, events);
    }

    private void extractSlots(CaseState state, String message) {
        if (containsAny(message, "밤", "새벽", "저녁")) {
            state.filledSlots.put("incidentTime", "야간");
        }
        if (containsAny(message, "매일", "자주", "반복", "매주")) {
            state.filledSlots.put("frequency", "반복 발생");
        }
        if (containsAny(message, "쿵", "발망치", "소음", "끌", "뛰")) {
            state.filledSlots.put("noiseType", "충격/생활 소음");
        }
        if (containsAny(message, "관리사무소", "조정", "중재")) {
            state.filledSlots.put("priorMediation", true);
        }
    }

    private void evaluateRiskSignal(CaseState state, String message) {
        if (!state.riskSignalDetected && containsAny(message, "폭행", "위협", "스토킹", "죽", "칼")) {
            state.riskSignalDetected = true;
            state.riskLevel = ApiModels.RiskLevel.CRITICAL;
            appendTimeline(
                    state,
                    ApiModels.TimelineEventType.RISK_DETECTED,
                    "즉시위험 신호가 감지되었습니다.",
                    "고위험 키워드 기반 룰이 감지되었습니다.",
                    ApiModels.TimelineActor.SYSTEM
            );
        }
    }

    private static boolean containsAny(String text, String... keywords) {
        for (String keyword : keywords) {
            if (text.contains(keyword)) {
                return true;
            }
        }
        return false;
    }

    private List<String> missingSlots(CaseState state) {
        return REQUIRED_SLOTS.stream()
                .filter(slot -> !state.filledSlots.containsKey(slot))
                .toList();
    }

    private String followUpQuestionFor(String slot) {
        return switch (slot) {
            case "incidentTime" -> "소음이 주로 발생하는 시간대를 알려주세요.";
            case "frequency" -> "소음이 얼마나 자주 반복되는지 알려주세요.";
            case "noiseType" -> "어떤 종류의 소음인지 예시와 함께 알려주세요.";
            default -> "추가 정보를 입력해 주세요.";
        };
    }

    private double adequacyScore(ApiModels.EvidenceType type) {
        return switch (type) {
            case AUDIO -> 0.75;
            case LOG -> 0.60;
            case IMAGE -> 0.50;
            case DOCUMENT -> 0.70;
        };
    }

    private ApiModels.EvidenceChecklist computeChecklist(CaseState state) {
        boolean hasAudio = state.evidenceItems.stream().anyMatch(item -> item.evidenceType() == ApiModels.EvidenceType.AUDIO);
        boolean hasLog = state.evidenceItems.stream().anyMatch(item -> item.evidenceType() == ApiModels.EvidenceType.LOG);

        List<String> missing = new ArrayList<>();
        if (!hasAudio) {
            missing.add("녹음 파일(AUDIO)");
        }
        if (!hasLog) {
            missing.add("소음 일지(LOG)");
        }

        boolean sufficient = missing.isEmpty();
        String guidance = sufficient
                ? "증거가 충분합니다. 기관 제출 단계를 진행하세요."
                : "필수 증거를 추가하면 제출 준비 상태로 전환됩니다.";

        return new ApiModels.EvidenceChecklist(sufficient, missing, guidance);
    }

    private CaseState getCaseState(UUID caseId) {
        CaseState state = store.get(caseId);
        if (state == null) {
            throw ApiException.notFound("CASE_NOT_FOUND", "Case not found: " + caseId);
        }
        return state;
    }

    private ApiModels.CaseDetail toCaseDetail(CaseState state) {
        ApiModels.IntakeSnapshot intake = new ApiModels.IntakeSnapshot(
                REQUIRED_SLOTS,
                Map.copyOf(state.filledSlots),
                state.riskSignalDetected
        );

        ApiModels.DecompositionResult decomposition = state.decompositionNodes.isEmpty()
                ? null
                : new ApiModels.DecompositionResult(state.caseId, List.copyOf(state.decompositionNodes));

        ApiModels.RoutingRecommendation routing = state.routingOptions.isEmpty()
                ? null
                : new ApiModels.RoutingRecommendation(state.caseId, List.copyOf(state.routingOptions), state.selectedOptionId);

        ApiModels.EvidenceChecklist checklist = computeChecklist(state);

        return new ApiModels.CaseDetail(
                state.caseId,
                state.status,
                state.riskLevel,
                state.createdAt,
                state.updatedAt,
                intake,
                decomposition,
                routing,
                checklist,
                state.currentActionRequired
        );
    }

    private void transition(CaseState state, ApiModels.CaseStatus next) {
        if (state.status == next) {
            return;
        }

        Set<ApiModels.CaseStatus> allowed = ALLOWED_TRANSITIONS.getOrDefault(state.status, Set.of());
        if (!allowed.contains(next)) {
            throw ApiException.conflict(
                    "CASE_STATE_CONFLICT",
                    "Invalid case status transition.",
                    List.of("currentState=" + state.status, "nextState=" + next)
            );
        }

        state.status = next;
        state.updatedAt = Instant.now();
    }

    private void appendTimeline(
            CaseState state,
            ApiModels.TimelineEventType type,
            String title,
            String description,
            ApiModels.TimelineActor actor
    ) {
        state.timeline.add(new ApiModels.TimelineEvent(
                UUID.randomUUID(),
                type,
                Instant.now(),
                title,
                description,
                actor
        ));
    }

    private static final class CaseState {
        private final UUID caseId;
        private ApiModels.CaseStatus status;
        private ApiModels.RiskLevel riskLevel;
        private final Instant createdAt;
        private Instant updatedAt;
        private final String scenarioType;
        private final String housingType;
        private final String initialSummary;
        private boolean riskSignalDetected;
        private final Map<String, Object> filledSlots;
        private List<ApiModels.DecompositionNode> decompositionNodes;
        private List<ApiModels.RoutingOption> routingOptions;
        private String selectedOptionId;
        private final List<ApiModels.EvidenceItem> evidenceItems;
        private String currentActionRequired;
        private String submissionId;
        private ApiModels.SubmissionStatus submissionStatus;
        private final List<ApiModels.TimelineEvent> timeline;

        private CaseState(
                UUID caseId,
                ApiModels.CaseStatus status,
                ApiModels.RiskLevel riskLevel,
                Instant createdAt,
                Instant updatedAt,
                String scenarioType,
                String housingType,
                String initialSummary,
                boolean riskSignalDetected,
                Map<String, Object> filledSlots,
                List<ApiModels.DecompositionNode> decompositionNodes,
                List<ApiModels.RoutingOption> routingOptions,
                String selectedOptionId,
                List<ApiModels.EvidenceItem> evidenceItems,
                String currentActionRequired,
                String submissionId,
                ApiModels.SubmissionStatus submissionStatus,
                List<ApiModels.TimelineEvent> timeline
        ) {
            this.caseId = caseId;
            this.status = status;
            this.riskLevel = riskLevel;
            this.createdAt = createdAt;
            this.updatedAt = updatedAt;
            this.scenarioType = scenarioType;
            this.housingType = housingType;
            this.initialSummary = initialSummary;
            this.riskSignalDetected = riskSignalDetected;
            this.filledSlots = filledSlots;
            this.decompositionNodes = decompositionNodes;
            this.routingOptions = routingOptions;
            this.selectedOptionId = selectedOptionId;
            this.evidenceItems = evidenceItems;
            this.currentActionRequired = currentActionRequired;
            this.submissionId = submissionId;
            this.submissionStatus = submissionStatus;
            this.timeline = timeline;
        }
    }
}
