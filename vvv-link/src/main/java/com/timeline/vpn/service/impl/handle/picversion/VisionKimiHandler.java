package com.timeline.vpn.service.impl.handle.picversion;

import com.timeline.vpn.model.form.ChatContentForm;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.Choice;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;

/**
 * @author gqli
 * @version V1.0
 * @Description: 5-10; vip3 15天
 * @date 2018年7月31日 下午4:25:18
 */
@Slf4j
@Component
public class VisionKimiHandler extends BaseVisionHandleProxy {
    public static String url = "https://api.moonshot.cn/v1/chat/completions";
    public static String model = "moonshot-v1-8k-vision-preview";
    //    public static String url = "http://openapi2.ok123find.top";
    public static String apiKey = "Bearer sk";
    public static String apiKey1 = "U9YZRxr6hW5vqZfirRiFUlS";
    public static String apiKey2 = "-it18PatDDjE3U68z1qsOrkeyb";
    ;

    @Override
    public boolean support(Integer t) {
        return t < 5;
    }

    public Choice chatWithGpt(BaseQuery baseQuery, ChatContentForm chatContentForm, MultipartFile file, String text) throws Exception {
        Choice choice = process(file, url, model, apiKey + apiKey2 + apiKey1, text);
        choice.setId(chatContentForm.getId());
        log.info("VisionKimiHandler");
        return choice;
    }

    @Override
    public boolean isDefault() {
        return true;
    }
}

