package com.contest.complaint.api;

import com.contest.complaint.api.model.ApiModels;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;

import java.util.UUID;

@RequestMapping("/api/v1")
public interface ScenarioAApi {

    @PostMapping("/cases")
    ResponseEntity<ApiModels.CaseDetail> createCase(
            @RequestHeader(value = "X-Trace-Id", required = false) String traceId,
            @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey,
            @Valid @RequestBody ApiModels.CreateCaseRequest request
    );

    @GetMapping("/cases/{caseId}")
    ResponseEntity<ApiModels.CaseDetail> getCase(
            @RequestHeader(value = "X-Trace-Id", required = false) String traceId,
            @PathVariable UUID caseId
    );

    @PostMapping("/cases/{caseId}/intake/messages")
    ResponseEntity<ApiModels.IntakeUpdateResponse> appendIntakeMessage(
            @RequestHeader(value = "X-Trace-Id", required = false) String traceId,
            @PathVariable UUID caseId,
            @Valid @RequestBody ApiModels.AppendIntakeMessageRequest request
    );

    @PostMapping("/chat/turn")
    ResponseEntity<ApiModels.ChatTurnResponse> chatTurn(
            @RequestHeader(value = "X-Trace-Id", required = false) String traceId,
            @Valid @RequestBody ApiModels.ChatTurnRequest request
    );

    @PostMapping("/cases/{caseId}/decomposition")
    ResponseEntity<ApiModels.DecompositionResult> decomposeCase(
            @RequestHeader(value = "X-Trace-Id", required = false) String traceId,
            @PathVariable UUID caseId
    );

    @PostMapping("/cases/{caseId}/routing/recommendation")
    ResponseEntity<ApiModels.RoutingRecommendation> recommendRoute(
            @RequestHeader(value = "X-Trace-Id", required = false) String traceId,
            @PathVariable UUID caseId
    );

    @PostMapping("/cases/{caseId}/routing/decision")
    ResponseEntity<ApiModels.CaseDetail> confirmRouteDecision(
            @RequestHeader(value = "X-Trace-Id", required = false) String traceId,
            @PathVariable UUID caseId,
            @Valid @RequestBody ApiModels.RouteDecisionRequest request
    );

    @PostMapping("/cases/{caseId}/evidence")
    ResponseEntity<ApiModels.EvidenceItem> registerEvidence(
            @RequestHeader(value = "X-Trace-Id", required = false) String traceId,
            @PathVariable UUID caseId,
            @Valid @RequestBody ApiModels.RegisterEvidenceRequest request
    );

    @GetMapping("/cases/{caseId}/evidence/checklist")
    ResponseEntity<ApiModels.EvidenceChecklist> getEvidenceChecklist(
            @RequestHeader(value = "X-Trace-Id", required = false) String traceId,
            @PathVariable UUID caseId
    );

    @PostMapping("/cases/{caseId}/submission")
    ResponseEntity<ApiModels.SubmissionResponse> submitCase(
            @RequestHeader(value = "X-Trace-Id", required = false) String traceId,
            @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey,
            @PathVariable UUID caseId,
            @Valid @RequestBody ApiModels.SubmitCaseRequest request
    );

    @PostMapping("/cases/{caseId}/institution/mock-event")
    ResponseEntity<ApiModels.CaseDetail> applyInstitutionMockEvent(
            @RequestHeader(value = "X-Trace-Id", required = false) String traceId,
            @PathVariable UUID caseId,
            @Valid @RequestBody ApiModels.InstitutionMockEventRequest request
    );

    @PostMapping("/cases/{caseId}/supplement-response")
    ResponseEntity<ApiModels.CaseDetail> respondSupplement(
            @RequestHeader(value = "X-Trace-Id", required = false) String traceId,
            @PathVariable UUID caseId,
            @Valid @RequestBody ApiModels.SupplementResponseRequest request
    );

    @GetMapping("/cases/{caseId}/timeline")
    ResponseEntity<ApiModels.TimelineResponse> getTimeline(
            @RequestHeader(value = "X-Trace-Id", required = false) String traceId,
            @PathVariable UUID caseId
    );
}
