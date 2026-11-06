package com.timeline.poetry.persistence;

import org.apache.ibatis.annotations.*;
import java.util.List;
import java.util.Map;

/** Persistence for durable agent orchestration. No foreign-key annotations or constraints. */
public interface PoetryAgentOrchestrationMapper {
    @Insert("INSERT INTO poetry_agent_task (id,work_id,title,task_type,requested_by,requested_role,instructions,requested_profile,status) VALUES (#{id},#{workId},#{title},#{type},#{requestedBy},#{requestedRole},#{instructions},#{profile},'CREATED')")
    int insertTask(@Param("id") String id, @Param("workId") String workId, @Param("title") String title, @Param("type") String type, @Param("requestedBy") String requestedBy, @Param("requestedRole") String requestedRole, @Param("instructions") String instructions, @Param("profile") String profile);

    @Select("SELECT id AS task_id,work_id,title,task_type,status,requested_by,requested_role,instructions,requested_profile,active_run_id,created_at,updated_at FROM poetry_agent_task WHERE id=#{id}")
    Map<String,Object> task(@Param("id") String id);
    @Select("SELECT COUNT(*) FROM poetry_agent_task WHERE id=#{id}") int taskExists(@Param("id") String id);
    @Select("SELECT work_id FROM poetry_agent_task WHERE id=#{id}") String taskWorkId(@Param("id") String id);
    @Update("UPDATE poetry_agent_task SET status=#{status},active_run_id=#{runId},updated_at=NOW() WHERE id=#{id}")
    int taskState(@Param("id") String id, @Param("status") String status, @Param("runId") String runId);

    @Insert("INSERT IGNORE INTO poetry_agent_profile_version (fingerprint,profile_name,manifest_json) VALUES (#{fingerprint},#{name},#{manifest})")
    int ensureProfile(@Param("fingerprint") String fingerprint, @Param("name") String name, @Param("manifest") String manifest);
    @Insert("INSERT INTO poetry_agent_run (id,task_id,mandate_id,runtime,profile_name,profile_fingerprint,status) VALUES (#{id},#{taskId},#{mandateId},#{runtime},#{profileName},#{fingerprint},'WAITING_FOR_RUNTIME')")
    int insertRun(@Param("id") String id, @Param("taskId") String taskId, @Param("mandateId") String mandateId, @Param("runtime") String runtime, @Param("profileName") String profileName, @Param("fingerprint") String fingerprint);
    @Insert("INSERT INTO poetry_agent_mandate (run_id,mandate_id,work_id,actor_role,status) VALUES (#{runId},#{mandateId},#{workId},#{role},'ACTIVE')")
    int insertMandate(@Param("runId") String runId, @Param("mandateId") String mandateId, @Param("workId") String workId, @Param("role") String role);
    @Select("SELECT r.id AS run_id,r.task_id,r.mandate_id,r.runtime,r.profile_name,r.profile_fingerprint,r.status,r.runtime_thread_id,r.runtime_run_id,r.reason,r.created_at,r.updated_at,t.work_id,t.requested_by,t.requested_role FROM poetry_agent_run r JOIN poetry_agent_task t ON t.id=r.task_id WHERE r.id=#{id}")
    Map<String,Object> run(@Param("id") String id);
    @Select("SELECT COUNT(*) FROM poetry_agent_run WHERE id=#{id}") int runExists(@Param("id") String id);
    @Update("UPDATE poetry_agent_run SET status=#{status},runtime_thread_id=#{threadId},runtime_run_id=#{runtimeRunId},reason=#{reason},updated_at=NOW() WHERE id=#{id}")
    int admitRun(@Param("id") String id, @Param("status") String status, @Param("threadId") String threadId, @Param("runtimeRunId") String runtimeRunId, @Param("reason") String reason);
    @Update("UPDATE poetry_agent_run SET status=#{status},reason=#{reason},updated_at=NOW() WHERE id=#{id}") int runState(@Param("id") String id, @Param("status") String status, @Param("reason") String reason);

    @Insert("INSERT INTO poetry_agent_event (run_id,event_type,payload_json) VALUES (#{runId},#{type},#{payload})")
    int insertEvent(@Param("runId") String runId, @Param("type") String type, @Param("payload") String payload);
    @Select("SELECT id AS event_id,run_id,event_type,payload_json,occurred_at FROM poetry_agent_event WHERE run_id=#{runId} AND id > #{afterId} ORDER BY id ASC LIMIT #{limit}")
    List<Map<String,Object>> events(@Param("runId") String runId, @Param("afterId") long afterId, @Param("limit") int limit);

    @Select("SELECT p.id AS proposal_id,p.work_id,p.run_id,p.mandate_id,p.proposal_json,p.status,p.review_status,p.review_id,p.created_at,p.applied_at,r.task_id FROM poetry_agent_proposal p JOIN poetry_agent_run r ON r.id=p.run_id WHERE p.id=#{id}")
    Map<String,Object> proposal(@Param("id") String id);
}
