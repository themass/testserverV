package com.timeline.poetry.persistence;

import org.apache.ibatis.annotations.*;
import java.util.List;
import java.util.Map;

/**
 * Poetry Studio 的 SQL 面。MySQL 5.6 兼容：无 CTE、无窗口函数、无外键。
 * 返回 Map 而不是 record：键名由显式 AS 别名决定，不依赖 MyBatis 的 record 构造器映射，也不依赖命名策略。
 * 可选过滤条件由服务层把"缺省"规范成空串，SQL 里用 {@code #{x}='' OR col=#{x}}，避免 {@code ? IS NULL} 的类型推断差异。
 * 注意：MyBatis 默认不为 NULL 列在 Map 里放键，服务层负责补全固定键集合。
 */
public interface PoetryStudioMapper {

    // ------------------------------------------------------------------ 列表(读)

    @Select("SELECT id AS task_id,work_id,title,task_type,status,requested_by,requested_role,instructions,requested_profile,active_run_id,created_at,updated_at "
        + "FROM poetry_agent_task WHERE (#{workId}='' OR work_id=#{workId}) AND (#{status}='' OR status=#{status}) AND (#{taskType}='' OR task_type=#{taskType}) "
        + "ORDER BY created_at DESC, id DESC LIMIT #{limit} OFFSET #{offset}")
    List<Map<String, Object>> tasks(@Param("workId") String workId, @Param("status") String status, @Param("taskType") String taskType,
                                    @Param("limit") int limit, @Param("offset") int offset);

    @Select("SELECT COUNT(*) FROM poetry_agent_task WHERE id=#{id}")
    Integer taskExists(@Param("id") String id);

    @Select("SELECT r.id AS run_id,r.task_id,r.mandate_id,r.runtime,r.profile_name,r.profile_fingerprint,r.status,r.runtime_thread_id,r.runtime_run_id,r.reason,r.created_at,r.updated_at,t.work_id,t.requested_by,t.requested_role "
        + "FROM poetry_agent_run r JOIN poetry_agent_task t ON t.id=r.task_id WHERE r.task_id=#{taskId} ORDER BY r.created_at DESC, r.id DESC LIMIT 200")
    List<Map<String, Object>> taskRuns(@Param("taskId") String taskId);

    /** LEFT JOIN：旧流程可能存在没有 run 记录的提案，不能让它从列表里消失。 */
    @Select("SELECT p.id AS proposal_id,p.work_id,p.run_id,r.task_id,p.mandate_id,p.status,p.review_status,p.review_id,p.reviewed_by,p.review_comment,p.created_at,p.applied_at,p.proposal_json "
        + "FROM poetry_agent_proposal p LEFT JOIN poetry_agent_run r ON r.id=p.run_id "
        + "WHERE (#{workId}='' OR p.work_id=#{workId}) AND (#{status}='' OR p.status=#{status}) AND (#{reviewStatus}='' OR p.review_status=#{reviewStatus}) "
        + "AND (#{runId}='' OR p.run_id=#{runId}) AND (#{taskId}='' OR r.task_id=#{taskId}) "
        + "ORDER BY p.created_at DESC, p.id DESC LIMIT #{limit} OFFSET #{offset}")
    List<Map<String, Object>> proposals(@Param("workId") String workId, @Param("status") String status, @Param("reviewStatus") String reviewStatus,
                                        @Param("runId") String runId, @Param("taskId") String taskId,
                                        @Param("limit") int limit, @Param("offset") int offset);

    @Select("SELECT item_index,decision,reviewer,comment,created_at FROM poetry_agent_proposal_item WHERE proposal_id=#{proposalId} ORDER BY item_index")
    List<Map<String, Object>> proposalItems(@Param("proposalId") String proposalId);

    @Select("SELECT COUNT(*) FROM poetry_agent_proposal WHERE id=#{id}")
    Integer proposalExists(@Param("id") String id);

    /** 行锁：让"写逐项记录"与"整体评审(PENDING→APPROVED)"串行，避免评审通过后又改逐项。 */
    @Select("SELECT review_status FROM poetry_agent_proposal WHERE id=#{id} FOR UPDATE")
    String lockProposalReviewStatus(@Param("id") String id);

    @Select("SELECT proposal_json FROM poetry_agent_proposal WHERE id=#{id}")
    String proposalJson(@Param("id") String id);

