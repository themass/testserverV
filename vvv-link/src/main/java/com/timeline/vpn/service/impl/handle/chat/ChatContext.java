package com.timeline.vpn.service.impl.handle.chat;

import com.timeline.vpn.common.annotation.MethodTimed;
import com.timeline.vpn.model.form.ChatContentForm;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.Choice;
import com.timeline.vpn.service.strategy.BaseSingleServiceContext;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.List;
import java.util.Random;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * @author gqli
 * @version V1.0
 * @date 2018年7月31日 下午5:01:15
 */
@Component
@MethodTimed
public class ChatContext extends BaseSingleServiceContext<Integer, BaseChatHandle> {
    private static final Logger LOGGER =
            LoggerFactory.getLogger(ChatContext.class);

    /** 非流式：随机选 handler，失败最多重试 3 次。历史与用户消息由调用方（ChatServiceImpl）负责。 */
    public Choice chatWithGpt(BaseQuery baseQuery, ChatContentForm chatContentForm) throws Exception {
        Random random = new Random();

        for(int i =0; i<3;i++) {
            BaseChatHandle handle =null;
            int r = 0;
            try {
                r = random.nextInt(11);
                LOGGER.info("生成的数字 ："+r);
                handle = getService(r);
                return handle.chatWithGptBase(baseQuery, chatContentForm);
            } catch (Exception e) {
                LOGGER.error("大语言模型调用失败-count:"+i+";rondem:"+r+"; handle:"+handle, e);
            }
        }
        throw new RuntimeException("重试3次失败");
    }

    // ------------------------------------------------------------------
    // 流式对话。独立于上面 chatWithGpt 的随机重试选择逻辑：
    // 只在"支持流式"的 handler 里选（当前是 Devcto / DevctoDeepSeek / Deepseek 三个
    // OpenAI 协议兼容的，见 BaseChatHandleProxy#supportsStream），不会把请求路由到
    // Qwen（DashScope SDK）/Doubao（火山引擎 SDK）/Gemini 这些还没接流式的实现上。
    //
    // 一旦开始往 emitter 里吐字就不能像非流式那样整包重试了，所以这里不重试：
    // 选 handler 失败直接报错，选中之后的失败交给 emitter.completeWithError。
    // onFinish 在流结束或中途失败/取消时被调用，用来保存助手回复（可能是部分文本）。
    // ------------------------------------------------------------------

    @Autowired(required = false)
    private List<BaseChatHandle> allHandles;

    private static final ExecutorService STREAM_EXECUTOR = Executors.newCachedThreadPool();

    public SseEmitter chatWithGptStream(BaseQuery baseQuery, ChatContentForm chatContentForm, long userMessageId,
                                        Function<String, Long> onFinish) {
        SseEmitter emitter = new SseEmitter(0L); // 不设超时，由我们主动 complete/completeWithError

        List<BaseChatHandleProxy> streamable = allHandles == null ? java.util.Collections.emptyList() :
                allHandles.stream()
                        .filter(h -> h instanceof BaseChatHandleProxy)
                        .map(h -> (BaseChatHandleProxy) h)
                        .filter(BaseChatHandleProxy::supportsStream)
                        .collect(Collectors.toList());

        if (streamable.isEmpty()) {
            emitter.completeWithError(new IllegalStateException("当前没有可用的流式模型"));
            return emitter;
        }

        BaseChatHandleProxy handle = streamable.get(new Random().nextInt(streamable.size()));
        LOGGER.info("流式对话选用 handle：{}", handle.getClass().getName());

        STREAM_EXECUTOR.execute(() -> {
            try {
                handle.chatWithGptStream(baseQuery, chatContentForm, emitter, userMessageId, onFinish);
            } catch (Exception e) {
                LOGGER.error("流式对话失败：handle=" + handle.getClass().getName(), e);
                try {
                    emitter.completeWithError(e);
                } catch (Exception ignore) {
                }
            }
        });

        return emitter;
    }
}
