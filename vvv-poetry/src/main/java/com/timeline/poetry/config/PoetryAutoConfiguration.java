package com.timeline.poetry.config;

import com.timeline.poetry.api.PoetryController;
import com.timeline.poetry.persistence.PoetryMapper;
import com.timeline.poetry.service.PoetryCatalog;
import org.apache.ibatis.session.SqlSessionFactory;
import org.mybatis.spring.mapper.MapperFactoryBean;
import org.springframework.boot.autoconfigure.AutoConfiguration;
import org.springframework.boot.autoconfigure.condition.ConditionalOnBean;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;

/** Opt-in only; shares the host's DataSource/SqlSessionFactory. Does not run migrations. */
@AutoConfiguration(afterName = "org.mybatis.spring.boot.autoconfigure.MybatisAutoConfiguration")
@ConditionalOnBean(SqlSessionFactory.class)
@ConditionalOnProperty(prefix = "poetry", name = "enabled", havingValue = "true")
@Import(PoetryController.class)
public class PoetryAutoConfiguration {
    @Bean
    public MapperFactoryBean<PoetryMapper> poetryMapper(SqlSessionFactory factory) {
        MapperFactoryBean<PoetryMapper> bean = new MapperFactoryBean<>(PoetryMapper.class);
        bean.setSqlSessionFactory(factory);
        return bean;
    }
    @Bean
    public PoetryCatalog poetryCatalog(PoetryMapper mapper) { return new PoetryCatalog(mapper); }
}
