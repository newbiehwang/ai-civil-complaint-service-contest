import type { CaseStatus } from '../api-contract';
import './StatusBadge.css';

const LABELS: Record<CaseStatus, string> = {
  RECEIVED: '접수됨',
  CLASSIFIED: '분류 완료',
  ROUTE_CONFIRMED: '경로 확정',
  EVIDENCE_COLLECTING: '증거 수집',
  FORMAL_SUBMISSION_READY: '제출 준비 완료',
  INSTITUTION_PROCESSING: '기관 처리 중',
  SUPPLEMENT_REQUIRED: '보완 요청',
  COMPLETED: '완료',
  CLOSED: '종결',
};

type StatusBadgeProps = {
  status: CaseStatus;
};

export function StatusBadge({ status }: StatusBadgeProps) {
  return <span className={`status-badge ${status.toLowerCase()}`}>{LABELS[status]}</span>;
}
