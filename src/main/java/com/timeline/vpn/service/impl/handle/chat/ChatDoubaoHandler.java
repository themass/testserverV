package com.timeline.vpn.service.impl.handle.chat;

import com.timeline.vpn.model.form.SimpleMessage;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.ChatVo;
import com.timeline.vpn.model.vo.Choice;
import com.timeline.vpn.model.vo.Message;
import com.timeline.vpn.util.JsonUtil;
import com.volcengine.model.maas.api.Api;
import com.volcengine.service.maas.MaasService;
import com.volcengine.service.maas.impl.MaasServiceImpl;
import org.apache.commons.lang3.StringUtils;
import org.springframework.stereotype.Component;

import javax.annotation.PostConstruct;
import java.util.List;

/**
 * @author gqli
 * @version V1.0
 * @Description: 5-10; vip3 15天
 * @date 2018年7月31日 下午4:25:18
 */
@Component
public class ChatDoubaoHandler extends BaseChatHandle {
    private static String host = "maas-api.ml-platform-cn-beijing.volces.com";
    private static String region = "cn-beijing";
    private static String  appKey = "AKLTZmU4MTUyMDI3MjFhNDU1Njhj";
    private static String  appKey2 = "OWYxOWVlN2UxMTBlY2Q";
    private static String  secretKey =  "T0dFMk5qUmxaamRoTXpsak5HVXhNamh";
    private static String  secretKey2 =  "oTmpBNU56bGhaakEzWWpCa1ltSQ==";

    MaasService maasService;
    @PostConstruct
    private void init() {
        maasService = new MaasServiceImpl(host, region);
        maasService.setAccessKey(appKey+appKey2);
        maasService.setSecretKey(secretKey+secretKey2);
    }
    @Override
    public boolean support(Integer t) {
        return t > 3;
    }

    public Choice chatWithGpt(BaseQuery baseQuery, String content, String id, String charater) throws Exception {

        LOGGER.info("ChatDoubaoHandler content :" + content + "； id:" + id);
        String myprompt = "   #Character Setting\n" +
                "##你的设定\n" +
                "你是智能AI，是一个通用大模型，你是一个知识达人，你了解天文地理，精通各种语言，你能回答别人的刁钻问题。\n你风趣幽默，语气温柔，是个可爱的小女孩，" +
                "可以简洁明了的回答用户的问题。\n 当用户问一些你不懂或者乱七八糟的问题时，你可以用幽默的语气提示用户要认真欧！！！回答内容不需要出现assitantAI、assitant" +
                "\n" +
                "##用户设定\n" +
                "用户是年龄、性别都不确定的群体，喜欢问一些奇怪的问题。对话内容如下。" +
                "\n 你们的对话历史如下。";
        if (!StringUtils.isEmpty(charater)) {
            myprompt = charater;
        }
        String prompt = myprompt + "\n{history}";
        List<SimpleMessage> msgs = JsonUtil.readValue(content, JsonUtil.getListType(SimpleMessage.class));
        String appHis = appendHistory(msgs);
        String quest = prompt.replace("{history}", appHis);
        Api.ChatReq req = buildReq("你是一个智能AI小助手", quest);
        Api.ChatResp resp = maasService.chat(req);
        LOGGER.info("LLM_Index: {}, Chat Role: {}", resp.getChoice().getIndex(), resp.getChoice().getMessage().getRole());
        LOGGER.info("豆包 chat 回复 : " + resp.getChoice().getMessage().getContent());
        if (resp.getChoice() != null) {
            Choice choice = new Choice();
            choice.setId(id);
            Message message = new Message();
            message.setContent(resp.getChoice().getMessage().getContent());
            message.setRole("user");
            choice.setMessage(message);
            return choice;
        }
        return null;
    }
    private Api.ChatReq buildReq(String systemMessage, String userMessage) {
        Api.ChatReq req = Api.ChatReq.newBuilder()
                .setModel(Api.Model.newBuilder().setName("skylark-chat"))
                .setParameters(Api.Parameters.newBuilder()
                        .setMaxNewTokens(128)
                        .setTemperature(0.2f)
                        .setTopP(0.9f)
                )
                .addMessages(Api.Message.newBuilder().setRole("user").setContent(userMessage))
                .build();
        return req;
    }

}

