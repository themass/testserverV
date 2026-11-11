package com.timeline.student.config;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.concurrent.TimeUnit;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.CacheControl;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;
import org.springframework.web.servlet.resource.PathResourceResolver;

/**
 * Serves the student frontend and its assets from disk (docs/specs/2026-11-11-student-hosting.md).
 *
 * <p>Two roots, both off by default. A blank root registers nothing and the path 404s — a misconfigured
 * deployment serves nothing rather than accidentally serving the repository's working copy.
 *
 * <ul>
 *   <li>{@code /app/**}    {@code student.app.root}   — the built frontend ({@code dist/web})
 *   <li>{@code /assets/**} {@code student.asset.root} — scene assets, addressed by the uri the bundle names
 * </ul>
 *
 * <p>Cache: both are immutable for a year. The one file whose name never changes but whose content must is
 * {@code index.html}, and it is handled outside Spring's resource chain by {@link StudentIndexController},
 * because {@code ResourceHandlerRegistration} cannot give two patterns different headers when one is a
 * prefix of the other (the longer pattern wins the mapping, so index.html would take {@code /app/**}'s
 * headers and be cached for a year — the exact failure that leaves students on last week's build).
 *
 * <p>No history-mode fallback: the app routes on the fragment ({@code #/lesson/...}), so the server only
 * ever sees {@code /app/}. A catch-all would turn every typo into a 200 and make a missing file look like a
 * working deployment.
 */
public class StudentStaticResources implements WebMvcConfigurer {

    private static final Logger log = LoggerFactory.getLogger(StudentStaticResources.class);

    public static final String APP_PATTERN = "/app/**";
    public static final String ASSET_PATTERN = "/assets/**";

    private final String appRoot;
    private final String assetRoot;

    public StudentStaticResources(String appRoot, String assetRoot) {
        this.appRoot = appRoot == null ? "" : appRoot.trim();
        this.assetRoot = assetRoot == null ? "" : assetRoot.trim();
    }

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        Path app = usable("student.app.root", appRoot);
        Path assets = usable("student.asset.root", assetRoot);

        if (app != null) {
            registry.addResourceHandler(APP_PATTERN)
                .addResourceLocations(toLocation(app))
                .setCacheControl(IMMUTABLE)
                .resourceChain(true)
                .addResolver(new PathResourceResolver());
        }
        if (assets != null) {
            // Content-addressed: the uri carries the hash or version, so the path changes when the bytes do.
            registry.addResourceHandler(ASSET_PATTERN)
                .addResourceLocations(toLocation(assets))
                .setCacheControl(IMMUTABLE)
                .resourceChain(true)
                .addResolver(new PathResourceResolver());
        }
    }

    /** A year, public, immutable. Used for both roots; index.html is served separately with no-cache. */
    public static final CacheControl IMMUTABLE = CacheControl.maxAge(365, TimeUnit.DAYS).cachePublic().immutable();

    /**
     * A root that is blank or not an existing directory is skipped, loudly. Startup is not failed: a missing
     * asset directory should not take the whole host down, but it must not look like a working deployment.
     */
    private static Path usable(String property, String value) {
        if (value.isEmpty()) {
            return null;
        }
        Path path = Paths.get(value);
        if (Files.isDirectory(path)) {
            return path;
        }
        log.warn("{}={} 不是已存在的目录，该路径不注册（请求会 404）。核对挂载与权限。", property, value);
        return null;
    }

    /** {@code file:} location with a trailing slash; Spring resolves resources relative to it. */
    public static String toLocation(Path directory) {
        String uri = directory.toAbsolutePath().normalize().toUri().toString();
        return uri.endsWith("/") ? uri : uri + "/";
    }
}
