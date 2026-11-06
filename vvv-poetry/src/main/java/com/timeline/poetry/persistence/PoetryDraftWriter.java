package com.timeline.poetry.persistence;

import com.timeline.poetry.api.PoetryDraftModels.*;
import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;
import java.util.List;

/**
 * Authoring writes for the base information tables.
 * There are no foreign keys, so the service checks every referenced id before inserting;
 * these queries exist so that check is one round trip each, not a guess.
 * No DELETE anywhere: withdrawal is a status change (see PoetryReviewService.retract).
 * The one exception is poetry_claim_selection, which is a pointer row, not content.
 */
public interface PoetryDraftWriter {
    @Select("SELECT COUNT(*) FROM poetry_content WHERE id=#{id}") Integer existsContent(@Param("id") String id);
    @Select("SELECT COUNT(*) FROM poetry_claim WHERE id=#{id}") Integer existsClaim(@Param("id") String id);
    @Select("SELECT COUNT(*) FROM poetry_source WHERE id=#{id}") Integer existsSource(@Param("id") String id);
    @Select("SELECT entity_type FROM poetry_content WHERE id=#{id}") String entityType(@Param("id") String id);
    @Select("SELECT COUNT(*) FROM poetry_content WHERE entity_type=#{type} AND slug=#{slug}")
    Integer countSlug(@Param("type") String type, @Param("slug") String slug);
    @Select("SELECT COUNT(*) FROM poetry_claim WHERE subject_id=#{subjectId} AND property_key=#{propertyKey}")
    Integer countClaims(@Param("subjectId") String subjectId, @Param("propertyKey") String propertyKey);

    @Select("SELECT id,entity_type,slug,title,summary,start_year,end_year,time_precision,status,revision,reviewed_by "
        + "FROM poetry_content WHERE id=#{id}")
    DraftContent draftContent(@Param("id") String id);

    @Select("SELECT id,entity_type,slug,title,summary,start_year,end_year,time_precision,status,revision,reviewed_by "
        + "FROM poetry_content WHERE (#{type} IS NULL OR entity_type=#{type}) "
        + "AND (#{status} IS NULL OR status=#{status}) AND (#{q} IS NULL OR title LIKE CONCAT('%',#{q},'%') "
        + "OR id LIKE CONCAT('%',#{q},'%')) ORDER BY entity_type,id LIMIT #{limit} OFFSET #{offset}")
    List<DraftContent> draftContents(@Param("type") String type, @Param("status") String status,
                                     @Param("q") String q, @Param("limit") int limit, @Param("offset") int offset);

    @Insert("INSERT INTO poetry_content (id, entity_type, slug, title, summary, start_year, end_year, time_precision) "
        + "VALUES (#{id}, #{entityType}, #{slug}, #{title}, #{summary}, #{startYear}, #{endYear}, #{timePrecision})")
    int insertContent(ContentCore c);

    @Update("UPDATE poetry_content SET title=#{title}, summary=#{summary}, start_year=#{startYear}, "
        + "end_year=#{endYear}, time_precision=#{timePrecision}, revision=revision+1 WHERE id=#{id}")
    int updateContent(@Param("id") String id, @Param("title") String title, @Param("summary") String summary,
                      @Param("startYear") Integer startYear, @Param("endYear") Integer endYear,
                      @Param("timePrecision") String timePrecision);

    @Insert("INSERT INTO poetry_dynasty (id) VALUES (#{id})") int insertDynasty(@Param("id") String id);
    @Insert("INSERT INTO poetry_period (id, dynasty_id, parent_id) VALUES (#{id}, #{dynastyId}, #{parentId})")
    int insertPeriod(ContentCreate c);
    @Insert("INSERT INTO poetry_place (id, modern_name, parent_id) VALUES (#{id}, #{modernName}, #{parentId})")
    int insertPlace(ContentCreate c);
    @Insert("INSERT INTO poetry_person (id, dynasty_id, courtesy_name) VALUES (#{id}, #{dynastyId}, #{courtesyName})")
    int insertPerson(ContentCreate c);
    @Insert("INSERT INTO poetry_event (id, place_id) VALUES (#{id}, #{placeId})") int insertEvent(ContentCreate c);
    @Insert("INSERT INTO poetry_experience (id, person_id, event_id, place_id) VALUES (#{id}, #{personId}, #{eventId}, #{placeId})")
    int insertExperience(ContentCreate c);
    @Insert("INSERT INTO poetry_work (id, dynasty_id, creation_place_id, genre) VALUES (#{id}, #{dynastyId}, #{placeId}, #{genre})")
    int insertWork(ContentCreate c);
    @Insert("INSERT INTO poetry_theme (id, period_scope) VALUES (#{id}, #{periodScope})") int insertTheme(ContentCreate c);

