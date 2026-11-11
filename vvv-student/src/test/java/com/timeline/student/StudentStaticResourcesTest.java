package com.timeline.student;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.timeline.student.config.StudentStaticResources;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.web.context.support.StaticWebApplicationContext;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;

/**
 * A blank or unusable root must never serve anything (docs/specs/2026-11-11-student-hosting.md §3).
 * The cache policy is checked on the controller that owns index.html (StudentIndexControllerTest), because
 * index.html is deliberately NOT a resource handler there.
 */
class StudentStaticResourcesTest {

    private static ResourceHandlerRegistry registry() {
        return new ResourceHandlerRegistry(new StaticWebApplicationContext(), null);
    }

    @Test void blankRootsRegisterNothing() {
        ResourceHandlerRegistry reg = registry();
        new StudentStaticResources("", "").addResourceHandlers(reg);
        assertFalse(reg.hasMappingForPattern(StudentStaticResources.APP_PATTERN),
            "unconfigured must mean 404, not 'serve the working directory'");
        assertFalse(reg.hasMappingForPattern(StudentStaticResources.ASSET_PATTERN));
    }

    @Test void aRootThatIsNotADirectoryIsSkipped(@TempDir Path tmp) {
        ResourceHandlerRegistry reg = registry();
        new StudentStaticResources(tmp.resolve("does-not-exist").toString(), "").addResourceHandlers(reg);
        assertFalse(reg.hasMappingForPattern(StudentStaticResources.APP_PATTERN));
    }

    @Test void bothRootsRegisterWhenTheyExist(@TempDir Path tmp) throws IOException {
        Path app = Files.createDirectories(tmp.resolve("app"));
        Path assets = Files.createDirectories(tmp.resolve("assets"));
        ResourceHandlerRegistry reg = registry();
        new StudentStaticResources(app.toString(), assets.toString()).addResourceHandlers(reg);
        assertTrue(reg.hasMappingForPattern(StudentStaticResources.APP_PATTERN));
        assertTrue(reg.hasMappingForPattern(StudentStaticResources.ASSET_PATTERN));
    }

    @Test void appAndAssetRootsAreIndependent(@TempDir Path tmp) throws IOException {
        Path app = Files.createDirectories(tmp.resolve("app"));
        ResourceHandlerRegistry reg = registry();
        new StudentStaticResources(app.toString(), "").addResourceHandlers(reg);
        assertTrue(reg.hasMappingForPattern(StudentStaticResources.APP_PATTERN));
        assertFalse(reg.hasMappingForPattern(StudentStaticResources.ASSET_PATTERN), "only the configured root is served");
    }

    @Test void theSharedCachePolicyIsAYearPublicImmutable() {
        String header = StudentStaticResources.IMMUTABLE.getHeaderValue();
        assertTrue(header.contains("max-age=31536000"), header);
        assertTrue(header.contains("immutable"), header);
        assertTrue(header.contains("public"), header);
    }

    @Test void locationIsAnAbsoluteFileUriEndingWithASlash(@TempDir Path tmp) {
        String location = StudentStaticResources.toLocation(tmp);
        assertTrue(location.startsWith("file:"), location);
        assertTrue(location.endsWith("/"), location);
    }
}
