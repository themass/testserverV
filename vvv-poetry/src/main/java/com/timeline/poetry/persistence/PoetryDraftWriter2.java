package com.timeline.poetry.persistence;

import com.timeline.poetry.api.PoetryDraftModels.*;
import org.apache.ibatis.annotations.*;
import java.util.List;

/**
 * Slice-2 authoring writes: text versions, lines, backgrounds, background->line links, annotations,
 * relations, authorship and textbook placements. Still no DELETE and no FOREIGN KEY: the service
 * checks every reference, and the 106 audit checks run inside the same transaction afterwards.
 */
public interface PoetryDraftWriter2 {
    // existence probes (these replace the foreign keys we are not allowed to declare)
    @Select("SELECT COUNT(*) FROM poetry_text_version WHERE id=#{id}") Integer existsVersion(@Param("id") String id);
    @Select("SELECT COUNT(*) FROM poetry_background WHERE id=#{id}") Integer existsBackground(@Param("id") String id);
    @Select("SELECT COUNT(*) FROM poetry_textbook WHERE id=#{id}") Integer existsTextbook(@Param("id") String id);
    @Select("SELECT COUNT(*) FROM poetry_text_line WHERE version_id=#{versionId} AND line_seq=#{lineSeq}")
    Integer existsLine(@Param("versionId") String versionId, @Param("lineSeq") int lineSeq);
    @Select("SELECT COUNT(*) FROM poetry_text_line WHERE version_id=#{versionId}") Integer countLines(@Param("versionId") String versionId);
    @Select("SELECT COALESCE(MAX(line_seq),0) FROM poetry_text_line WHERE version_id=#{versionId}") Integer maxLineSeq(@Param("versionId") String versionId);
    @Select("SELECT work_id FROM poetry_text_version WHERE id=#{id}") String versionWork(@Param("id") String id);
    @Select("SELECT work_id FROM poetry_background WHERE id=#{id}") String backgroundWork(@Param("id") String id);

    @Insert("INSERT INTO poetry_text_version (id, work_id, version_code, label, script, source_id, source_locator) "
        + "VALUES (#{id}, #{workId}, #{versionCode}, #{label}, #{script}, #{sourceId}, #{sourceLocator})")
    int insertVersion(VersionCreate v);
    @Update("UPDATE poetry_text_version SET label=#{label}, source_id=#{sourceId}, source_locator=#{sourceLocator} "
        + "WHERE id=#{id}")
    int updateVersion(@Param("id") String id, @Param("v") VersionUpdate v);
    @Select("SELECT id,work_id,version_code,label,script,source_id,source_locator,status FROM poetry_text_version "
        + "WHERE work_id=#{workId} ORDER BY id")
    List<DraftVersion> versionsOf(@Param("workId") String workId);
    @Select("SELECT id,work_id,version_code,label,script,source_id,source_locator,status FROM poetry_text_version WHERE id=#{id}")
    DraftVersion draftVersion(@Param("id") String id);

    @Insert("INSERT INTO poetry_text_line (version_id, line_seq, content, pinyin) VALUES (#{versionId}, #{lineSeq}, #{content}, #{pinyin})")
    int insertLine(LineWrite l);
    @Update("UPDATE poetry_text_line SET content=#{content}, pinyin=#{pinyin} WHERE version_id=#{versionId} AND line_seq=#{lineSeq}")
    int updateLine(LineWrite l);
    @Select("SELECT version_id,line_seq,content,pinyin FROM poetry_text_line WHERE version_id=#{versionId} ORDER BY line_seq")
    List<DraftLine> linesOf(@Param("versionId") String versionId);

