ALTER TABLE complaint_cases
    ADD COLUMN owner_subject VARCHAR(120);

CREATE INDEX idx_complaint_cases_owner_subject
    ON complaint_cases (owner_subject);
