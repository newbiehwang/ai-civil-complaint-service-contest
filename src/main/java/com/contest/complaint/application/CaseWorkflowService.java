package com.contest.complaint.application;

import com.contest.complaint.api.ApiException;
import com.contest.complaint.api.model.ApiModels;
import com.contest.complaint.application.chat.ChatTurnPlan;
import com.contest.complaint.application.chat.ChatTurnPlanValidator;
import com.contest.complaint.application.chat.ChatTurnPlannerRequest;
import com.contest.complaint.application.chat.LlmChatTurnPlannerClient;
import com.contest.complaint.application.chat.RuleBasedTurnFallbackPlanner;
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
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.EnumMap;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;

@Service
public class CaseWorkflowService {

    private static final Logger log = LoggerFactory.getLogger(CaseWorkflowService.class);

    private static final String SAFETY_DANGER = "위협 징후 있음";
    private static final String DEFAULT_SCENARIO_TYPE = "SCENARIO_A";
    private static final String DEFAULT_HOUSING_TYPE = "APARTMENT";
    private static final Set<String> INTAKE_ACTIVATION_TOKENS = Set.of(
            "민원접수",
            "접수할게요",
            "접수해주세요",
            "신고할게요",
            "신고해주세요",
            "진행할게요",
            "진행해주세요",
            "접수진행"
    );
    private static final Set<String> AFFIRMATIVE_TOKENS = Set.of(
            "네",
            "예",
            "응",
            "좋아요",
            "진행",
            "진행할게요",
            "진행해주세요"
    );
    private static final Set<String> INTAKE_INTENT_HINT_TOKENS = Set.of(
            "층간소음",
            "윗집",
            "아랫집",
            "쿵쿵",
            "발망치",
            "시끄러",
            "소음"
    );
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
    private static final Set<String> TRIAGE_SLOTS = Set.of("noiseNow", "safety");
    private static final Set<String> BASIC_INTAKE_SLOTS = Set.of("residence", "management", "sourceCertainty");
    private static final Set<String> DETAIL_INTAKE_SLOTS = Set.of("noiseType", "frequency", "timeBand");

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
    private final LlmChatTurnPlannerClient llmChatTurnPlannerClient;
    private final RuleBasedTurnFallbackPlanner ruleBasedTurnFallbackPlanner;
    private final ChatTurnPlanValidator chatTurnPlanValidator;
    private final ObjectMapper objectMapper;
    private final boolean chatUseLlm;
    private final boolean mockSubmissionAutoProcessEnabled;
    private final boolean institutionGatewayFailDirectApi;

    public CaseWorkflowService(
            CaseEntityRepository caseRepository,
            EvidenceEntityRepository evidenceRepository,
            TimelineEventEntityRepository timelineRepository,
            MockInstitutionSubmissionWorker mockInstitutionSubmissionWorker,
            IntakeFollowUpAdvisor intakeFollowUpAdvisor,
            LlmChatTurnPlannerClient llmChatTurnPlannerClient,
            RuleBasedTurnFallbackPlanner ruleBasedTurnFallbackPlanner,
            ChatTurnPlanValidator chatTurnPlanValidator,
            ObjectMapper objectMapper,
            @Value("${complaint.ai.chat.use-llm:false}") boolean chatUseLlm,
            @Value("${complaint.mock-submission.auto-process-enabled:true}") boolean mockSubmissionAutoProcessEnabled,
            @Value("${complaint.institution-gateway.fail-direct-api:false}") boolean institutionGatewayFailDirectApi
    ) {
        this.caseRepository = caseRepository;
        this.evidenceRepository = evidenceRepository;
        this.timelineRepository = timelineRepository;
        this.mockInstitutionSubmissionWorker = mockInstitutionSubmissionWorker;
        this.intakeFollowUpAdvisor = intakeFollowUpAdvisor;
        this.llmChatTurnPlannerClient = llmChatTurnPlannerClient;
        this.ruleBasedTurnFallbackPlanner = ruleBasedTurnFallbackPlanner;
        this.chatTurnPlanValidator = chatTurnPlanValidator;
        this.objectMapper = objectMapper;
        this.chatUseLlm = chatUseLlm;
        this.mockSubmissionAutoProcessEnabled = mockSubmissionAutoProcessEnabled;
        this.institutionGatewayFailDirectApi = institutionGatewayFailDirectApi;
    }

    @Transactional
    public ApiModels.CaseDetail createCase(ApiModels.CreateCaseRequest request) {
        return createCase(request, "anonymous");
    }

