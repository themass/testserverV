package com.timeline.vpn.service.impl.handle.picversion;

import com.timeline.vpn.common.annotation.MethodTimed;
import com.timeline.vpn.model.chat.ChatPicMessages;
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
@MethodTimed
public class VisionMyGpt4Handler extends BaseVisionHandleProxy {
    public static String url = "https://api.openai.com/v1/chat/completions";
    public static String modle = "gpt-4o-mini";
    //    public static String url = "http://openapi2.ok123find.top";
    public static String apiKey = "Bearer sk";
    public static String apiKey1 = "3TiIs5LyxJVCIU2wr";
    public static String apiKey2 = "-IA5tH6GqUNfVxUJb0gyQT3BlbkFJVWa";
    ;

    @Override
    public boolean support(Integer t) {
        return false;
    }

    public Choice chatWithGpt(BaseQuery baseQuery, ChatContentForm chatContentForm, MultipartFile file, String text) throws Exception {
        log.info("VisionMyGpt4Handler");
        ChatPicMessages chatPicMessages = getChatPicMessages(file, modle,  text);
        Choice choice = process(chatPicMessages, url, apiKey + apiKey2 + apiKey1);
        choice.setId(chatContentForm.getId());
        return choice;
    }

    @Override
    public boolean isDefault() {
        return true;
    }
}

