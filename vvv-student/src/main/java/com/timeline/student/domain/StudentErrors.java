package com.timeline.student.domain;

/** Distinct from IllegalArgumentException on purpose: a 404 must never be remapped to a 400. */
public final class StudentErrors {
    private StudentErrors() {}

    public static class NotFound extends RuntimeException {
        public NotFound(String message) { super(message); }
    }

    public static class BadRequest extends RuntimeException {
        public BadRequest(String message) { super(message); }
    }

    public static class Unauthorized extends RuntimeException {
        public Unauthorized(String message) { super(message); }
    }

    /** A dependency (token, bundle store) is not configured: fail closed with 503, never open. */
    public static class Unavailable extends RuntimeException {
        public Unavailable(String message) { super(message); }
    }
}
