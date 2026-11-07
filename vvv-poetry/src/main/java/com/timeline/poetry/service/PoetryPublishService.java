package com.timeline.poetry.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.timeline.poetry.api.PoetryMediaModels.Asset;
import com.timeline.poetry.api.PoetryMediaModels.Written;
import com.timeline.poetry.api.PoetryPublishModels.ScriptGate;
import com.timeline.poetry.api.PoetryPublishModels.ScriptPublish;
import com.timeline.poetry.persistence.PoetryMediaMapper;
import com.timeline.poetry.persistence.PoetryPublishMapper;
import com.timeline.poetry.service.PoetryDraftService.Dirty;
import com.timeline.poetry.service.PoetryDraftService.Invalid;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;
import org.springframework.transaction.annotation.Transactional;

/**
 * Publish paths for scripts and assets: DRAFT -> PUBLISHED, conditional, inside one transaction, with the
 * same audit the write side already runs. Only the human reviewer endpoint reaches this class.
 *
 * Semantics (to be confirmed by the user; see docs/handoff/A.md §10 and the architecture review P0-1/P0-2):
 *  - script: its text version and every asset it pulls must already be PUBLISHED; the compiled manifest for
 *    the given bundle_hash must exist under bundleRoot and name this script; the flip happens only from DRAFT.
 *  - asset: rights and meaning are re-checked on the stored row; every link of its fallback chain down to L0
 *    must already be PUBLISHED, so a student who degrades never lands on a DRAFT row.
 *  - bundleRoot unset means script publish is refused: a bundle hash that nothing on disk can confirm is not
 *    a publish fact.
 */
public class PoetryPublishService {
    private static final ObjectMapper JSON = new ObjectMapper();

    private final PoetryPublishMapper publish;
    private final PoetryMediaMapper media;
    private final AuditRunner audit;
    private final Path bundleRoot;

    public PoetryPublishService(PoetryPublishMapper publish, PoetryMediaMapper media, AuditRunner audit, Path bundleRoot) {
        this.publish = publish; this.media = media; this.audit = audit; this.bundleRoot = bundleRoot;
    }

    @Transactional
    public Written publishScript(String id, String version, ScriptPublish req) {
        requireSlug(id, "script");
        if (version == null || !version.matches("^[0-9]+\\.[0-9]+\\.[0-9]+$"))
            throw new Invalid("script_version must be semantic (1.0.0): " + version);
        if (req == null || req.bundleHash() == null || !req.bundleHash().matches("^[a-f0-9]{64}$"))
            throw new Invalid("bundle_hash must be the full 64-character sha256 the compiler printed");
        if (req.compiledBy() == null || req.compiledBy().isBlank() || req.compiledBy().length() > 100)
            throw new Invalid("compiled_by is required (<=100 chars)");
        LocalDateTime at = parseCompiledAt(req.compiledAt());

        ScriptGate s = publish.scriptGate(id, version);
        if (s == null) throw new Invalid("script not found: " + id + "@" + version);
        if (!"DRAFT".equals(s.status()))
            throw new Invalid("only DRAFT scripts can be published: " + id + "@" + version + " is " + s.status());
        if (s.bundleHash() != null) throw new Invalid("script already carries a bundle_hash: " + id + "@" + version);
        if (!"PUBLISHED".equals(publish.textVersionStatus(s.textVersionId())))
            throw new Invalid("text version " + s.textVersionId() + " is not PUBLISHED: a script cannot publish on unpublished text");
        int open = publish.unpublishedAssetsOfScript(id, version);
        if (open > 0) throw new Invalid(open + " asset(s) referenced by this script are not PUBLISHED");
        if (publish.bundleHashTaken(req.bundleHash()) > 0)
            throw new Invalid("bundle_hash already belongs to another script version: " + req.bundleHash().substring(0, 12));
        verifyManifest(id, version, req.bundleHash());

        if (publish.publishScript(id, version, req.bundleHash(), req.compiledBy().trim(), at) != 1)
            throw new Invalid("script changed while publishing (no longer DRAFT): " + id + "@" + version);
        requireClean();
        return new Written(id + "@" + version, 1);
    }

    @Transactional
    public Written publishAsset(String id) {
        requireSlug(id, "asset");
        Asset a = media.anyAsset(id);
        if (a == null) throw new Invalid("asset not found: " + id);
        if (!"DRAFT".equals(a.status()))
            throw new Invalid("only DRAFT assets can be published: " + id + " is " + a.status());
        checkRow(a);
        checkFloor(a);
        if (publish.publishAsset(id) != 1) throw new Invalid("asset changed while publishing (no longer DRAFT): " + id);
        requireClean();
        return new Written(id, 1);
    }

