package com.timeline.poetry.persistence;

import com.timeline.poetry.api.PoetryMediaModels.*;
import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import java.util.List;
import static com.timeline.poetry.persistence.PoetrySql.PAGE;

/** V006 tables. No foreign keys, so every write path here resolves its references before inserting. */
public interface PoetryMediaMapper {
    String A = "a.id,a.kind,a.level,a.uri,a.hash,a.bytes,a.fallback_id AS fallbackId,a.meaning,"
        + "a.workflow_ref AS workflowRef,a.human_fix AS humanFix,a.rights_origin AS rightsOrigin,"
        + "a.rights_license AS rightsLicense,a.status";

    @Select("SELECT " + A + " FROM poetry_asset a WHERE a.status='PUBLISHED'"
        + " AND (#{level} IS NULL OR a.level=#{level}) ORDER BY a.level,a.id" + PAGE)
    List<Asset> assets(@Param("level") String level, @Param("fetchLimit") int fetchLimit,
                       @Param("offset") int offset);

    @Select("SELECT " + A + " FROM poetry_asset a WHERE a.status='PUBLISHED' AND a.id=#{id}")
    Asset asset(@Param("id") String id);

    @Select("SELECT " + A + " FROM poetry_asset a WHERE a.id=#{id}")
    Asset anyAsset(@Param("id") String id);

    @Select("SELECT COUNT(*) FROM poetry_asset WHERE id=#{id}")
    int existsAsset(@Param("id") String id);

    @Select("SELECT COUNT(*) FROM poetry_asset WHERE hash=#{hash} AND id<>#{id}")
    int hashTaken(@Param("hash") String hash, @Param("id") String id);

    @Insert("INSERT INTO poetry_asset (id,kind,level,uri,hash,bytes,fallback_id,meaning,workflow_ref,human_fix,"
        + "rights_origin,rights_license) VALUES (#{id},#{kind},#{level},#{uri},#{hash},#{bytes},#{fallbackId},"
        + "#{meaning},#{workflowRef},#{humanFix},#{rightsOrigin},#{rightsLicense})")
    int insertAsset(@Param("id") String id, @Param("kind") String kind, @Param("level") String level,
                    @Param("uri") String uri, @Param("hash") String hash, @Param("bytes") long bytes,
                    @Param("fallbackId") String fallbackId, @Param("meaning") String meaning,
                    @Param("workflowRef") String workflowRef, @Param("humanFix") boolean humanFix,
                    @Param("rightsOrigin") String rightsOrigin, @Param("rightsLicense") String rightsLicense);

    @org.apache.ibatis.annotations.Update("UPDATE poetry_asset SET kind=#{u.kind},level=#{u.level},uri=#{u.uri},"
        + "hash=#{u.hash},bytes=#{u.bytes},fallback_id=#{u.fallbackId},meaning=#{u.meaning},"
        + "workflow_ref=#{u.workflowRef},human_fix=#{u.humanFix},rights_origin=#{u.rightsOrigin},"
        + "rights_license=#{u.rightsLicense} WHERE id=#{id} AND status='DRAFT'")
    int updateAsset(@Param("id") String id, @Param("u") AssetWrite u);

    @Select("SELECT COUNT(*) FROM poetry_content WHERE id=#{id} AND entity_type='WORK'")
    int existsWork(@Param("id") String id);

    @Select("SELECT COUNT(*) FROM poetry_text_version WHERE id=#{id} AND work_id=#{workId}")
    int versionOfWork(@Param("id") String id, @Param("workId") String workId);

    @Select("SELECT s.id,s.script_version AS scriptVersion,s.schema_version AS schemaVersion,s.work_id AS workId,"
        + "s.text_version_id AS textVersionId,s.coverage_notice AS coverageNotice,s.bundle_hash AS bundleHash,"
        + "s.compiled_by AS compiledBy,s.compiled_at AS compiledAt,s.revision FROM poetry_script s"
        + " WHERE s.status='PUBLISHED' ORDER BY s.id,s.script_version DESC" + PAGE)
    List<Script> scripts(@Param("fetchLimit") int fetchLimit, @Param("offset") int offset);

    @Select("SELECT s.id,s.script_version AS scriptVersion,s.schema_version AS schemaVersion,s.work_id AS workId,"
        + "s.text_version_id AS textVersionId,s.coverage_notice AS coverageNotice,s.bundle_hash AS bundleHash,"
        + "s.compiled_by AS compiledBy,s.compiled_at AS compiledAt,s.revision FROM poetry_script s"
        + " WHERE s.status='PUBLISHED' AND s.id=#{id} ORDER BY s.script_version DESC LIMIT 1")
    Script script(@Param("id") String id);

    @Select("SELECT " + A + " FROM poetry_script_asset sa JOIN poetry_asset a ON a.id=sa.asset_id"
        + " WHERE sa.script_id=#{id} AND sa.script_version=#{version} AND a.status='PUBLISHED'"
        + " ORDER BY a.level,a.id")
    List<Asset> scriptAssets(@Param("id") String id, @Param("version") String version);

    @Select("SELECT COUNT(*) FROM poetry_script WHERE id=#{id} AND script_version=#{version}")
    int existsScript(@Param("id") String id, @Param("version") String version);

    @Insert("INSERT INTO poetry_script (id,script_version,schema_version,work_id,text_version_id,coverage_notice)"
        + " VALUES (#{id},#{version},#{schemaVersion},#{workId},#{textVersionId},#{coverageNotice})")
    int insertScript(@Param("id") String id, @Param("version") String version,
                     @Param("schemaVersion") String schemaVersion, @Param("workId") String workId,
                     @Param("textVersionId") String textVersionId, @Param("coverageNotice") String coverageNotice);

    @Insert("INSERT INTO poetry_script_asset (script_id,script_version,asset_id,step)"
        + " VALUES (#{scriptId},#{scriptVersion},#{assetId},#{step})")
    int insertScriptAsset(@Param("scriptId") String scriptId, @Param("scriptVersion") String scriptVersion,
                          @Param("assetId") String assetId, @Param("step") String step);
}
