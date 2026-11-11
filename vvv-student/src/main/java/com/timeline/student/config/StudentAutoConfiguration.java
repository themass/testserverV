package com.timeline.student.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.timeline.poetry.config.PoetryAutoConfiguration;
import com.timeline.poetry.service.PoetryCatalog;
import com.timeline.student.api.StudentAccessGuard;
import com.timeline.student.api.StudentAdvice;
import com.timeline.student.api.StudentContentController;
import com.timeline.student.api.StudentCorsFilter;
import com.timeline.student.api.StudentDeviceController;
import com.timeline.student.api.StudentIndexController;
import com.timeline.student.api.StudentModels.Config;
import com.timeline.student.persistence.StudentContentMapper;
import com.timeline.student.persistence.StudentDeviceMapper;
import com.timeline.student.service.BundleStore;
import com.timeline.student.service.ContentService;
import com.timeline.student.service.DeviceService;
import org.apache.ibatis.session.SqlSessionFactory;
import org.mybatis.spring.mapper.MapperFactoryBean;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.AutoConfiguration;
import org.springframework.boot.autoconfigure.condition.ConditionalOnBean;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.transaction.PlatformTransactionManager;
import java.util.Arrays;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

/**
 * Opt-in: student.enabled=true AND the poetry module is active (it supplies PoetryCatalog, the publish gate).
 * Shares the host's DataSource/SqlSessionFactory. Runs no migrations: db/student/*.sql is applied by a person.
 *
 * Properties (all optional except where noted):
 *   student.enabled=true                         required to turn the module on
 *   student.bundle.root=/path/to/dist/bundles    where the compiler's bundles live; blank = bundles answer 503
 *   student.assetBase=https://cdn.example/scenes object-store/CDN base the app prefixes to asset uris
 *   student.dataNoticeVersion=2026-11-06         which privacy notice text the app shows
 *   student.internalToken=                       gap board token; blank keeps /internal/* closed (503)
 *   student.agentEnabled=false                   tells the app whether to try the agent service
 *   student.cors.allowedOrigins=a,b              comma list; defaults to the Capacitor/localhost set
 *   student.rateLimitPerMinute=300, student.deviceCreatePerMinute=10
 *   student.trustForwardedFor=false              true ONLY behind a proxy that overwrites X-Forwarded-For
 *   student.app.root=                            built frontend to serve at /app/; blank = not served (404)
 *   student.asset.root=                          scene assets to serve at /assets/; blank = not served (404)
 */
@AutoConfiguration(after = PoetryAutoConfiguration.class,
    afterName = "org.mybatis.spring.boot.autoconfigure.MybatisAutoConfiguration")
@ConditionalOnBean({SqlSessionFactory.class, PoetryCatalog.class})
@ConditionalOnProperty(prefix = "student", name = "enabled", havingValue = "true")
public class StudentAutoConfiguration {

    @Bean
    public MapperFactoryBean<StudentContentMapper> studentContentMapper(SqlSessionFactory factory) {
        MapperFactoryBean<StudentContentMapper> bean = new MapperFactoryBean<>(StudentContentMapper.class);
        bean.setSqlSessionFactory(factory);
        return bean;
    }

    @Bean
    public MapperFactoryBean<StudentDeviceMapper> studentDeviceMapper(SqlSessionFactory factory) {
        MapperFactoryBean<StudentDeviceMapper> bean = new MapperFactoryBean<>(StudentDeviceMapper.class);
        bean.setSqlSessionFactory(factory);
        return bean;
    }

    @Bean
    public BundleStore studentBundleStore(@Value("${student.bundle.root:}") String root, ObjectMapper json) {
        return new BundleStore(root, json);
    }

    @Bean
    public ContentService studentContentService(PoetryCatalog catalog, StudentContentMapper mapper, BundleStore store) {
        return new ContentService(catalog, mapper, store);
    }

    @Bean
    public Config studentConfig(@Value("${student.assetBase:}") String assetBase,
                                @Value("${student.dataNoticeVersion:2026-11-06}") String notice,
                                @Value("${student.agentEnabled:false}") boolean agentEnabled) {
        return new Config(assetBase, 1, notice, List.of("PRIMARY", "JUNIOR"), agentEnabled);
    }

    @Bean
    public StudentContentController studentContentController(ContentService content, Config config) {
        return new StudentContentController(content, config);
    }

    /** Device writes need a transaction manager; without one the whole write side stays unassembled. */
    @Bean
    @ConditionalOnBean(PlatformTransactionManager.class)
    public DeviceService studentDeviceService(StudentDeviceMapper mapper,
            @Value("${student.dataNoticeVersion:2026-11-06}") String notice) {
        return new DeviceService(mapper, notice);
    }

    @Bean
    @ConditionalOnBean(DeviceService.class)
    public StudentDeviceController studentDeviceController(DeviceService devices,
            @Value("${student.internalToken:}") String internalToken) {
        return new StudentDeviceController(devices, internalToken);
    }

    /**
     * Static hosting for the frontend and its assets. Spring Boot applies every {@code WebMvcConfigurer} bean in
     * the context, so a host that has its own MVC config simply gets these two handlers added to it.
     * Both roots default to blank: unconfigured means 404, never "serve whatever is in the working directory".
     */
    @Bean
    public StudentStaticResources studentStaticResources(@Value("${student.app.root:}") String appRoot,
                                                         @Value("${student.asset.root:}") String assetRoot) {
        return new StudentStaticResources(appRoot, assetRoot);
    }

    /** index.html needs a different cache policy from every other file under /app/, so it is a controller. */
    @Bean
    public StudentIndexController studentIndexController(@Value("${student.app.root:}") String appRoot) {
        return new StudentIndexController(appRoot);
    }

    @Bean
    public StudentAdvice studentAdvice() { return new StudentAdvice(); }

    @Bean
    public FilterRegistrationBean<StudentAccessGuard> studentAccessGuard(
            @Value("${student.rateLimitPerMinute:300}") int perMinute,
            @Value("${student.deviceCreatePerMinute:10}") int deviceCreatePerMinute,
            @Value("${student.trustForwardedFor:false}") boolean trustForwardedFor) {
        FilterRegistrationBean<StudentAccessGuard> reg =
            new FilterRegistrationBean<>(new StudentAccessGuard(perMinute, deviceCreatePerMinute, trustForwardedFor));
        reg.addUrlPatterns("/api/student/*");
        reg.setName("studentAccessGuard");
        reg.setOrder(2);
        return reg;
    }

    @Bean
    public FilterRegistrationBean<StudentCorsFilter> studentCors(
            @Value("${student.cors.allowedOrigins:}") String configured) {
        Set<String> allowed = new LinkedHashSet<>(StudentCorsFilter.SHELL_DEFAULTS);
        Arrays.stream(configured.split(",")).map(String::trim).filter(s -> !s.isEmpty()).forEach(allowed::add);
        FilterRegistrationBean<StudentCorsFilter> reg = new FilterRegistrationBean<>(new StudentCorsFilter(allowed));
        reg.addUrlPatterns("/api/student/*");
        reg.setName("studentCors");
        reg.setOrder(1);
        return reg;
    }
}