    @Insert("INSERT INTO poetry_source (id, title, author, edition, url, rights_note, source_kind, reliability) "
        + "VALUES (#{id}, #{title}, #{author}, #{edition}, #{url}, #{rightsNote}, #{sourceKind}, #{reliability})")
    int insertSource(SourceCreate s);
    @Update("UPDATE poetry_source SET title=#{u.title}, edition=#{u.edition}, url=#{u.url}, rights_note=#{u.rightsNote}, "
        + "source_kind=#{u.sourceKind}, reliability=#{u.reliability} WHERE id=#{id}")
    int updateSource(@Param("id") String id, @Param("u") SourceUpdate u);
    @Select("SELECT id,title,author,edition,url,rights_note,source_kind,reliability,verification_status "
        + "FROM poetry_source WHERE id=#{id}") DraftSource draftSource(@Param("id") String id);
    @Select("SELECT id,title,author,edition,url,rights_note,source_kind,reliability,verification_status "
        + "FROM poetry_source WHERE (#{status} IS NULL OR verification_status=#{status}) ORDER BY id "
        + "LIMIT #{limit} OFFSET #{offset}")
    List<DraftSource> draftSources(@Param("status") String status, @Param("limit") int limit, @Param("offset") int offset);

    @Insert("INSERT INTO poetry_claim (id, subject_id, property_key, value_text, claim_kind, certainty) "
        + "VALUES (#{id}, #{subjectId}, #{propertyKey}, #{valueText}, #{claimKind}, #{certainty})")
    int insertClaim(ClaimCreate c);
    @Update("UPDATE poetry_claim SET value_text=#{valueText}, certainty=#{certainty} WHERE id=#{id}")
    int updateClaim(@Param("id") String id, @Param("valueText") String valueText, @Param("certainty") String certainty);
    @Select("SELECT id,subject_id,property_key,value_text,claim_kind,certainty,status FROM poetry_claim "
        + "WHERE subject_id=#{subjectId} ORDER BY property_key,id")
    List<DraftClaim> draftClaims(@Param("subjectId") String subjectId);

    @Insert("INSERT INTO poetry_citation (claim_id, source_id, locator, evidence_excerpt) "
        + "VALUES (#{claimId}, #{sourceId}, #{locator}, #{evidenceExcerpt})")
    int insertCitation(CitationCreate c);
    @Select("SELECT ci.claim_id,ci.source_id,ci.locator,ci.evidence_excerpt,s.verification_status "
        + "FROM poetry_citation ci JOIN poetry_source s ON s.id=ci.source_id WHERE ci.claim_id=#{claimId} ORDER BY ci.source_id")
    List<DraftCitation> draftCitations(@Param("claimId") String claimId);

    /** Pointer row, so replacing it is legitimate; the history of choices lives in poetry_review_log. */
    @Insert("REPLACE INTO poetry_claim_selection (subject_id, property_key, claim_id) "
        + "VALUES (#{subjectId}, #{propertyKey}, #{claimId})")
    int replaceSelection(Adoption a);
    @Select("SELECT subject_id,property_key,claim_id FROM poetry_claim_selection WHERE subject_id=#{subjectId} "
        + "ORDER BY property_key")
    List<DraftSelection> draftSelections(@Param("subjectId") String subjectId);

    @Insert("INSERT INTO poetry_coverage (id, entity_type, from_year, to_year, coverage_kind, status, note, updated_by, updated_at) "
        + "VALUES (#{id}, #{entityType}, #{fromYear}, #{toYear}, #{coverageKind}, #{status}, #{note}, #{updatedBy}, NOW())")
    int insertCoverage(CoverageWrite c);
    @Update("UPDATE poetry_coverage SET entity_type=#{entityType}, from_year=#{fromYear}, to_year=#{toYear}, "
        + "coverage_kind=#{coverageKind}, status=#{status}, note=#{note}, updated_by=#{updatedBy}, updated_at=NOW() WHERE id=#{id}")
    int updateCoverage(CoverageWrite c);
    @Select("SELECT id,entity_type,from_year,to_year,coverage_kind,status,note FROM poetry_coverage "
        + "WHERE (#{type} IS NULL OR entity_type=#{type}) ORDER BY entity_type,from_year")
    List<DraftCoverage> draftCoverage(@Param("type") String type);
}
