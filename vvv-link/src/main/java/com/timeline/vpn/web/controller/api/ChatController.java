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
 * 对话接口。历史由服务端保存：客户端只发 sessionId + 当轮 text，历史不再上传。
 * 设计见 docs/chat-history-server.md。
 *
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
        log.info("nostream " + JsonUtil.writeValueAsString(chatContent));
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

    // ---------------- 会话 ----------------

    @RequestMapping(value = "/sessions.json", method = {RequestMethod.POST, RequestMethod.GET})
    public JsonResult sessions(@UserInfo(required = true) BaseQuery baseQuery) {
        return new JsonResult(chatService.sessions(baseQuery));
    }

    @PostMapping(value = "/session/create.json")
    public JsonResult createSession(@UserInfo(required = true) BaseQuery baseQuery,
                                    @RequestParam(value = "name", required = false) String name,
                                    @RequestParam(value = "characterId", required = false) Integer characterId,
                                    @RequestParam(value = "roleId", required = false) String roleId) {
        return new JsonResult(chatService.createSession(baseQuery, name, characterId, roleId));
    }

    @PostMapping(value = "/session/rename.json")
    public JsonResult renameSession(@UserInfo(required = true) BaseQuery baseQuery,
                                    @RequestParam("id") long id,
                                    @RequestParam("name") String name) {
        return new JsonResult(chatService.renameSession(baseQuery, id, name));
    }

    @PostMapping(value = "/session/delete.json")
    public JsonResult deleteSession(@UserInfo(required = true) BaseQuery baseQuery,
                                    @RequestParam("id") long id) {
        chatService.deleteSession(baseQuery, id);
        return new JsonResult();
    }

    // ---------------- 消息 ----------------

    /** 分页拉取会话消息：beforeId 为空取最新一页，返回按时间正序，hasMore 表示还有更早的。 */
    @RequestMapping(value = "/messages.json", method = {RequestMethod.POST, RequestMethod.GET})
    public JsonResult messages(@UserInfo(required = true) BaseQuery baseQuery,
                               @RequestParam("sessionId") long sessionId,
                               @RequestParam(value = "beforeId", required = false) Long beforeId,
                               @RequestParam(value = "limit", defaultValue = "30") int limit) {
        return new JsonResult(chatService.messages(baseQuery, sessionId, beforeId, limit));
    }

    @PostMapping(value = "/message/delete.json")
    public JsonResult deleteMessage(@UserInfo(required = true) BaseQuery baseQuery,
                                    @RequestParam("sessionId") long sessionId,
                                    @RequestParam("id") long id) {
        chatService.deleteMessage(baseQuery, sessionId, id);
        return new JsonResult();
    }

    /** 编辑用户消息：改内容并删掉之后的所有消息，之后调 /stream.json 即可重新回答。 */
    @PostMapping(value = "/message/edit.json")
    public JsonResult editMessage(@UserInfo(required = true) BaseQuery baseQuery,
                                  @RequestParam("sessionId") long sessionId,
                                  @RequestParam("id") long id,
                                  @RequestParam("text") String text) {
        return new JsonResult(chatService.editMessage(baseQuery, sessionId, id, text));
    }
}
