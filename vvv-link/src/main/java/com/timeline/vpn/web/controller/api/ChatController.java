package com.timeline.vpn.web.controller.api;

import com.timeline.vpn.model.form.ChatContentForm;
import com.timeline.vpn.model.form.PageBaseForm;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.JsonResult;
import com.timeline.vpn.util.JsonUtil;
import com.timeline.vpn.web.common.resolver.UserInfo;
import com.timeline.vpn.web.controller.BaseController;
import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;


/**
 * @author gqli
 * @date 2015年7月24日 下午3:16:25
 * @version V1.0
 */
@RestController
@RequestMapping("/api/chat")
@Slf4j
public class ChatController extends BaseController {
    @PostMapping(value = "/nostream.json")
    public JsonResult nostream(@UserInfo(required = true) BaseQuery baseQuery,
                               @ModelAttribute @Valid PageBaseForm form, @ModelAttribute @Valid ChatContentForm chatContent) throws Exception {
       log.info(JsonUtil.writeValueAsString(chatContent));
        return new JsonResult(chatService.chatWithGpt(baseQuery, chatContent));
    }
    /**
     * 流式对话。响应不走 JsonResult 的 AES 封装（SseEmitter 返回类型绕过了 Jackson 的
     * ResponseBody 序列化），所以这里的 data: 帧是明文 JSON（见 StreamChunk）。
     * 只有部分模型接了流式（BaseChatHandleProxy#supportsStream），服务端会自动只在
     * 这些模型里选，不会路由到还没支持流式的实现上。
     */
    @PostMapping(value = "/stream.json")
    public SseEmitter stream(@UserInfo(required = true) BaseQuery baseQuery,
                              @ModelAttribute @Valid PageBaseForm form, @ModelAttribute @Valid ChatContentForm chatContent) {
        log.info("stream " + JsonUtil.writeValueAsString(chatContent));
        return chatService.chatWithGptStream(baseQuery, chatContent);
    }
    @PostMapping(value = "/transword.json")
    public JsonResult transword(@UserInfo(required = true) BaseQuery baseQuery,
                               @ModelAttribute @Valid PageBaseForm form, @ModelAttribute @Valid ChatContentForm chatContent) throws Exception {
        return new JsonResult(chatService.chatWithGpt(baseQuery, chatContent));
    }
    @RequestMapping(value = "/sessions.json", method = {RequestMethod.POST,RequestMethod.GET})
    public JsonResult sessions(@UserInfo BaseQuery baseQuery) {
        return new JsonResult(chatService.sessions(baseQuery));
    }
}

