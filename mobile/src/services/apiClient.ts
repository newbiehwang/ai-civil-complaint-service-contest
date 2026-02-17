import { APP_ENV, assertEnvConfigured } from "../config/env";
import { NativeModules, Platform } from "react-native";
import { getDevAccessToken } from "./authService";
import type {
  ApiError,
  AppendIntakeMessageRequest,
  CaseDetail,
  CreateCaseRequest,
  DecompositionResult,
  EvidenceChecklist,
  EvidenceItem,
  InstitutionMockEventRequest,
  IntakeUpdateResponse,
  RegisterEvidenceRequest,
  RouteDecisionRequest,
  RoutingRecommendation,
  SubmissionResponse,
  SubmitCaseRequest,
  SupplementResponseRequest,
  TimelineResponse,
} from "../types/api";

type HttpMethod = "GET" | "POST";

type RequestOptions = {
  traceId?: string;
  idempotencyKey?: string;
};

type ApiErrorPayload = Partial<ApiError>;

export class ApiClientError extends Error {
  readonly code: string;
  readonly status?: number;
  readonly traceId?: string;
  readonly details: string[];

  constructor(params: {
    code: string;
    message: string;
    status?: number;
    traceId?: string;
    details?: string[];
  }) {
    super(params.message);
    this.name = "ApiClientError";
    this.code = params.code;
    this.status = params.status;
    this.traceId = params.traceId;
    this.details = params.details ?? [];
  }
}

export function createTraceId(prefix = "mobile"): string {
  return `${prefix}-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 10)}`;
}

const LOCAL_HOSTS = new Set(["localhost", "127.0.0.1", "0.0.0.0"]);

function getDevBundleHost(): string | null {
  const scriptUrl = NativeModules?.SourceCode?.scriptURL;
  if (!scriptUrl || typeof scriptUrl !== "string") {
    return null;
  }

  try {
    const parsed = new URL(scriptUrl);
    return parsed.hostname || null;
  } catch {
    return null;
  }
}

function normalizeBaseUrl(value: string): string {
  return value.replace(/\/+$/, "");
}

function buildBaseUrlCandidates(baseUrl: string): string[] {
  const normalizedBase = normalizeBaseUrl(baseUrl);
  const candidates = [normalizedBase];

  try {
    const parsed = new URL(normalizedBase);
    const isLocalHost = LOCAL_HOSTS.has(parsed.hostname);

    if (isLocalHost) {
      const bundleHost = getDevBundleHost();
      if (bundleHost && !LOCAL_HOSTS.has(bundleHost)) {
        const bundleHostCandidate = normalizeBaseUrl(
          `${parsed.protocol}//${bundleHost}${parsed.port ? `:${parsed.port}` : ""}${parsed.pathname}`,
        );
        if (!candidates.includes(bundleHostCandidate)) {
          candidates.push(bundleHostCandidate);
        }
      }

      if (Platform.OS === "android") {
        const androidEmulatorCandidate = normalizeBaseUrl(
          `${parsed.protocol}//10.0.2.2${parsed.port ? `:${parsed.port}` : ""}${parsed.pathname}`,
        );
        if (!candidates.includes(androidEmulatorCandidate)) {
          candidates.push(androidEmulatorCandidate);
        }
      }
    }
  } catch {
    return candidates;
  }

  return candidates;
}

function createNetworkErrorMessage(path: string, attemptedBaseUrls: string[]): string {
  const attempted = attemptedBaseUrls.map((baseUrl) => `${baseUrl}${path}`).join(", ");
  return (
    "네트워크 연결이 원활하지 않습니다. " +
    `요청 주소(${attempted})에 접근하지 못했습니다. ` +
    "실기기(Expo Go)라면 mobile/.env에서 localhost 대신 PC의 LAN IP를 사용해 주세요."
  );
}

function parseApiErrorPayload(value: unknown): ApiErrorPayload | null {
  if (!value || typeof value !== "object") {
    return null;
  }

  const candidate = value as ApiErrorPayload;
  if (typeof candidate.code === "string" || typeof candidate.message === "string") {
    return candidate;
  }

  return null;
}

