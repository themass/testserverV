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

