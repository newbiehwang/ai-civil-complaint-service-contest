package com.contest.complaint.api.model;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

public final class ApiModels {

    private ApiModels() {
    }

    public enum CaseStatus {
        RECEIVED,
        CLASSIFIED,
        ROUTE_CONFIRMED,
        EVIDENCE_COLLECTING,
        MEDIATION_IN_PROGRESS,
        MEDIATION_SUCCESS,
        MEDIATION_FAILED,
        FORMAL_SUBMISSION_READY,
        INSTITUTION_PROCESSING,
        SUPPLEMENT_REQUIRED,
        COMPLETED,
        CLOSED
    }

    public enum RiskLevel {
        LOW,
        MEDIUM,
        HIGH,
        CRITICAL
    }

    public enum MessageRole {
        USER,
        AGENT
    }

    public enum FollowUpInterfaceType {
        OPTIONS,
        DATE
    }

    public enum FollowUpSelectionMode {
        SINGLE,
        MULTIPLE
    }

    public enum ChatUiType {
        NONE,
        LIST_PICKER,
        OPTION_LIST,
        SUMMARY_CARD,
        PATH_CHOOSER,
        STATUS_FEED
    }

    public enum ChatUiSelectionMode {
        NONE,
        SINGLE,
        MULTIPLE
    }

    public enum ChatInteractionType {
        TEXT,
        MINI_SELECTION,
        SYSTEM_CONFIRM
    }

    public enum DecompositionNodeType {
        LIVING_NOISE,
        IMMEDIATE_RISK,
        LONG_TERM_DISPUTE
    }

    public enum RoutingChannelType {
        EMERGENCY_112,
        MANAGEMENT_OFFICE,
        NEIGHBOR_CENTER,
        E_PEOPLE,
        DISPUTE_MEDIATION
    }

    public enum EvidenceType {
        AUDIO,
        LOG,
        IMAGE,
        DOCUMENT
    }

    public enum SubmissionChannel {
        MCP_API,
        DIRECT_API,
        MANUAL_PDF
    }

    public enum SubmissionStatus {
        QUEUED,
        SUBMITTED,
        FAILED
    }

    public enum InstitutionMockEventType {
        SUPPLEMENT_REQUIRED,
        COMPLETED
    }

    public enum TimelineEventType {
        CASE_CREATED,
        RISK_DETECTED,
        CLASSIFICATION_DONE,
        ROUTE_RECOMMENDED,
        ROUTE_CONFIRMED,
        EVIDENCE_ADDED,
        SUBMISSION_STARTED,
        SUBMISSION_COMPLETED,
        SUPPLEMENT_REQUESTED,
        SUPPLEMENT_RESPONDED,
        CASE_COMPLETED
    }

    public enum TimelineActor {
        SYSTEM,
        USER,
        INSTITUTION
    }

    public record DemoLoginRequest(
            @NotBlank String username,
            @NotBlank String password
    ) {
    }

    public record UserProfile(
            String name,
            String phone,
            String email,
            String housingName,
            String address
    ) {
    }

    public record DemoLoginResponse(
            String accessToken,
            String tokenType,
            Instant expiresAt,
            UserProfile profile
    ) {
    }

    public record CreateCaseRequest(
            @NotBlank String scenarioType,
            @NotBlank String housingType,
            @NotNull Boolean consentAccepted,
            @Size(max = 2000) String initialSummary
    ) {
    }

    public record CaseSummary(
            UUID caseId,
            CaseStatus status,
            RiskLevel riskLevel,
            Instant createdAt,
            Instant updatedAt
    ) {
    }

    public record CaseListResponse(
            List<CaseSummary> items
    ) {
    }

    public record CaseDetail(
            UUID caseId,
            CaseStatus status,
            RiskLevel riskLevel,
            Instant createdAt,
            Instant updatedAt,
            IntakeSnapshot intake,
            DecompositionResult decomposition,
            RoutingRecommendation routing,
            EvidenceChecklist evidenceChecklist,
            String currentActionRequired
    ) {
    }

    public record IntakeSnapshot(
            List<String> requiredSlots,
            Map<String, Object> filledSlots,
            boolean riskSignalDetected
    ) {
    }

