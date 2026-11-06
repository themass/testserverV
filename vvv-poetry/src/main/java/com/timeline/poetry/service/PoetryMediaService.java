package com.timeline.poetry.service;

import com.timeline.poetry.api.PoetryMediaModels.*;
import com.timeline.poetry.persistence.PoetryMediaMapper;
import com.timeline.poetry.service.PoetryDraftService.Dirty;
import com.timeline.poetry.service.PoetryDraftService.Invalid;
import java.util.ArrayList;
import java.util.List;
import org.springframework.transaction.annotation.Transactional;

/**
 * Media + script authoring over the V006 tables. The rules enforced here are the ones the bundle
 * compiler enforces too (docs/specs/2026-11-06-qijing-script-dsl.md R4/R9/R10): an asset that
 * cannot say which line it explains, or that has no path down to text, is refused at write time
 * instead of becoming a broken bundle later. There is deliberately no publish method here.
 */
public class PoetryMediaService {
    static final List<String> KINDS =
        List.of("illustration", "map", "character", "audio", "voice", "subtitle", "video");
    static final List<String> LEVELS = List.of("L0", "L1", "L2", "L3", "L4");
    static final List<String> STEPS = List.of("read", "arrive", "meet", "return", "recite");

    private final PoetryMediaMapper media;
    private final AuditRunner audit;

    public PoetryMediaService(PoetryMediaMapper media, AuditRunner audit) {
        this.media = media; this.audit = audit;
    }

    private static int z(Integer v) { return v == null ? 0 : v; }
    private static long z(long fallback, Long v) { return v == null ? fallback : v; }

    @Transactional
    public Written createAsset(String id, AssetWrite w) {
        requireId(id);
        if (z(media.existsAsset(id)) > 0) throw new Invalid("asset id already exists: " + id);
        validate(id, w);
        media.insertAsset(id, w.kind(), w.level(), w.uri(), w.hash(), z(0L, w.bytes()), w.fallbackId(),
            w.meaning().trim(), w.workflowRef(), Boolean.TRUE.equals(w.humanFix()),
            w.rightsOrigin().trim(), w.rightsLicense().trim());
        requireClean();
        return new Written(id, 1);
    }

    @Transactional
    public Written updateAsset(String id, AssetWrite w) {
        Asset current = media.anyAsset(id);
        if (current == null) throw new Invalid("asset not found: " + id);
        if (!"DRAFT".equals(current.status()))
            throw new Invalid("only DRAFT assets are editable: " + id + " is " + current.status());
        validate(id, w);
        if (media.updateAsset(id, w) == 0) throw new Invalid("nothing updated (draft only): " + id);
        requireClean();
        return new Written(id, 1);
    }

    /** R4: kind/level vocabulary, content hash, rights, meaning, and a strictly descending chain. */
    private void validate(String id, AssetWrite w) {
        if (w.kind() == null || !KINDS.contains(w.kind()))
            throw new Invalid("asset kind outside vocabulary: " + w.kind());
        if (w.level() == null || !LEVELS.contains(w.level()))
            throw new Invalid("asset level outside vocabulary L0..L4: " + w.level());
        if (w.uri() == null || w.uri().isBlank() || w.uri().length() > 500)
            throw new Invalid("uri is required (object key, not a signed url) and must be <=500 chars");
        if (w.hash() == null || !w.hash().matches("^[a-f0-9]{12,64}$"))
            throw new Invalid("hash must be 12-64 lowercase hex: content addressing is how offline and rollback work");
        if (z(media.hashTaken(w.hash(), id)) > 0)
            throw new Invalid("hash already used by another asset: " + w.hash());
        if (z(-1L, w.bytes()) < 0) throw new Invalid("bytes cannot be negative");
        if (w.meaning() == null || w.meaning().trim().length() < 8)
            throw new Invalid("meaning is required: say which line this asset helps the student understand");
        if (w.rightsOrigin() == null || w.rightsOrigin().isBlank()
            || w.rightsLicense() == null || w.rightsLicense().isBlank())
            throw new Invalid("rights_origin and rights_license are required (R10)");
        if ("L0".equals(w.level())) {
            if (w.fallbackId() != null && !w.fallbackId().isBlank())
                throw new Invalid("L0 is the floor: it must not declare a fallback");
        } else {
            if (w.fallbackId() == null || w.fallbackId().isBlank())
                throw new Invalid("non-L0 asset must declare fallback_id: every asset needs a path down to text");
            if (w.fallbackId().equals(id)) throw new Invalid("asset cannot fall back to itself: " + id);
            String lower = levelOf(w.fallbackId());
            if (LEVELS.indexOf(lower) >= LEVELS.indexOf(w.level()))
                throw new Invalid("fallback must be a strictly lower level: " + w.level() + " -> " + lower);
        }
    }

    private String levelOf(String assetId) {
        Asset a = media.anyAsset(assetId);
        if (a == null) throw new Invalid("fallback asset not found (create the lower level first): " + assetId);
        return a.level();
    }

