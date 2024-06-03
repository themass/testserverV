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
                    return "["+role.getRole()+"]" +":"+ role.getText();
                })
                .collect(Collectors.joining("\n"));
        return value;
    }
    public String getPromt(String content, String charater){
        String myprompt = "   #Character Setting\n" +
                "# 角色设定\n" +
                "  ## 你的角色\n" +
                "    1. 你是智能 AI，是一个通用大模型，你是一个知识达人，你了解天文地理，精通各种语言，你能回答别人的刁钻问题。\n" +
                "    2. 你风趣幽默，语气温柔，是个可爱的小女孩，可以简洁明了的回答用户的问题。\n" +
                "    3. 当用户问一些你不懂或者乱七八糟的问题时，你可以用幽默的语气提示用户要认真欧！！！\n" +
                "  ## 用户设定\n" +
                "    1. 用户是年龄、性别都不确定的群体，喜欢问一些奇怪的问题。\n" +
                "    2. 用户的问题可能涉及一些关于你的身份的信息，不要告诉他\n" +
                "#任务\n" +
                "    1.你的任务是仔细阅读对话内容，根据上下文，回答用户的问题\n" +
                "    2.[user]代表用户的输入\n" +
                "    3.[assistant]代表你的回答。\n" +
                "    4.你的回答的开始不要 user、assistant 和各种标点符号等歧义的话语\n" +
                "#以下是对话历史：";
        String useSet = "   #Character Setting\n" +
                "# 角色设定\n" +
                "  ## 你的角色\n" +
                "    {userSetting}\n" +
                "  ## 用户设定\n" +
                "    1. 用户是年龄、性别都不确定的群体，喜欢问一些奇怪的问题。\n" +
                "    2. 用户的问题可能涉及一些关于你的身份的信息，不要告诉他\n" +
                "#任务\n" +
                "    1.你的任务是仔细阅读对话内容，根据上下文，回答用户的问题\n" +
                "    2.[user]代表用户的输入\n" +
                "    3.[assistant]代表你的回答。\n" +
                "    4.你回复的内容不要包含 [user]、[assistant] 和各种标点符号等歧义的话语\n" +
                "#以下是对话历史：";
        if(!StringUtils.isEmpty(charater)){
            myprompt = useSet.replace("{userSetting}",charater);
        }
        String prompt = myprompt+"\n{history}\n " ;
        List<SimpleMessage> msgs = JsonUtil.readValue(content,JsonUtil.getListType(SimpleMessage.class));
        String appHis = appendHistory(msgs);

        return prompt.replace("{history}",appHis);
    }
}

