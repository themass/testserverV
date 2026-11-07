package com.timeline.poetry.config;

import com.timeline.poetry.api.PoetryAccessGuard;
import com.timeline.poetry.api.PoetryAuthoringAdvice;
import com.timeline.poetry.api.PoetryMediaController;
import com.timeline.poetry.api.PoetryController;
import com.timeline.poetry.api.PoetryDraftController;
import com.timeline.poetry.api.PoetryReviewController;
import com.timeline.poetry.persistence.PoetryDraftWriter;
import com.timeline.poetry.persistence.PoetryDraftWriter2;
import com.timeline.poetry.persistence.PoetryAgentMapper;
import com.timeline.poetry.persistence.PoetryAgentOrchestrationMapper;
import com.timeline.poetry.persistence.PoetryMapper;
import com.timeline.poetry.persistence.PoetryMediaMapper;
import com.timeline.poetry.persistence.PoetryWriter;
import com.timeline.poetry.service.AuditRunner;
import com.timeline.poetry.service.PoetryCatalog;
import com.timeline.poetry.service.PoetryDraftService;
import com.timeline.poetry.service.PoetryMediaService;
import com.timeline.poetry.service.PoetryReviewService;
import com.timeline.poetry.service.PoetryTextService;
import com.timeline.poetry.service.PoetryAgentService;
import com.timeline.poetry.service.PoetryAgentOrchestrationService;
import com.timeline.poetry.api.PoetryAgentController;
import com.timeline.poetry.api.PoetryAgentOrchestrationController;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.timeline.poetry.service.PoetrySelfCheck;
import javax.sql.DataSource;
import org.springframework.transaction.PlatformTransactionManager;
import org.apache.ibatis.session.SqlSessionFactory;
import org.mybatis.spring.mapper.MapperFactoryBean;
import org.springframework.boot.autoconfigure.AutoConfiguration;
import org.springframework.boot.autoconfigure.condition.ConditionalOnBean;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Import;

/** Opt-in only; shares the host's DataSource/SqlSessionFactory. Does not run migrations. */
@AutoConfiguration(afterName = "org.mybatis.spring.boot.autoconfigure.MybatisAutoConfiguration")
@ConditionalOnBean(SqlSessionFactory.class)
@ConditionalOnProperty(prefix = "poetry", name = "enabled", havingValue = "true")
@Import({PoetryController.class, PoetryReviewController.class})
public class PoetryAutoConfiguration {
    @Bean
    public MapperFactoryBean<PoetryMapper> poetryMapper(SqlSessionFactory factory) {
        MapperFactoryBean<PoetryMapper> bean = new MapperFactoryBean<>(PoetryMapper.class);
        bean.setSqlSessionFactory(factory);
        return bean;
    }
    @Bean
    public PoetryCatalog poetryCatalog(PoetryMapper mapper) { return new PoetryCatalog(mapper); }

    /** Never throws: a broken poetry schema must not take the host application down. */
    @Bean
    public PoetrySelfCheck poetrySelfCheck(PoetryMapper mapper) { return new PoetrySelfCheck(mapper); }

    @Bean
    public MapperFactoryBean<PoetryWriter> poetryWriter(SqlSessionFactory factory) {
        MapperFactoryBean<PoetryWriter> bean = new MapperFactoryBean<>(PoetryWriter.class);
        bean.setSqlSessionFactory(factory);
        return bean;
    }

    /** The audit file is the single definition of the publish preconditions; run it from the classpath. */
    @Bean
    public AuditRunner poetryAuditRunner(DataSource dataSource) { return new AuditRunner(dataSource); }

    @Bean
    public MapperFactoryBean<PoetryDraftWriter> poetryDraftWriter(SqlSessionFactory factory) {
        MapperFactoryBean<PoetryDraftWriter> bean = new MapperFactoryBean<>(PoetryDraftWriter.class);
        bean.setSqlSessionFactory(factory);
        return bean;
    }

    @Bean
    @ConditionalOnBean(PlatformTransactionManager.class)
    public PoetryDraftService poetryDraftService(PoetryDraftWriter writer, AuditRunner audit) {
        return new PoetryDraftService(writer, audit);
    }

    /** Draft authoring token; falls back to the review token so one operator can run both. */
    @Bean
    public MapperFactoryBean<PoetryDraftWriter2> poetryDraftWriter2(SqlSessionFactory factory) {
        MapperFactoryBean<PoetryDraftWriter2> bean = new MapperFactoryBean<>(PoetryDraftWriter2.class);
        bean.setSqlSessionFactory(factory);
        return bean;
    }