    /** Walk the declared chain. Loop or dead end is a data error, surfaced instead of guessed around. */
    public Chain chain(String assetId) {
        Asset start = media.anyAsset(assetId);
        if (start == null) throw new Invalid("asset not found: " + assetId);
        List<ChainLink> chain = new ArrayList<>();
        List<String> seen = new ArrayList<>();
        Asset cursor = start;
        boolean reachesText = false, loop = false;
        while (cursor != null && chain.size() <= 10) {
            chain.add(new ChainLink(cursor.id(), cursor.level(), cursor.hash(), cursor.meaning()));
            if ("L0".equals(cursor.level())) { reachesText = true; break; }
            if (seen.contains(cursor.id())) { loop = true; break; }
            seen.add(cursor.id());
            cursor = cursor.fallbackId() == null ? null : media.anyAsset(cursor.fallbackId());
        }
        return new Chain(assetId, List.copyOf(chain), reachesText, loop);
    }


    /* ---------- read side: PUBLISHED only, so a draft asset can never reach a student ---------- */

    public List<Asset> assets(String level, int limit, int offset) {
        return media.assets(validLevel(level), clamp(limit, 200), Math.max(0, offset));
    }

    public Asset asset(String id) {
        Asset a = media.asset(id);
        if (a == null) throw new Invalid("published asset not found: " + id);
        return a;
    }

    public List<Script> scripts(int limit, int offset) { return media.scripts(clamp(limit, 100), Math.max(0, offset)); }

    public ScriptDetail scriptDetail(String id) {
        Script s = media.script(id);
        if (s == null) throw new Invalid("published script not found: " + id);
        return new ScriptDetail(s, media.scriptAssets(s.id(), s.scriptVersion()));
    }

    private static String validLevel(String level) {
        if (level == null || level.isBlank()) return null;
        if (!LEVELS.contains(level)) throw new Invalid("level filter outside L0..L4: " + level);
        return level;
    }

    private static int clamp(int value, int max) { return Math.min(Math.max(value, 1), max); }

    /* ---------- script authoring: references are resolved before the insert, no FKs exist ---------- */

    @Transactional
    public Written createScript(String id, String version, ScriptWrite w) {
        requireSlug(id, "script");
        if (version == null || !version.matches("^[0-9]+\\.[0-9]+\\.[0-9]+$"))
            throw new Invalid("script_version must be semantic (1.0.0): " + version);
        if (z(media.existsScript(id, version)) > 0) throw new Invalid("script version exists: " + id + "@" + version);
        String schema = w.schemaVersion() == null ? "1.0" : w.schemaVersion();
        if (!schema.startsWith("1.")) throw new Invalid("schema_version outside 1.x: " + schema);
        if (z(media.existsWork(w.workId())) == 0) throw new Invalid("work not found: " + w.workId());
        if (z(media.versionOfWork(w.textVersionId(), w.workId())) == 0)
            throw new Invalid("text version is not a version of that work: " + w.textVersionId() + " / " + w.workId());
        if (w.coverageNotice() == null || w.coverageNotice().trim().length() < 12)
            throw new Invalid("coverage_notice is required and must say what this round does NOT cover (R5)");
        media.insertScript(id, version, schema, w.workId(), w.textVersionId(), w.coverageNotice().trim());
        requireClean();
        return new Written(id + "@" + version, 1);
    }

    @Transactional
    public int registerAssets(String scriptId, String version, List<ScriptAssetWrite> rows) {
        if (z(media.existsScript(scriptId, version)) == 0)
            throw new Invalid("script not found: " + scriptId + "@" + version);
        if (rows == null || rows.isEmpty()) throw new Invalid("no assets given");
        int n = 0;
        for (ScriptAssetWrite r : rows) {
            if (r.assetId() == null || z(media.existsAsset(r.assetId())) == 0)
                throw new Invalid("asset not found: " + r.assetId());
            if (r.step() == null || !STEPS.contains(r.step()))
                throw new Invalid("step outside the five steps: " + r.step());
            n += media.insertScriptAsset(scriptId, version, r.assetId(), r.step());
        }
        requireClean();
        return n;
    }

    private static void requireSlug(String value, String what) {
        if (value == null || value.isBlank() || value.length() > 64 || !value.matches("^[a-z0-9][a-z0-9._-]*$"))
            throw new Invalid(what + " id must be lowercase, <=64 chars, [a-z0-9._-]: " + value);
    }
    private void requireClean() {
        AuditRunner.Result r = audit.run();
        if (!r.clean()) throw new Dirty("write would leave the base unverified: " + r.nonZero());
    }

    private static void requireId(String id) {
        if (id == null || id.isBlank() || id.length() > 64 || !id.matches("^[a-z0-9][a-z0-9._-]*$"))
            throw new Invalid("asset id must be lowercase, <=64 chars, [a-z0-9._-]: " + id);
    }
}
