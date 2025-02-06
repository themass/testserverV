package com.timeline.vpn.service.impl.handle.picversion;

import com.timeline.vpn.model.form.ChatContentForm;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.Choice;
import com.timeline.vpn.service.strategy.BaseSingleServiceContext;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;

import java.util.Random;

/**
 * @author gqli
 * @version V1.0
 * @date 2018年7月31日 下午5:01:15
 */
@Component
public class VisionContext extends BaseSingleServiceContext<Integer, BaseVisionHandle> {
    private static final Logger LOGGER =
            LoggerFactory.getLogger(VisionContext.class);

    public Choice chatWithGpt(BaseQuery baseQuery, ChatContentForm chatContentForm, MultipartFile file) {
        Random random = new Random();

        for (int i = 0; i < 3; i++) {
            try {
                int r = random.nextInt(10);
                return getService(r).chatWithGptBase(baseQuery, chatContentForm, file);
            } catch (Exception e) {
                LOGGER.error("大语言模型调用失败-" + i, e);
            }
        }
        throw new RuntimeException("重试3次失败");
    }
}

