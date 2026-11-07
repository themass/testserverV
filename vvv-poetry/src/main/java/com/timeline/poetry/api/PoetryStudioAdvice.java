package com.timeline.poetry.api;

import com.timeline.poetry.api.PoetryStudioModels.StudioResponse;
import com.timeline.poetry.service.PoetryStudioService.Failure;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import java.util.Map;

/**
 * 只覆盖两个 Studio 控制器：让 400/403/404/409 带有可读的统一信封。
 * 不修改既有 {@link PoetryAuthoringAdvice}(它用旧的 Response 信封，且只覆盖旧控制器)。
 */
@RestControllerAdvice(assignableTypes = {PoetryStudioReadController.class, PoetryStudioWriteController.class})
public class PoetryStudioAdvice {

    @ExceptionHandler(Failure.class)
    public ResponseEntity<StudioResponse<Map<String, Object>>> failure(Failure ex) {
        String next = ex.http() == 409 ? "REPLAN" : (ex.http() == 403 ? "HUMAN_REVIEW" : "REPLAN");
        return ResponseEntity.status(ex.http()).body(StudioResponse.error(ex.status(), ex.code(), ex.getMessage(), ex.details(), next));
    }
}