    @Bean
    @ConditionalOnBean(PlatformTransactionManager.class)
    public PoetryTextService poetryTextService(PoetryDraftWriter2 writer2, PoetryDraftWriter writer1, AuditRunner audit) {
        return new PoetryTextService(writer2, writer1, audit);
    }

    @Bean
    @ConditionalOnBean(PlatformTransactionManager.class)
    public PoetryDraftController poetryDraftController(
            PoetryDraftService service, PoetryTextService texts,
            @Value("${poetry.authorToken:${poetry.reviewToken:}}") String authorToken) {
        return new PoetryDraftController(service, texts, authorToken);
    }

    /** Authoring exceptions become 400/409 with a message a content operator can act on. */
    @Bean
    public PoetryAuthoringAdvice poetryAuthoringAdvice() { return new PoetryAuthoringAdvice(); }

    /* ---------- V006 media + script layer: assets, scripts, degradation chains ---------- */

    @Bean
    public MapperFactoryBean<PoetryMediaMapper> poetryMediaMapper(SqlSessionFactory factory) {
        MapperFactoryBean<PoetryMediaMapper> bean = new MapperFactoryBean<>(PoetryMediaMapper.class);
        bean.setSqlSessionFactory(factory);
        return bean;
    }

    @Bean
    @ConditionalOnBean(PlatformTransactionManager.class)
    public PoetryMediaService poetryMediaService(PoetryMediaMapper mapper, AuditRunner audit) {
        return new PoetryMediaService(mapper, audit);
    }

    /** Same authoring token as the draft endpoints; there is no media publish path at all. */
    @Bean
    @ConditionalOnBean(PlatformTransactionManager.class)
    public PoetryMediaController poetryMediaController(
            PoetryMediaService media,
            @Value("${poetry.authorToken:${poetry.reviewToken:}}") String authorToken) {
        return new PoetryMediaController(media, authorToken);
    }

    /* ---------- publish side (architecture review P0-1 / P0-2): human reviewer token only ---------- */

    @Bean
    public MapperFactoryBean<com.timeline.poetry.persistence.PoetryPublishMapper> poetryPublishMapper(SqlSessionFactory factory) {
        MapperFactoryBean<com.timeline.poetry.persistence.PoetryPublishMapper> bean =
            new MapperFactoryBean<>(com.timeline.poetry.persistence.PoetryPublishMapper.class);
        bean.setSqlSessionFactory(factory);
        return bean;
    }

    /** poetry.bundleRoot: where the compiler writes {hash32}/manifest.json. Unset -> script publish is refused. */
    @Bean
    @ConditionalOnBean(PlatformTransactionManager.class)
    public com.timeline.poetry.service.PoetryPublishService poetryPublishService(
            com.timeline.poetry.persistence.PoetryPublishMapper publish, PoetryMediaMapper media, AuditRunner audit,
            @Value("${poetry.bundleRoot:}") String bundleRoot) {
        java.nio.file.Path root = (bundleRoot == null || bundleRoot.isBlank()) ? null : java.nio.file.Path.of(bundleRoot);
        return new com.timeline.poetry.service.PoetryPublishService(publish, media, audit, root);
    }

    @Bean
    @ConditionalOnBean(PlatformTransactionManager.class)
    public com.timeline.poetry.api.PoetryPublishController poetryPublishController(
            com.timeline.poetry.service.PoetryPublishService publish,
            @Value("${poetry.studioReviewerToken:}") String reviewerToken,
            @Value("${poetry.agentInternalToken:}") String agentToken) {
        return new com.timeline.poetry.api.PoetryPublishController(publish, reviewerToken, agentToken);
    }

    /**
     * Write side. Only assembled when a transaction manager exists, because a half-applied
     * status change is worse than no write side at all. Endpoints still refuse everything until
     * poetry.reviewToken is configured.
     */
    @Bean
    @ConditionalOnBean(PlatformTransactionManager.class)
    public PoetryReviewService poetryReviewService(PoetryWriter writer, AuditRunner audit) {
        return new PoetryReviewService(writer, audit);
    }

    /* ---------- V007/V008 Agent domain: authenticated, durable, DRAFT-only ---------- */

    @Bean
    public MapperFactoryBean<PoetryAgentMapper> poetryAgentMapper(SqlSessionFactory factory) {
        MapperFactoryBean<PoetryAgentMapper> bean = new MapperFactoryBean<>(PoetryAgentMapper.class);
        bean.setSqlSessionFactory(factory);
        return bean;
    }

