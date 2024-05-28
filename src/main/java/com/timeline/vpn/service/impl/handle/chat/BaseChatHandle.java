package com.timeline.vpn.service.impl.handle.chat;

import com.timeline.vpn.model.form.SimpleMessage;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.Choice;
import com.timeline.vpn.service.strategy.BaseSupportHandle;
import com.timeline.vpn.util.JsonUtil;
import org.apache.commons.lang3.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * @author gqli
 * @version V1.0
 * @date 2017年11月28日 下午6:32:52
 */
public abstract class BaseChatHandle implements BaseSupportHandle<Integer> {
    protected static final Logger LOGGER =
            LoggerFactory.getLogger(BaseChatHandle.class);

    public abstract Choice chatWithGpt(BaseQuery baseQuery, String content, String id, String charater) throws Exception;

    @Override
    public boolean isDefault() {
        return false;
    }

    protected String appendHistory(List<SimpleMessage> history) {
        if (history == null) {
            return "";
        }
        String value = Optional.ofNullable(history).orElse(null).stream().map(role -> {
                    return role.getRole() +":"+ role.getText();
                })
                .collect(Collectors.joining("\n"));
        return value;
    }
    public String getPromt(String content, String charater){
        String myprompt = "   #Character Setting\n" +
                "##你的设定\n" +
                "你是智能AI，是一个通用大模型，你是一个知识达人，你了解天文地理，精通各种语言，你能回答别人的刁钻问题。\n你风趣幽默，语气温柔，是个可爱的小女孩，" +
                "可以简洁明了的回答用户的问题。\n 当用户问一些你不懂或者乱七八糟的问题时，你可以用幽默的语气提示用户要认真欧！！！" +
                "\n" +
                "##用户设定\n" +
                "用户是年龄、性别都不确定的群体，喜欢问一些奇怪的问题。对话内容如下。";
        if(!StringUtils.isEmpty(charater)){
            myprompt = charater;
        }
        String prompt = myprompt+"\n 你们的对话历史如下。\n{history}\n 其中：user代表用户的输入，assistant代表你的回答。\n 你的回答里不要出现user、assistant等歧义的话语" ;
        List<SimpleMessage> msgs = JsonUtil.readValue(content,JsonUtil.getListType(SimpleMessage.class));
        String appHis = appendHistory(msgs);

        return prompt.replace("{history}",appHis);
    }
}

