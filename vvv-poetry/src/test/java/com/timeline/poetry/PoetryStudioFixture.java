package com.timeline.poetry;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.timeline.poetry.api.PoetryAgentOrchestrationController;
import com.timeline.poetry.api.PoetryStudioAdvice;
import com.timeline.poetry.api.PoetryStudioReadController;
import com.timeline.poetry.api.PoetryStudioWriteController;
import com.timeline.poetry.persistence.PoetryAgentMapper;
import com.timeline.poetry.persistence.PoetryAgentOrchestrationMapper;
import com.timeline.poetry.persistence.PoetryDraftWriter;
import com.timeline.poetry.persistence.PoetryDraftWriter2;
import com.timeline.poetry.persistence.PoetryStudioMapper;
import com.timeline.poetry.persistence.PoetryWriter;
import com.timeline.poetry.service.AuditRunner;
import com.timeline.poetry.service.PoetryAgentOrchestrationService;
import com.timeline.poetry.service.PoetryAgentService;
import com.timeline.poetry.service.PoetryReviewService;
import com.timeline.poetry.service.PoetryStudioService;
import com.timeline.poetry.service.PoetryTextService;
import org.apache.ibatis.mapping.Environment;
import org.apache.ibatis.session.Configuration;
import org.apache.ibatis.session.SqlSessionFactoryBuilder;
import org.apache.ibatis.transaction.jdbc.JdbcTransactionFactory;
import org.h2.jdbcx.JdbcDataSource;
import org.mybatis.spring.SqlSessionTemplate;
import org.springframework.core.io.ClassPathResource;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.init.ResourceDatabasePopulator;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import java.nio.charset.StandardCharsets;
import java.util.ArrayDeque;
import java.util.List;
import java.util.Queue;
import java.util.UUID;

/**
 * Studio 测试共用夹具：每个测试一个独立的 H2 内存库(MySQL 模式)，装载真实迁移文件。
 *
 * <p>装载方式与 PoetryIntegrationTest 相同(ResourceDatabasePopulator + ClassPathResource)。
 * 唯一例外是 V008：H2 2.2 不接受它的"单条 ALTER 多个 ADD COLUMN ... AFTER"，
 * 所以改用 src/test/resources/db/poetry-test/V008_h2_equivalent.sql(列集合一致，见该文件头部说明)。
 * V001、V002、V003、V004、V007、V009 都是仓库里的真实文件。V002/V004 去掉 START TRANSACTION/COMMIT(H2 不支持)，其余原样。
 *
 * <p>审计用 {@link ScriptedAudit} 代替真实的 106 项 SQL：这些测试验证的是 Studio 逻辑，不是审计 SQL；
 * 审计 SQL 自身在 H2 上能否运行没有被任何现有测试验证过。
 */
final class PoetryStudioFixture {
    static final String AGENT_TOKEN = "test-agent-token-not-a-secret";
    static final String STUDIO_TOKEN = "test-studio-token-not-a-secret";
    static final String REVIEWER = "Zhang Wei";
    static final String ROLE = "HISTORICAL_REVIEWER";

    final JdbcTemplate jdbc;
    final ScriptedAudit audit;
    final ObjectMapper json = new ObjectMapper();
    final PoetryAgentMapper agentMapper;
    final PoetryAgentService agent;
    final PoetryStudioService studio;
    final MockMvc mvc;

    /** 可编排的审计桩：默认每次都干净；offer() 的结果按调用顺序消费。 */
    static final class ScriptedAudit extends AuditRunner {
        private final Queue<Result> queue = new ArrayDeque<>();
        ScriptedAudit(javax.sql.DataSource ds) { super(ds); }
        void offer(Result r) { queue.add(r); }
        @Override public Result run() { Result r = queue.poll(); return r != null ? r : new Result(106, List.of()); }
    }

    PoetryStudioFixture() throws Exception { this(STUDIO_TOKEN, AGENT_TOKEN); }

    PoetryStudioFixture(String studioToken, String agentToken) throws Exception {
        JdbcDataSource ds = new JdbcDataSource();
        ds.setURL("jdbc:h2:mem:" + UUID.randomUUID() + ";MODE=MySQL;DATABASE_TO_LOWER=TRUE;DB_CLOSE_DELAY=-1");
        script(ds, "db/poetry/V001__foundation.sql", false);
        script(ds, "db/poetry/V002__draft_seed.sql", true);
        script(ds, "db/poetry/V003__integrity.sql", false);
        script(ds, "db/poetry/V004__chunwang_context_draft.sql", true);
        script(ds, "db/poetry/V007__agent_domain_audit.sql", false);
        script(ds, "db/poetry-test/V008_h2_equivalent.sql", false);
        script(ds, "db/poetry/V009__studio_governance.sql", false);
        jdbc = new JdbcTemplate(ds);

        Configuration config = new Configuration(new Environment("test", new JdbcTransactionFactory(), ds));
        config.addMapper(PoetryAgentMapper.class);
        config.addMapper(PoetryAgentOrchestrationMapper.class);
        config.addMapper(PoetryDraftWriter.class);
        config.addMapper(PoetryDraftWriter2.class);
        config.addMapper(PoetryWriter.class);
        config.addMapper(PoetryStudioMapper.class);
        SqlSessionTemplate session = new SqlSessionTemplate(new SqlSessionFactoryBuilder().build(config));

        audit = new ScriptedAudit(ds);
        agentMapper = session.getMapper(PoetryAgentMapper.class);
        PoetryTextService texts = new PoetryTextService(session.getMapper(PoetryDraftWriter2.class), session.getMapper(PoetryDraftWriter.class), audit);
        agent = new PoetryAgentService(agentMapper, texts, audit, json);
        PoetryReviewService review = new PoetryReviewService(session.getMapper(PoetryWriter.class), audit);
        studio = new PoetryStudioService(session.getMapper(PoetryStudioMapper.class), agent, review, json);

        PoetryAgentOrchestrationService orchestration = new PoetryAgentOrchestrationService(
            session.getMapper(PoetryAgentOrchestrationMapper.class), agent, json);
        mvc = MockMvcBuilders.standaloneSetup(
                new PoetryStudioReadController(studio, agentToken),
                new PoetryStudioWriteController(studio, studioToken, agentToken, json),
                new PoetryAgentOrchestrationController(orchestration, agentToken))
            .setControllerAdvice(new PoetryStudioAdvice()).build();
    }