    public record AppendIntakeMessageRequest(
            @NotNull MessageRole role,
            @NotBlank @Size(max = 5000) String message
    ) {
    }

    public record FollowUpOption(
            String optionId,
            String label
    ) {
    }

    public record FollowUpInterface(
            FollowUpInterfaceType interfaceType,
            FollowUpSelectionMode selectionMode,
            List<FollowUpOption> options
    ) {
    }

    public record IntakeUpdateResponse(
            UUID caseId,
            CaseStatus status,
            IntakeSnapshot intake,
            String recommendedFollowUpQuestion,
            FollowUpInterface followUpInterface
    ) {
    }

    public record ChatTurnContext(
            String caseId,
            String scenarioType,
            String housingType,
            Boolean consentAccepted
    ) {
    }

    public record ChatTurnInteraction(
            ChatInteractionType interactionType,
            List<String> selectedOptionIds,
            List<String> selectedOptionLabels,
            ChatUiType sourceUiType,
            Map<String, Object> meta
    ) {
    }

    public record ChatTurnHistoryMessage(
            String role,
            @Size(max = 5000) String text,
            String source
    ) {
    }

    public record ChatTurnRequest(
            @Size(max = 5000) String userMessage,
            ChatTurnContext context,
            List<String> uiCapabilities,
            ChatTurnInteraction interaction,
            String lastUiHintType,
            List<ChatTurnHistoryMessage> recentMessages
    ) {
    }

    public record ChatUiOption(
            String id,
            String label
    ) {
    }

    public record ChatUiHint(
            ChatUiType type,
            ChatUiSelectionMode selectionMode,
            String title,
            String subtitle,
            List<ChatUiOption> options,
            Map<String, Object> meta
    ) {
    }

    public record ChatTurnResponse(
            String sessionId,
            String assistantMessage,
            ChatUiHint uiHint,
            Map<String, Object> statePatch,
            String nextAction
    ) {
    }

    public record DecompositionNode(
            DecompositionNodeType nodeType,
            String title,
            int priority,
            String rationale
    ) {
    }

    public record DecompositionResult(
            UUID caseId,
            List<DecompositionNode> nodes
    ) {
    }

    public record RoutingOption(
            String optionId,
            RoutingChannelType channelType,
            String label,
            int priority,
            String reason,
            List<String> requiredEvidence
    ) {
    }

    public record RoutingRecommendation(
            UUID caseId,
            List<RoutingOption> options,
            String selectedOptionId
    ) {
    }

    public record RouteDecisionRequest(
            @NotBlank String optionId,
            @NotNull Boolean userConfirmed,
            @Size(max = 1000) String note
    ) {
    }

    public record RegisterEvidenceRequest(
            @NotNull EvidenceType evidenceType,
            @NotBlank String storageKey,
            String originalFileName,
            String mimeType,
            Long sizeBytes,
            @NotNull Instant capturedAt,
            String notes
    ) {
    }

    public record EvidenceItem(
            UUID evidenceId,
            EvidenceType evidenceType,
            String storageKey,
            Instant uploadedAt,
            double adequacyScore
    ) {
    }

    public record EvidenceChecklist(
            boolean isSufficient,
            List<String> missingItems,
            String guidance
    ) {
    }

    public record SubmitCaseRequest(
            @NotNull SubmissionChannel submissionChannel,
            @NotNull Boolean userConsent,
            @NotNull Boolean identityVerified
    ) {
    }

    public record SubmissionResponse(
            UUID caseId,
            String submissionId,
            SubmissionStatus submissionStatus,
            Instant submittedAt
    ) {
    }

    public record SupplementResponseRequest(
            @NotBlank @Size(max = 3000) String message,
            List<UUID> evidenceIds
    ) {
    }

    public record InstitutionMockEventRequest(
            @NotNull InstitutionMockEventType eventType,
            @Size(max = 3000) String message
    ) {
    }

    public record TimelineEvent(
            UUID eventId,
            TimelineEventType eventType,
            Instant occurredAt,
            String title,
            String description,
            TimelineActor actor
    ) {
    }

    public record TimelineResponse(
            UUID caseId,
            List<TimelineEvent> events
    ) {
    }

    public record ApiError(
            Instant timestamp,
            String traceId,
            String code,
            String message,
            List<String> details
    ) {
    }
}
