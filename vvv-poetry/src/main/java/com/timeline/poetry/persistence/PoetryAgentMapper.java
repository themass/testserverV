package com.timeline.poetry.persistence;

import com.timeline.poetry.api.PoetryAgentModels.*;
import com.timeline.poetry.api.PoetryDraftModels.*;
import com.timeline.poetry.api.PoetryModels.WorkInfo;
import org.apache.ibatis.annotations.*;
import java.util.List;

/** SQL surface for Agent audit records. No table in this mapper has a foreign key. */
public interface PoetryAgentMapper {
    @Select("SELECT id,entity_type,slug,title,summary,start_year,end_year,time_precision,status,revision,reviewed_by FROM poetry_content WHERE id=#{id}")
    DraftContent work(@Param("id") String id);
    @Select("SELECT id,genre, dynasty_id AS dynastyId, creation_place_id AS creationPlaceId FROM poetry_work WHERE id=#{id}")
    WorkInfo workInfo(@Param("id") String id);
    @Select("SELECT id,work_id,version_code,label,script,source_id,source_locator,status FROM poetry_text_version WHERE work_id=#{workId} ORDER BY id")
    List<DraftVersion> versions(@Param("workId") String workId);
    @Select("SELECT l.version_id,l.line_seq,l.content,l.pinyin FROM poetry_text_line l JOIN poetry_text_version v ON v.id=l.version_id WHERE v.work_id=#{workId} ORDER BY l.version_id,l.line_seq")
    List<DraftLine> lines(@Param("workId") String workId);
    @Select("SELECT id,subject_id,property_key,value_text,claim_kind,certainty,status FROM poetry_claim WHERE subject_id=#{workId} ORDER BY property_key,id")
    List<DraftClaim> claims(@Param("workId") String workId);
    @Select("SELECT ci.claim_id,ci.source_id,ci.locator,ci.evidence_excerpt,s.verification_status FROM poetry_citation ci JOIN poetry_claim cl ON cl.id=ci.claim_id JOIN poetry_source s ON s.id=ci.source_id WHERE cl.subject_id=#{workId} ORDER BY ci.claim_id,ci.source_id")
    List<DraftCitation> citations(@Param("workId") String workId);
    @Select("SELECT id,work_id,layer,audience,body_text,claim_id FROM poetry_background WHERE work_id=#{workId} ORDER BY layer,id")
    List<DraftBackground> backgrounds(@Param("workId") String workId);
    @Select("SELECT a.id,a.version_id,a.line_seq,a.annotation_kind,a.audience,a.content,a.claim_id FROM poetry_annotation a JOIN poetry_text_version v ON v.id=a.version_id WHERE v.work_id=#{workId} ORDER BY a.version_id,a.line_seq,a.id")
    List<DraftAnnotation> annotations(@Param("workId") String workId);
    @Select("SELECT s.id,s.title,s.author,s.edition,s.url,s.rights_note,s.source_kind,s.reliability,s.verification_status FROM poetry_source s JOIN poetry_text_version v ON v.source_id=s.id WHERE v.work_id=#{workId} UNION SELECT s.id,s.title,s.author,s.edition,s.url,s.rights_note,s.source_kind,s.reliability,s.verification_status FROM poetry_source s JOIN poetry_citation ci ON ci.source_id=s.id JOIN poetry_claim cl ON cl.id=ci.claim_id WHERE cl.subject_id=#{workId} ORDER BY id")
    List<DraftSource> sources(@Param("workId") String workId);
    @Select("SELECT COUNT(*) FROM poetry_text_line l JOIN poetry_text_version v ON v.id=l.version_id WHERE v.work_id=#{workId}")
    Integer lineCount(@Param("workId") String workId);
    @Select("SELECT COUNT(*) FROM poetry_claim cl WHERE cl.subject_id=#{workId} AND NOT EXISTS (SELECT 1 FROM poetry_citation ci JOIN poetry_source s ON s.id=ci.source_id WHERE ci.claim_id=cl.id AND TRIM(ci.locator)<>'' AND s.verification_status='VERIFIED')")
    Integer unverifiedClaimCount(@Param("workId") String workId);
    @Select("SELECT COUNT(*) FROM poetry_source s JOIN poetry_text_version v ON v.source_id=s.id WHERE v.work_id=#{workId} AND s.verification_status<>'VERIFIED'")
    Integer pendingTextSourceCount(@Param("workId") String workId);

