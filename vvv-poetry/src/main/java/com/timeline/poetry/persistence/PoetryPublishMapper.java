package com.timeline.poetry.persistence;

import com.timeline.poetry.api.PoetryPublishModels.ScriptGate;
import java.time.LocalDateTime;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;

/**
 * Publish statements only. Reads of assets go through PoetryMediaMapper; this interface adds the
 * conditional status flips and the checks a publish needs. No foreign keys exist, so every reference
 * is resolved here before the flip, and each flip is conditional on DRAFT so a race fails loudly.
 */
public interface PoetryPublishMapper {
    @Select("SELECT status, bundle_hash AS bundleHash, text_version_id AS textVersionId FROM poetry_script"
        + " WHERE id=#{id} AND script_version=#{version}")
    ScriptGate scriptGate(@Param("id") String id, @Param("version") String version);

    @Select("SELECT status FROM poetry_text_version WHERE id=#{id}")
    String textVersionStatus(@Param("id") String id);

    /** Assets the script pulls that are missing or not PUBLISHED. Zero means the script may publish. */
    @Select("SELECT COUNT(*) FROM poetry_script_asset sa LEFT JOIN poetry_asset a ON a.id=sa.asset_id"
        + " WHERE sa.script_id=#{id} AND sa.script_version=#{version} AND (a.id IS NULL OR a.status<>'PUBLISHED')")
    int unpublishedAssetsOfScript(@Param("id") String id, @Param("version") String version);

    @Select("SELECT COUNT(*) FROM poetry_script WHERE bundle_hash=#{hash}")
    int bundleHashTaken(@Param("hash") String hash);

    @Update("UPDATE poetry_script SET status='PUBLISHED', bundle_hash=#{hash}, compiled_by=#{compiledBy},"
        + " compiled_at=#{compiledAt}, revision=revision+1"
        + " WHERE id=#{id} AND script_version=#{version} AND status='DRAFT' AND bundle_hash IS NULL")
    int publishScript(@Param("id") String id, @Param("version") String version, @Param("hash") String hash,
                      @Param("compiledBy") String compiledBy, @Param("compiledAt") LocalDateTime compiledAt);

    @Update("UPDATE poetry_asset SET status='PUBLISHED' WHERE id=#{id} AND status='DRAFT'")
    int publishAsset(@Param("id") String id);
}
