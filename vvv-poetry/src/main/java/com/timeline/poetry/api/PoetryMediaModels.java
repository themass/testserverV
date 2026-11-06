package com.timeline.poetry.api;

import java.util.List;

/** Media + script side of the base (V006). Read side exposes PUBLISHED only; write side writes DRAFT only. */
public final class PoetryMediaModels {
    private PoetryMediaModels() {}

    public record Asset(String id, String kind, String level, String uri, String hash, Long bytes,
                        String fallbackId, String meaning, String workflowRef, Boolean humanFix,
                        String rightsOrigin, String rightsLicense, String status) {}
    /** No status field on purpose: this endpoint cannot publish, and it cannot retire either. */
    public record AssetWrite(String kind, String level, String uri, String hash, Long bytes,
                             String fallbackId, String meaning, String workflowRef, Boolean humanFix,
                             String rightsOrigin, String rightsLicense) {}
    /** The degradation path as the base sees it — the client may differ, this is what was reviewed. */
    public record ChainLink(String assetId, String level, String hash, String meaning) {}
    public record Chain(String assetId, List<ChainLink> chain, boolean reachesText, boolean loop) {}

    public record Script(String id, String scriptVersion, String schemaVersion, String workId,
                         String textVersionId, String coverageNotice, String bundleHash,
                         String compiledBy, String compiledAt, Integer revision) {}
    public record ScriptWrite(String schemaVersion, String workId, String textVersionId, String coverageNotice) {}
    public record ScriptAssetWrite(String assetId, String step) {}
    public record ScriptDetail(Script script, List<Asset> assets) {}
    public record Written(String id, Integer revision) {}
}
