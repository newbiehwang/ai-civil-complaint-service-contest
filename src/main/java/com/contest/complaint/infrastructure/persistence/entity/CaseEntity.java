package com.contest.complaint.infrastructure.persistence.entity;

import com.contest.complaint.api.model.ApiModels;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "complaint_cases")
public class CaseEntity {

    @Id
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "owner_subject", length = 120)
    private String ownerSubject;

    @Column(name = "scenario_type", nullable = false, length = 100)
    private String scenarioType;

    @Column(name = "housing_type", nullable = false, length = 50)
    private String housingType;

    @Column(name = "initial_summary", columnDefinition = "TEXT")
    private String initialSummary;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 50)
    private ApiModels.CaseStatus status;

    @Enumerated(EnumType.STRING)
    @Column(name = "risk_level", nullable = false, length = 20)
    private ApiModels.RiskLevel riskLevel;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @Column(name = "risk_signal_detected", nullable = false)
    private boolean riskSignalDetected;

    @Column(name = "filled_slots_json", nullable = false, columnDefinition = "TEXT")
    private String filledSlotsJson;

    @Column(name = "decomposition_nodes_json", nullable = false, columnDefinition = "TEXT")
    private String decompositionNodesJson;

    @Column(name = "routing_options_json", nullable = false, columnDefinition = "TEXT")
    private String routingOptionsJson;

    @Column(name = "selected_option_id", length = 100)
    private String selectedOptionId;

    @Column(name = "current_action_required", nullable = false, length = 100)
    private String currentActionRequired;

    @Column(name = "submission_id", length = 100)
    private String submissionId;

    @Enumerated(EnumType.STRING)
    @Column(name = "submission_status", length = 30)
    private ApiModels.SubmissionStatus submissionStatus;

    @PrePersist
    public void prePersist() {
        Instant now = Instant.now();
        if (createdAt == null) {
            createdAt = now;
        }
        updatedAt = now;
    }

    @PreUpdate
    public void preUpdate() {
        updatedAt = Instant.now();
    }

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public String getOwnerSubject() {
        return ownerSubject;
    }

    public void setOwnerSubject(String ownerSubject) {
        this.ownerSubject = ownerSubject;
    }

    public String getScenarioType() {
        return scenarioType;
    }

    public void setScenarioType(String scenarioType) {
        this.scenarioType = scenarioType;
    }

    public String getHousingType() {
        return housingType;
    }

    public void setHousingType(String housingType) {
        this.housingType = housingType;
    }

    public String getInitialSummary() {
        return initialSummary;
    }

    public void setInitialSummary(String initialSummary) {
        this.initialSummary = initialSummary;
    }

    public ApiModels.CaseStatus getStatus() {
        return status;
    }

    public void setStatus(ApiModels.CaseStatus status) {
        this.status = status;
    }

    public ApiModels.RiskLevel getRiskLevel() {
        return riskLevel;
    }

    public void setRiskLevel(ApiModels.RiskLevel riskLevel) {
        this.riskLevel = riskLevel;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(Instant updatedAt) {
        this.updatedAt = updatedAt;
    }

    public boolean isRiskSignalDetected() {
        return riskSignalDetected;
    }

    public void setRiskSignalDetected(boolean riskSignalDetected) {
        this.riskSignalDetected = riskSignalDetected;
    }

    public String getFilledSlotsJson() {
        return filledSlotsJson;
    }

    public void setFilledSlotsJson(String filledSlotsJson) {
        this.filledSlotsJson = filledSlotsJson;
    }

    public String getDecompositionNodesJson() {
        return decompositionNodesJson;
    }

    public void setDecompositionNodesJson(String decompositionNodesJson) {
        this.decompositionNodesJson = decompositionNodesJson;
    }

    public String getRoutingOptionsJson() {
        return routingOptionsJson;
    }

    public void setRoutingOptionsJson(String routingOptionsJson) {
        this.routingOptionsJson = routingOptionsJson;
    }

    public String getSelectedOptionId() {
        return selectedOptionId;
    }

    public void setSelectedOptionId(String selectedOptionId) {
        this.selectedOptionId = selectedOptionId;
    }

    public String getCurrentActionRequired() {
        return currentActionRequired;
    }

    public void setCurrentActionRequired(String currentActionRequired) {
        this.currentActionRequired = currentActionRequired;
    }

    public String getSubmissionId() {
        return submissionId;
    }

    public void setSubmissionId(String submissionId) {
        this.submissionId = submissionId;
    }

    public ApiModels.SubmissionStatus getSubmissionStatus() {
        return submissionStatus;
    }

    public void setSubmissionStatus(ApiModels.SubmissionStatus submissionStatus) {
        this.submissionStatus = submissionStatus;
    }
}
