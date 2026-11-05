package com.timeline.poetry.persistence;

import com.timeline.poetry.api.PoetryModels.*;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import java.util.List;
import static com.timeline.poetry.persistence.PoetrySql.*;

public interface PoetryMapper {
    @Select("SELECT " + COLUMNS + " FROM poetry_content c WHERE " + PUBLIC_CONTENT
        + " AND (#{type} IS NULL OR c.entity_type=#{type}) ORDER BY c.id" + PAGE)
    List<ContentItem> contents(@Param("type") String type, @Param("fetchLimit") int fetchLimit, @Param("offset") int offset);

    @Select("SELECT " + COLUMNS + " FROM poetry_content c WHERE " + PUBLIC_CONTENT + " AND c.id=#{id}")
    ContentItem content(@Param("id") String id);

    @Select("SELECT " + COLUMNS + " FROM poetry_content c JOIN poetry_experience e ON e.id=c.id "
        + "JOIN poetry_content p ON p.id=e.person_id AND p.entity_type='PERSON' "
        + "WHERE " + PUBLIC_CONTENT + " AND p.status='PUBLISHED' AND p.reviewed_by IS NOT NULL "
        + "AND TRIM(p.reviewed_by)!='' AND p.reviewed_at IS NOT NULL AND e.person_id=#{personId} "
        + "ORDER BY c.start_year,c.id" + PAGE)
    List<ContentItem> experiences(@Param("personId") String personId, @Param("fetchLimit") int fetchLimit, @Param("offset") int offset);

    @Select("SELECT " + COLUMNS + " FROM poetry_content c WHERE " + PUBLIC_CONTENT
        + " AND (#{type} IS NULL OR c.entity_type=#{type}) AND c.time_precision!='UNKNOWN' "
        + "AND c.start_year IS NOT NULL AND c.end_year IS NOT NULL "
        + "AND c.start_year <= #{toYear} AND c.end_year >= #{fromYear} "
        + "ORDER BY c.start_year,c.id" + PAGE)
    List<ContentItem> timeline(@Param("type") String type, @Param("fromYear") int fromYear,
                              @Param("toYear") int toYear, @Param("fetchLimit") int fetchLimit, @Param("offset") int offset);

    @Select("SELECT w.id,w.genre,dc.id AS dynasty_id,pc.id AS creation_place_id FROM poetry_work w "
        + "JOIN poetry_content c ON c.id=w.id AND c.entity_type='WORK' "
        + "LEFT JOIN poetry_content dc ON dc.id=w.dynasty_id AND dc.status='PUBLISHED' "
        + "AND dc.reviewed_by IS NOT NULL AND TRIM(dc.reviewed_by)!='' AND dc.reviewed_at IS NOT NULL "
        + "LEFT JOIN poetry_content pc ON pc.id=w.creation_place_id AND pc.status='PUBLISHED' "
        + "AND pc.reviewed_by IS NOT NULL AND TRIM(pc.reviewed_by)!='' AND pc.reviewed_at IS NOT NULL "
        + "WHERE " + PUBLIC_CONTENT + " AND w.id=#{id}")
    WorkInfo work(@Param("id") String id);

    @Select("SELECT v.id,v.work_id,v.version_code,v.label,v.script,v.source_id,v.source_locator "
        + "FROM poetry_text_version v JOIN poetry_content c ON c.id=v.work_id AND c.entity_type='WORK' "
        + "JOIN poetry_source s ON s.id=v.source_id WHERE " + PUBLIC_CONTENT + " AND " + PUBLIC_VERSION
        + " AND v.work_id=#{workId} ORDER BY v.id" + PAGE)
    List<TextVersion> versions(@Param("workId") String workId, @Param("fetchLimit") int fetchLimit, @Param("offset") int offset);

    @Select("SELECT v.id,v.work_id,v.version_code,v.label,v.script,v.source_id,v.source_locator "
        + "FROM poetry_text_version v JOIN poetry_content c ON c.id=v.work_id AND c.entity_type='WORK' "
        + "JOIN poetry_source s ON s.id=v.source_id WHERE " + PUBLIC_CONTENT + " AND " + PUBLIC_VERSION + " AND v.id=#{id}")
    TextVersion version(@Param("id") String id);

    @Select("SELECT l.version_id,l.line_seq,l.content,l.pinyin FROM poetry_text_line l "
        + "JOIN poetry_text_version v ON v.id=l.version_id "
        + "JOIN poetry_content c ON c.id=v.work_id AND c.entity_type='WORK' "
        + "JOIN poetry_source s ON s.id=v.source_id WHERE " + PUBLIC_CONTENT + " AND " + PUBLIC_VERSION
        + " AND l.version_id=#{versionId} ORDER BY l.line_seq" + PAGE)
    List<TextLine> lines(@Param("versionId") String versionId, @Param("fetchLimit") int fetchLimit, @Param("offset") int offset);

    String CLAIM_COLUMNS = "cl.id,cl.subject_id,cl.property_key,cl.value_text,cl.claim_kind,cl.certainty,"
        + "cl.dramatization_labeled,CASE WHEN EXISTS (SELECT 1 FROM poetry_claim_selection sel "
        + "WHERE sel.subject_id=cl.subject_id AND sel.property_key=cl.property_key AND sel.claim_id=cl.id) THEN TRUE ELSE FALSE END AS selected";
    @Select("SELECT " + CLAIM_COLUMNS + " FROM poetry_claim cl JOIN poetry_content c ON c.id=cl.subject_id "
        + "WHERE " + PUBLIC_CONTENT + " AND " + PUBLIC_CLAIM
        + " AND cl.subject_id=#{subjectId} ORDER BY cl.property_key,cl.id" + PAGE)
    List<Claim> claims(@Param("subjectId") String subjectId, @Param("fetchLimit") int fetchLimit, @Param("offset") int offset);

