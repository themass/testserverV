package com.timeline.poetry;

import com.timeline.poetry.api.PoetryController;
import com.timeline.poetry.persistence.PoetryMapper;
import com.timeline.poetry.service.PoetryCatalog;
import org.apache.ibatis.mapping.Environment;
import org.apache.ibatis.session.Configuration;
import org.apache.ibatis.session.SqlSession;
import org.apache.ibatis.session.SqlSessionFactoryBuilder;
import org.apache.ibatis.transaction.jdbc.JdbcTransactionFactory;
import org.h2.jdbcx.JdbcDataSource;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.core.io.ClassPathResource;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.init.ResourceDatabasePopulator;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import java.util.UUID;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/** Synthetic publication fixtures are test data, not approval of historical seed content. */
class PoetryIntegrationTest {
    private JdbcTemplate jdbc;
    private SqlSession session;
    private PoetryMapper mapper;
    private PoetryCatalog catalog;
    private MockMvc mvc;
    @BeforeEach void setUp() throws Exception {
        JdbcDataSource ds = new JdbcDataSource();
        ds.setURL("jdbc:h2:mem:" + UUID.randomUUID() + ";MODE=MySQL;DATABASE_TO_LOWER=TRUE;DB_CLOSE_DELAY=-1");
        new ResourceDatabasePopulator(new ClassPathResource("db/poetry/V001__foundation.sql")).execute(ds);
        // H2 does not implement MySQL START TRANSACTION; exercise the unchanged DML inside a Spring transaction.
        String seed = new ClassPathResource("db/poetry/V002__draft_seed.sql").getContentAsString(java.nio.charset.StandardCharsets.UTF_8)
            .replace("START TRANSACTION;", "").replace("COMMIT;", "");
        new org.springframework.transaction.support.TransactionTemplate(
            new org.springframework.jdbc.datasource.DataSourceTransactionManager(ds)).executeWithoutResult(status ->
                new ResourceDatabasePopulator(new org.springframework.core.io.ByteArrayResource(
                    seed.getBytes(java.nio.charset.StandardCharsets.UTF_8))).execute(ds));
        jdbc = new JdbcTemplate(ds);
        Configuration config = new Configuration(new Environment("test", new JdbcTransactionFactory(), ds));
        // Match the host: no underscore-to-camel-case setting or custom record mapping.
        config.addMapper(PoetryMapper.class);
        session = new org.mybatis.spring.SqlSessionTemplate(new SqlSessionFactoryBuilder().build(config));
        mapper = session.getMapper(PoetryMapper.class);
        catalog = new PoetryCatalog(mapper);
        mvc = MockMvcBuilders.standaloneSetup(new PoetryController(catalog)).build();
    }
    void reviewNode(String id) {
        jdbc.update("UPDATE poetry_content SET status='PUBLISHED',reviewed_by='test-reviewer',reviewed_at=CURRENT_TIMESTAMP WHERE id=?", id);
    }
    void reviewWorkAndSource() {
        reviewNode("work-chun-wang");
        jdbc.update("UPDATE poetry_source SET verification_status='VERIFIED',verified_by='test-reviewer',verified_at=CURRENT_TIMESTAMP");
        jdbc.update("UPDATE poetry_text_version SET status='PUBLISHED',reviewed_by='test-reviewer',reviewed_at=CURRENT_TIMESTAMP");
    }
    void reviewClaim(String id) {
        jdbc.update("UPDATE poetry_claim SET status='PUBLISHED',reviewed_by='test-reviewer',reviewed_at=CURRENT_TIMESTAMP WHERE id=?", id);
    }
    @Test void draftSeedIsPresentButInvisibleEvenViaChildUrls() throws Exception {
        assertEquals(8, jdbc.queryForObject("SELECT COUNT(*) FROM poetry_text_line", Integer.class));
        assertEquals(2, jdbc.queryForObject("SELECT COUNT(*) FROM poetry_schema_version", Integer.class));
        assertTrue(catalog.contents(null, 20, 0).items().isEmpty());
        assertThrows(PoetryCatalog.NotFound.class, () -> catalog.work("work-chun-wang"));
        mvc.perform(get("/api/poetry/v1/versions/text-chun-wang-draft/lines")).andExpect(status().isNotFound());
        mvc.perform(get("/api/poetry/v1/claims/claim-chun-wang-author/citations")).andExpect(status().isNotFound());
    }
    @Test void reviewMetadataIsRequiredNotJustPublishedFlag() {
        jdbc.update("UPDATE poetry_content SET status='PUBLISHED'");
        assertTrue(catalog.contents(null, 20, 0).items().isEmpty());
        reviewNode("work-chun-wang");
        assertNull(catalog.work("work-chun-wang").work().dynastyId());
        assertTrue(catalog.versions("work-chun-wang", 20, 0).items().isEmpty());
    }
    @Test void publishedVersionRequiresPublishedWorkAndVerifiedSource() {
        reviewWorkAndSource();
        assertEquals("work-chun-wang", catalog.work("work-chun-wang").content().id());
        assertEquals(8, catalog.lines("text-chun-wang-draft", 20, 0).items().size());
        assertEquals(1, catalog.versions("work-chun-wang", 20, 0).items().size());
        jdbc.update("UPDATE poetry_source SET verification_status='PENDING'");
        assertThrows(PoetryCatalog.NotFound.class, () -> catalog.lines("text-chun-wang-draft", 20, 0));
        assertTrue(catalog.versions("work-chun-wang", 20, 0).items().isEmpty());
    }
    @Test void paginationIsStableAndIndicatesMoreWithoutUnboundedReads() {
        reviewNode("dynasty-tang"); reviewNode("person-du-fu"); reviewNode("work-chun-wang");
        var page = catalog.contents(null, 2, 0);
        assertEquals(2, page.items().size()); assertTrue(page.hasMore());
        assertEquals("work-chun-wang", catalog.contents(null, 2, 2).items().getFirst().id());
        assertFalse(catalog.contents(null, 2, 2).hasMore());
        assertEquals("PERSON", catalog.contents("person", 20, 0).items().getFirst().entityType());
    }
    @Test void uncertainIntervalsOverlapRatherThanCollapsingToOneYear() {
        reviewNode("work-chun-wang"); reviewNode("person-du-fu");
        jdbc.update("UPDATE poetry_content SET start_year=756,end_year=758,time_precision='APPROXIMATE' WHERE id='work-chun-wang'");
        var result = catalog.timeline("WORK", 757, 757, 20, 0);
        assertEquals(1, result.results().items().size());
        assertEquals(756, result.results().items().getFirst().startYear());
        assertFalse(result.includesUnknownDates());
        assertTrue(catalog.timeline(null, 759, 760, 20, 0).results().items().isEmpty());
        assertEquals(2, catalog.contents(null, 20, 0).items().size());
    }
    @Test void claimsNeedEvidenceAndSelectedClaimMustBelongToItsProperty() {
        reviewNode("work-chun-wang"); reviewClaim("claim-chun-wang-author");
        assertTrue(catalog.claims("work-chun-wang", 20, 0).items().isEmpty());
        jdbc.update("UPDATE poetry_source SET verification_status='VERIFIED',verified_by='test',verified_at=CURRENT_TIMESTAMP");
        assertEquals(1, catalog.claims("work-chun-wang", 20, 0).items().size());
        jdbc.update("INSERT INTO poetry_claim_selection VALUES ('work-chun-wang','creation_date','claim-chun-wang-author')");
        assertFalse(catalog.claim("claim-chun-wang-author").selected());
        jdbc.update("INSERT INTO poetry_claim_selection VALUES ('work-chun-wang','authorship','claim-chun-wang-author')");
        assertTrue(catalog.claim("claim-chun-wang-author").selected());
        assertEquals(1, catalog.citations("claim-chun-wang-author", 20, 0).items().size());
    }
    @Test void authorsAndRelationsDoNotLeakDraftTargets() {
        reviewWorkAndSource(); reviewClaim("claim-chun-wang-author");
        jdbc.update("UPDATE poetry_work_author SET attribution='ACCEPTED'");
        jdbc.update("INSERT INTO poetry_relation VALUES ('r1','work-chun-wang','AUTHORED_BY','person-du-fu','claim-chun-wang-author')");
        assertTrue(catalog.authors("work-chun-wang", 20, 0).items().isEmpty());
        assertTrue(catalog.relations("work-chun-wang", 20, 0).items().isEmpty());
        reviewNode("person-du-fu");
        assertEquals(1, catalog.authors("work-chun-wang", 20, 0).items().size());
        assertEquals(1, catalog.relations("work-chun-wang", 20, 0).items().size());
    }
    @Test void unlabeledDramatizationIsNeverReturnedAsHistory() {
        reviewNode("work-chun-wang");
        jdbc.update("INSERT INTO poetry_claim (id,subject_id,property_key,value_text,claim_kind,status,reviewed_by,reviewed_at) VALUES ('scene','work-chun-wang','scene','synthetic scene','DRAMATIZATION','PUBLISHED','test',CURRENT_TIMESTAMP)");
        assertTrue(catalog.claims("work-chun-wang", 20, 0).items().isEmpty());
        jdbc.update("UPDATE poetry_claim SET dramatization_labeled=1 WHERE id='scene'");
        assertEquals("DRAMATIZATION", catalog.claim("scene").claimKind());
    }
    @Test void apiValidatesBoundsTypesMissingParametersAndIds() throws Exception {
        for (String url : new String[]{"/content?limit=0", "/content?limit=101", "/content?offset=-1",
            "/content?type=secret", "/content?limit=no", "/timeline", "/timeline?fromYear=0&toYear=1",
            "/timeline?fromYear=758&toYear=757", "/timeline?fromYear=-9999&toYear=9999"}) {
            mvc.perform(get("/api/poetry/v1" + url)).andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errno").value(400));
        }
        mvc.perform(get("/api/poetry/v1/content/missing")).andExpect(status().isNotFound());
        assertThrows(IllegalArgumentException.class, () -> catalog.content("' OR 1=1", null));
    }
    @Test void publicApiIsPlainJsonAndSupportsTypedDetailAndLines() throws Exception {
        reviewWorkAndSource();
        mvc.perform(get("/api/poetry/v1/works/work-chun-wang")).andExpect(status().isOk())
            .andExpect(jsonPath("$.errno").value(0)).andExpect(jsonPath("$.data.content.title").value("春望"));
        mvc.perform(get("/api/poetry/v1/versions/text-chun-wang-draft/lines?limit=2"))
            .andExpect(status().isOk()).andExpect(jsonPath("$.data.items[0].lineSeq").value(1))
            .andExpect(jsonPath("$.data.hasMore").value(true));
    }
    @Test void foreignKeysRejectBrokenReferencesAndDuplicateTextLines() {
        assertThrows(Exception.class, () -> jdbc.update("INSERT INTO poetry_text_line VALUES ('absent',1,'x',NULL)"));
        assertThrows(Exception.class, () -> jdbc.update("INSERT INTO poetry_text_line VALUES ('text-chun-wang-draft',1,'x',NULL)"));
    }
    @Test void emptyTypedEndpointsExecuteTheirQueries() {
        reviewWorkAndSource(); reviewNode("person-du-fu");
        assertTrue(catalog.backgrounds("work-chun-wang", 20, 0).items().isEmpty());
        assertTrue(catalog.experiences("person-du-fu", 20, 0).items().isEmpty());
        assertTrue(mapper.backgroundLines("none", 21, 0).isEmpty());
    }
}
