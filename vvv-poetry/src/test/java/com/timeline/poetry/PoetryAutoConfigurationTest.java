package com.timeline.poetry;

import com.timeline.poetry.config.PoetryAutoConfiguration;
import com.timeline.poetry.api.PoetryController;
import org.apache.ibatis.session.SqlSessionFactory;
import org.apache.ibatis.session.SqlSessionFactoryBuilder;
import org.junit.jupiter.api.Test;
import org.springframework.boot.autoconfigure.AutoConfigurations;
import org.springframework.boot.test.context.runner.ApplicationContextRunner;
import static org.assertj.core.api.Assertions.assertThat;

class PoetryAutoConfigurationTest {
    private final ApplicationContextRunner runner = new ApplicationContextRunner()
        .withConfiguration(AutoConfigurations.of(PoetryAutoConfiguration.class));
    private static org.h2.jdbcx.JdbcDataSource ds() {
        org.h2.jdbcx.JdbcDataSource ds = new org.h2.jdbcx.JdbcDataSource();
        ds.setURL("jdbc:h2:mem:autoconfig-" + java.util.UUID.randomUUID() + ";MODE=MySQL");
        return ds;
    }
    private static SqlSessionFactory factory() {
        return factory(ds());
    }
    private static SqlSessionFactory factory(javax.sql.DataSource ds) {
        var configuration = new org.apache.ibatis.session.Configuration(new org.apache.ibatis.mapping.Environment(
            "test", new org.apache.ibatis.transaction.jdbc.JdbcTransactionFactory(), ds));
        return new SqlSessionFactoryBuilder().build(configuration);
    }
    @Test void disabledByDefaultEvenWhenHostFactoryExists() {
        runner.withBean(SqlSessionFactory.class, PoetryAutoConfigurationTest::factory).run(c -> assertThat(c).doesNotHaveBean(PoetryController.class));
    }
    @Test void enabledOnlyWithHostFactory() {
        runner.withPropertyValues("poetry.enabled=true").run(c -> assertThat(c).doesNotHaveBean(PoetryController.class));
        // Since the 2026-11-21 production fix the whole module is class-gated on BOTH
        // SqlSessionFactory and PlatformTransactionManager — a factory alone must skip cleanly,
        // never half-register (that asymmetry is what took the host down).
        runner.withPropertyValues("poetry.enabled=true")
            .withBean(SqlSessionFactory.class, PoetryAutoConfigurationTest::factory)
            .run(c -> { assertThat(c).hasNotFailed(); assertThat(c).doesNotHaveBean(PoetryController.class); });
        org.h2.jdbcx.JdbcDataSource ds = ds();
        runner.withPropertyValues("poetry.enabled=true")
            .withBean(org.h2.jdbcx.JdbcDataSource.class, () -> ds)
            .withBean(SqlSessionFactory.class, () -> factory(ds))
            .withBean(org.springframework.transaction.PlatformTransactionManager.class,
                () -> new org.springframework.jdbc.datasource.DataSourceTransactionManager(ds))
            .withBean(com.fasterxml.jackson.databind.ObjectMapper.class, com.fasterxml.jackson.databind.ObjectMapper::new)
            .run(c -> { assertThat(c).hasNotFailed(); assertThat(c).hasSingleBean(PoetryController.class); });
    }
}