    @Select("SELECT c.id AS work_id,c.title,c.status,w.genre,w.dynasty_id,"
        + "(SELECT COUNT(*) FROM poetry_text_line l JOIN poetry_text_version v ON v.id=l.version_id WHERE v.work_id=c.id) AS line_count,"
        + "(SELECT COUNT(*) FROM poetry_text_version v WHERE v.work_id=c.id) AS version_count,"
        + "(SELECT COUNT(*) FROM poetry_background b WHERE b.work_id=c.id) AS background_count,"
        + "(SELECT COUNT(*) FROM poetry_annotation a JOIN poetry_text_version v ON v.id=a.version_id WHERE v.work_id=c.id) AS annotation_count,"
        + "(SELECT COUNT(*) FROM poetry_claim cl WHERE cl.subject_id=c.id OR cl.subject_id IN (SELECT b.id FROM poetry_background b WHERE b.work_id=c.id)) AS claim_count,"
        + "(SELECT COUNT(*) FROM poetry_source s WHERE s.verification_status!='VERIFIED' AND ("
        + "EXISTS (SELECT 1 FROM poetry_text_version v WHERE v.work_id=c.id AND v.source_id=s.id) OR "
        + "EXISTS (SELECT 1 FROM poetry_citation ci JOIN poetry_claim cl ON cl.id=ci.claim_id WHERE ci.source_id=s.id AND "
        + "(cl.subject_id=c.id OR cl.subject_id IN (SELECT b.id FROM poetry_background b WHERE b.work_id=c.id))))) AS pending_source_count "
        + "FROM poetry_content c JOIN poetry_work w ON w.id=c.id WHERE c.entity_type='WORK' ORDER BY c.id LIMIT #{limit} OFFSET #{offset}")
    List<Map<String, Object>> works(@Param("limit") int limit, @Param("offset") int offset);

    @Select("SELECT COUNT(*) FROM poetry_content WHERE id=#{id} AND entity_type='WORK'")
    Integer workExists(@Param("id") String id);

    @Select("SELECT id,title,author,edition,url,rights_note,source_kind,reliability,verification_status,verified_by,verified_at "
        + "FROM poetry_source WHERE (#{status}='' OR verification_status=#{status}) ORDER BY id LIMIT #{limit} OFFSET #{offset}")
    List<Map<String, Object>> sources(@Param("status") String status, @Param("limit") int limit, @Param("offset") int offset);

    @Select("<script>SELECT ci.source_id,ci.claim_id,cl.value_text AS claim_value,cl.claim_kind,cl.status AS claim_status,ci.locator,ci.evidence_excerpt "
        + "FROM poetry_citation ci JOIN poetry_claim cl ON cl.id=ci.claim_id WHERE ci.source_id IN "
        + "<foreach collection='ids' item='i' open='(' separator=',' close=')'>#{i}</foreach> ORDER BY ci.source_id, ci.claim_id</script>")
    List<Map<String, Object>> citationsOfSources(@Param("ids") List<String> ids);

    // ------------------------------------------------------------------ 作品范围(studio-view / coverage)
    // 范围 = 作品本身 + 其背景(背景的 claim 以背景 id 为 subject)。比 snapshot 的 claims 多出背景 claim，是它的超集。

    @Select("SELECT id,entity_type,slug,title,summary,start_year,end_year,time_precision,status,revision,reviewed_by FROM poetry_content WHERE id=#{id}")
    Map<String, Object> workContent(@Param("id") String id);

    @Select("SELECT id,genre,dynasty_id,creation_place_id FROM poetry_work WHERE id=#{id}")
    Map<String, Object> workInfo(@Param("id") String id);

    @Select("SELECT id,work_id,version_code,label,script,source_id,source_locator,status FROM poetry_text_version WHERE work_id=#{workId} ORDER BY id")
    List<Map<String, Object>> scopeVersions(@Param("workId") String workId);

    @Select("SELECT l.version_id,l.line_seq,l.content,l.pinyin FROM poetry_text_line l JOIN poetry_text_version v ON v.id=l.version_id WHERE v.work_id=#{workId} ORDER BY l.version_id,l.line_seq")
    List<Map<String, Object>> scopeLines(@Param("workId") String workId);

