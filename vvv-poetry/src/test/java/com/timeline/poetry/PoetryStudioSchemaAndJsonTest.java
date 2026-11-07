package com.timeline.poetry;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.timeline.poetry.api.PoetryAgentOrchestrationModels.TaskCreate;
import com.timeline.poetry.api.PoetryStudioModels.ItemDecisions;
import com.timeline.poetry.api.PoetryStudioModels.LocatorUpdate;
import com.timeline.poetry.api.PoetryStudioModels.StudioResponse;
import org.junit.jupiter.api.Test;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.core.io.ClassPathResource;
import org.springframework.jdbc.datasource.init.ResourceDatabasePopulator;
import java.nio.charset.StandardCharsets;
import java.util.List;
import static org.junit.jupiter.api.Assertions.*;

/** V009 的装载/回滚(H2)，以及 Jackson 命名绑定的特征测试。 */
class PoetryStudioSchemaAndJsonTest {

    // ------------------------------------------------------------------ V009

    @Test void v009CreatesTheTablesAndTheLedgerRowAndTheKeysEnforceUniqueness() throws Exception {
        PoetryStudioFixture fx = new PoetryStudioFixture();
        assertEquals(1, fx.jdbc.queryForObject("SELECT COUNT(*) FROM poetry_schema_version WHERE version_no=9", Integer.class));
        assertEquals(0, fx.jdbc.queryForObject("SELECT COUNT(*) FROM poetry_agent_proposal_item", Integer.class));
        assertEquals(0, fx.jdbc.queryForObject("SELECT COUNT(*) FROM poetry_studio_check_log", Integer.class));
        fx.jdbc.update("INSERT INTO poetry_agent_proposal_item (proposal_id,item_index,decision,reviewer) VALUES ('p1',0,'APPROVE','Li Na')");
        assertThrows(Exception.class, () -> fx.jdbc.update("INSERT INTO poetry_agent_proposal_item (proposal_id,item_index,decision,reviewer) VALUES ('p1',0,'REJECT','Li Na')"));
        fx.jdbc.update("INSERT INTO poetry_agent_proposal_item (proposal_id,item_index,decision,reviewer) VALUES ('p1',1,'REJECT','Li Na')");
        fx.jdbc.update("INSERT INTO poetry_studio_check_log (action,reviewer,reviewer_role) VALUES ('X','Li Na','CONTENT_EDITOR')");
        assertNotNull(fx.jdbc.queryForObject("SELECT created_at FROM poetry_studio_check_log", java.sql.Timestamp.class));
    }

    @Test void v009RollbackRemovesWhatV009Added() throws Exception {
        PoetryStudioFixture fx = new PoetryStudioFixture();
        String sql = new ClassPathResource("db/poetry/recovery/V009_rollback.sql").getContentAsString(StandardCharsets.UTF_8);
        // 回滚里的 DROP INDEX ... ON 是 MySQL 语法；H2 的 MySQL 模式接受它。如果 H2 版本升级后不接受，改成 H2 的 DROP INDEX name 即可。
        ResourceDatabasePopulator populator = new ResourceDatabasePopulator(new ByteArrayResource(sql.getBytes(StandardCharsets.UTF_8)));
        populator.setSqlScriptEncoding("UTF-8");
        populator.execute(fx.jdbc.getDataSource());
        assertEquals(0, fx.jdbc.queryForObject("SELECT COUNT(*) FROM poetry_schema_version WHERE version_no=9", Integer.class));
        // The rollback renames the two tables (audit trail kept), it does not drop them.
        assertThrows(Exception.class, () -> fx.jdbc.queryForObject("SELECT COUNT(*) FROM poetry_agent_proposal_item", Integer.class));
        assertThrows(Exception.class, () -> fx.jdbc.queryForObject("SELECT COUNT(*) FROM poetry_studio_check_log", Integer.class));
        assertEquals(0, fx.jdbc.queryForObject("SELECT COUNT(*) FROM poetry_studio_check_log_rolledback_20261107", Integer.class), "audit trail renamed, not dropped");
        assertEquals(0, fx.jdbc.queryForObject("SELECT COUNT(*) FROM poetry_agent_proposal_item_rolledback_20261107", Integer.class));
        assertEquals(1, fx.jdbc.queryForObject("SELECT COUNT(*) FROM poetry_schema_version WHERE version_no=7", Integer.class), "earlier ledger rows stay");
    }

