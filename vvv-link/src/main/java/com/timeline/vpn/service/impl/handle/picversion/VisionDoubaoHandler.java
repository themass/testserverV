package com.timeline.vpn.service.impl.handle.picversion;

import com.timeline.vpn.common.annotation.MethodTimed;
import com.timeline.vpn.model.chat.ChatPicMessages;
import com.timeline.vpn.model.form.ChatContentForm;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.Choice;
import com.timeline.vpn.model.vo.Message;
import com.volcengine.ark.runtime.model.completion.chat.ChatCompletionChoice;
import com.volcengine.ark.runtime.model.completion.chat.ChatCompletionRequest;
import com.volcengine.ark.runtime.model.completion.chat.ChatCompletionResult;
import com.volcengine.ark.runtime.service.ArkService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;

import javax.annotation.PostConstruct;
import java.util.List;

/**
 * @author gqli
 * @version V1.0
 * @Description: 5-10; vip3 15天
 * @date 2018年7月31日 下午4:25:18
 */
@Slf4j
@Component
@MethodTimed
public class VisionDoubaoHandler extends BaseVisionHandleProxy {

    public static String model = "doubao-vision-lite-32k-241015";

    private static String  appKey = "49279ceb-e5b0-4409-" ;
    private static String  appKey2 =  "a02a-e74e52782f9a";
    private static String endPoint = "https://ark.cn-beijing.volces.com/api/v3/";
    ArkService service = null;
    @PostConstruct
    private void init() {
        service = ArkService.builder().apiKey(appKey+appKey2).baseUrl(endPoint).build();
    }
    @Override
    public boolean support(Integer t) {
        return t>=3 && t<6;
    }

    public Choice chatWithGpt(BaseQuery baseQuery, ChatContentForm chatContentForm, MultipartFile file, String text) throws Exception {
        log.info("VisionDoubaoHandler");
        ChatPicMessages chatPicMessages = getChatPicMessages(file, model,  text);
        ChatCompletionRequest streamChatCompletionRequest = ChatCompletionRequest.builder()
                .model(model)
                .messages((List)chatPicMessages.getMessages())
                .build();
        ChatCompletionResult chatCompletionResult = service.createChatCompletion(streamChatCompletionRequest);
        for (ChatCompletionChoice choices : chatCompletionResult.getChoices()) {
            Choice choice = new Choice();
            Message message = new Message();
            message.setContent(choices.getMessage().getContent().toString().replace("user","").replace("assistant","").replace("[]:",""));
            message.setRole(choices.getMessage().getRole().toString());
            choice.setMessage(message);
            choice.setProd("ChatDoubaoHandler");
            return choice;

        }
        return null;
    }

    @Override
    public boolean isDefault() {
        return true;
    }
}

