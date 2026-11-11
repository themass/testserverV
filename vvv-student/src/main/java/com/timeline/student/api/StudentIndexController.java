package com.timeline.student.api;

import com.timeline.student.config.StudentStaticResources;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.core.io.Resource;
import org.springframework.http.CacheControl;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.resource.ResourceHttpRequestHandler;

/**
 * {@code /app/} and {@code /app/index.html}: the one file that must never be cached and the directory that
 * must always resolve to it.
 *
 * <p>Why this is not a {@code ResourceHandler}: {@code ResourceHandlerRegistration} cannot give two patterns
 * different cache headers when one pattern is a prefix of the other — the longer pattern wins the mapping, so
 * {@code index.html} would inherit {@code /app/**}'s "immutable, one year" headers. That failure is silent and
 * the symptom is a student stuck on last week's build, so index.html gets its own controller.
 *
 * <p>{@code /app/} itself (and {@code /app}, which browsers request too) redirects to {@code index.html}
 * rather than serving the bytes at the directory URL: one canonical address, and the redirect itself is
 * no-store so the choice is re-made every time.
 */
@RestController
public class StudentIndexController {

    private final String appRoot;

    public StudentIndexController(String appRoot) {
        this.appRoot = appRoot == null ? "" : appRoot.trim();
    }

    @GetMapping({"/app", "/app/"})
    public ResponseEntity<Void> root() {
        return ResponseEntity.status(302)
            .cacheControl(CacheControl.noStore())
            .location(java.net.URI.create("/app/index.html"))
            .build();
    }

    @GetMapping("/app/index.html")
    public ResponseEntity<Resource> index() throws IOException {
        Path root = appRoot.isEmpty() ? null : Paths.get(appRoot);
        if (root == null || !Files.isDirectory(root)) {
            return ResponseEntity.notFound().cacheControl(CacheControl.noStore()).build();
        }
        Path file = root.resolve("index.html").normalize();
        // Defensive: resolve("index.html") cannot escape a directory, but the check is the reason it stays true.
        if (!file.startsWith(root.normalize()) || !Files.isRegularFile(file)) {
            return ResponseEntity.notFound().cacheControl(CacheControl.noStore()).build();
        }
        return ResponseEntity.ok()
            .cacheControl(CacheControl.noCache())
            .contentType(MediaType.TEXT_HTML)
            .body(new ByteArrayResource(Files.readAllBytes(file)));
    }
}