    @Select("SELECT id,subject_id,property_key,value_text,claim_kind,certainty,status FROM poetry_claim "
        + "WHERE subject_id=#{workId} OR subject_id IN (SELECT b.id FROM poetry_background b WHERE b.work_id=#{workId}) ORDER BY property_key,id")
    List<Map<String, Object>> scopeClaims(@Param("workId") String workId);

    @Select("SELECT ci.claim_id,ci.source_id,ci.locator,ci.evidence_excerpt,s.verification_status FROM poetry_citation ci JOIN poetry_claim cl ON cl.id=ci.claim_id JOIN poetry_source s ON s.id=ci.source_id "
        + "WHERE cl.subject_id=#{workId} OR cl.subject_id IN (SELECT b.id FROM poetry_background b WHERE b.work_id=#{workId}) ORDER BY ci.claim_id,ci.source_id")
    List<Map<String, Object>> scopeCitations(@Param("workId") String workId);

    @Select("SELECT id,work_id,layer,audience,body_text,claim_id FROM poetry_background WHERE work_id=#{workId} ORDER BY layer,id")
    List<Map<String, Object>> scopeBackgrounds(@Param("workId") String workId);

    @Select("SELECT bl.background_id,bl.version_id,bl.line_seq FROM poetry_background_line bl JOIN poetry_background b ON b.id=bl.background_id WHERE b.work_id=#{workId} ORDER BY bl.background_id,bl.version_id,bl.line_seq")
    List<Map<String, Object>> scopeBackgroundLines(@Param("workId") String workId);

    @Select("SELECT bc.id,bc.status FROM poetry_content bc JOIN poetry_background b ON b.id=bc.id WHERE b.work_id=#{workId} ORDER BY bc.id")
    List<Map<String, Object>> scopeBackgroundContentStatus(@Param("workId") String workId);

    @Select("SELECT a.id,a.version_id,a.line_seq,a.annotation_kind,a.audience,a.content,a.claim_id FROM poetry_annotation a JOIN poetry_text_version v ON v.id=a.version_id WHERE v.work_id=#{workId} ORDER BY a.version_id,a.line_seq,a.id")
    List<Map<String, Object>> scopeAnnotations(@Param("workId") String workId);

    @Select("SELECT s.id,s.title,s.author,s.edition,s.url,s.rights_note,s.source_kind,s.reliability,s.verification_status FROM poetry_source s "
        + "WHERE s.id IN (SELECT v.source_id FROM poetry_text_version v WHERE v.work_id=#{workId}) "
        + "OR s.id IN (SELECT ci.source_id FROM poetry_citation ci JOIN poetry_claim cl ON cl.id=ci.claim_id WHERE cl.subject_id=#{workId} "
        + "OR cl.subject_id IN (SELECT b.id FROM poetry_background b WHERE b.work_id=#{workId})) ORDER BY s.id")
    List<Map<String, Object>> scopeSources(@Param("workId") String workId);

    @Select("SELECT id,entity_type,from_year,to_year,coverage_kind,status,note FROM poetry_coverage WHERE entity_type='WORK' ORDER BY from_year,id")
    List<Map<String, Object>> coverageRows();

    // ------------------------------------------------------------------ 写

    @Select("SELECT locator,evidence_excerpt FROM poetry_citation WHERE claim_id=#{claimId} AND source_id=#{sourceId}")
    Map<String, Object> citation(@Param("claimId") String claimId, @Param("sourceId") String sourceId);

    @Update("UPDATE poetry_citation SET locator=#{locator},evidence_excerpt=#{excerpt} WHERE claim_id=#{claimId} AND source_id=#{sourceId}")
    int updateCitation(@Param("claimId") String claimId, @Param("sourceId") String sourceId,
                       @Param("locator") String locator, @Param("excerpt") String excerpt);

    @Select("SELECT verification_status FROM poetry_source WHERE id=#{id}")
    String sourceStatus(@Param("id") String id);

    /** Demote a verified source back to PENDING. Used when its locator is rewritten (see setLocator). */
    @Update("UPDATE poetry_source SET verification_status='PENDING', verified_by=NULL, verified_at=NULL "
        + "WHERE id=#{id} AND verification_status='VERIFIED'")
    int demoteSourceToPending(@Param("id") String id);

    /** Review-log entry so a locator rewrite is visible next to publish/retract, not only in the studio log. */
    @Insert("INSERT INTO poetry_review_log (subject_table, subject_id, subject_revision, decision, reviewer, note) "
        + "VALUES ('poetry_source', #{sourceId}, 1, 'LOCATOR_CHANGED', #{reviewer}, #{note})")
    int appendLocatorChangeReviewLog(@Param("sourceId") String sourceId, @Param("reviewer") String reviewer,
                                     @Param("note") String note);

