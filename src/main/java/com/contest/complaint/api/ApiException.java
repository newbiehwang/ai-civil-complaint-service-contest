package com.contest.complaint.api;

import org.springframework.http.HttpStatus;

import java.util.List;

public class ApiException extends RuntimeException {

    private final HttpStatus status;
    private final String code;
    private final List<String> details;

    public ApiException(HttpStatus status, String code, String message, List<String> details) {
        super(message);
        this.status = status;
        this.code = code;
        this.details = details == null ? List.of() : details;
    }

    public HttpStatus getStatus() {
        return status;
    }

    public String getCode() {
        return code;
    }

    public List<String> getDetails() {
        return details;
    }

    public static ApiException notFound(String code, String message) {
        return new ApiException(HttpStatus.NOT_FOUND, code, message, List.of());
    }

    public static ApiException conflict(String code, String message, List<String> details) {
        return new ApiException(HttpStatus.CONFLICT, code, message, details);
    }

    public static ApiException badRequest(String code, String message, List<String> details) {
        return new ApiException(HttpStatus.BAD_REQUEST, code, message, details);
    }
}
