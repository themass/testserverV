package com.timeline.student.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.timeline.student.domain.StudentErrors.NotFound;
import com.timeline.student.domain.StudentErrors.Unavailable;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;
import static com.timeline.student.domain.StudentVocabulary.BUNDLE_HASH;

/**
 * Reads compiled scene bundles written by the content pipeline's compiler:
 * {root}/{first 32 hex of hash}/bundle.json and manifest.json.
 *
 * This class decides nothing about publication; ContentService checks the database first. What it does
 * enforce is the file side: the hash is validated as exactly 64 hex characters before it touches a path,
 * the resolved path must stay under the root (symlinks not followed), the manifest must name the same
 * hash, and files over the size cap are refused.
 *
 * It does NOT re-derive the canonical hash from the bytes. The compiler owns canonicalisation (sorted
 * keys, JS number formatting); re-implementing it here could only produce false alarms. Integrity of
 * the bytes is the object store's / CDN's job; here we guarantee "this hash is published and its
 * manifest agrees".
 */
public class BundleStore {
    static final long MAX_BYTES = 8L * 1024 * 1024;
    private final Path root;
    private final ObjectMapper json;

    public BundleStore(String root, ObjectMapper json) {
        this.root = root == null || root.isBlank() ? null : Path.of(root).toAbsolutePath().normalize();
        this.json = json;
    }

    public boolean configured() { return root != null; }

    public byte[] bundle(String hash) { return read(hash, "bundle.json", false); }

    public byte[] manifest(String hash) { return read(hash, "manifest.json", true); }

    private byte[] read(String hash, String name, boolean checkManifestHash) {
        if (root == null) throw new Unavailable("student.bundle.root is not configured: bundles stay closed");
        if (hash == null || !BUNDLE_HASH.matcher(hash).matches()) throw new NotFound("bundle not found");
        Path dir = root.resolve(hash.substring(0, 32)).normalize();
        Path file = dir.resolve(name).normalize();
        if (!file.startsWith(root) || Files.isSymbolicLink(dir) || Files.isSymbolicLink(file)
                || !Files.isRegularFile(file, LinkOption.NOFOLLOW_LINKS)) throw new NotFound("bundle not found");
        try {
            if (Files.size(file) > MAX_BYTES) throw new NotFound("bundle not found");
            byte[] bytes = Files.readAllBytes(file);
            if (checkManifestHash || !name.equals("manifest.json")) verifyManifest(dir, hash, checkManifestHash ? bytes : null);
            return bytes;
        } catch (IOException ex) {
            throw new NotFound("bundle not found");
        }
    }

    private void verifyManifest(Path dir, String hash, byte[] alreadyRead) throws IOException {
        byte[] bytes = alreadyRead;
        if (bytes == null) {
            Path m = dir.resolve("manifest.json").normalize();
            if (!m.startsWith(root) || Files.isSymbolicLink(m) || !Files.isRegularFile(m, LinkOption.NOFOLLOW_LINKS)
                    || Files.size(m) > MAX_BYTES) throw new NotFound("bundle not found");
            bytes = Files.readAllBytes(m);
        }
        JsonNode node = json.readTree(bytes);
        String declared = node.path("bundle_hash").asText("");
        if (!hash.equals(declared)) throw new NotFound("bundle not found");
    }
}
