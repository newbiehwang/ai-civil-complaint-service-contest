package com.contest.complaint.api;

import com.contest.complaint.api.model.ApiModels;
import com.contest.complaint.application.CaseWorkflowService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
public class ScenarioAApiController implements ScenarioAApi {

    private final CaseWorkflowService caseWorkflowService;

    public ScenarioAApiController(CaseWorkflowService caseWorkflowService) {
        this.caseWorkflowService = caseWorkflowService;
    }

    @Override
    public ResponseEntity<ApiModels.CaseDetail> createCase(String traceId, String idempotencyKey, ApiModels.CreateCaseRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(caseWorkflowService.createCase(request));
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
    public ResponseEntity<ApiModels.SubmissionResponse> submitCase(String traceId, UUID caseId, ApiModels.SubmitCaseRequest request) {
        return ResponseEntity.status(HttpStatus.ACCEPTED).body(caseWorkflowService.submitCase(caseId, request));
    }

    @Override
    public ResponseEntity<ApiModels.CaseDetail> respondSupplement(String traceId, UUID caseId, ApiModels.SupplementResponseRequest request) {
        return ResponseEntity.status(HttpStatus.ACCEPTED).body(caseWorkflowService.respondSupplement(caseId, request));
    }

    @Override
    public ResponseEntity<ApiModels.TimelineResponse> getTimeline(String traceId, UUID caseId) {
        return ResponseEntity.ok(caseWorkflowService.getTimeline(caseId));
    }
}
