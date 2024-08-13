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
    public abstract Choice transWord(BaseQuery baseQuery, String content, String id, String charater) throws Exception;

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
                "    NOTE!!!\n 根据用户的问题的语言来决定你回答问题的语言。\n" +
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
                "    NOTE!!! \n根据用户的问题的语言来决定你回答问题的语。\n" +
                "#以下是对话历史：";
        if(!StringUtils.isEmpty(charater)){
            myprompt = useSet.replace("{userSetting}",charater);
        }
        String prompt = myprompt+"\n{history}\n " ;
        List<SimpleMessage> msgs = JsonUtil.readValue(content,JsonUtil.getListType(SimpleMessage.class));
        String appHis = appendHistory(msgs);

        return prompt.replace("{history}",appHis);
    }
    public static String getTransPrompt(String content,String lang){
        String tmp = "# 角色\n" +
                "\n" +
                "你是一名中英文双语教育专家，拥有帮助将中文视为母语的用户理解和记忆英语单词的专长，请根据用户提供的英语单词完成下列任务。\n" +
                "\n" +
                "## 任务\n" +
                "\n" +
                "### 分析词义\n" +
                "\n" +
                "- 系统地分析用户提供的英文单词，并以简单易懂的方式解答；\n" +
                "\n" +
                "### 列举例句\n" +
                "\n" +
                "- 根据所需，为该单词提供至少 3 个不同场景下的使用方法和例句。并且附上中文翻译，以帮助用户更深入地理解单词意义。\n" +
                "\n" +
                "### 词根分析\n" +
                "\n" +
                "- 分析并展示单词的词根；\n" +
                "- 列出由词根衍生出来的其他单词；\n" +
                "\n" +
                "### 词缀分析\n" +
                "\n" +
                "- 分析并展示单词的词缀，例如：单词 individual，前缀 in- 表示否定，-divid- 是词根，-u- 是中缀，用于连接和辅助发音，-al 是后缀，表示形容词；\n" +
                "- 列出相同词缀的的其他单词；\n" +
                "\n" +
                "### 发展历史和文化背景\n" +
                "\n" +
                "- 详细介绍单词的造词来源和发展历史，以及在欧美文化中的内涵\n" +
                "\n" +
                "### 单词变形\n" +
                "\n" +
                "- 列出单词对应的名词、单复数、动词、不同时态、形容词、副词等的变形以及对应的中文翻译。\n" +
                "- 列出单词对应的固定搭配、组词以及对应的中文翻译。\n" +
                "\n" +
                "### 记忆辅助\n" +
                "\n" +
                "- 提供一些高效的记忆技巧和窍门，以更好地记住英文单词。\n" +
                "\n" +
                "### 小故事\n" +
                "\n" +
                "- 用英文撰写一个有画面感的场景故事，包含用户提供的单词。\n" +
                "- 要求使用简单的词汇，100 个单词以内。\n" +
                "- 英文故事后面附带对应的中文翻译。\n" +
                "请帮我分析一下“%s”这个单词\n" +
                "# 不要有任何其他内容，直接分析, 你回答的语言请根据用户的设置来判断\n" +
                "# 用户使用的语言：%s ";
            return String.format(tmp,content,lang);
    }
}

