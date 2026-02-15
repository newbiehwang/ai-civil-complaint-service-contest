package com.contest.complaint.application;

import com.contest.complaint.api.ApiException;
import com.contest.complaint.infrastructure.persistence.entity.IdempotencyRecordEntity;
import com.contest.complaint.infrastructure.persistence.repository.IdempotencyRecordRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.function.Supplier;

@Service
public class IdempotencyService {

    private final IdempotencyRecordRepository idempotencyRecordRepository;
    private final ObjectMapper objectMapper;

    public IdempotencyService(
            IdempotencyRecordRepository idempotencyRecordRepository,
            ObjectMapper objectMapper
    ) {
        this.idempotencyRecordRepository = idempotencyRecordRepository;
        this.objectMapper = objectMapper;
    }

    public <T> T execute(
            String operation,
            String idempotencyKey,
            Object requestBody,
            Class<T> responseType,
            Supplier<T> action
    ) {
        if (idempotencyKey == null || idempotencyKey.isBlank()) {
            return action.get();
        }

        String normalizedKey = idempotencyKey.trim();
        String requestJson = writeJson(requestBody);

        Optional<IdempotencyRecordEntity> existing = idempotencyRecordRepository
                .findByOperationAndIdempotencyKey(operation, normalizedKey);
        if (existing.isPresent()) {
            return replay(existing.get(), requestJson, responseType);
        }

        T response = action.get();
        IdempotencyRecordEntity entity = new IdempotencyRecordEntity();
        entity.setOperation(operation);
        entity.setIdempotencyKey(normalizedKey);
        entity.setRequestJson(requestJson);
        entity.setResponseJson(writeJson(response));

        try {
            idempotencyRecordRepository.save(entity);
            return response;
        } catch (DataIntegrityViolationException ex) {
            IdempotencyRecordEntity concurrent = idempotencyRecordRepository
                    .findByOperationAndIdempotencyKey(operation, normalizedKey)
                    .orElseThrow(() -> ex);
            return replay(concurrent, requestJson, responseType);
        }
    }

    private <T> T replay(IdempotencyRecordEntity entity, String requestJson, Class<T> responseType) {
        if (!Objects.equals(entity.getRequestJson(), requestJson)) {
            throw ApiException.conflict(
                    "IDEMPOTENCY_KEY_REUSED",
                    "Idempotency-Key was already used with a different request payload.",
                    List.of("operation=" + entity.getOperation(), "idempotencyKey=" + entity.getIdempotencyKey())
            );
        }
        return readJson(entity.getResponseJson(), responseType);
    }

    private String writeJson(Object value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (Exception ex) {
            throw new IllegalStateException("Failed to serialize idempotency payload", ex);
        }
    }

    private <T> T readJson(String json, Class<T> type) {
        try {
            return objectMapper.readValue(json, type);
        } catch (Exception ex) {
            throw new IllegalStateException("Failed to deserialize idempotency payload", ex);
        }
    }
}
