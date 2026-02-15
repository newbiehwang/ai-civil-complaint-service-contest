CREATE TABLE idempotency_records (
    id UUID PRIMARY KEY,
    operation VARCHAR(120) NOT NULL,
    idempotency_key VARCHAR(255) NOT NULL,
    request_json TEXT NOT NULL,
    response_json TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL
);

CREATE UNIQUE INDEX uq_idempotency_operation_key
    ON idempotency_records (operation, idempotency_key);
