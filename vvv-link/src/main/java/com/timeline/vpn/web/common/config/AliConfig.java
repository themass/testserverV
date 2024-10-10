package com.timeline.vpn.web.common.config;

import com.alibaba.dashscope.aigc.generation.Generation;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.pool2.BasePooledObjectFactory;
import org.apache.commons.pool2.PooledObject;
import org.apache.commons.pool2.impl.DefaultPooledObject;
import org.apache.commons.pool2.impl.GenericObjectPool;
import org.apache.commons.pool2.impl.GenericObjectPoolConfig;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * @Author： liguoqing
 * @Date： 2024/10/10 11:55
 * @Describe：
 */
@Slf4j
@Configuration
public class AliConfig {
    @Bean("aliLlmGenericObjectPool")
    public GenericObjectPool<Generation> aliLlmGenericObjectPool() {
        PooledDashScopeLlmObjectFactory pooledDashScopeObjectFactory =
                new PooledDashScopeLlmObjectFactory();
        GenericObjectPoolConfig<Generation> config = new GenericObjectPoolConfig<>();
        config.setMaxTotal(150);
        config.setMinIdle(100);
        config.setTestOnBorrow(true);
        config.setBlockWhenExhausted(true);
        config.setJmxNamePrefix("aliconle-tts");
        config.setJmxEnabled(false);
        GenericObjectPool<Generation> aliCloneGenericObjectPool = new GenericObjectPool<>(pooledDashScopeObjectFactory, config);
        return aliCloneGenericObjectPool;
    }

    public class PooledDashScopeLlmObjectFactory extends BasePooledObjectFactory<Generation> {

        @Override
        public Generation create() throws Exception {
            return new Generation();
        }

        @Override
        public PooledObject<Generation> wrap(Generation obj) {
            return new DefaultPooledObject<>(obj);
        }
    }
}