    @Insert("INSERT IGNORE INTO poetry_agent_mandate (run_id,mandate_id,work_id,actor_role,status) VALUES (#{runId},#{mandateId},#{workId},#{role},'ACTIVE')")
    int ensureMandate(@Param("runId") String runId, @Param("mandateId") String mandateId, @Param("workId") String workId, @Param("role") String role);
    @Select("SELECT COUNT(*) FROM poetry_agent_mandate WHERE run_id=#{runId} AND mandate_id=#{mandateId} AND work_id=#{workId} AND status='ACTIVE'")
    Integer activeMandate(@Param("runId") String runId, @Param("mandateId") String mandateId, @Param("workId") String workId);

    @Select("SELECT result_ref FROM poetry_agent_tool_receipt WHERE operation=#{operation} AND idempotency_key=#{key}")
    String receipt(@Param("operation") String operation, @Param("key") String key);
    @Insert("INSERT INTO poetry_agent_tool_receipt (operation,idempotency_key,run_id,mandate_id,result_ref) VALUES (#{operation},#{key},#{runId},#{mandateId},#{ref})")
    int receiptInsert(@Param("operation") String operation, @Param("key") String key, @Param("runId") String runId, @Param("mandateId") String mandateId, @Param("ref") String ref);

    @Insert("INSERT INTO poetry_agent_proposal (id,work_id,run_id,mandate_id,proposal_json,status,review_status,created_by) VALUES (#{id},#{workId},#{runId},#{mandateId},#{json},'DRAFT','PENDING','DEERFLOW')")
    int proposalInsert(@Param("id") String id, @Param("workId") String workId, @Param("runId") String runId, @Param("mandateId") String mandateId, @Param("json") String json);
    @Select("SELECT COUNT(*) FROM poetry_agent_proposal WHERE id=#{id} AND work_id=#{workId} AND run_id=#{runId} AND mandate_id=#{mandateId}")
    Integer proposalExists(@Param("id") String id, @Param("workId") String workId, @Param("runId") String runId, @Param("mandateId") String mandateId);
    @Select("SELECT proposal_json FROM poetry_agent_proposal WHERE id=#{id}") String proposalJson(@Param("id") String id);
    @Select("SELECT work_id FROM poetry_agent_proposal WHERE id=#{id}") String proposalWorkId(@Param("id") String id);
    @Select("SELECT review_status FROM poetry_agent_proposal WHERE id=#{id}") String proposalReviewStatus(@Param("id") String id);
    @Select("SELECT review_id FROM poetry_agent_proposal WHERE id=#{id}") String proposalReviewId(@Param("id") String id);
    @Update("UPDATE poetry_agent_proposal SET review_status=#{decision},review_id=#{reviewId},reviewed_by=#{reviewer},reviewed_at=NOW(),review_comment=#{comment} WHERE id=#{id} AND review_status='PENDING'")
    int reviewProposal(@Param("id") String id, @Param("reviewId") String reviewId, @Param("decision") String decision, @Param("reviewer") String reviewer, @Param("comment") String comment);
    @Update("UPDATE poetry_agent_proposal SET status='APPLIED',applied_at=NOW() WHERE id=#{id} AND status='DRAFT' AND review_status='APPROVED'")
    int markApplied(@Param("id") String id);
    @Insert("INSERT INTO poetry_agent_review (id,proposal_id,reviewer_id,decision,comment) VALUES (#{id},#{proposalId},#{reviewer},#{decision},#{comment})")
    int reviewInsert(@Param("id") String id, @Param("proposalId") String proposalId, @Param("reviewer") String reviewer, @Param("decision") String decision, @Param("comment") String comment);

    @Insert("INSERT INTO poetry_agent_compile_request (id,work_id,script_version,run_id,mandate_id,status,reason) VALUES (#{id},#{workId},#{version},#{runId},#{mandateId},#{status},#{reason})")
    int compileInsert(@Param("id") String id, @Param("workId") String workId, @Param("version") String version, @Param("runId") String runId, @Param("mandateId") String mandateId, @Param("status") String status, @Param("reason") String reason);
}
