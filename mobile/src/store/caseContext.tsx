import { createContext, ReactNode, useContext, useMemo, useRef, useState } from "react";
import { createTraceId } from "../services/apiClient";
import type {
  CaseDetail,
  CaseStatus,
  EvidenceChecklist,
  IntakeSnapshot,
  IntakeUpdateResponse,
  RoutingRecommendation,
  SubmissionResponse,
  TimelineEvent,
} from "../types/api";

export type MediationDecision = "TRY_MEDIATION_FIRST" | "PROCEED_FORMAL_SUBMISSION";

type CaseContextValue = {
  caseId: string | null;
  status: CaseStatus | null;
  intakeSnapshot: IntakeSnapshot | null;
  routingRecommendation: RoutingRecommendation | null;
  evidenceChecklist: EvidenceChecklist | null;
  submissionResponse: SubmissionResponse | null;
  timelineEvents: TimelineEvent[];
  mediationDecision: MediationDecision | null;
  lastFollowUpQuestion: string | null;
  traceId: string;
  applyCaseDetail: (detail: CaseDetail) => void;
  setCaseFromCreate: (detail: CaseDetail) => void;
  applyIntakeUpdate: (response: IntakeUpdateResponse) => void;
  setRoutingRecommendation: (routing: RoutingRecommendation | null) => void;
  setEvidenceChecklist: (checklist: EvidenceChecklist | null) => void;
  setSubmissionResponse: (response: SubmissionResponse | null) => void;
  setTimelineEvents: (events: TimelineEvent[]) => void;
  setMediationDecision: (decision: MediationDecision | null) => void;
  resetCase: () => void;
};

const CaseContext = createContext<CaseContextValue | null>(null);

type CaseProviderProps = {
  children: ReactNode;
};

export function CaseProvider({ children }: CaseProviderProps) {
  const [caseId, setCaseId] = useState<string | null>(null);
  const [status, setStatus] = useState<CaseStatus | null>(null);
  const [intakeSnapshot, setIntakeSnapshot] = useState<IntakeSnapshot | null>(null);
  const [routingRecommendation, setRoutingRecommendation] = useState<RoutingRecommendation | null>(null);
  const [evidenceChecklist, setEvidenceChecklist] = useState<EvidenceChecklist | null>(null);
  const [submissionResponse, setSubmissionResponse] = useState<SubmissionResponse | null>(null);
  const [timelineEvents, setTimelineEvents] = useState<TimelineEvent[]>([]);
  const [mediationDecision, setMediationDecision] = useState<MediationDecision | null>(null);
  const [lastFollowUpQuestion, setLastFollowUpQuestion] = useState<string | null>(null);
  const traceIdRef = useRef(createTraceId());

  const applyCaseDetail = (detail: CaseDetail) => {
    setCaseId(detail.caseId ?? null);
    setStatus(detail.status ?? null);
    setIntakeSnapshot(detail.intake ?? null);
    setRoutingRecommendation(detail.routing ?? null);
    setEvidenceChecklist(detail.evidenceChecklist ?? null);
    setLastFollowUpQuestion(null);
  };

  const value = useMemo<CaseContextValue>(
    () => ({
      caseId,
      status,
      intakeSnapshot,
      routingRecommendation,
      evidenceChecklist,
      submissionResponse,
      timelineEvents,
      mediationDecision,
      lastFollowUpQuestion,
      traceId: traceIdRef.current,
      applyCaseDetail,
      setCaseFromCreate: (detail) => applyCaseDetail(detail),
      applyIntakeUpdate: (response) => {
        setCaseId(response.caseId ?? null);
        setStatus(response.status ?? null);
        setIntakeSnapshot(response.intake ?? null);
        setLastFollowUpQuestion(response.recommendedFollowUpQuestion ?? null);
      },
      setRoutingRecommendation: (routing) => {
        setRoutingRecommendation(routing);
      },
      setEvidenceChecklist: (checklist) => {
        setEvidenceChecklist(checklist);
      },
      setSubmissionResponse: (response) => {
        setSubmissionResponse(response);
      },
      setTimelineEvents: (events) => {
        setTimelineEvents(events);
      },
      setMediationDecision: (decision) => {
        setMediationDecision(decision);
      },
      resetCase: () => {
        setCaseId(null);
        setStatus(null);
        setIntakeSnapshot(null);
        setRoutingRecommendation(null);
        setEvidenceChecklist(null);
        setSubmissionResponse(null);
        setTimelineEvents([]);
        setMediationDecision(null);
        setLastFollowUpQuestion(null);
      },
    }),
    [
      caseId,
      evidenceChecklist,
      intakeSnapshot,
      lastFollowUpQuestion,
      mediationDecision,
      routingRecommendation,
      status,
      submissionResponse,
      timelineEvents,
    ],
  );

  return <CaseContext.Provider value={value}>{children}</CaseContext.Provider>;
}

export function useCaseContext(): CaseContextValue {
  const context = useContext(CaseContext);
  if (!context) {
    throw new Error("useCaseContext must be used inside CaseProvider");
  }
  return context;
}