async function request<TResponse>(
  method: HttpMethod,
  path: string,
  body?: unknown,
  options?: RequestOptions,
): Promise<TResponse> {
  assertEnvConfigured();

  const traceId = options?.traceId ?? createTraceId();
  const headers: Record<string, string> = {
    Authorization: `Bearer ${getDevAccessToken()}`,
    "X-Trace-Id": traceId,
  };

  if (options?.idempotencyKey) {
    headers["Idempotency-Key"] = options.idempotencyKey;
  }

  if (body !== undefined) {
    headers["Content-Type"] = "application/json";
  }

  const attemptedBaseUrls = buildBaseUrlCandidates(APP_ENV.apiBaseUrl);

  let response: Response | null = null;
  let networkFailed = false;
  for (const baseUrl of attemptedBaseUrls) {
    const url = `${baseUrl}${path}`;
    try {
      response = await fetch(url, {
        method,
        headers,
        body: body === undefined ? undefined : JSON.stringify(body),
      });
      networkFailed = false;
      break;
    } catch {
      networkFailed = true;
    }
  }

  if (!response || networkFailed) {
    throw new ApiClientError({
      code: "NETWORK_ERROR",
      message: createNetworkErrorMessage(path, attemptedBaseUrls),
      traceId,
    });
  }

  const rawText = await response.text();
  let parsed: unknown = null;
  if (rawText) {
    try {
      parsed = JSON.parse(rawText) as unknown;
    } catch {
      parsed = null;
    }
  }

  if (!response.ok) {
    const parsedError = parseApiErrorPayload(parsed);
    throw new ApiClientError({
      code: parsedError?.code ?? `HTTP_${response.status}`,
      message: parsedError?.message ?? `요청 실패 (${response.status})`,
      status: response.status,
      traceId: parsedError?.traceId ?? traceId,
      details: parsedError?.details,
    });
  }

  return (parsed ?? {}) as TResponse;
}

export const apiClient = {
  createCase(requestBody: CreateCaseRequest, options?: RequestOptions): Promise<CaseDetail> {
    return request<CaseDetail>("POST", "/api/v1/cases", requestBody, options);
  },

  getCase(caseId: string, options?: RequestOptions): Promise<CaseDetail> {
    return request<CaseDetail>("GET", `/api/v1/cases/${caseId}`, undefined, options);
  },

  appendIntakeMessage(
    caseId: string,
    requestBody: AppendIntakeMessageRequest,
    options?: RequestOptions,
  ): Promise<IntakeUpdateResponse> {
    return request<IntakeUpdateResponse>(
      "POST",
      `/api/v1/cases/${caseId}/intake/messages`,
      requestBody,
      options,
    );
  },

  decomposeCase(caseId: string, options?: RequestOptions): Promise<DecompositionResult> {
    return request<DecompositionResult>("POST", `/api/v1/cases/${caseId}/decomposition`, undefined, options);
  },

  recommendRoute(caseId: string, options?: RequestOptions): Promise<RoutingRecommendation> {
    return request<RoutingRecommendation>("POST", `/api/v1/cases/${caseId}/routing/recommendation`, undefined, options);
  },

  confirmRouteDecision(
    caseId: string,
    requestBody: RouteDecisionRequest,
    options?: RequestOptions,
  ): Promise<CaseDetail> {
    return request<CaseDetail>("POST", `/api/v1/cases/${caseId}/routing/decision`, requestBody, options);
  },

  registerEvidence(
    caseId: string,
    requestBody: RegisterEvidenceRequest,
    options?: RequestOptions,
  ): Promise<EvidenceItem> {
    return request<EvidenceItem>("POST", `/api/v1/cases/${caseId}/evidence`, requestBody, options);
  },

  getEvidenceChecklist(caseId: string, options?: RequestOptions): Promise<EvidenceChecklist> {
    return request<EvidenceChecklist>("GET", `/api/v1/cases/${caseId}/evidence/checklist`, undefined, options);
  },

  submitCase(
    caseId: string,
    requestBody: SubmitCaseRequest,
    options?: RequestOptions,
  ): Promise<SubmissionResponse> {
    return request<SubmissionResponse>("POST", `/api/v1/cases/${caseId}/submission`, requestBody, options);
  },

  applyInstitutionMockEvent(
    caseId: string,
    requestBody: InstitutionMockEventRequest,
    options?: RequestOptions,
  ): Promise<CaseDetail> {
    return request<CaseDetail>(
      "POST",
      `/api/v1/cases/${caseId}/institution/mock-event`,
      requestBody,
      options,
    );
  },

  respondSupplement(
    caseId: string,
    requestBody: SupplementResponseRequest,
    options?: RequestOptions,
  ): Promise<CaseDetail> {
    return request<CaseDetail>("POST", `/api/v1/cases/${caseId}/supplement-response`, requestBody, options);
  },

  getTimeline(caseId: string, options?: RequestOptions): Promise<TimelineResponse> {
    return request<TimelineResponse>("GET", `/api/v1/cases/${caseId}/timeline`, undefined, options);
  },
};