    @Select("SELECT " + CLAIM_COLUMNS + " FROM poetry_claim cl JOIN poetry_content c ON c.id=cl.subject_id "
        + "WHERE " + PUBLIC_CONTENT + " AND " + PUBLIC_CLAIM + " AND cl.id=#{id}")
    Claim claim(@Param("id") String id);

    @Select("SELECT s.id,s.title,s.author,s.edition,s.url,s.rights_note,ci.locator,ci.evidence_excerpt "
        + "FROM poetry_citation ci JOIN poetry_source s ON s.id=ci.source_id "
        + "JOIN poetry_claim cl ON cl.id=ci.claim_id JOIN poetry_content c ON c.id=cl.subject_id "
        + "WHERE " + PUBLIC_CONTENT + " AND " + PUBLIC_CLAIM + " AND " + VERIFIED_SOURCE
        + " AND ci.claim_id=#{claimId} AND TRIM(ci.locator)!='' ORDER BY s.id" + PAGE)
    List<Citation> citations(@Param("claimId") String claimId, @Param("fetchLimit") int fetchLimit, @Param("offset") int offset);

    @Select("SELECT r.id,r.predicate,o.id,o.title,r.claim_id FROM poetry_relation r "
        + "JOIN poetry_content c ON c.id=r.subject_id JOIN poetry_content o ON o.id=r.object_id "
        + "JOIN poetry_claim cl ON cl.id=r.claim_id AND cl.subject_id=r.subject_id "
        + "WHERE " + PUBLIC_CONTENT + " AND " + PUBLIC_CLAIM + " AND o.status='PUBLISHED' "
        + "AND o.reviewed_by IS NOT NULL AND TRIM(o.reviewed_by)!='' AND o.reviewed_at IS NOT NULL "
        + "AND r.subject_id=#{subjectId} ORDER BY r.id" + PAGE)
    List<Relation> relations(@Param("subjectId") String subjectId, @Param("fetchLimit") int fetchLimit, @Param("offset") int offset);

    @Select("SELECT p.id,p.title,a.attribution,a.claim_id FROM poetry_work_author a "
        + "JOIN poetry_content c ON c.id=a.work_id AND c.entity_type='WORK' "
        + "JOIN poetry_content p ON p.id=a.person_id AND p.entity_type='PERSON' "
        + "JOIN poetry_claim cl ON cl.id=a.claim_id AND cl.subject_id=a.work_id AND cl.property_key='authorship' "
        + "WHERE " + PUBLIC_CONTENT + " AND " + PUBLIC_CLAIM + " AND p.status='PUBLISHED' "
        + "AND p.reviewed_by IS NOT NULL AND TRIM(p.reviewed_by)!='' AND p.reviewed_at IS NOT NULL "
        + "AND a.attribution IN ('ACCEPTED','DISPUTED') AND a.work_id=#{workId} ORDER BY p.id" + PAGE)
    List<Author> authors(@Param("workId") String workId, @Param("fetchLimit") int fetchLimit, @Param("offset") int offset);

    @Select("SELECT b.id,c.title,b.layer,b.primary_text,b.middle_text,b.claim_id FROM poetry_background b "
        + "JOIN poetry_content c ON c.id=b.id AND c.entity_type='BACKGROUND' "
        + "JOIN poetry_content w ON w.id=b.work_id AND w.entity_type='WORK' "
        + "JOIN poetry_claim cl ON cl.id=b.claim_id AND cl.subject_id=b.id "
        + "WHERE " + PUBLIC_CONTENT + " AND " + PUBLIC_CLAIM + " AND w.status='PUBLISHED' "
        + "AND w.reviewed_by IS NOT NULL AND TRIM(w.reviewed_by)!='' AND w.reviewed_at IS NOT NULL "
        + "AND b.work_id=#{workId} AND EXISTS (SELECT 1 FROM poetry_background_line bl "
        + "JOIN poetry_text_version v ON v.id=bl.version_id JOIN poetry_source s ON s.id=v.source_id "
        + "WHERE bl.background_id=b.id AND v.work_id=b.work_id AND " + PUBLIC_VERSION + ") ORDER BY b.id" + PAGE)
    List<Background> backgrounds(@Param("workId") String workId, @Param("fetchLimit") int fetchLimit, @Param("offset") int offset);

    @Select("SELECT bl.version_id,bl.line_seq FROM poetry_background_line bl "
        + "JOIN poetry_background b ON b.id=bl.background_id "
        + "JOIN poetry_content c ON c.id=b.id AND c.entity_type='BACKGROUND' "
        + "JOIN poetry_content w ON w.id=b.work_id AND w.entity_type='WORK' "
        + "JOIN poetry_claim cl ON cl.id=b.claim_id AND cl.subject_id=b.id "
        + "JOIN poetry_text_version v ON v.id=bl.version_id AND v.work_id=b.work_id "
        + "JOIN poetry_source s ON s.id=v.source_id WHERE " + PUBLIC_CONTENT + " AND " + PUBLIC_CLAIM
        + " AND " + PUBLIC_VERSION + " AND w.status='PUBLISHED' AND w.reviewed_by IS NOT NULL "
        + "AND TRIM(w.reviewed_by)!='' AND w.reviewed_at IS NOT NULL "
        + "AND b.id=#{id} ORDER BY bl.version_id,bl.line_seq" + PAGE)
    List<BackgroundLine> backgroundLines(@Param("id") String id, @Param("fetchLimit") int fetchLimit, @Param("offset") int offset);
}
