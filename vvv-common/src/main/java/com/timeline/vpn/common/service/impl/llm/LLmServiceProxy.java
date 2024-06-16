package com.timeline.vpn.common.service.impl.llm;

import com.timeline.vpn.common.annotation.MethodTimed;
import com.timeline.vpn.common.config.LlmConfig;
import com.timeline.vpn.common.service.LLMService;
import com.timeline.vpn.common.service.impl.llm.dto.ChatResponse;
import com.timeline.vpn.common.utils.JacksonJsonUtil;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.StringUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Primary;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.function.Function;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * 大语言模型调用
 *
 * @author linmingyang
 */
@Slf4j
@Primary
@Component
@MethodTimed
public class LLmServiceProxy implements LLMService {

    @Autowired
    private Map<String, LLMService> llmServices;
    @Resource(name = "llmApply")
    private ExecutorService llmApply;
    @Autowired
    private LlmConfig llmConfig;
    private static String endRegex = ".*[.;:!?。；：！？:]$";
    private static String regex = "[a-zA-Z]";
    private static Pattern stopRegex = Pattern.compile(regex);
    private static Pattern pattern = Pattern.compile("([^.?!;。？！；:]+[.?!;。？！；:]?)");

    private static List<String> stopStream = Arrays.asList("finishPhase", "finishEpoch");
    private static String startWord = "teacherResponse";

    public ChatResponse chat(String systemMessage, String userMessage, Function<String, String> function) {
        try {
            return getTarget().chat(systemMessage, userMessage, function);
        } catch (Exception e) {
            log.error("llm 大模型主失败，切换从", e);
            return getBackTarget().chat(systemMessage, userMessage, function);
        }
    }

    public ChatResponse chatStream(String systemMessage, String userMessage, Function<String, String> function) {
        try {
            return chatStream(getTarget(), systemMessage, userMessage, function);
        } catch (Exception e) {
            log.error("llm 大模型主失败，切换从", e);
            return chatStream(getBackTarget(), systemMessage, userMessage, function);
        }
    }

    private ChatResponse chatStream(LLMService llmService, String systemMessage, String userMessage, Function<String, String> function) {

        StringBuilder sb = new StringBuilder();
        AtomicBoolean isFinish = new AtomicBoolean(false);
        AtomicBoolean isStart = new AtomicBoolean(false);
        log.info("流式请求开始:{}", llmService.getClass().getName());
        ChatResponse response = llmService.chatStream(systemMessage, userMessage, new Function<String, String>() {
            @Override
            public String apply(String content) {
                // 字符串不是空并且没有结束，解析字符串
                long start = System.currentTimeMillis();
                if (!StringUtils.isBlank(content) && !isFinish.get()) {
                    sb.append(content);//缓存字符串
                    //如果没有遇到 内容开始标志
                    // 检测标志，设置标志，截取字符串
                    if (!isStart.get()) {
                        if (sb.toString().contains(startWord)) { // 如果开始了，设置标志位，把teacherResponse 字符串之前的字符全部去掉
                            isStart.set(true);
                            sb.delete(0, sb.indexOf(startWord) + startWord.length());
                        } else {
                            return content; // 没有开始，也没遇到开始标志，不处理
                        }
                    }
                    //如果收到的字符串有结束标志，设置标志位
                    if (isFinish(sb)) {
                        isFinish.set(true);
                    }

                    // 分割字符串，按标点
                    //出最后一个句子，其他发送出去
                    //为什么最后一个句子不处理？ 因为可能没有结束，还需要放回缓冲区
                    List<String> list = splitSentences(sb.toString());
                    if (list.size() > 1) {
                        String result = String.join(" ", list.subList(0, list.size() - 1));
                        log.info("流式回答： " + result);
                        //TODO : 异步虽然快，有可能会乱序，比如tts的时候，后面的消息先完成tts
                        llmApply.submit(() -> {
                            function.apply(result);
                        });

                    }
                    sb.setLength(0);
                    //处理字后一个句子，如果是标点结尾就发送，非标点结尾加入缓冲区
                    if (list.size() >= 1) {
                        String last = list.get(list.size() - 1);
                        if (last.matches(endRegex)) {
                            log.info("流式回答last： " + last);
                            llmApply.submit(() -> {
                                function.apply(last);
                            });
                        } else {
                            sb.append(last);
                        }
                    }
                }
                long end = System.currentTimeMillis();
                long cost = end-start;
                if(cost > 5) {
                    log.info("大模型流式解析耗时：llm={}, cost={}", llmConfig.getActive(), end - start);
                }
                return content;
            }
        });
        log.info("流式请求结束 :{}", JacksonJsonUtil.toJsonStr(response));
        return response;
    }

    @Override
    public String genContent(String systemMessage, String userMessage) {
        try {
            return getTarget().genContent(systemMessage, userMessage);
        } catch (Exception e) {
            log.error("llm 大模型主失败，切换从", e);
            return getBackTarget().genContent(systemMessage, userMessage);
        }
    }

    private LLMService getTarget() {
        return llmServices.get(llmConfig.getActive());
    }

    private LLMService getBackTarget() {
        return llmServices.get(llmConfig.getBackUp());
    }

    private static boolean isFinish(StringBuilder sb) {
        for (String stopWord : stopStream) {
            if (sb.toString().contains(stopWord)) {
                sb.delete(sb.indexOf(stopWord), sb.length());
                return true;
            }
        }
        return false;
    }

    public static List<String> splitSentences(String text) {
//        log.info("-------"+text);
        List<String> sentences = new ArrayList<>();
        // 使用正则表达式匹配句子结束的标点符号，并在其之后断句
        Matcher matcher = pattern.matcher(text);

        while (matcher.find()) {
            // 添加匹配到的句子到列表中，包括末尾的标点符号（如果有）
            String sentence = matcher.group(1);
            // 确保空字符串不被添加到结果列表中
            // 开始、结尾、标点不加入列表
            boolean isNiceWord = true;
            for (String stopWord : stopStream) {
                if (sentence.contains(stopWord)) {
                    isNiceWord = false;
                    break;
                }
            }
            if (useContent(sentence) && isNiceWord) {
                sentences.add(sentence.replace("\"", "").replace("\\", ""));
            }
        }
        return sentences;
    }

    private static boolean useContent(String sentence) {
        return !StringUtils.isBlank(sentence) && stopRegex.matcher(sentence).find();
    }

}
