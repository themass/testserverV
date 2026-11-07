package com.timeline.poetry;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.timeline.poetry.api.PoetryMediaModels.Asset;
import com.timeline.poetry.api.PoetryPublishController;
import com.timeline.poetry.api.PoetryPublishModels.ScriptGate;
import com.timeline.poetry.api.PoetryPublishModels.ScriptPublish;
import com.timeline.poetry.persistence.PoetryMediaMapper;
import com.timeline.poetry.persistence.PoetryPublishMapper;
import com.timeline.poetry.service.AuditRunner;
import com.timeline.poetry.service.PoetryDraftService.Dirty;
import com.timeline.poetry.service.PoetryDraftService.Invalid;
import com.timeline.poetry.service.PoetryPublishService;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

/**
 * Publish paths (P0-1 / P0-2). Written, not run: the mapper is mocked, so these check the decisions the
 * service makes, not the SQL. The SQL is covered by the conditional UPDATEs and by the audit that runs after.
 */
class PoetryPublishTest {
    private static final String HASH = "a".repeat(64);
    private PoetryPublishMapper publish;
    private PoetryMediaMapper media;
    private AuditRunner audit;
    private Path root;
    private PoetryPublishService svc;

    @BeforeEach
    void setUp(@TempDir Path tmp) {
        publish = mock(PoetryPublishMapper.class);
        media = mock(PoetryMediaMapper.class);
        audit = mock(AuditRunner.class);
        when(audit.run()).thenReturn(new AuditRunner.Result(156, List.of()));
        root = tmp;
        svc = new PoetryPublishService(publish, media, audit, root);
    }

    private void writeManifest(String scriptId, String version, String hash) throws IOException {
        Path dir = root.resolve(hash.substring(0, 32));
        Files.createDirectories(dir);
        Files.writeString(dir.resolve("bundle.json"), "{}");
        Files.writeString(dir.resolve("manifest.json"),
            "{\"bundle_hash\":\"" + hash + "\",\"script_id\":\"" + scriptId + "\",\"script_version\":\"" + version + "\"}");
    }

    private static ScriptPublish req(String hash) {
        return new ScriptPublish(hash, "reviewer-1", "2026-11-07T00:00:00.000Z");
    }

    private void readyScript() {
        when(publish.scriptGate("chun", "1.0.0")).thenReturn(new ScriptGate("DRAFT", null, "tv-1"));
        when(publish.textVersionStatus("tv-1")).thenReturn("PUBLISHED");
        when(publish.unpublishedAssetsOfScript("chun", "1.0.0")).thenReturn(0);
        when(publish.bundleHashTaken(HASH)).thenReturn(0);
        when(publish.publishScript(eq("chun"), eq("1.0.0"), eq(HASH), eq("reviewer-1"), any())).thenReturn(1);
    }

    private static Asset asset(String id, String level, String fallback, String status) {
        return new Asset(id, "illustration", level, "objects/" + id, "abcdef123456", 0L, fallback,
            "says which line this image helps the student understand", null, false,
            "origin-museum", "CC-BY-4.0", status);
    }

    /* ---------- scripts ---------- */

    @Test
    void scriptPublishesWhenTextAssetsAndManifestAllHold() throws IOException {
        writeManifest("chun", "1.0.0", HASH);
        readyScript();
        assertEquals("chun@1.0.0", svc.publishScript("chun", "1.0.0", req(HASH)).id());
        verify(publish).publishScript(eq("chun"), eq("1.0.0"), eq(HASH), eq("reviewer-1"), any());
    }

    @Test
    void scriptRefusedWhenNoBundleRootIsConfigured() {
        svc = new PoetryPublishService(publish, media, audit, null);
        readyScript();
        assertThrows(Invalid.class, () -> svc.publishScript("chun", "1.0.0", req(HASH)));
        verify(publish, never()).publishScript(anyString(), anyString(), anyString(), anyString(), any());
    }

    @Test
    void scriptRefusedWhenManifestNamesAnotherScript() throws IOException {
        writeManifest("other", "1.0.0", HASH);
        readyScript();
        assertThrows(Invalid.class, () -> svc.publishScript("chun", "1.0.0", req(HASH)));
        verify(publish, never()).publishScript(anyString(), anyString(), anyString(), anyString(), any());
    }

    @Test
    void scriptRefusedWhenNoCompiledBundleExistsForTheHash() {
        readyScript();
        assertThrows(Invalid.class, () -> svc.publishScript("chun", "1.0.0", req(HASH)));
    }

    @Test
    void scriptRefusedWhenItsTextVersionIsNotPublished() throws IOException {
        writeManifest("chun", "1.0.0", HASH);
        readyScript();
        when(publish.textVersionStatus("tv-1")).thenReturn("DRAFT");
        assertThrows(Invalid.class, () -> svc.publishScript("chun", "1.0.0", req(HASH)));
    }

    @Test
    void scriptRefusedWhenAnyReferencedAssetIsNotPublished() throws IOException {
        writeManifest("chun", "1.0.0", HASH);
        readyScript();
        when(publish.unpublishedAssetsOfScript("chun", "1.0.0")).thenReturn(2);
        assertThrows(Invalid.class, () -> svc.publishScript("chun", "1.0.0", req(HASH)));
    }

