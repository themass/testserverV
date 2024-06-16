package com.timeline.vpn.common.config;

import com.alibaba.dashscope.audio.tts.SpeechSynthesizer;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.pool2.BasePooledObjectFactory;
import org.apache.commons.pool2.PooledObject;
import org.apache.commons.pool2.impl.DefaultPooledObject;
import org.apache.commons.pool2.impl.GenericObjectPool;
import org.apache.commons.pool2.impl.GenericObjectPoolConfig;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Slf4j
@Configuration
public class AliClonePoolConfig {
    @Bean("aliCloneGenericObjectPool")
    public GenericObjectPool<SpeechSynthesizer> aliCloneGenericObjectPool() {
        PooledDashScopeObjectFactory pooledDashScopeObjectFactory =
                new PooledDashScopeObjectFactory();
        GenericObjectPoolConfig<SpeechSynthesizer> config = new GenericObjectPoolConfig<>();
        config.setMaxTotal(150);
        config.setMinIdle(100);
        config.setTestOnBorrow(true);
        config.setBlockWhenExhausted(true);
        config.setJmxNamePrefix("aliconle-tts");
        config.setJmxEnabled(false);
        GenericObjectPool<SpeechSynthesizer> aliCloneGenericObjectPool = new GenericObjectPool<>(pooledDashScopeObjectFactory, config);
        return aliCloneGenericObjectPool;
    }

    public class PooledDashScopeObjectFactory extends BasePooledObjectFactory<SpeechSynthesizer> {
        @Override
        public SpeechSynthesizer create() throws Exception {
            return new SpeechSynthesizer();
        }

        @Override
        public PooledObject<SpeechSynthesizer> wrap(SpeechSynthesizer obj) {
            return new DefaultPooledObject<>(obj);
        }
    }
}
