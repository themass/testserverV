package com.timeline.vpn.service.impl.handle.chat;

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
public class ChatContext extends BaseSingleServiceContext<Integer, BaseChatHandle> {
    private static final Logger LOGGER =
            LoggerFactory.getLogger(ChatContext.class);

    public Choice chatWithGpt(BaseQuery baseQuery, String content, String id, String charater) throws Exception {
        Random random = new Random();
        int r = random.nextInt(10);
        return getService(r).chatWithGpt(baseQuery, content, id, charater);
    }
    public Choice transWord(BaseQuery baseQuery, String content, String id) throws Exception {
        Random random = new Random();
        int r = random.nextInt(10);
        return getService(r).transWord(baseQuery, content, id);
    }
}

