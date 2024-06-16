package com.timeline.vpn.common.config;

import com.alibaba.dashscope.audio.tts.SpeechSynthesizer;
import org.apache.commons.pool2.BasePooledObjectFactory;
import org.apache.commons.pool2.PooledObject;
import org.apache.commons.pool2.impl.DefaultPooledObject;

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