package com.contest.complaint.api;

import com.contest.complaint.api.model.ApiModels;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.time.Instant;
import java.util.List;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(ApiException.class)
    public ResponseEntity<ApiModels.ApiError> handleApiException(ApiException ex, HttpServletRequest request) {
        return ResponseEntity.status(ex.getStatus()).body(new ApiModels.ApiError(
                Instant.now(),
                traceId(request),
                ex.getCode(),
                ex.getMessage(),
                ex.getDetails()
        ));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiModels.ApiError> handleValidation(MethodArgumentNotValidException ex, HttpServletRequest request) {
        List<String> details = ex.getBindingResult().getFieldErrors().stream()
                .map(GlobalExceptionHandler::formatFieldError)
                .toList();

        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(new ApiModels.ApiError(
                Instant.now(),
                traceId(request),
                "VALIDATION_ERROR",
                "Request validation failed.",
                details
        ));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiModels.ApiError> handleUnexpected(Exception ex, HttpServletRequest request) {
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(new ApiModels.ApiError(
                Instant.now(),
                traceId(request),
                "INTERNAL_ERROR",
                "Unexpected server error.",
                List.of(ex.getClass().getSimpleName())
        ));
    }

    private static String traceId(HttpServletRequest request) {
        String header = request.getHeader("X-Trace-Id");
        return header == null || header.isBlank() ? "N/A" : header;
    }

    private static String formatFieldError(FieldError error) {
        return error.getField() + ": " + (error.getDefaultMessage() == null ? "invalid" : error.getDefaultMessage());
    }
}
