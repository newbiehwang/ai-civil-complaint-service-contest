package com.contest.complaint.api;

import com.contest.complaint.api.model.ApiModels;
import com.contest.complaint.application.CaseWorkflowService;
import com.contest.complaint.application.IdempotencyService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
public class ScenarioAApiController implements ScenarioAApi {

    private final CaseWorkflowService caseWorkflowService;
    private final IdempotencyService idempotencyService;

    public ScenarioAApiController(
            CaseWorkflowService caseWorkflowService,
            IdempotencyService idempotencyService
    ) {
        this.caseWorkflowService = caseWorkflowService;
        this.idempotencyService = idempotencyService;
    }

    @Override
    public ResponseEntity<ApiModels.CaseDetail> createCase(
            String traceId,
            String idempotencyKey,
            ApiModels.CreateCaseRequest request,
            Authentication authentication
    ) {
        String ownerSubject = resolveOwnerSubject(authentication);
        ApiModels.CaseDetail response = idempotencyService.execute(
                "CREATE_CASE",
                idempotencyKey,
                request,
                ApiModels.CaseDetail.class,
                () -> caseWorkflowService.createCase(request, ownerSubject)
        );
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @Override
    public ResponseEntity<ApiModels.CaseListResponse> listCases(String traceId, Authentication authentication) {
        String ownerSubject = resolveOwnerSubject(authentication);
        return ResponseEntity.ok(caseWorkflowService.listCasesByOwner(ownerSubject));
    }

    @Override
    public ResponseEntity<Void> deleteCase(String traceId, UUID caseId, Authentication authentication) {
        String ownerSubject = resolveOwnerSubject(authentication);
        caseWorkflowService.deleteCase(caseId, ownerSubject);
        return ResponseEntity.noContent().build();
    }

    @Override
    public ResponseEntity<ApiModels.CaseDetail> getCase(String traceId, UUID caseId) {
        return ResponseEntity.ok(caseWorkflowService.getCase(caseId));
    }

    @Override
    public ResponseEntity<ApiModels.IntakeUpdateResponse> appendIntakeMessage(String traceId, UUID caseId, ApiModels.AppendIntakeMessageRequest request) {
        return ResponseEntity.ok(caseWorkflowService.appendIntakeMessage(caseId, request));
    }

    @Override
    public ResponseEntity<ApiModels.ChatTurnResponse> chatTurn(
            String traceId,
            ApiModels.ChatTurnRequest request,
            Authentication authentication
    ) {
        String ownerSubject = resolveOwnerSubject(authentication);
        return ResponseEntity.ok(caseWorkflowService.chatTurn(traceId, request, ownerSubject));
    }

    @Override
    public ResponseEntity<ApiModels.DecompositionResult> decomposeCase(String traceId, UUID caseId) {
        return ResponseEntity.ok(caseWorkflowService.decomposeCase(caseId));
    }

    @Override
    public ResponseEntity<ApiModels.RoutingRecommendation> recommendRoute(String traceId, UUID caseId) {
        return ResponseEntity.ok(caseWorkflowService.recommendRoute(caseId));
    }

    @Override
    public ResponseEntity<ApiModels.CaseDetail> confirmRouteDecision(String traceId, UUID caseId, ApiModels.RouteDecisionRequest request) {
        return ResponseEntity.ok(caseWorkflowService.confirmRouteDecision(caseId, request));
    }

    @Override
    public ResponseEntity<ApiModels.EvidenceItem> registerEvidence(String traceId, UUID caseId, ApiModels.RegisterEvidenceRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(caseWorkflowService.registerEvidence(caseId, request));
    }

    @Override
    public ResponseEntity<ApiModels.EvidenceChecklist> getEvidenceChecklist(String traceId, UUID caseId) {
        return ResponseEntity.ok(caseWorkflowService.getEvidenceChecklist(caseId));
    }

    @Override
    public ResponseEntity<ApiModels.SubmissionResponse> submitCase(
            String traceId,
            String idempotencyKey,
            UUID caseId,
            ApiModels.SubmitCaseRequest request
    ) {
        ApiModels.SubmissionResponse response = idempotencyService.execute(
                "SUBMIT_CASE:" + caseId,
                idempotencyKey,
                request,
                ApiModels.SubmissionResponse.class,
                () -> caseWorkflowService.submitCase(caseId, request)
        );
        return ResponseEntity.status(HttpStatus.ACCEPTED).body(response);
    }

    @Override
    public ResponseEntity<ApiModels.CaseDetail> applyInstitutionMockEvent(
            String traceId,
            UUID caseId,
            ApiModels.InstitutionMockEventRequest request
    ) {
        return ResponseEntity.ok(caseWorkflowService.applyInstitutionMockEvent(caseId, request));
    }

    @Override
    public ResponseEntity<ApiModels.CaseDetail> respondSupplement(String traceId, UUID caseId, ApiModels.SupplementResponseRequest request) {
        return ResponseEntity.status(HttpStatus.ACCEPTED).body(caseWorkflowService.respondSupplement(caseId, request));
    }

    @Override
    public ResponseEntity<ApiModels.TimelineResponse> getTimeline(String traceId, UUID caseId) {
        return ResponseEntity.ok(caseWorkflowService.getTimeline(caseId));
    }

    private static String resolveOwnerSubject(Authentication authentication) {
        if (authentication == null || authentication.getName() == null || authentication.getName().isBlank()) {
            return "anonymous";
        }
        return authentication.getName().trim();
    }
}
