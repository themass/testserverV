package com.timeline.poetry.persistence;

import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;

/** Write side only. Everything here is a state transition on rows that already exist. */
public interface PoetryWriter {
    @Select("SELECT revision FROM poetry_content WHERE id=#{id}")
    Integer contentRevision(@Param("id") String id);

    @Select("SELECT entity_type FROM poetry_content WHERE id=#{id}")
    String contentType(@Param("id") String id);

    @Select("SELECT claim_kind FROM poetry_claim WHERE id=#{id}")
    String claimKind(@Param("id") String id);

    @Select("SELECT dramatization_labeled FROM poetry_claim WHERE id=#{id}")
    Integer claimDramatizationLabeled(@Param("id") String id);

    @Select("SELECT s.id FROM poetry_citation ci JOIN poetry_source s ON s.id=ci.source_id "
        + "JOIN poetry_claim cl ON cl.id=ci.claim_id "
        + "WHERE ci.claim_id=#{id} AND TRIM(ci.locator)<>'' AND s.verification_status='VERIFIED' "
        + "AND s.verified_by IS NOT NULL AND TRIM(s.verified_by)<>'' AND s.verified_at IS NOT NULL")
    java.util.List<String> verifiedSourceIdsForClaim(@Param("id") String id);

    @Select("SELECT source_kind FROM poetry_source WHERE id=#{id}")
    String sourceKind(@Param("id") String id);

    @Select("SELECT reliability FROM poetry_source WHERE id=#{id}")
    String sourceReliability(@Param("id") String id);

    @Select("SELECT COUNT(*) FROM poetry_text_line WHERE version_id=#{id}")
    Integer versionLineCount(@Param("id") String id);

    @Select("SELECT script FROM poetry_text_version WHERE id=#{id}")
    String versionScript(@Param("id") String id);

    @Select("SELECT COUNT(*) FROM poetry_text_version v JOIN poetry_source s ON s.id=v.source_id "
        + "WHERE v.id=#{id} AND s.verification_status='VERIFIED' AND s.verified_by IS NOT NULL "
        + "AND TRIM(s.verified_by)<>'' AND s.verified_at IS NOT NULL AND TRIM(v.source_locator)<>''")
    Integer versionVerifiedSourceCount(@Param("id") String id);

    @Update("UPDATE poetry_content SET status=#{status}, reviewed_by=#{reviewer}, reviewed_at=NOW(), "
        + "revision=revision+1 WHERE id=#{id}")
    int updateContentStatus(@Param("id") String id, @Param("status") String status, @Param("reviewer") String reviewer);

    @Update("UPDATE poetry_claim SET status=#{status}, reviewed_by=#{reviewer}, reviewed_at=NOW() WHERE id=#{id}")
    int updateClaimStatus(@Param("id") String id, @Param("status") String status, @Param("reviewer") String reviewer);

    @Update("UPDATE poetry_text_version SET status=#{status}, reviewed_by=#{reviewer}, reviewed_at=NOW() WHERE id=#{id}")
    int updateVersionStatus(@Param("id") String id, @Param("status") String status, @Param("reviewer") String reviewer);

    @Update("UPDATE poetry_source SET verification_status=#{status}, verified_by=#{reviewer}, verified_at=NOW() WHERE id=#{id}")
    int updateSourceVerification(@Param("id") String id, @Param("status") String status, @Param("reviewer") String reviewer);

    @Insert("INSERT INTO poetry_review_log (subject_table, subject_id, subject_revision, decision, reviewer, note) "
        + "VALUES (#{subjectTable}, #{subjectId}, #{revision}, #{decision}, #{reviewer}, #{note})")
    int appendReviewLog(@Param("subjectTable") String subjectTable, @Param("subjectId") String subjectId,
                        @Param("revision") int revision, @Param("decision") String decision,
                        @Param("reviewer") String reviewer, @Param("note") String note);

    @Select("SELECT COUNT(*) FROM poetry_content WHERE status='PUBLISHED'")
    Integer publishedContentCount();

    @Select("SELECT COUNT(*) FROM poetry_text_version WHERE status='PUBLISHED'")
    Integer publishedVersionCount();

    @Select("SELECT COUNT(*) FROM poetry_background b JOIN poetry_content c ON c.id=b.id AND c.status='PUBLISHED'")
    Integer publishedBackgroundCount();

    @Select("SELECT COUNT(*) FROM poetry_source WHERE verification_status='VERIFIED'")
    Integer verifiedSourceCount();
}