    @Insert("INSERT INTO poetry_content (id, entity_type, slug, title, summary, time_precision) "
        + "VALUES (#{id}, 'BACKGROUND', #{id}, #{title}, #{summary}, 'UNKNOWN')")
    int insertBackgroundContent(@Param("id") String id, @Param("title") String title, @Param("summary") String summary);
    @Insert("INSERT INTO poetry_background (id, work_id, layer, audience, body_text, claim_id) "
        + "VALUES (#{id}, #{workId}, #{layer}, #{audience}, #{bodyText}, #{claimId})")
    int insertBackground(BackgroundWrite b);
    @Update("UPDATE poetry_background SET layer=#{layer}, audience=#{audience}, body_text=#{bodyText} WHERE id=#{id}")
    int updateBackground(BackgroundWrite b);
    @Select("SELECT id,work_id,layer,audience,body_text,claim_id FROM poetry_background WHERE work_id=#{workId} ORDER BY id")
    List<DraftBackground> backgroundsOf(@Param("workId") String workId);
    @Select("SELECT id,work_id,layer,audience,body_text,claim_id FROM poetry_background WHERE id=#{id}")
    DraftBackground draftBackground(@Param("id") String id);

    @Insert("INSERT INTO poetry_background_line (background_id, version_id, line_seq) VALUES (#{backgroundId}, #{versionId}, #{lineSeq})")
    int insertBackgroundLine(BackgroundLineWrite l);
    @Select("SELECT version_id,line_seq FROM poetry_background_line WHERE background_id=#{backgroundId} ORDER BY version_id,line_seq")
    List<DraftLine> backgroundLines(@Param("backgroundId") String backgroundId);

    @Insert("INSERT INTO poetry_annotation (id, version_id, line_seq, annotation_kind, audience, content, claim_id) "
        + "VALUES (#{id}, #{versionId}, #{lineSeq}, #{annotationKind}, #{audience}, #{content}, #{claimId})")
    int insertAnnotation(AnnotationWrite a);
    @Select("SELECT id,version_id,line_seq,annotation_kind,audience,content,claim_id FROM poetry_annotation "
        + "WHERE version_id=#{versionId} ORDER BY line_seq,annotation_kind,id")
    List<DraftAnnotation> annotationsOf(@Param("versionId") String versionId);

    @Insert("INSERT INTO poetry_relation (id, subject_id, predicate, object_id, claim_id) "
        + "VALUES (#{id}, #{subjectId}, #{predicate}, #{objectId}, #{claimId})")
    int insertRelation(RelationWrite r);
    @Select("SELECT id,subject_id,predicate,object_id,claim_id FROM poetry_relation WHERE subject_id=#{subjectId} ORDER BY predicate,id")
    List<DraftRelation> relationsOf(@Param("subjectId") String subjectId);

    @Insert("INSERT INTO poetry_work_author (work_id, person_id, attribution, claim_id) VALUES (#{workId}, #{personId}, #{attribution}, #{claimId})")
    int insertWorkAuthor(WorkAuthorWrite a);
    @Update("UPDATE poetry_work_author SET attribution=#{attribution}, claim_id=#{claimId} WHERE work_id=#{workId} AND person_id=#{personId}")
    int updateWorkAuthor(WorkAuthorWrite a);
    @Select("SELECT work_id,person_id,attribution,claim_id FROM poetry_work_author WHERE work_id=#{workId} ORDER BY person_id")
    List<DraftWorkAuthor> authorsOf(@Param("workId") String workId);

    @Insert("INSERT INTO poetry_textbook (id, title, publisher, edition, school_stage, grade_no, volume, isbn) "
        + "VALUES (#{id}, #{title}, #{publisher}, #{edition}, #{schoolStage}, #{gradeNo}, #{volume}, #{isbn})")
    int insertTextbook(TextbookCreate t);
    @Select("SELECT id,title,publisher,edition,school_stage,grade_no,volume,isbn,verification_status FROM poetry_textbook ORDER BY school_stage,grade_no,id")
    List<DraftTextbook> textbooks();

    @Insert("INSERT INTO poetry_textbook_work (textbook_id, work_id, version_id, unit_label, lesson_label, page_locator) "
        + "VALUES (#{textbookId}, #{workId}, #{versionId}, #{unitLabel}, #{lessonLabel}, #{pageLocator})")
    int insertTextbookWork(TextbookWorkWrite w);
    @Select("SELECT textbook_id,work_id,version_id,unit_label,lesson_label,page_locator FROM poetry_textbook_work WHERE work_id=#{workId}")
    List<TextbookWorkWrite> textbookWorksOf(@Param("workId") String workId);
}
