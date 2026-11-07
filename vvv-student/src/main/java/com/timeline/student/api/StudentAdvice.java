package com.timeline.student.api;

import com.timeline.poetry.service.PoetryCatalog;
import com.timeline.student.api.StudentModels.Response;
import com.timeline.student.domain.StudentErrors.BadRequest;
import com.timeline.student.domain.StudentErrors.NotFound;
import com.timeline.student.domain.StudentErrors.Unauthorized;
import com.timeline.student.domain.StudentErrors.Unavailable;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MissingRequestHeaderException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

/**
 * Scoped to this module's controllers only, so it cannot change how vvv-poetry or the host answer errors.
 * Messages are fixed phrases: no stack trace, no SQL, no echo of what the client sent.
 */
@RestControllerAdvice(assignableTypes = {StudentContentController.class, StudentDeviceController.class})
@Order(Ordered.HIGHEST_PRECEDENCE)
public class StudentAdvice {

    @ExceptionHandler({NotFound.class, PoetryCatalog.NotFound.class})
    public ResponseEntity<Response<Void>> notFound(RuntimeException ex) {
        return ResponseEntity.status(404).body(new Response<>(404, null, "Content not found"));
    }

    @ExceptionHandler(BadRequest.class)
    public ResponseEntity<Response<Void>> badRequest(BadRequest ex) {
        return ResponseEntity.badRequest().body(new Response<>(400, null, ex.getMessage()));
    }

    @ExceptionHandler({PoetryCatalog.BadRequest.class, MissingServletRequestParameterException.class,
        MethodArgumentTypeMismatchException.class, HttpMessageNotReadableException.class})
    public ResponseEntity<Response<Void>> invalid(Exception ex) {
        return ResponseEntity.badRequest().body(new Response<>(400, null, "Invalid request parameters"));
    }

    @ExceptionHandler({Unauthorized.class, MissingRequestHeaderException.class})
    public ResponseEntity<Response<Void>> unauthorized(Exception ex) {
        return ResponseEntity.status(401).body(new Response<>(401, null, "missing or invalid credentials"));
    }

    @ExceptionHandler(Unavailable.class)
    public ResponseEntity<Response<Void>> unavailable(Unavailable ex) {
        return ResponseEntity.status(503).body(new Response<>(503, null, ex.getMessage()));
    }
}
