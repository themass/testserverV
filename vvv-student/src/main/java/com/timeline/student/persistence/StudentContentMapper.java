package com.timeline.student.persistence;

import com.timeline.student.api.StudentModels.AnnotationItem;
import com.timeline.student.api.StudentModels.AssetRow;
import com.timeline.student.api.StudentModels.LessonEntry;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import java.util.List;
import static com.timeline.student.persistence.StudentSql.*;

/**
 * Read-only access to the few published poetry_* rows PoetryCatalog does not expose. Every query carries a
 * PUBLISHED condition; this interface has no @Insert/@Update/@Delete and must never get one.
 * Column order in each SELECT matches the record constructor order (MyBatis constructor auto-mapping).
 */
public interface StudentContentMapper {

    /** Newest published script of a work that has a compiled bundle. */
    @Select("SELECT sc.id, sc.script_version, sc.schema_version, sc.work_id, sc.text_version_id, sc.bundle_hash, "
        + "sc.coverage_notice FROM poetry_script sc WHERE " + PUBLIC_SCRIPT + " AND sc.work_id=#{workId} "
        + "AND EXISTS (SELECT 1 FROM poetry_text_version v JOIN poetry_source s ON s.id=v.source_id "
        + "WHERE v.id=sc.text_version_id AND v.work_id=sc.work_id AND " + PUBLIC_VERSION + ") "
        + "ORDER BY sc.compiled_at DESC, sc.script_version DESC LIMIT 1")
    LessonEntry latestLesson(@Param("workId") String workId);

    /** Work ids that have at least one servable lesson; used to mark timeline cards and the home page. */
    @Select("SELECT DISTINCT sc.work_id FROM poetry_script sc WHERE " + PUBLIC_SCRIPT + " ORDER BY sc.work_id LIMIT 200")
    List<String> lessonWorkIds();

    /** True only when a published script with exactly this bundle hash exists. */
    @Select("SELECT COUNT(*) FROM poetry_script sc WHERE " + PUBLIC_SCRIPT + " AND sc.bundle_hash=#{hash}")
    int publishedBundleCount(@Param("hash") String hash);

    /** Published annotations of a published text version, each backed by a public claim. */
    @Select("SELECT a.id, a.line_seq, a.annotation_kind, a.audience, a.content FROM poetry_annotation a "
        + "JOIN poetry_text_version v ON v.id=a.version_id "
        + "JOIN poetry_source s ON s.id=v.source_id "
        + "JOIN poetry_content w ON w.id=v.work_id "
        + "JOIN poetry_claim cl ON cl.id=a.claim_id "
        + "WHERE " + PUBLIC_WORK + " AND " + PUBLIC_VERSION + " AND " + PUBLIC_CLAIM
        + " AND a.version_id=#{versionId} ORDER BY a.line_seq, a.id LIMIT 300")
    List<AnnotationItem> annotations(@Param("versionId") String versionId);

    @Select("SELECT a.id, a.kind, a.level, a.uri, a.hash, a.bytes, a.fallback_id, a.meaning, a.rights_origin, "
        + "a.rights_license FROM poetry_asset a WHERE a.status='PUBLISHED' "
        + "AND (#{level} IS NULL OR a.level=#{level}) ORDER BY a.level, a.id LIMIT #{limit} OFFSET #{offset}")
    List<AssetRow> assets(@Param("level") String level, @Param("limit") int limit, @Param("offset") int offset);

    @Select("SELECT a.id, a.kind, a.level, a.uri, a.hash, a.bytes, a.fallback_id, a.meaning, a.rights_origin, "
        + "a.rights_license FROM poetry_asset a WHERE a.status='PUBLISHED' AND a.id=#{id}")
    AssetRow asset(@Param("id") String id);
}