    @Bean
    public MapperFactoryBean<PoetryAgentOrchestrationMapper> poetryAgentOrchestrationMapper(SqlSessionFactory factory) {
        MapperFactoryBean<PoetryAgentOrchestrationMapper> bean = new MapperFactoryBean<>(PoetryAgentOrchestrationMapper.class);
        bean.setSqlSessionFactory(factory);
        return bean;
    }

    @Bean
    @ConditionalOnBean(PlatformTransactionManager.class)
    public PoetryAgentService poetryAgentService(PoetryAgentMapper mapper, PoetryTextService texts, AuditRunner audit, ObjectMapper json) {
        return new PoetryAgentService(mapper, texts, audit, json);
    }

    @Bean
    @ConditionalOnBean(PlatformTransactionManager.class)
    public PoetryAgentController poetryAgentController(PoetryAgentService service,
            @Value("${poetry.agentInternalToken:}") String internalToken) {
        return new PoetryAgentController(service, internalToken);
    }

    @Bean
    @ConditionalOnBean(PlatformTransactionManager.class)
    public PoetryAgentOrchestrationService poetryAgentOrchestrationService(PoetryAgentOrchestrationMapper mapper, PoetryAgentService domain, ObjectMapper json) {
        return new PoetryAgentOrchestrationService(mapper, domain, json);
    }

    @Bean
    @ConditionalOnBean(PlatformTransactionManager.class)
    public PoetryAgentOrchestrationController poetryAgentOrchestrationController(PoetryAgentOrchestrationService service,
            @Value("${poetry.agentInternalToken:}") String internalToken) {
        return new PoetryAgentOrchestrationController(service, internalToken);
    }

    /** Published content is token-free by decision, so it gets a log and a cheap ceiling. */
    @Bean
    public FilterRegistrationBean<PoetryAccessGuard> poetryAccessGuard(
            @Value("${poetry.rateLimitPerMinute:300}") int rateLimitPerMinute) {
        FilterRegistrationBean<PoetryAccessGuard> registration = new FilterRegistrationBean<>(
            new PoetryAccessGuard(rateLimitPerMinute));
        registration.addUrlPatterns("/api/poetry/*");
        registration.setName("poetryAccessGuard");
        registration.setOrder(1);
        return registration;
    }

    /* ---------- V009 Studio governance (appended; no existing bean above is changed) ---------- */

    @Bean
    public MapperFactoryBean<com.timeline.poetry.persistence.PoetryStudioMapper> poetryStudioMapper(SqlSessionFactory factory) {
        MapperFactoryBean<com.timeline.poetry.persistence.PoetryStudioMapper> bean =
            new MapperFactoryBean<>(com.timeline.poetry.persistence.PoetryStudioMapper.class);
        bean.setSqlSessionFactory(factory);
        return bean;
    }

    @Bean
    @ConditionalOnBean(PlatformTransactionManager.class)
    public com.timeline.poetry.service.PoetryStudioService poetryStudioService(
            com.timeline.poetry.persistence.PoetryStudioMapper mapper, PoetryAgentService domain,
            PoetryReviewService review, ObjectMapper json) {
        return new com.timeline.poetry.service.PoetryStudioService(mapper, domain, review, json);
    }

    /** Read routes for the MCP control bridge. Same agent token and 403 behaviour as the orchestration controller. */
    @Bean
    @ConditionalOnBean(PlatformTransactionManager.class)
    public com.timeline.poetry.api.PoetryStudioReadController poetryStudioReadController(
            com.timeline.poetry.service.PoetryStudioService service,
            @Value("${poetry.agentInternalToken:}") String internalToken) {
        return new com.timeline.poetry.api.PoetryStudioReadController(service, internalToken);
    }

    /** Human write routes. Own token (poetry.studioReviewerToken); unset -> 503, wrong or agent token -> 401. */
    @Bean
    @ConditionalOnBean(PlatformTransactionManager.class)
    public com.timeline.poetry.api.PoetryStudioWriteController poetryStudioWriteController(
            com.timeline.poetry.service.PoetryStudioService service, ObjectMapper json,
            @Value("${poetry.studioReviewerToken:}") String reviewerToken,
            @Value("${poetry.agentInternalToken:}") String agentToken) {
        return new com.timeline.poetry.api.PoetryStudioWriteController(service, reviewerToken, agentToken, json);
    }

    @Bean
    public com.timeline.poetry.api.PoetryStudioAdvice poetryStudioAdvice() { return new com.timeline.poetry.api.PoetryStudioAdvice(); }
}
