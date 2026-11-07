package com.timeline.poetry.api;

import com.timeline.poetry.service.PoetryDraftService.Dirty;
import com.timeline.poetry.service.PoetryDraftService.Invalid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

/**
 * Authoring errors become explainable HTTP instead of a stack trace:
 * 400 = the request itself is wrong (vocabulary, missing reference, duplicate), 409 = the write was
 * refused because it would leave the library unverified (already rolled back by the service).
 */
@RestControllerAdvice(assignableTypes = {PoetryDraftController.class, PoetryReviewController.class, PoetryController.class,
    PoetryMediaController.class, PoetryPublishController.class, PoetryAgentController.class})
public class PoetryAuthoringAdvice {

    @ExceptionHandler(Invalid.class)
    public ResponseEntity<PoetryModels.Response<Void>> invalid(Invalid ex) {
        return ResponseEntity.badRequest().body(new PoetryModels.Response<>(400, null, ex.getMessage()));
    }

    @ExceptionHandler(Dirty.class)
    public ResponseEntity<PoetryModels.Response<Void>> dirty(Dirty ex) {
        return ResponseEntity.status(409).body(new PoetryModels.Response<>(409, null, ex.getMessage()));
    }
}
