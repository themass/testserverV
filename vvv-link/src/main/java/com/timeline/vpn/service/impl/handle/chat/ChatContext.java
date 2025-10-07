package com.timeline.vpn.service.impl.handle.chat;

import com.timeline.vpn.common.annotation.MethodTimed;
import com.timeline.vpn.model.form.ChatContentForm;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.Choice;
import com.timeline.vpn.service.strategy.BaseSingleServiceContext;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.util.Random;

/**
 * @author gqli
 * @version V1.0
 * @date 2018年7月31日 下午5:01:15
 */
@Component
@MethodTimed
public class ChatContext extends BaseSingleServiceContext<Integer, BaseChatHandle> {
    private static final Logger LOGGER =
            LoggerFactory.getLogger(ChatContext.class);

    public Choice chatWithGpt(BaseQuery baseQuery, ChatContentForm chatContentForm) throws Exception {
        Random random = new Random();

        for(int i =0; i<3;i++) {
            BaseChatHandle handle =null;
            int r = 0;
            try {
                r = random.nextInt(11);
                LOGGER.info("生成的数字 ："+r);
                handle = getService(r);
                return handle.chatWithGptBase(baseQuery, chatContentForm);
            } catch (Exception e) {
                LOGGER.error("大语言模型调用失败-count:"+i+";rondem:"+r+"; handle:"+handle, e);
            }
        }
        throw new RuntimeException("重试3次失败");
    }
}

