package com.timeline.student;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.timeline.student.api.StudentIndexController;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

/**
 * index.html must be revalidated on every load while everything else under /app/ is cached for a year.
 * This is the one failure that is silent in production — a student stuck on last week's build — so it gets
 * its own test rather than being inferred from the resource handler's headers.
 */
class StudentIndexControllerTest {

    private static ResponseEntity<Resource> get(StudentIndexController controller) throws IOException {
        return controller.index();
    }

    @Test void servesIndexHtmlWithNoCache(@TempDir Path tmp) throws IOException {
        Files.writeString(tmp.resolve("index.html"), "<!doctype html><title>诗词</title>", StandardCharsets.UTF_8);
        ResponseEntity<Resource> res = get(new StudentIndexController(tmp.toString()));

        assertEquals(HttpStatus.OK, res.getStatusCode());
        String cache = String.valueOf(res.getHeaders().getCacheControl());
        assertFalse(cache.contains("immutable"), "index.html must not be immutable: " + cache);
        assertTrue(cache.contains("no-cache") || cache.contains("no-store"), cache);
        assertEquals("text/html", String.valueOf(res.getHeaders().getContentType().getType()) + "/"
            + res.getHeaders().getContentType().getSubtype());
        assertTrue(new String(res.getBody().getInputStream().readAllBytes(), StandardCharsets.UTF_8).contains("诗词"));
    }

    @Test void missingRootIs404NotAnEmptyPage(@TempDir Path tmp) throws IOException {
        ResponseEntity<Resource> res = get(new StudentIndexController(tmp.resolve("absent").toString()));
        assertEquals(HttpStatus.NOT_FOUND, res.getStatusCode());
    }

    @Test void blankRootIs404(@TempDir Path unused) throws IOException {
        assertEquals(HttpStatus.NOT_FOUND, get(new StudentIndexController("")).getStatusCode());
    }

    @Test void aDirectoryNamedIndexHtmlIs404(@TempDir Path tmp) throws IOException {
        Files.createDirectories(tmp.resolve("index.html"));
        assertEquals(HttpStatus.NOT_FOUND, get(new StudentIndexController(tmp.toString())).getStatusCode());
    }

    @Test void theDirectoryUrlRedirectsToIndexHtmlAndIsNotStored() {
        ResponseEntity<Void> res = new StudentIndexController("/anywhere").root();
        assertEquals(HttpStatus.FOUND, res.getStatusCode());
        assertEquals("/app/index.html", String.valueOf(res.getHeaders().getLocation()));
        String cache = String.valueOf(res.getHeaders().getCacheControl());
        assertTrue(cache.contains("no-store"), cache);
    }
}