    private static void script(JdbcDataSource ds, String path, boolean stripTransaction) throws Exception {
        String sql = new ClassPathResource(path).getContentAsString(StandardCharsets.UTF_8);
        if (stripTransaction) sql = sql.replace("START TRANSACTION;", "").replace("COMMIT;", "");
        ResourceDatabasePopulator populator = new ResourceDatabasePopulator(new org.springframework.core.io.ByteArrayResource(sql.getBytes(StandardCharsets.UTF_8)));
        populator.setSqlScriptEncoding("UTF-8");
        populator.execute(ds);
    }

    // ------------------------------------------------------------------ 种子辅助

    /** 一个带 3 个 change 的提案：0 和 1 可执行(CREATE_ANNOTATION)，2 不可执行。 */
    String seedProposal(String proposalId) throws Exception {
        String runId = "run_" + proposalId;
        String mandateId = "mandate_" + proposalId;
        jdbc.update("INSERT INTO poetry_agent_mandate (run_id,mandate_id,work_id,actor_role,status) VALUES (?,?,?,?,'ACTIVE')",
            runId, mandateId, "work-chun-wang", "CONTENT_EDITOR");
        jdbc.update("INSERT INTO poetry_agent_proposal (id,work_id,run_id,mandate_id,proposal_json,status,review_status,created_by) VALUES (?,?,?,?,?,'DRAFT','PENDING','DEERFLOW')",
            proposalId, "work-chun-wang", runId, mandateId, proposalJson(proposalId));
        return runId;
    }

    String proposalJson(String proposalId) throws Exception {
        return json.writeValueAsString(json.readTree("""
            {"schema_version":1,"status":"DRAFT","summary":"test proposal","human_review_question":"ok?",
             "changes":[
               {"change_type":"ANNOTATION","classification":"DRAFT","body":"annotation A","draft_payload":
                 {"operation":"CREATE_ANNOTATION","id":"ann-%1$s-a","version_id":"text-chun-wang-draft","line_seq":2,"annotation_kind":"WORD",
                  "audience":"PRIMARY","content":"content A","claim_id":"claim-%1$s-a","claim_value":"claim A","certainty":"LIKELY","source_id":null,"locator":null}},
               {"change_type":"ANNOTATION","classification":"DRAFT","body":"annotation B","draft_payload":
                 {"operation":"CREATE_ANNOTATION","id":"ann-%1$s-b","version_id":"text-chun-wang-draft","line_seq":3,"annotation_kind":"PHRASE",
                  "audience":"JUNIOR","content":"content B","claim_id":"claim-%1$s-b","claim_value":"claim B","certainty":"DISPUTED","source_id":null,"locator":null}},
               {"change_type":"GAP_REPORT","classification":"DRAFT","body":"a gap"}
             ]}
            """.formatted(proposalId)));
    }

    void approveProposal(String proposalId, String reviewId) {
        jdbc.update("UPDATE poetry_agent_proposal SET review_status='APPROVED',review_id=?,reviewed_by='Li Na',reviewed_at=CURRENT_TIMESTAMP WHERE id=?", reviewId, proposalId);
    }

    PoetryAgentService.Context contextFor(String proposalId, String idempotencyKey) {
        return new PoetryAgentService.Context("run_" + proposalId, "mandate_" + proposalId, idempotencyKey, "CONTENT_EDITOR");
    }

    void seedTask(String id, String workId, String taskType, String status, String createdAt) {
        jdbc.update("INSERT INTO poetry_agent_task (id,work_id,task_type,requested_by,status,created_at,title,instructions,requested_profile,requested_role) VALUES (?,?,?,?,?,?,?,?,?,?)",
            id, workId, taskType, "Li Na", status, createdAt, "title " + id, "instructions", "authoring", "CONTENT_EDITOR");
    }

    void seedRun(String runId, String taskId) {
        jdbc.update("INSERT INTO poetry_agent_run (id,task_id,runtime,profile_fingerprint,status,mandate_id,profile_name) VALUES (?,?,?,?,?,?,?)",
            runId, taskId, "STUB", "a".repeat(64), "COMPLETED", "mandate_" + runId, "authoring");
    }

    JsonNode tree(String body) throws Exception { return json.readTree(body); }
}
