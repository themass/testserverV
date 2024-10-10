package com.timeline.vpn.service.impl.handle.chat;

import com.alibaba.dashscope.aigc.generation.Generation;
import com.alibaba.dashscope.aigc.generation.GenerationOutput;
import com.alibaba.dashscope.aigc.generation.GenerationParam;
import com.alibaba.dashscope.aigc.generation.GenerationResult;
import com.alibaba.dashscope.common.Message;
import com.alibaba.dashscope.common.Role;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.Choice;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.pool2.impl.GenericObjectPool;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;
import java.util.Arrays;


/**
 * @author gqli
 * @version V1.0
 * @Description: 5-10; vip3 15天
 * @date 2018年7月31日 下午4:25:18
 */
@Slf4j
@Component
public class ChatQwenHandler extends BaseChatHandleProxy {
    public static String key = "sk";
    public static String key2 = "-2a8e45f1b5c8";
    public static String key1 = "4f04a9b10d85e81633bf";
    @Resource(name = "aliLlmGenericObjectPool")
    private GenericObjectPool<Generation> aliLlmGenericObjectPool;
    @Override
    public boolean support(Integer t) {
        return  t > 8;
    }

    public Choice chatWithGpt(BaseQuery baseQuery, String prompt) throws Exception {
        Message systemMsg = Message.builder()
                .role(Role.SYSTEM.getValue())
                .content("你是一个智能AI小助手")
                .build();
        Message userMsg = Message.builder()
                .role(Role.USER.getValue())
                .content(prompt)
                .build();
        GenerationParam param = GenerationParam.builder()
                .apiKey(key + key2 + key1)
                .model("qwen-plus")
                .messages(Arrays.asList(systemMsg, userMsg))
                .resultFormat(GenerationParam.ResultFormat.MESSAGE)
                .build();
        Generation gen = null;
        try {
            gen = aliLlmGenericObjectPool.borrowObject();
            GenerationResult result = gen.call(param);
            for (GenerationOutput.Choice choices : result.getOutput().getChoices()) {
                Choice choice = new Choice();
                com.timeline.vpn.model.vo.Message message = new com.timeline.vpn.model.vo.Message();
                message.setContent(choices.getMessage().getContent().toString().replace("user", "").replace("assistant", "").replace("[]:", ""));
                message.setRole(choices.getMessage().getRole().toString());
                choice.setMessage(message);
                return choice;
            }
        } catch (Exception e) {
            log.error("阿里大模型调用失败", e);
        } finally {
            if (gen != null) {
                aliLlmGenericObjectPool.returnObject(gen);
            }
        }
        return null;
    }

}

