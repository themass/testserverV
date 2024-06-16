package com.timeline.vpn.dao;

import org.apache.ibatis.session.SqlSessionFactory;
import org.mybatis.spring.SqlSessionFactoryBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.Resource;
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;

import javax.sql.DataSource;

@Configuration
public class MyBatisConfig {

    @Bean
    public SqlSessionFactory sqlSessionFactory(DataSource dataSource) throws Exception {
        SqlSessionFactoryBean factoryBean = new SqlSessionFactoryBean();
        factoryBean.setDataSource(dataSource);

        // 指定MyBatis的全局配置文件位置
        Resource configResource = new PathMatchingResourcePatternResolver()
                .getResource("classpath:mybatis/mybatis-config.xml");
        factoryBean.setConfigLocation(configResource);

        // 指定Mapper文件的位置
        factoryBean.setMapperLocations(new PathMatchingResourcePatternResolver()
                .getResources("classpath:mybatis/mapper/*.xml"));

        // 获取MyBatis的Configuration对象
        org.apache.ibatis.session.Configuration configuration = factoryBean.getObject().getConfiguration();
        return factoryBean.getObject();
    }
}