    @Test
    void scriptRefusedWhenItIsNotDraft() throws IOException {
        writeManifest("chun", "1.0.0", HASH);
        readyScript();
        when(publish.scriptGate("chun", "1.0.0")).thenReturn(new ScriptGate("PUBLISHED", HASH, "tv-1"));
        assertThrows(Invalid.class, () -> svc.publishScript("chun", "1.0.0", req(HASH)));
    }

    @Test
    void scriptRefusedWhenTheHashBelongsToAnotherVersion() throws IOException {
        writeManifest("chun", "1.0.0", HASH);
        readyScript();
        when(publish.bundleHashTaken(HASH)).thenReturn(1);
        assertThrows(Invalid.class, () -> svc.publishScript("chun", "1.0.0", req(HASH)));
    }

    @Test
    void scriptRefusedOnMalformedHashOrTimestamp() throws IOException {
        writeManifest("chun", "1.0.0", HASH);
        readyScript();
        assertThrows(Invalid.class, () -> svc.publishScript("chun", "1.0.0", req("not-a-hash")));
        assertThrows(Invalid.class, () -> svc.publishScript("chun", "1.0.0",
            new ScriptPublish(HASH, "reviewer-1", "yesterday")));
    }

    @Test
    void scriptIsRolledBackWhenTheAuditIsDirty() throws IOException {
        writeManifest("chun", "1.0.0", HASH);
        readyScript();
        when(audit.run()).thenReturn(new AuditRunner.Result(156, List.of("item_missing_proposal=1")));
        assertThrows(Dirty.class, () -> svc.publishScript("chun", "1.0.0", req(HASH)));
    }

    /* ---------- assets ---------- */

    @Test
    void assetPublishesWhenItsWholeFallbackChainIsPublished() {
        when(media.anyAsset("a-l1")).thenReturn(asset("a-l1", "L1", "a-l0", "DRAFT"));
        when(media.anyAsset("a-l0")).thenReturn(asset("a-l0", "L0", null, "PUBLISHED"));
        when(publish.publishAsset("a-l1")).thenReturn(1);
        assertEquals("a-l1", svc.publishAsset("a-l1").id());
        verify(publish).publishAsset("a-l1");
    }

    @Test
    void assetRefusedWhenTheFloorBelowIsStillDraft() {
        when(media.anyAsset("a-l1")).thenReturn(asset("a-l1", "L1", "a-l0", "DRAFT"));
        when(media.anyAsset("a-l0")).thenReturn(asset("a-l0", "L0", null, "DRAFT"));
        assertThrows(Invalid.class, () -> svc.publishAsset("a-l1"));
        verify(publish, never()).publishAsset(anyString());
    }

    @Test
    void assetRefusedWhenANonFloorAssetHasNoFallback() {
        when(media.anyAsset("a-l2")).thenReturn(asset("a-l2", "L2", null, "DRAFT"));
        assertThrows(Invalid.class, () -> svc.publishAsset("a-l2"));
    }

    @Test
    void assetRefusedWhenFallbackIsNotStrictlyLower() {
        when(media.anyAsset("a-l1")).thenReturn(asset("a-l1", "L1", "a-l2", "DRAFT"));
        when(media.anyAsset("a-l2")).thenReturn(asset("a-l2", "L2", "a-l0", "PUBLISHED"));
        assertThrows(Invalid.class, () -> svc.publishAsset("a-l1"));
    }

    @Test
    void assetRefusedWhenRightsAreMissing() {
        Asset noRights = new Asset("a-l0", "illustration", "L0", "objects/a-l0", "abcdef123456", 0L, null,
            "says which line this image helps the student understand", null, false, " ", "CC-BY-4.0", "DRAFT");
        when(media.anyAsset("a-l0")).thenReturn(noRights);
        assertThrows(Invalid.class, () -> svc.publishAsset("a-l0"));
    }

    @Test
    void assetRefusedWhenItIsNotDraft() {
        when(media.anyAsset("a-l0")).thenReturn(asset("a-l0", "L0", null, "PUBLISHED"));
        assertThrows(Invalid.class, () -> svc.publishAsset("a-l0"));
    }

    /* ---------- human gate on the controller ---------- */

    @Test
    void publishStaysClosedWhenTheReviewerTokenIsUnsetOrEqualsTheAgentToken() {
        PoetryPublishController unset = new PoetryPublishController(svc, "", "agent-secret");
        assertEquals(503, unset.publishAsset("anything", "a-l0").getStatusCode().value());
        PoetryPublishController same = new PoetryPublishController(svc, "same", "same");
        assertEquals(503, same.publishAsset("same", "a-l0").getStatusCode().value());
    }

    @Test
    void agentTokenIsRefusedAndOnlyTheReviewerTokenPasses() {
        PoetryPublishController c = new PoetryPublishController(svc, "reviewer-secret", "agent-secret");
        assertEquals(401, c.publishAsset(null, "a-l0").getStatusCode().value());
        assertEquals(401, c.publishAsset("agent-secret", "a-l0").getStatusCode().value());
        when(media.anyAsset("a-l0")).thenReturn(asset("a-l0", "L0", null, "DRAFT"));
        when(publish.publishAsset("a-l0")).thenReturn(1);
        assertEquals(200, c.publishAsset("reviewer-secret", "a-l0").getStatusCode().value());
    }
}
