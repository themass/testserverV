package com.timeline.student;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.timeline.student.domain.StudentErrors.NotFound;
import com.timeline.student.domain.StudentErrors.Unavailable;
import com.timeline.student.service.BundleStore;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import static org.junit.jupiter.api.Assertions.*;

class BundleStoreTest {
    private static final String HASH = "60279d333becba38e65414e58d433ee58235acb08841277ddf7d62a598f91d11";
    private final ObjectMapper json = new ObjectMapper();

    private BundleStore store(Path root) { return new BundleStore(root.toString(), json); }

    private void write(Path root, String hash, String bundle, String manifestHash) throws IOException {
        Path dir = root.resolve(hash.substring(0, 32));
        Files.createDirectories(dir);
        Files.writeString(dir.resolve("bundle.json"), bundle, StandardCharsets.UTF_8);
        Files.writeString(dir.resolve("manifest.json"), "{\"bundle_hash\":\"" + manifestHash + "\"}", StandardCharsets.UTF_8);
    }

    @Test void servesABundleWhoseManifestNamesTheSameHash(@TempDir Path root) throws IOException {
        write(root, HASH, "{\"script_id\":\"qj-chun-wang\"}", HASH);
        assertTrue(new String(store(root).bundle(HASH), StandardCharsets.UTF_8).contains("qj-chun-wang"));
        assertTrue(new String(store(root).manifest(HASH), StandardCharsets.UTF_8).contains(HASH));
    }

    @Test void refusesWhenTheManifestDisagrees(@TempDir Path root) throws IOException {
        write(root, HASH, "{}", "f".repeat(64));
        assertThrows(NotFound.class, () -> store(root).bundle(HASH));
        assertThrows(NotFound.class, () -> store(root).manifest(HASH));
    }

    @Test void anythingButAFullLowerCaseHexHashNeverTouchesTheFilesystem(@TempDir Path root) throws IOException {
        write(root, HASH, "{}", HASH);
        for (String bad : new String[] {"../" + HASH, "..", "", " ", HASH.substring(0, 32), HASH.toUpperCase(),
                HASH + "0", "60279d333becba38e65414e58d433ee5/../x", "%2e%2e%2f", null})
            assertThrows(NotFound.class, () -> store(root).bundle(bad), String.valueOf(bad));
    }

    @Test void unknownHashIsNotFound(@TempDir Path root) {
        assertThrows(NotFound.class, () -> store(root).bundle("a".repeat(64)));
    }

    @Test void symlinkedDirectoriesAreNotFollowed(@TempDir Path root, @TempDir Path elsewhere) throws IOException {
        write(elsewhere, HASH, "{\"leak\":true}", HASH);
        Files.createSymbolicLink(root.resolve(HASH.substring(0, 32)), elsewhere.resolve(HASH.substring(0, 32)));
        assertThrows(NotFound.class, () -> store(root).bundle(HASH));
    }

    @Test void unconfiguredRootFailsClosedWithUnavailable() {
        assertThrows(Unavailable.class, () -> new BundleStore("", json).bundle(HASH));
        assertThrows(Unavailable.class, () -> new BundleStore(null, json).bundle(HASH));
        assertFalse(new BundleStore("  ", json).configured());
    }

    @Test void oversizedFilesAreRefused(@TempDir Path root) throws IOException {
        write(root, HASH, "x".repeat(8 * 1024 * 1024 + 1), HASH);
        assertThrows(NotFound.class, () -> store(root).bundle(HASH));
    }
}
