CREATE TABLE complaint_cases (
    id UUID PRIMARY KEY,
    scenario_type VARCHAR(100) NOT NULL,
    housing_type VARCHAR(50) NOT NULL,
    initial_summary TEXT,
    status VARCHAR(50) NOT NULL,
    risk_level VARCHAR(20) NOT NULL,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL,
    risk_signal_detected BOOLEAN NOT NULL DEFAULT FALSE,
    filled_slots_json TEXT NOT NULL,
    decomposition_nodes_json TEXT NOT NULL,
    routing_options_json TEXT NOT NULL,
    selected_option_id VARCHAR(100),
    current_action_required VARCHAR(100) NOT NULL,
    submission_id VARCHAR(100),
    submission_status VARCHAR(30)
);

CREATE TABLE evidence_items (
    id UUID PRIMARY KEY,
    case_id UUID NOT NULL,
    evidence_type VARCHAR(20) NOT NULL,
    storage_key VARCHAR(255) NOT NULL,
    original_file_name VARCHAR(255),
    mime_type VARCHAR(100),
    size_bytes BIGINT,
    captured_at TIMESTAMP,
    notes TEXT,
    uploaded_at TIMESTAMP NOT NULL,
    adequacy_score DOUBLE PRECISION NOT NULL,
    CONSTRAINT fk_evidence_case FOREIGN KEY (case_id) REFERENCES complaint_cases (id) ON DELETE CASCADE
);

CREATE TABLE timeline_events (
    id UUID PRIMARY KEY,
    case_id UUID NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    occurred_at TIMESTAMP NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    actor VARCHAR(20) NOT NULL,
    CONSTRAINT fk_timeline_case FOREIGN KEY (case_id) REFERENCES complaint_cases (id) ON DELETE CASCADE
);

CREATE INDEX idx_evidence_case_id ON evidence_items (case_id);
CREATE INDEX idx_timeline_case_id ON timeline_events (case_id);
