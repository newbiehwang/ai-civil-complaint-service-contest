import type { components, paths } from "./api.generated";

export type { components, paths };

export type Schemas = components["schemas"];

export type CaseStatus = Schemas["CaseStatus"];
export type RiskLevel = Schemas["RiskLevel"];

export type CreateCaseRequest = Schemas["CreateCaseRequest"];
export type CaseSummary = Schemas["CaseSummary"];
export type CaseDetail = Schemas["CaseDetail"];

export type IntakeSnapshot = Schemas["IntakeSnapshot"];
export type AppendIntakeMessageRequest = Schemas["AppendIntakeMessageRequest"];
export type IntakeUpdateResponse = Schemas["IntakeUpdateResponse"];
export type FollowUpInterface = Schemas["FollowUpInterface"];
export type FollowUpOption = Schemas["FollowUpOption"];
export type FollowUpInterfaceType = Schemas["FollowUpInterfaceType"];
export type FollowUpSelectionMode = Schemas["FollowUpSelectionMode"];

export type DecompositionResult = Schemas["DecompositionResult"];
export type RoutingRecommendation = Schemas["RoutingRecommendation"];
export type RoutingOption = Schemas["RoutingOption"];
export type RouteDecisionRequest = Schemas["RouteDecisionRequest"];

export type EvidenceType = Schemas["RegisterEvidenceRequest"]["evidenceType"];
export type RegisterEvidenceRequest = Schemas["RegisterEvidenceRequest"];
export type EvidenceItem = Schemas["EvidenceItem"];
export type EvidenceChecklist = Schemas["EvidenceChecklist"];

export type SubmitCaseRequest = Schemas["SubmitCaseRequest"];
export type SubmissionResponse = Schemas["SubmissionResponse"];
export type SubmissionStatus = Schemas["SubmissionResponse"]["submissionStatus"];

export type InstitutionMockEventRequest = Schemas["InstitutionMockEventRequest"];
export type SupplementResponseRequest = Schemas["SupplementResponseRequest"];
export type TimelineEvent = Schemas["TimelineEvent"];
export type TimelineResponse = Schemas["TimelineResponse"];

export type ApiError = Schemas["ApiError"];