    /** The row must already satisfy R4/R10; a row that does not is refused rather than repaired. */
    private static void checkRow(Asset a) {
        if (!PoetryMediaService.KINDS.contains(a.kind())) throw new Invalid("asset kind outside vocabulary: " + a.kind());
        if (!PoetryMediaService.LEVELS.contains(a.level())) throw new Invalid("asset level outside vocabulary: " + a.level());
        if (a.hash() == null || !a.hash().matches("^[a-f0-9]{12,64}$")) throw new Invalid("asset has no valid content hash: " + a.id());
        if (a.rightsOrigin() == null || a.rightsOrigin().isBlank() || a.rightsLicense() == null || a.rightsLicense().isBlank())
            throw new Invalid("asset has no rights (R10): " + a.id());
        if (a.meaning() == null || a.meaning().trim().length() < 8)
            throw new Invalid("asset has no meaning (R10): " + a.id());
    }

    /** Every link down to L0 must be PUBLISHED and strictly lower; a dead end or a loop refuses the publish. */
    private void checkFloor(Asset start) {
        Asset cursor = start;
        List<String> seen = new ArrayList<>();
        while (!"L0".equals(cursor.level())) {
            if (cursor.fallbackId() == null || cursor.fallbackId().isBlank())
                throw new Invalid("non-L0 asset " + cursor.id() + " declares no fallback");
            if (seen.contains(cursor.id()) || seen.size() >= 10)
                throw new Invalid("fallback chain from " + start.id() + " loops or is too long");
            seen.add(cursor.id());
            Asset next = media.anyAsset(cursor.fallbackId());
            if (next == null) throw new Invalid("fallback " + cursor.fallbackId() + " not found");
            if (!"PUBLISHED".equals(next.status()))
                throw new Invalid("fallback " + next.id() + " is not PUBLISHED (" + next.status() + "): the chain would dead-end");
            if (PoetryMediaService.LEVELS.indexOf(next.level()) >= PoetryMediaService.LEVELS.indexOf(cursor.level()))
                throw new Invalid("fallback must be a strictly lower level: " + cursor.level() + " -> " + next.level());
            cursor = next;
        }
    }

    /** Reads {bundleRoot}/{hash[0:32]}/manifest.json and checks that it names this script and this exact hash. */
    private void verifyManifest(String id, String version, String hash) {
        if (bundleRoot == null)
            throw new Invalid("poetry.bundleRoot is not configured: cannot confirm the compiled manifest, so script publish is refused");
        Path dir = bundleRoot.resolve(hash.substring(0, 32));
        Path manifest = dir.resolve("manifest.json");
        if (!Files.isRegularFile(manifest) || !Files.isRegularFile(dir.resolve("bundle.json")))
            throw new Invalid("no compiled bundle for hash " + hash.substring(0, 12) + " under the configured bundle root");
        try {
            JsonNode m = JSON.readTree(Files.readString(manifest));
            if (!hash.equals(m.path("bundle_hash").asText()) || !id.equals(m.path("script_id").asText())
                || !version.equals(m.path("script_version").asText()))
                throw new Invalid("manifest does not name " + id + "@" + version + " with this bundle_hash");
        } catch (IOException e) {
            throw new Invalid("manifest unreadable for hash " + hash.substring(0, 12));
        }
    }

    static LocalDateTime parseCompiledAt(String compiledAt) {
        if (compiledAt == null || compiledAt.isBlank())
            throw new Invalid("compiled_at is required (ISO-8601 instant, as the compiler manifest prints it)");
        try {
            return LocalDateTime.ofInstant(Instant.parse(compiledAt), ZoneOffset.UTC);
        } catch (DateTimeParseException e) {
            throw new Invalid("compiled_at must be ISO-8601 with a Z suffix: " + compiledAt);
        }
    }

    private void requireClean() {
        AuditRunner.Result r = audit.run();
        if (!r.clean()) throw new Dirty("write would leave the base unverified: " + r.nonZero());
    }

    private static void requireSlug(String value, String what) {
        if (value == null || value.isBlank() || value.length() > 64 || !value.matches("^[a-z0-9][a-z0-9._-]*$"))
            throw new Invalid(what + " id must be lowercase, <=64 chars, [a-z0-9._-]: " + value);
    }
}
