package com.timeline.vpn.service.impl.handle.asr;

import com.timeline.vpn.common.utils.JacksonJsonUtil;
import com.timeline.vpn.model.form.AsrContentForm;
import com.timeline.vpn.model.form.ChatContentForm;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.AsrResponseVo;
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
public class AsrContext extends BaseSingleServiceContext<Integer, BaseAsrHandle> {
    private static final Logger LOGGER =
            LoggerFactory.getLogger(AsrContext.class);

    public AsrResponseVo asrHandler(BaseQuery baseQuery, AsrContentForm asrContentForm) {
        Random random = new Random();

        for(int i =0; i<3;i++) {
            try {
                int r = random.nextInt(10);
                AsrResponseVo asrResponseVo = getService(r).asrHandlerBase(baseQuery, asrContentForm);
                LOGGER.info("asr识别结果r={} ：{}",r, JacksonJsonUtil.toJsonStr(asrResponseVo));
                return asrResponseVo;
            } catch (Exception e) {
                LOGGER.error("asr 识别错误-"+i, e);
            }
        }
        throw new RuntimeException("asr 识别重试3次失败");
    }
}