    // ------------------------------------------------------------------ Jackson

    @Test void studioRecordsBindSnakeCaseKeysWhateverTheGlobalNamingStrategyIs() throws Exception {
        String locator = "{\"locator\":\"卷一\",\"evidence_excerpt\":\"x\",\"reviewer\":\"Zhang Wei\",\"reviewer_role\":\"HISTORICAL_REVIEWER\",\"note\":\"n\"}";
        String items = "{\"decisions\":[{\"item_index\":2,\"decision\":\"APPROVE\",\"comment\":\"c\"}],\"reviewer\":\"Li Na\",\"reviewer_role\":\"CONTENT_EDITOR\"}";
        for (ObjectMapper mapper : List.of(new ObjectMapper(),
                new ObjectMapper().setPropertyNamingStrategy(PropertyNamingStrategies.SNAKE_CASE),
                new ObjectMapper().setPropertyNamingStrategy(PropertyNamingStrategies.LOWER_CAMEL_CASE),
                new ObjectMapper().setPropertyNamingStrategy(PropertyNamingStrategies.UPPER_CAMEL_CASE))) {
            LocatorUpdate l = mapper.readValue(locator, LocatorUpdate.class);
            assertEquals("HISTORICAL_REVIEWER", l.reviewerRole());
            assertEquals("x", l.evidenceExcerpt());
            ItemDecisions d = mapper.readValue(items, ItemDecisions.class);
            assertEquals(2, d.decisions().get(0).itemIndex().intValue());
            assertEquals("CONTENT_EDITOR", d.reviewerRole());
        }
    }

    @Test void studioResponseSerialisesWithSnakeCaseEnvelopeKeys() throws Exception {
        for (ObjectMapper mapper : List.of(new ObjectMapper(), new ObjectMapper().setPropertyNamingStrategy(PropertyNamingStrategies.UPPER_CAMEL_CASE))) {
            var tree = mapper.valueToTree(StudioResponse.ok(java.util.Map.of("a", 1), List.of("ref")));
            assertTrue(tree.has("audit_refs"));
            assertTrue(tree.has("next_action"));
            assertFalse(tree.has("auditRefs"));
        }
    }

    /** 说明性特征测试：一个没有显式名字的 camelCase record 在默认 Jackson 下确实不认 snake_case 键(这正是原先的风险)。 */
    record Implicit(String taskId) {}
    record Explicit(@JsonProperty("task_id") String taskId) {}

    @Test void anUnannotatedCamelCaseRecordDoesNotBindSnakeCaseByDefault() throws Exception {
        ObjectMapper lenient = new ObjectMapper().configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);
        assertNull(lenient.readValue("{\"task_id\":\"t\"}", Implicit.class).taskId(), "default Jackson ignores task_id for a taskId component");
        assertEquals("t", lenient.readValue("{\"taskId\":\"t\"}", Implicit.class).taskId());
        assertEquals("t", lenient.readValue("{\"task_id\":\"t\"}", Explicit.class).taskId());
        assertThrows(Exception.class, () -> new ObjectMapper().readValue("{\"task_id\":\"t\"}", Implicit.class), "strict mapper would reject it");
    }

    /** 协调者已给 TaskCreate 加了显式 snake_case(含 camelCase 别名)；这里钉住：两种键都能绑。 */
    @Test void taskCreateAcceptsSnakeCaseAndCamelCaseAfterTheWireFix() throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        TaskCreate snake = mapper.readValue("{\"task_id\":\"task_1\",\"work_id\":\"w\"}", TaskCreate.class);
        assertEquals("task_1", snake.taskId());
        TaskCreate camel = mapper.readValue("{\"taskId\":\"task_2\",\"workId\":\"w\"}", TaskCreate.class);
        assertEquals("task_2", camel.taskId());
    }
}
