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
    private static SqlSessionFactory factory() {
        org.h2.jdbcx.JdbcDataSource ds = new org.h2.jdbcx.JdbcDataSource();
        ds.setURL("jdbc:h2:mem:autoconfig;MODE=MySQL");
        var configuration = new org.apache.ibatis.session.Configuration(new org.apache.ibatis.mapping.Environment(
            "test", new org.apache.ibatis.transaction.jdbc.JdbcTransactionFactory(), ds));
        return new SqlSessionFactoryBuilder().build(configuration);
    }
    @Test void disabledByDefaultEvenWhenHostFactoryExists() {
        runner.withBean(SqlSessionFactory.class, PoetryAutoConfigurationTest::factory).run(c -> assertThat(c).doesNotHaveBean(PoetryController.class));
    }
    @Test void enabledOnlyWithHostFactory() {
        runner.withPropertyValues("poetry.enabled=true").run(c -> assertThat(c).doesNotHaveBean(PoetryController.class));
        runner.withPropertyValues("poetry.enabled=true")
            .withBean(SqlSessionFactory.class, PoetryAutoConfigurationTest::factory)
            .run(c -> { assertThat(c).hasNotFailed(); assertThat(c).hasSingleBean(PoetryController.class); });
    }
}