    @Select("SELECT ci.claim_id,ci.locator FROM poetry_citation ci WHERE ci.source_id=#{sourceId} ORDER BY ci.claim_id")
    List<Map<String, Object>> citationsOfSource(@Param("sourceId") String sourceId);

    /** Text versions that name this source as their base text; their own source_locator is not a citation. */
    @Select("SELECT v.id,v.source_locator FROM poetry_text_version v WHERE v.source_id=#{sourceId} ORDER BY v.id")
    List<Map<String, Object>> textVersionsOfSource(@Param("sourceId") String sourceId);

    /** PUBLISHED content that would lose its provenance if this source were rejected. */
    @Select("SELECT 'claim' AS kind, cl.id AS ref_id FROM poetry_citation ci JOIN poetry_claim cl ON cl.id=ci.claim_id "
        + "WHERE ci.source_id=#{sourceId} AND cl.status='PUBLISHED' "
        + "UNION ALL SELECT 'text_version' AS kind, v.id AS ref_id FROM poetry_text_version v "
        + "WHERE v.source_id=#{sourceId} AND v.status='PUBLISHED' ORDER BY kind, ref_id")
    List<Map<String, Object>> publishedDependentsOfSource(@Param("sourceId") String sourceId);

    @Update("UPDATE poetry_agent_proposal_item SET decision=#{decision},reviewer=#{reviewer},comment=#{comment},updated_at=NOW() WHERE proposal_id=#{proposalId} AND item_index=#{itemIndex}")
    int itemUpdate(@Param("proposalId") String proposalId, @Param("itemIndex") int itemIndex,
                   @Param("decision") String decision, @Param("reviewer") String reviewer, @Param("comment") String comment);

    @Insert("INSERT INTO poetry_agent_proposal_item (proposal_id,item_index,decision,reviewer,comment,updated_at) VALUES (#{proposalId},#{itemIndex},#{decision},#{reviewer},#{comment},NOW())")
    int itemInsert(@Param("proposalId") String proposalId, @Param("itemIndex") int itemIndex,
                   @Param("decision") String decision, @Param("reviewer") String reviewer, @Param("comment") String comment);

    @Insert("INSERT INTO poetry_studio_check_log (action,source_id,claim_id,proposal_id,locator,evidence_excerpt,decision,reviewer,reviewer_role,note) "
        + "VALUES (#{e.action},#{e.sourceId},#{e.claimId},#{e.proposalId},#{e.locator},#{e.evidenceExcerpt},#{e.decision},#{e.reviewer},#{e.reviewerRole},#{e.note})")
    @Options(useGeneratedKeys = true, keyProperty = "e.id")
    int insertLog(@Param("e") LogEntry e);

    /** 审计行。MyBatis 通过 getter/setter 反射读写，所以用 JavaBean 而不是 record(要回填自增 id)。 */
    class LogEntry {
        private Long id;
        private String action, sourceId, claimId, proposalId, locator, evidenceExcerpt, decision, reviewer, reviewerRole, note;
        public Long getId() { return id; }
        public void setId(Long id) { this.id = id; }
        public String getAction() { return action; }
        public void setAction(String v) { this.action = v; }
        public String getSourceId() { return sourceId; }
        public void setSourceId(String v) { this.sourceId = v; }
        public String getClaimId() { return claimId; }
        public void setClaimId(String v) { this.claimId = v; }
        public String getProposalId() { return proposalId; }
        public void setProposalId(String v) { this.proposalId = v; }
        public String getLocator() { return locator; }
        public void setLocator(String v) { this.locator = v; }
        public String getEvidenceExcerpt() { return evidenceExcerpt; }
        public void setEvidenceExcerpt(String v) { this.evidenceExcerpt = v; }
        public String getDecision() { return decision; }
        public void setDecision(String v) { this.decision = v; }
        public String getReviewer() { return reviewer; }
        public void setReviewer(String v) { this.reviewer = v; }
        public String getReviewerRole() { return reviewerRole; }
        public void setReviewerRole(String v) { this.reviewerRole = v; }
        public String getNote() { return note; }
        public void setNote(String v) { this.note = v; }
    }
}