    @Transactional
    public ApiModels.CaseDetail createCase(ApiModels.CreateCaseRequest request, String ownerSubject) {
        if (!Boolean.TRUE.equals(request.consentAccepted())) {
            throw ApiException.badRequest("VALIDATION_ERROR", "consentAccepted must be true.", List.of("consentAccepted=true required"));
        }

        CaseEntity entity = new CaseEntity();
        entity.setId(UUID.randomUUID());
        entity.setOwnerSubject(normalizeOwnerSubject(ownerSubject));
        entity.setScenarioType(request.scenarioType());
        entity.setHousingType(request.housingType());
        entity.setInitialSummary(request.initialSummary());
        entity.setStatus(ApiModels.CaseStatus.RECEIVED);
        entity.setRiskLevel(ApiModels.RiskLevel.LOW);
        entity.setRiskSignalDetected(false);
        entity.setFilledSlotsJson("{}");
        entity.setDecompositionNodesJson("[]");
        entity.setRoutingOptionsJson("[]");
        entity.setCurrentActionRequired("GENERAL_CHAT");

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
    public ApiModels.CaseListResponse listCasesByOwner(String ownerSubject) {
        List<ApiModels.CaseSummary> items = caseRepository
                .findAllByOwnerSubjectOrderByUpdatedAtDesc(normalizeOwnerSubject(ownerSubject))
                .stream()
                .map(this::toCaseSummary)
                .toList();
        return new ApiModels.CaseListResponse(items);
    }

    @Transactional
    public void deleteCase(UUID caseId, String ownerSubject) {
        CaseEntity entity = caseRepository
                .findByIdAndOwnerSubject(caseId, normalizeOwnerSubject(ownerSubject))
                .orElseThrow(() -> ApiException.notFound("CASE_NOT_FOUND", "Case not found: " + caseId));
        caseRepository.delete(entity);
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
    public ApiModels.ChatTurnResponse chatTurn(String traceId, ApiModels.ChatTurnRequest request) {
        return chatTurn(traceId, request, "anonymous");
    }

    @Transactional
    public ApiModels.ChatTurnResponse chatTurn(String traceId, ApiModels.ChatTurnRequest request, String ownerSubject) {
        String userMessage = request.userMessage() == null ? "" : request.userMessage().trim();
        UUID caseId = resolveCaseIdForChatTurn(request, userMessage, ownerSubject);
        List<ApiModels.ChatTurnHistoryMessage> recentMessages = sanitizeRecentMessages(request.recentMessages());

        ApiModels.CaseDetail detail = ensureRoutingPrepared(caseId, getCase(caseId));
        ApiModels.IntakeUpdateResponse intakeUpdate = null;
        String interactionNotice = null;
        List<String> uiCapabilities = sanitizeUiCapabilities(request.uiCapabilities());
        ApiModels.ChatTurnInteraction interaction = request.interaction();

        InteractionApplyResult interactionApplyResult =
                applyUserInteractionDeterministically(caseId, detail, interaction, userMessage);
        detail = interactionApplyResult.detail();
        intakeUpdate = interactionApplyResult.intakeUpdate();
        interactionNotice = interactionApplyResult.noticeMessage();

        // Selection-based intake answers arrive as interaction payloads from Flutter.
        // To keep intake behavior identical to origin/main, continue slot extraction on RECEIVED.
        if (interaction != null
                && detail.status() == ApiModels.CaseStatus.RECEIVED
                && !isGeneralChatMode(detail)
                && intakeUpdate == null
                && !userMessage.isBlank()) {
            intakeUpdate = appendIntakeMessage(
                    caseId,
                    new ApiModels.AppendIntakeMessageRequest(ApiModels.MessageRole.USER, userMessage)
            );
            detail = getCase(caseId);
            if (detail.status() != ApiModels.CaseStatus.RECEIVED) {
                detail = ensureRoutingPrepared(caseId, detail);
            }
        }

        if (interaction == null) {
            if (detail.status() == ApiModels.CaseStatus.RECEIVED && !userMessage.isBlank()) {
                if (isGeneralChatMode(detail)
                        && !chatUseLlm
                        && shouldActivateIntakeMode(userMessage, recentMessages)) {
                    detail = activateIntakeMode(caseId, detail);
                }

                if (isGeneralChatMode(detail)) {
                    interactionNotice = null;
                } else {
                intakeUpdate = appendIntakeMessage(
                        caseId,
                        new ApiModels.AppendIntakeMessageRequest(ApiModels.MessageRole.USER, userMessage)
                );
                detail = getCase(caseId);
                if (detail.status() != ApiModels.CaseStatus.RECEIVED) {
                    detail = ensureRoutingPrepared(caseId, detail);
                }
                }
            } else if (!userMessage.isBlank()) {
                try {
                    detail = applyPostIntakeChatAction(caseId, detail, userMessage);
                } catch (ApiException ex) {
                    interactionNotice = "현재 단계와 맞지 않는 요청입니다. 다시 확인해 주세요.";
                }
            }
        }

        detail = ensureRoutingPrepared(caseId, getCase(caseId));

        String normalizedLastUiHintType = normalizeLastUiHintType(request.lastUiHintType(), interaction);
        String flowStepHint = inferFlowStepHint(detail);

        ChatTurnPlannerRequest plannerRequest = new ChatTurnPlannerRequest(
                traceId,
                caseId,
                userMessage,
                detail.status(),
                detail.currentActionRequired(),
                flowStepHint,
                detail.riskLevel(),
                detail.intake() == null || detail.intake().filledSlots() == null
                        ? Map.of()
                        : Map.copyOf(detail.intake().filledSlots()),
                detail.intake() == null || detail.intake().filledSlots() == null
                        ? List.of()
                        : missingSlots(detail.intake().filledSlots()),
                detail.intake() != null && detail.intake().riskSignalDetected(),
                detail.routing() == null || detail.routing().options() == null
                        ? List.of()
                        : List.copyOf(detail.routing().options()),
                detail.evidenceChecklist(),
                uiCapabilities,
                normalizedLastUiHintType,
                recentMessages,
                interaction
        );

        ApiModels.CaseDetail finalDetail = detail;
        ApiModels.IntakeUpdateResponse finalIntakeUpdate = intakeUpdate;
        ChatTurnPlan resolvedPlan;
        String planSource;

        boolean deterministicIntake = finalDetail.status() == ApiModels.CaseStatus.RECEIVED
                && !isGeneralChatMode(finalDetail)
                && finalIntakeUpdate != null;

        if (deterministicIntake) {
            resolvedPlan = buildDeterministicIntakePlan(finalDetail);
            planSource = "intake-deterministic";
        } else {
            ChatTurnPlan llmPlan = llmChatTurnPlannerClient.plan(plannerRequest)
                    .map(plan -> chatTurnPlanValidator.sanitize(plan, finalDetail, uiCapabilities))
                    .filter(chatTurnPlanValidator::isUsable)
                    .orElse(null);
            if (llmPlan != null) {
                resolvedPlan = llmPlan;
                planSource = "llm";
            } else if (chatUseLlm) {
                throw ApiException.serviceUnavailable(
                        "LLM_UNAVAILABLE",
                        "LLM 응답을 생성하지 못했습니다. 잠시 후 다시 시도해 주세요.",
                        List.of("provider=claude", "fallback=disabled")
                );
            } else {
                resolvedPlan = ruleBasedTurnFallbackPlanner.plan(
                        finalIntakeUpdate,
                        finalDetail,
                        REQUIRED_SLOTS,
                        recentMessages
                );
                planSource = "fallback";
            }
        }

        if (interaction == null
                && !userMessage.isBlank()
                && isGeneralChatMode(detail)
                && "COLLECT_SLOT".equalsIgnoreCase(resolvedPlan.intent())) {
            detail = activateIntakeMode(caseId, detail);
            detail = ensureRoutingPrepared(caseId, detail);
            resolvedPlan = buildDeterministicIntakePlan(detail);
            planSource = "llm-intake-handoff";
        }

        String assistantMessage = interactionNotice != null && !interactionNotice.isBlank()
                ? interactionNotice
                : resolvedPlan.assistantMessage();
        ApiModels.ChatUiHint uiHint = resolvedPlan.uiHint();

        log.info(
                "chat-turn traceId={} caseId={} status={} source={} uiType={} nextAction={}",
                traceId,
                detail.caseId(),
                detail.status(),
                planSource,
                uiHint == null || uiHint.type() == null ? "NONE" : uiHint.type().name(),
                resolveNextAction(detail)
        );

        Map<String, Object> statePatch = new HashMap<>();
        statePatch.put("caseId", detail.caseId().toString());
        statePatch.put("status", detail.status().name());
        statePatch.put("riskLevel", detail.riskLevel().name());
        statePatch.put("currentActionRequired", detail.currentActionRequired());
        if (detail.routing() != null && detail.routing().selectedOptionId() != null
                && !detail.routing().selectedOptionId().isBlank()) {
            statePatch.put("selectedRouteOptionId", detail.routing().selectedOptionId());
            String selectedRouteLabel = resolveSelectedRouteLabel(detail);
            if (selectedRouteLabel != null && !selectedRouteLabel.isBlank()) {
                statePatch.put("selectedRouteLabel", selectedRouteLabel);
            }
        }
        if (detail.intake() != null) {
            statePatch.put("requiredSlots", detail.intake().requiredSlots());
            statePatch.put("filledSlots", detail.intake().filledSlots());
            statePatch.put("riskSignalDetected", detail.intake().riskSignalDetected());
        }

        return new ApiModels.ChatTurnResponse(
                detail.caseId().toString(),
                assistantMessage,
                uiHint,
                statePatch,
                resolveNextAction(detail)
        );
    }

    private ChatTurnPlan buildDeterministicIntakePlan(ApiModels.CaseDetail detail) {
        return buildDeterministicIntakePlan(detail, null);
    }

    private String resolveSelectedRouteLabel(ApiModels.CaseDetail detail) {
        if (detail == null || detail.routing() == null || detail.routing().selectedOptionId() == null) {
            return null;
        }
        String selectedOptionId = detail.routing().selectedOptionId();
        List<ApiModels.RoutingOption> options = detail.routing().options();
        if (options == null || options.isEmpty()) {
            return null;
        }
        for (ApiModels.RoutingOption option : options) {
            if (option != null
                    && option.optionId() != null
                    && option.optionId().equals(selectedOptionId)
                    && option.label() != null
                    && !option.label().isBlank()) {
                return option.label();
            }
        }
        return null;
    }

    private ChatTurnPlan buildDeterministicIntakePlan(ApiModels.CaseDetail detail, String handoffMessage) {
        Map<String, Object> filledSlots = detail.intake() == null || detail.intake().filledSlots() == null
                ? Map.of()
                : detail.intake().filledSlots();
        List<String> requiredFields = missingSlots(filledSlots);

        String safeHandoffMessage = handoffMessage == null ? "" : handoffMessage.trim();

        if (requiredFields.contains("safetyContinue")) {
            ApiModels.ChatUiHint uiHint = new ApiModels.ChatUiHint(
                    ApiModels.ChatUiType.LIST_PICKER,
                    ApiModels.ChatUiSelectionMode.SINGLE,
                    "단일 선택",
                    null,
                    List.of(
                            new ApiModels.ChatUiOption("safety-guide", "112 안전 안내 확인"),
                            new ApiModels.ChatUiOption("safety-continue", "생활소음 접수 계속")
                    ),
                    Map.of(
                            "flowStep", "safety",
                            "requiredFields", List.of("safetyContinue"),
                            "submitAllowed", true,
                            "requiresExplicitConfirm", false
                    )
            );
            return new ChatTurnPlan(
                    safeHandoffMessage.isBlank()
                            ? "위협·폭행 우려가 있으면 112 신고가 우선입니다.\n안전 안내를 확인한 뒤 계속 진행할 수 있어요."
                            : safeHandoffMessage,
                    uiHint,
                    "COLLECT_SLOT",
                    Map.of()
            );
        }

        if (containsAnyRequiredField(requiredFields, TRIAGE_SLOTS)) {
            return new ChatTurnPlan(
                    safeHandoffMessage.isBlank()
                            ? "힘드셨겠어요.\n현재 소음 상태와 안전 긴급도를 함께 선택해 주세요."
                            : safeHandoffMessage,
                    buildDeterministicIntakeHint(requiredFields),
                    "COLLECT_SLOT",
                    Map.of()
            );
        }

        if (containsAnyRequiredField(requiredFields, BASIC_INTAKE_SLOTS)) {
            return new ChatTurnPlan(
                    safeHandoffMessage.isBlank()
                            ? "좋아요. 기본 정보를 입력해 주세요."
                            : safeHandoffMessage,
                    buildDeterministicIntakeHint(requiredFields),
                    "COLLECT_SLOT",
                    Map.of()
            );
        }

        if (containsAnyRequiredField(requiredFields, DETAIL_INTAKE_SLOTS)) {
            return new ChatTurnPlan(
                    safeHandoffMessage.isBlank()
                            ? "좋아요. 소음 패턴과 시작 시점을 입력해 주세요."
                            : safeHandoffMessage,
                    buildDeterministicIntakeHint(requiredFields),
                    "COLLECT_SLOT",
                    Map.of()
            );
        }

        return new ChatTurnPlan(
                "정리해드릴게요.",
                new ApiModels.ChatUiHint(
                        ApiModels.ChatUiType.SUMMARY_CARD,
                        ApiModels.ChatUiSelectionMode.NONE,
                        "요약 확인",
                        null,
                        List.of(),
                        Map.of(
                                "flowStep", "summary",
                                "requiredFields", List.of(),
                                "submitAllowed", true,
                                "requiresExplicitConfirm", false
                        )
                ),
                "COLLECT_SLOT",
                Map.of()
        );
    }

    private ApiModels.ChatUiHint buildDeterministicIntakeHint(List<String> requiredFields) {
        return new ApiModels.ChatUiHint(
                ApiModels.ChatUiType.LIST_PICKER,
                ApiModels.ChatUiSelectionMode.NONE,
                null,
                null,
                List.of(),
                Map.of(
                        "flowStep", "intake",
                        "requiredFields", List.copyOf(requiredFields),
                        "submitAllowed", false,
                        "requiresExplicitConfirm", false
                )
        );
    }

    private boolean containsAnyRequiredField(List<String> requiredFields, Set<String> targets) {
        for (String requiredField : requiredFields) {
            if (targets.contains(requiredField)) {
                return true;
            }
        }
        return false;
    }

    private List<String> sanitizeUiCapabilities(List<String> uiCapabilities) {
        if (uiCapabilities == null || uiCapabilities.isEmpty()) {
            return List.of();
        }
        return uiCapabilities.stream()
                .filter(value -> value != null && !value.isBlank())
                .map(value -> value.trim().toUpperCase(Locale.ROOT))
                .toList();
    }

    private String normalizeLastUiHintType(
            String rawLastUiHintType,
            ApiModels.ChatTurnInteraction interaction
    ) {
        if (rawLastUiHintType != null && !rawLastUiHintType.isBlank()) {
            return rawLastUiHintType.trim().toUpperCase(Locale.ROOT);
        }
        if (interaction != null && interaction.sourceUiType() != null) {
            return interaction.sourceUiType().name();
        }
        return "NONE";
    }

    private List<ApiModels.ChatTurnHistoryMessage> sanitizeRecentMessages(
            List<ApiModels.ChatTurnHistoryMessage> recentMessages
    ) {
        if (recentMessages == null || recentMessages.isEmpty()) {
            return List.of();
        }
        return recentMessages.stream()
                .filter(message -> message != null
                        && message.text() != null
                        && !message.text().isBlank())
                .map(message -> new ApiModels.ChatTurnHistoryMessage(
                        message.role() == null || message.role().isBlank()
                                ? "UNKNOWN"
                                : message.role().trim().toUpperCase(Locale.ROOT),
                        message.text().trim(),
                        message.source() == null || message.source().isBlank()
                                ? "UNKNOWN"
                                : message.source().trim()
                ))
                .limit(12)
                .toList();
    }

    private String inferFlowStepHint(ApiModels.CaseDetail detail) {
        ApiModels.CaseStatus status = detail.status();
        String action = detail.currentActionRequired() == null ? "" : detail.currentActionRequired();

        if (status == ApiModels.CaseStatus.RECEIVED) {
            if ("GENERAL_CHAT".equalsIgnoreCase(action)) {
                return "general_chat";
            }
            return "intake";
        }
        if (status == ApiModels.CaseStatus.CLASSIFIED && "CONFIRM_ROUTE".equals(action)) {
            return "path_choice";
        }
        if (status == ApiModels.CaseStatus.ROUTE_CONFIRMED
                || status == ApiModels.CaseStatus.EVIDENCE_COLLECTING
                || status == ApiModels.CaseStatus.FORMAL_SUBMISSION_READY) {
            return "evidence_or_submit";
        }
        if (status == ApiModels.CaseStatus.INSTITUTION_PROCESSING
                || status == ApiModels.CaseStatus.SUPPLEMENT_REQUIRED
                || status == ApiModels.CaseStatus.COMPLETED
                || status == ApiModels.CaseStatus.CLOSED) {
            return "status_tracking";
        }
        return "general";
    }

    private InteractionApplyResult applyUserInteractionDeterministically(
            UUID caseId,
            ApiModels.CaseDetail detail,
            ApiModels.ChatTurnInteraction interaction,
            String fallbackUserMessage
    ) {
        if (interaction == null) {
            return new InteractionApplyResult(detail, null, null);
        }

        List<String> selectedIds = normalizeSelectionIds(interaction.selectedOptionIds());
        List<String> selectedLabels = normalizeSelectionLabels(interaction.selectedOptionLabels());
        String interactionMessage = selectedLabels.isEmpty()
                ? fallbackUserMessage
                : String.join(" ", selectedLabels);
        Map<String, Object> structuredSlots = extractStructuredIntakeSlots(interaction);

        try {
            if (detail.status() == ApiModels.CaseStatus.RECEIVED) {
                if (isGeneralChatMode(detail)) {
                    if (!shouldActivateIntakeMode(interactionMessage, List.of())) {
                        return new InteractionApplyResult(
                                detail,
                                null,
                                "접수를 시작하려면 접수 진행 의사를 알려주세요."
                        );
                    }
                    detail = activateIntakeMode(caseId, detail);
                }

                if (!structuredSlots.isEmpty()) {
                    mergeIntakeSlots(caseId, structuredSlots);
                    detail = getCase(caseId);
                }

                if ((interactionMessage == null || interactionMessage.isBlank()) && structuredSlots.isEmpty()) {
                    return new InteractionApplyResult(detail, null, "선택 항목을 다시 전달해 주세요.");
                }

                ApiModels.IntakeUpdateResponse intakeUpdate = null;
                ApiModels.CaseDetail updatedDetail;
                if (interactionMessage != null && !interactionMessage.isBlank()) {
                    intakeUpdate = appendIntakeMessage(
                            caseId,
                            new ApiModels.AppendIntakeMessageRequest(ApiModels.MessageRole.USER, interactionMessage)
                    );
                    updatedDetail = getCase(caseId);
                } else {
                    updatedDetail = getCase(caseId);
                    if (updatedDetail.intake() != null) {
                        intakeUpdate = new ApiModels.IntakeUpdateResponse(
                                updatedDetail.caseId(),
                                updatedDetail.status(),
                                updatedDetail.intake(),
                                "",
                                null
                        );
                    }
                }
                if (updatedDetail.status() != ApiModels.CaseStatus.RECEIVED) {
                    updatedDetail = ensureRoutingPrepared(caseId, updatedDetail);
                }
                return new InteractionApplyResult(updatedDetail, intakeUpdate, null);
            }

            ApiModels.CaseDetail current = detail;
            String sourceUiType = interaction.sourceUiType() == null
                    ? "NONE"
                    : interaction.sourceUiType().name();

            if ("PATH_CHOOSER".equalsIgnoreCase(sourceUiType)
                    || "CONFIRM_ROUTE".equals(current.currentActionRequired())) {
                String selectedOptionId = selectedIds.isEmpty() ? null : selectedIds.getFirst();
                if (selectedOptionId == null || selectedOptionId.isBlank()) {
                    selectedOptionId = resolveRouteOptionIdByMessage(
                            current,
                            selectedLabels.isEmpty() ? interactionMessage : selectedLabels.getFirst()
                    );
                }
                if (selectedOptionId == null || selectedOptionId.isBlank()) {
                    return new InteractionApplyResult(current, null, "경로를 다시 선택해 주세요.");
                }
                confirmRouteDecision(
                        caseId,
                        new ApiModels.RouteDecisionRequest(selectedOptionId, true, "chat-interaction-confirm-route")
                );
                return new InteractionApplyResult(getCase(caseId), null, null);
            }

            if ("STATUS_FEED".equalsIgnoreCase(sourceUiType)
                    || current.status() == ApiModels.CaseStatus.INSTITUTION_PROCESSING
                    || current.status() == ApiModels.CaseStatus.SUPPLEMENT_REQUIRED
                    || current.status() == ApiModels.CaseStatus.COMPLETED
                    || current.status() == ApiModels.CaseStatus.CLOSED) {
                List<String> actionIds = selectedIds.isEmpty()
                        ? inferActionIdsFromLabels(selectedLabels)
                        : selectedIds;
                if (actionIds.contains("status-refresh")) {
                    return new InteractionApplyResult(getCase(caseId), null, "최신 진행 상태를 불러왔어요.");
                }
                if (actionIds.contains("status-restart")) {
                    return new InteractionApplyResult(getCase(caseId), null, "새 민원 접수를 시작하려면 채팅을 새로 열어 주세요.");
                }
            }

            if (isEvidenceOrSubmissionState(current.status())) {
                List<String> actionIds = selectedIds.isEmpty()
                        ? inferActionIdsFromLabels(selectedLabels)
                        : selectedIds;
                if (actionIds.isEmpty()) {
                    return new InteractionApplyResult(current, null, "선택 항목을 확인해 주세요.");
                }

                boolean executed = false;
                for (String actionId : actionIds) {
                    if ("evidence-audio".equalsIgnoreCase(actionId)) {
                        registerEvidence(caseId, buildDemoEvidenceRequest(ApiModels.EvidenceType.AUDIO, "demo-audio.m4a", "audio/m4a"));
                        executed = true;
                    } else if ("evidence-video".equalsIgnoreCase(actionId)) {
                        registerEvidence(caseId, buildDemoEvidenceRequest(ApiModels.EvidenceType.IMAGE, "demo-video.mp4", "video/mp4"));
                        executed = true;
                    } else if ("evidence-log".equalsIgnoreCase(actionId)) {
                        registerEvidence(caseId, buildDemoEvidenceRequest(ApiModels.EvidenceType.LOG, "demo-noise-log.json", "application/json"));
                        executed = true;
                    } else if ("submit-confirm".equalsIgnoreCase(actionId) || "submit-now".equalsIgnoreCase(actionId)) {
                        if (!hasExplicitSubmitConfirm(interaction)) {
                            return new InteractionApplyResult(
                                    getCase(caseId),
                                    null,
                                    "최종 제출 전 한 번 더 확인해 주세요."
                            );
                        }
                        submitCase(
                                caseId,
                                new ApiModels.SubmitCaseRequest(
                                        ApiModels.SubmissionChannel.MCP_API,
                                        true,
                                        true
                                )
                        );
                        executed = true;
                    } else if ("supplement-done".equalsIgnoreCase(actionId)) {
                        respondSupplement(caseId, new ApiModels.SupplementResponseRequest("채팅에서 보완자료 제출 완료", List.of()));
                        executed = true;
                    }
                }

                if (!executed) {
                    return new InteractionApplyResult(getCase(caseId), null, "선택 항목을 현재 단계에서 처리할 수 없어요.");
                }
                return new InteractionApplyResult(getCase(caseId), null, null);
            }
        } catch (ApiException ex) {
            return new InteractionApplyResult(getCase(caseId), null, "현재 단계와 맞지 않는 요청입니다. 다시 확인해 주세요.");
        }

        return new InteractionApplyResult(detail, null, null);
    }

    private Map<String, Object> extractStructuredIntakeSlots(ApiModels.ChatTurnInteraction interaction) {
        if (interaction == null || interaction.meta() == null || interaction.meta().isEmpty()) {
            return Map.of();
        }
        Object rawFilledSlots = interaction.meta().get("filledSlots");
        if (!(rawFilledSlots instanceof Map<?, ?> rawMap) || rawMap.isEmpty()) {
            return Map.of();
        }

        Map<String, Object> slots = new HashMap<>();
        putAllowedSlot(slots, "noiseNow", rawMap.get("noiseNow"), Set.of("지금 진행 중", "방금 멈춤", "자주 반복"));
        putAllowedSlot(slots, "safety", rawMap.get("safety"), Set.of("위협 징후 없음", "잘 모르겠음", SAFETY_DANGER));
        putAllowedSlot(slots, "residence", rawMap.get("residence"), Set.of("아파트", "빌라", "오피스텔", "기타"));
        putAllowedSlot(slots, "management", rawMap.get("management"), Set.of("있음", "없음", "모름"));
        putAllowedSlot(slots, "sourceCertainty", rawMap.get("sourceCertainty"), Set.of("호수까지 확실", "층은 확실(호수 불명)", "모름"));
        putAllowedSlot(slots, "noiseType", rawMap.get("noiseType"), Set.of("충격 소음(쿵쿵)", "공기전달 소음(TV/음악)", "둘 다", "잘 모르겠음"));
        putAllowedSlot(slots, "frequency", rawMap.get("frequency"), Set.of("주 1회 이하", "주 2~3회", "거의 매일", "불규칙"));
        putAllowedSlot(slots, "timeBand", rawMap.get("timeBand"), Set.of("저녁", "심야", "새벽", "불규칙"));

        String startedAt = toTrimmedString(rawMap.get("startedAt"));
        if (startedAt != null) {
            slots.put("startedAt", startedAt);
        }
        return slots;
    }

    private void putAllowedSlot(
            Map<String, Object> target,
            String key,
            Object rawValue,
            Set<String> allowedValues
    ) {
        String value = toTrimmedString(rawValue);
        if (value == null) {
            return;
        }
        if (allowedValues.contains(value)) {
            target.put(key, value);
        }
    }

    private String toTrimmedString(Object rawValue) {
        if (rawValue == null) {
            return null;
        }
        String value = String.valueOf(rawValue).trim();
        return value.isEmpty() ? null : value;
    }

    private void mergeIntakeSlots(UUID caseId, Map<String, Object> structuredSlots) {
        if (structuredSlots.isEmpty()) {
            return;
        }
        CaseAggregate aggregate = loadAggregate(caseId);
        aggregate.filledSlots.putAll(structuredSlots);
        persistCase(aggregate);
    }

    private boolean isGeneralChatMode(ApiModels.CaseDetail detail) {
        return detail.status() == ApiModels.CaseStatus.RECEIVED
                && "GENERAL_CHAT".equalsIgnoreCase(detail.currentActionRequired());
    }

    private boolean shouldActivateIntakeMode(
            String userMessage,
            List<ApiModels.ChatTurnHistoryMessage> recentMessages
    ) {
        if (userMessage == null || userMessage.isBlank()) {
            return false;
        }
        String normalized = userMessage.replaceAll("\\s+", "").toLowerCase(Locale.ROOT);
        for (String token : INTAKE_ACTIVATION_TOKENS) {
            if (normalized.contains(token.replaceAll("\\s+", "").toLowerCase(Locale.ROOT))) {
                return true;
            }
        }

        for (String token : INTAKE_INTENT_HINT_TOKENS) {
            if (normalized.contains(token.replaceAll("\\s+", "").toLowerCase(Locale.ROOT))) {
                return true;
            }
        }

        if (AFFIRMATIVE_TOKENS.contains(userMessage.trim())
                || AFFIRMATIVE_TOKENS.contains(normalized)) {
            for (int i = recentMessages.size() - 1; i >= 0; i--) {
                ApiModels.ChatTurnHistoryMessage message = recentMessages.get(i);
                if (!"ASSISTANT".equalsIgnoreCase(message.role())) {
                    continue;
                }
                String assistantText = message.text() == null ? "" : message.text();
                String assistantNormalized = assistantText.replaceAll("\\s+", "").toLowerCase(Locale.ROOT);
                if (assistantNormalized.contains("진행할까요")
                        || assistantNormalized.contains("접수를도와드릴수있어요")
                        || assistantNormalized.contains("접수도와드릴수있어요")) {
                    return true;
                }
                break;
            }
        }
        return false;
    }

    private ApiModels.CaseDetail activateIntakeMode(UUID caseId, ApiModels.CaseDetail detail) {
        if (!isGeneralChatMode(detail)) {
            return detail;
        }
        CaseAggregate aggregate = loadAggregate(caseId);
        if (!"GENERAL_CHAT".equalsIgnoreCase(aggregate.caseEntity.getCurrentActionRequired())) {
            return toCaseDetail(aggregate);
        }
        aggregate.caseEntity.setCurrentActionRequired("INTAKE_REQUIRED");
        persistCase(aggregate);
        return toCaseDetail(aggregate);
    }

    private ApiModels.CaseDetail ensureRoutingPrepared(UUID caseId, ApiModels.CaseDetail detail) {
        ApiModels.CaseDetail current = detail;

        if (current.status() == ApiModels.CaseStatus.CLASSIFIED
                && "REQUEST_DECOMPOSITION".equals(current.currentActionRequired())) {
            decomposeCase(caseId);
            current = getCase(caseId);
        }

        if (current.status() == ApiModels.CaseStatus.CLASSIFIED
                && "REQUEST_ROUTING_RECOMMENDATION".equals(current.currentActionRequired())) {
            recommendRoute(caseId);
            current = getCase(caseId);
        }

        return current;
    }

    private ApiModels.CaseDetail applyPostIntakeChatAction(
            UUID caseId,
            ApiModels.CaseDetail detail,
            String userMessage
    ) {
        String message = userMessage == null ? "" : userMessage.trim();
        if (message.isEmpty()) {
            return detail;
        }

        ApiModels.CaseDetail current = detail;
        String normalized = message.replaceAll("\\s+", "").toLowerCase();

        if (current.status() == ApiModels.CaseStatus.CLASSIFIED
                && "CONFIRM_ROUTE".equals(current.currentActionRequired())) {
            String selectedOptionId = resolveRouteOptionIdByMessage(current, message);
            if (selectedOptionId != null) {
                confirmRouteDecision(
                        caseId,
                        new ApiModels.RouteDecisionRequest(selectedOptionId, true, "chat-turn-confirm-route")
                );
                current = getCase(caseId);
            }
        }

        if (current.status() == ApiModels.CaseStatus.ROUTE_CONFIRMED
                || current.status() == ApiModels.CaseStatus.EVIDENCE_COLLECTING
                || current.status() == ApiModels.CaseStatus.FORMAL_SUBMISSION_READY) {

            if (containsAny(normalized, "녹음파일첨부", "녹음파일", "오디오첨부", "audioupload", "audio")) {
                registerEvidence(caseId, buildDemoEvidenceRequest(ApiModels.EvidenceType.AUDIO, "demo-audio.m4a", "audio/m4a"));
                current = getCase(caseId);
            } else if (containsAny(normalized, "동영상첨부", "영상첨부", "동영상", "영상", "videoupload", "video")) {
                registerEvidence(caseId, buildDemoEvidenceRequest(ApiModels.EvidenceType.IMAGE, "demo-video.mp4", "video/mp4"));
                current = getCase(caseId);
            } else if (containsAny(normalized, "소음일지첨부", "소음일지", "로그첨부", "logupload")) {
                registerEvidence(caseId, buildDemoEvidenceRequest(ApiModels.EvidenceType.LOG, "demo-noise-log.json", "application/json"));
                current = getCase(caseId);
            }

            if (containsAny(normalized, "바로제출", "제출하기", "정부24연계", "submitnow", "submit")) {
                submitCase(
                        caseId,
                        new ApiModels.SubmitCaseRequest(
                                ApiModels.SubmissionChannel.MCP_API,
                                true,
                                true
                        )
                );
                current = getCase(caseId);
            }
        }

        if (current.status() == ApiModels.CaseStatus.SUPPLEMENT_REQUIRED
                && containsAny(normalized, "보완자료제출", "보완제출", "보완완료", "supplement")) {
            respondSupplement(caseId, new ApiModels.SupplementResponseRequest("채팅에서 보완자료 제출 완료", List.of()));
            current = getCase(caseId);
        }

        return current;
    }

    private ApiModels.RegisterEvidenceRequest buildDemoEvidenceRequest(
            ApiModels.EvidenceType type,
            String fileName,
            String mimeType
    ) {
        return new ApiModels.RegisterEvidenceRequest(
                type,
                "demo/" + type.name().toLowerCase() + "/" + UUID.randomUUID(),
                fileName,
                mimeType,
                1024L,
                Instant.now(),
                "chat-turn demo evidence"
        );
    }

    private boolean isEvidenceOrSubmissionState(ApiModels.CaseStatus status) {
        return status == ApiModels.CaseStatus.ROUTE_CONFIRMED
                || status == ApiModels.CaseStatus.EVIDENCE_COLLECTING
                || status == ApiModels.CaseStatus.FORMAL_SUBMISSION_READY
                || status == ApiModels.CaseStatus.SUPPLEMENT_REQUIRED;
    }

    private List<String> normalizeSelectionIds(List<String> selectedIds) {
        if (selectedIds == null || selectedIds.isEmpty()) {
            return List.of();
        }
        return selectedIds.stream()
                .filter(value -> value != null && !value.isBlank())
                .map(String::trim)
                .toList();
    }

    private List<String> normalizeSelectionLabels(List<String> selectedLabels) {
        if (selectedLabels == null || selectedLabels.isEmpty()) {
            return List.of();
        }
        return selectedLabels.stream()
                .filter(value -> value != null && !value.isBlank())
                .map(String::trim)
                .toList();
    }

    private boolean hasExplicitSubmitConfirm(ApiModels.ChatTurnInteraction interaction) {
        if (interaction == null) {
            return false;
        }
        if (interaction.interactionType() == ApiModels.ChatInteractionType.SYSTEM_CONFIRM) {
            return true;
        }
        Map<String, Object> meta = interaction.meta();
        if (meta == null || meta.isEmpty()) {
            return false;
        }
        Object confirmed = meta.get("confirmed");
        if (confirmed instanceof Boolean value) {
            return value;
        }
        return confirmed != null && "true".equalsIgnoreCase(confirmed.toString());
    }

    private List<String> inferActionIdsFromLabels(List<String> labels) {
        if (labels == null || labels.isEmpty()) {
            return List.of();
        }
        List<String> actionIds = new ArrayList<>();
        for (String label : labels) {
            String normalized = label.replaceAll("\\s+", "").toLowerCase(Locale.ROOT);
            if (containsAny(normalized, "녹음파일첨부", "녹음파일", "오디오첨부", "audio")) {
                actionIds.add("evidence-audio");
            } else if (containsAny(normalized, "동영상첨부", "영상첨부", "동영상", "영상", "video")) {
                actionIds.add("evidence-video");
            } else if (containsAny(normalized, "소음일지첨부", "소음일지", "로그첨부", "log")) {
                actionIds.add("evidence-log");
            } else if (containsAny(normalized, "제출진행확인", "바로제출", "제출하기", "정부24연계", "submit")) {
                actionIds.add("submit-confirm");
            } else if (containsAny(normalized, "보완제출", "보완완료", "supplement")) {
                actionIds.add("supplement-done");
            } else if (containsAny(normalized, "상태새로고침", "새로고침", "refresh")) {
                actionIds.add("status-refresh");
            } else if (containsAny(normalized, "처음으로돌아가기", "다시시작", "restart")) {
                actionIds.add("status-restart");
            }
        }
        return List.copyOf(actionIds);
    }

    private String resolveRouteOptionIdByMessage(ApiModels.CaseDetail detail, String userMessage) {
        ApiModels.RoutingRecommendation routing = detail.routing();
        if (routing == null || routing.options() == null || routing.options().isEmpty()) {
            return null;
        }

        String trimmed = userMessage == null ? "" : userMessage.trim();
        if (trimmed.isEmpty()) {
            return null;
        }

        for (ApiModels.RoutingOption option : routing.options()) {
            if (trimmed.equalsIgnoreCase(option.optionId())) {
                return option.optionId();
            }
        }

        String normalized = trimmed.replaceAll("\\s+", "").toLowerCase();
        for (ApiModels.RoutingOption option : routing.options()) {
            String labelNormalized = option.label() == null
                    ? ""
                    : option.label().replaceAll("\\s+", "").toLowerCase();
            if (!labelNormalized.isEmpty() && normalized.equals(labelNormalized)) {
                return option.optionId();
            }
        }

        return null;
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
        String housingType = aggregate.caseEntity.getHousingType() == null
                ? ""
                : aggregate.caseEntity.getHousingType().trim();
        String residenceSlot = Objects.toString(aggregate.filledSlots.get("residence"), "").trim();
        String managementSlot = Objects.toString(aggregate.filledSlots.get("management"), "").trim();
        boolean managementOfficeUnavailable = "없음".equals(managementSlot);
        boolean hasResidenceSlot = !residenceSlot.isBlank();
        boolean apartmentRouteEligible = hasResidenceSlot
                ? "아파트".equals(residenceSlot)
                : "APARTMENT".equalsIgnoreCase(housingType);
        boolean neighborCenterEligible = hasResidenceSlot
                ? ("아파트".equals(residenceSlot) || "빌라".equals(residenceSlot) || "오피스텔".equals(residenceSlot))
                : ("APARTMENT".equalsIgnoreCase(housingType)
                || "VILLA".equalsIgnoreCase(housingType)
                || "OFFICETEL".equalsIgnoreCase(housingType));

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

        if (apartmentRouteEligible && !managementOfficeUnavailable) {
            options.add(new ApiModels.RoutingOption(
                    "opt-management-office",
                    ApiModels.RoutingChannelType.MANAGEMENT_OFFICE,
                    "관리사무소 조정 요청",
                    2,
                    "관리주체가 있는 경우 우선 시도할 수 있는 1차 조정 채널입니다.",
                    List.of("소음 일지", "녹음 파일")
            ));
        }

        if (neighborCenterEligible) {
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

    private UUID resolveCaseIdForChatTurn(ApiModels.ChatTurnRequest request, String userMessage, String ownerSubject) {
        ApiModels.ChatTurnContext context = request.context();
        String rawCaseId = context == null ? null : context.caseId();
        if (rawCaseId != null && !rawCaseId.isBlank()) {
            try {
                return UUID.fromString(rawCaseId.trim());
            } catch (IllegalArgumentException ex) {
                throw ApiException.badRequest(
                        "VALIDATION_ERROR",
                        "Invalid context.caseId format.",
                        List.of("context.caseId must be UUID")
                );
            }
        }

        String scenarioType = context == null || context.scenarioType() == null || context.scenarioType().isBlank()
                ? DEFAULT_SCENARIO_TYPE
                : context.scenarioType().trim();
        String housingType = context == null || context.housingType() == null || context.housingType().isBlank()
                ? DEFAULT_HOUSING_TYPE
                : context.housingType().trim();
        boolean consentAccepted = context == null || !Boolean.FALSE.equals(context.consentAccepted());

        ApiModels.CaseDetail created = createCase(new ApiModels.CreateCaseRequest(
                scenarioType,
                housingType,
                consentAccepted,
                userMessage
        ), ownerSubject);

        return created.caseId();
    }

    private String resolveAssistantMessage(
            ApiModels.IntakeUpdateResponse intakeUpdate,
            ApiModels.CaseDetail detail,
            String userMessage
    ) {
        if (intakeUpdate != null) {
            String followUp = intakeUpdate.recommendedFollowUpQuestion();
            if (followUp != null && !followUp.isBlank()) {
                return followUp;
            }
        }

        return switch (detail.status()) {
            case RECEIVED -> "추가 정보를 입력해 주세요.";
            case CLASSIFIED -> "추천 경로를 준비했어요. 진행 방식을 선택해 주세요.";
            case ROUTE_CONFIRMED, EVIDENCE_COLLECTING -> "증거를 첨부하거나 바로 제출할 수 있어요.";
            case FORMAL_SUBMISSION_READY -> "제출 준비가 완료됐어요. 제출을 진행해 주세요.";
            case INSTITUTION_PROCESSING -> "접수 완료 후 기관 처리 중이에요. 진행 상태를 확인해 주세요.";
            case SUPPLEMENT_REQUIRED -> "보완자료 요청이 있어요. 보완 후 다시 제출해 주세요.";
            case COMPLETED, CLOSED -> "처리가 완료되었습니다.";
            default -> "다음 단계를 진행해 주세요.";
        };
    }

    private ApiModels.ChatUiHint toChatUiHint(
            ApiModels.FollowUpInterface followUpInterface,
            ApiModels.CaseDetail detail
    ) {
        if (detail.status() == ApiModels.CaseStatus.RECEIVED && followUpInterface != null) {
            List<ApiModels.ChatUiOption> options = new ArrayList<>();
            if (followUpInterface.options() != null) {
                for (ApiModels.FollowUpOption option : followUpInterface.options()) {
                    options.add(new ApiModels.ChatUiOption(option.optionId(), option.label()));
                }
            }

            List<String> requiredFields = detail.intake() == null || detail.intake().filledSlots() == null
                    ? List.of()
                    : missingSlots(detail.intake().filledSlots());

            return new ApiModels.ChatUiHint(
                    followUpInterface.interfaceType() == ApiModels.FollowUpInterfaceType.DATE
                            ? ApiModels.ChatUiType.OPTION_LIST
                            : ApiModels.ChatUiType.LIST_PICKER,
                    switch (followUpInterface.selectionMode()) {
                        case MULTIPLE -> ApiModels.ChatUiSelectionMode.MULTIPLE;
                        case SINGLE -> ApiModels.ChatUiSelectionMode.SINGLE;
                    },
                    null,
                    null,
                    options,
                    Map.of(
                            "flowStep", "intake",
                            "requiredFields", requiredFields,
                            "submitAllowed", false,
                            "requiresExplicitConfirm", false
                    )
            );
        }

        return switch (detail.status()) {
            case CLASSIFIED -> buildPathChooserHint(detail);
            case ROUTE_CONFIRMED, EVIDENCE_COLLECTING, FORMAL_SUBMISSION_READY -> buildEvidenceAndSubmitHint(detail);
            case INSTITUTION_PROCESSING, SUPPLEMENT_REQUIRED, COMPLETED, CLOSED -> buildStatusFeedHint(detail);
            default -> new ApiModels.ChatUiHint(
                    ApiModels.ChatUiType.NONE,
                    ApiModels.ChatUiSelectionMode.NONE,
                    null,
                    null,
                    List.of(),
                    Map.of()
            );
        };
    }

    private ApiModels.ChatUiHint buildPathChooserHint(ApiModels.CaseDetail detail) {
        List<ApiModels.ChatUiOption> options = new ArrayList<>();
        ApiModels.RoutingRecommendation routing = detail.routing();
        if (routing != null && routing.options() != null) {
            for (ApiModels.RoutingOption option : routing.options()) {
                if (option.optionId() == null || option.optionId().isBlank()) {
                    continue;
                }
                if (option.label() == null || option.label().isBlank()) {
                    continue;
                }
                options.add(new ApiModels.ChatUiOption(option.optionId(), option.label()));
            }
        }

        return new ApiModels.ChatUiHint(
                ApiModels.ChatUiType.PATH_CHOOSER,
                ApiModels.ChatUiSelectionMode.SINGLE,
                "추천 경로",
                "진행 방식을 선택해 주세요.",
                List.copyOf(options),
                Map.of("flowStep", "pathChooser")
        );
    }

    private ApiModels.ChatUiHint buildEvidenceAndSubmitHint(ApiModels.CaseDetail detail) {
        List<ApiModels.ChatUiOption> options = List.of(
                new ApiModels.ChatUiOption("evidence-audio", "녹음 파일 첨부"),
                new ApiModels.ChatUiOption("evidence-video", "동영상 첨부"),
                new ApiModels.ChatUiOption("evidence-log", "소음 일지 첨부"),
                new ApiModels.ChatUiOption("submit-now", "바로 제출")
        );

        return new ApiModels.ChatUiHint(
                ApiModels.ChatUiType.OPTION_LIST,
                ApiModels.ChatUiSelectionMode.SINGLE,
                "증거 제출",
                "필요한 항목을 선택해 주세요.",
                options,
                Map.of(
                        "flowStep", "evidence",
                        "status", detail.status().name()
                )
        );
    }

    private ApiModels.ChatUiHint buildStatusFeedHint(ApiModels.CaseDetail detail) {
        List<ApiModels.ChatUiOption> options = List.of(
                new ApiModels.ChatUiOption("status-refresh", "상태 새로고침"),
                new ApiModels.ChatUiOption("status-restart", "처음으로 돌아가기")
        );

        return new ApiModels.ChatUiHint(
                ApiModels.ChatUiType.STATUS_FEED,
                ApiModels.ChatUiSelectionMode.SINGLE,
                "진행 상태",
                "현재 처리 상태를 확인할 수 있어요.",
                options,
                Map.of(
                        "flowStep", "statusFeed",
                        "status", detail.status().name()
                )
        );
    }

    private String resolveNextAction(ApiModels.CaseDetail detail) {
        if (detail.currentActionRequired() != null && !detail.currentActionRequired().isBlank()) {
            return detail.currentActionRequired();
        }

        return switch (detail.status()) {
            case RECEIVED -> "INTAKE_REQUIRED";
            case CLASSIFIED -> "REQUEST_DECOMPOSITION";
            case ROUTE_CONFIRMED, EVIDENCE_COLLECTING -> "OPTIONAL_EVIDENCE_OR_SUBMIT";
            case FORMAL_SUBMISSION_READY -> "SUBMIT_CASE";
            case INSTITUTION_PROCESSING -> "WAIT_INSTITUTION_RESULT";
            case SUPPLEMENT_REQUIRED -> "RESPOND_SUPPLEMENT";
            case COMPLETED -> "CLOSE_CASE";
            case CLOSED -> "DONE";
            default -> "NONE";
        };
    }

    private ApiModels.CaseSummary toCaseSummary(CaseEntity entity) {
        return new ApiModels.CaseSummary(
                entity.getId(),
                entity.getStatus(),
                entity.getRiskLevel(),
                entity.getCreatedAt(),
                entity.getUpdatedAt()
        );
    }

    private String normalizeOwnerSubject(String ownerSubject) {
        if (ownerSubject == null || ownerSubject.isBlank()) {
            return "anonymous";
        }
        return ownerSubject.trim();
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
        String compact = trimmed.replaceAll("\\s+", "");

        if (equalsAny(trimmed, "생활소음 접수 계속")
                || containsAny(trimmed, "접수 계속", "계속 진행")
                || containsAnyCompact(compact, "생활소음접수계속", "접수계속", "계속진행")) {
            filledSlots.put("safetyContinue", true);
        }

        if (equalsAny(trimmed, "지금 진행 중")) {
            filledSlots.put("noiseNow", "지금 진행 중");
        } else if (equalsAny(trimmed, "방금 멈춤")) {
            filledSlots.put("noiseNow", "방금 멈춤");
        } else if (equalsAny(trimmed, "자주 반복")) {
            filledSlots.put("noiseNow", "자주 반복");
        } else if (containsAny(trimmed, "지금도", "현재도", "진행 중")
                || containsAnyCompact(compact, "현재소음상태지금진행중", "현재소음상태방금멈춤", "현재소음상태자주반복", "방금멈춤", "자주반복")) {
            if (containsAnyCompact(compact, "방금멈춤")) {
                filledSlots.put("noiseNow", "방금 멈춤");
            } else if (containsAnyCompact(compact, "자주반복")) {
                filledSlots.put("noiseNow", "자주 반복");
            } else {
                filledSlots.put("noiseNow", "지금 진행 중");
            }
        } else if (containsAnyCompact(compact, "현재소음상태지금진행중")) {
            filledSlots.put("noiseNow", "지금 진행 중");
        }

        if (equalsAny(trimmed, "위협 징후 없음", "없음(생활소음)")) {
            filledSlots.put("safety", "위협 징후 없음");
        } else if (containsAny(trimmed, "위협 징후 없음", "안전 문제 없음")
                || containsAnyCompact(compact, "안전긴급도위협징후없음", "위협징후없음", "안전문제없음")) {
            filledSlots.put("safety", "위협 징후 없음");
        } else if (equalsAny(trimmed, "잘 모르겠음")) {
            filledSlots.put("safety", "잘 모르겠음");
        } else if (containsAny(trimmed, "안전은 잘 모르겠", "위험 여부는 잘 모르겠")
                || containsAnyCompact(compact, "안전긴급도잘모르겠음", "위험여부잘모르겠", "안전잘모르겠")) {
            filledSlots.put("safety", "잘 모르겠음");
        } else if (equalsAny(trimmed, "위협 징후 있음", "있음(위험)")) {
            filledSlots.put("safety", SAFETY_DANGER);
        } else if (containsAny(trimmed, "폭행", "스토킹", "칼", "죽이", "협박", "기물파손")
                || containsAny(trimmed, "위협 징후 있음")
                || containsAnyCompact(compact, "안전긴급도위협징후있음", "위협징후있음", "있음위험")) {
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
        } else if (containsAnyCompact(compact, "거주형태기타", "주거형태기타")) {
            filledSlots.put("residence", "기타");
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
        } else if (containsAnyCompact(compact, "소음유형둘다", "둘다")) {
            filledSlots.put("noiseType", "둘 다");
        } else if (containsAnyCompact(compact, "소음유형잘모르겠음", "소음유형모름")) {
            filledSlots.put("noiseType", "잘 모르겠음");
        } else if (containsAny(trimmed, "쿵", "발망치", "뛰", "의자", "가구")) {
            filledSlots.put("noiseType", "충격 소음(쿵쿵)");
        } else if (containsAny(trimmed, "tv", "음악", "오디오", "스피커")) {
            filledSlots.put("noiseType", "공기전달 소음(TV/음악)");
        }

        if (equalsAny(trimmed, "거의 매일", "주 2~3회", "주 1회 이하", "불규칙")) {
            filledSlots.put("frequency", trimmed);
        } else if (containsAny(trimmed, "거의 매일", "매일")
                || containsAnyCompact(compact, "반복빈도거의매일")) {
            filledSlots.put("frequency", "거의 매일");
        } else if (containsAny(trimmed, "주 2", "주2", "주 3", "주3")
                || containsAnyCompact(compact, "반복빈도주2~3회", "반복빈도주2회", "반복빈도주3회")) {
            filledSlots.put("frequency", "주 2~3회");
        } else if (containsAny(trimmed, "주 1", "주1", "가끔")
                || containsAnyCompact(compact, "반복빈도주1회이하")) {
            filledSlots.put("frequency", "주 1회 이하");
        } else if (containsAny(trimmed, "불규칙")
                || containsAnyCompact(compact, "반복빈도불규칙")) {
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
        } else if (containsAnyCompact(compact, "주발생시간불규칙", "시간대불규칙")) {
            filledSlots.put("timeBand", "불규칙");
        }

        if (equalsAny(trimmed, "호수까지 확실", "층은 확실(호수 불명)", "모름")) {
            filledSlots.put("sourceCertainty", trimmed);
        } else if (containsAnyCompact(compact, "발생원특정모름", "발생원모름")) {
            filledSlots.put("sourceCertainty", "모름");
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

    private static boolean containsAnyCompact(String compactText, String... keywords) {
        String normalizedText = compactText == null ? "" : compactText.toLowerCase(Locale.ROOT);
        for (String keyword : keywords) {
            if (normalizedText.contains(keyword.toLowerCase(Locale.ROOT))) {
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

    private record InteractionApplyResult(
            ApiModels.CaseDetail detail,
            ApiModels.IntakeUpdateResponse intakeUpdate,
            String noticeMessage
    ) {
    }
}
