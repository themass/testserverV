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
        return t == 3;
    }

    public Choice chatWithGpt(BaseQuery baseQuery, String content, String id, String charater) throws Exception {

        LOGGER.info("ChatDoubaoHandler content :" + content + "； id:" + id);
        Api.ChatReq req = buildReq("你是一个智能AI小助手", getPromt(content, charater));
        Api.ChatResp resp = maasService.chat(req);
        LOGGER.info("ChatDoubaoHandler 豆包 输入："+getPromt(content, charater));
        LOGGER.info("LLM_Index: {}, Chat Role: {}", resp.getChoice().getIndex(), resp.getChoice().getMessage().getRole());
        LOGGER.info("ChatDoubaoHandler 豆包 chat 回复 : " + resp.getChoice().getMessage().getContent());
        if (resp.getChoice() != null) {
            Choice choice = new Choice();
            choice.setId(id);
            Message message = new Message();
            message.setContent(resp.getChoice().getMessage().getContent().replace("user","").replace("assistant",""));
            message.setRole(resp.getChoice().getMessage().getRole());
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

