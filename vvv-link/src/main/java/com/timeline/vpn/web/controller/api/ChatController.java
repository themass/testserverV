package com.timeline.vpn.web.controller.api;

import com.timeline.vpn.model.form.ChatContentForm;
import com.timeline.vpn.model.form.PageBaseForm;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.JsonResult;
import com.timeline.vpn.web.common.resolver.UserInfo;
import com.timeline.vpn.web.controller.BaseController;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;


/**
 * @author gqli
 * @date 2015年7月24日 下午3:16:25
 * @version V1.0
 */
@RestController
@RequestMapping("/api/chat")
public class ChatController extends BaseController {
    @PostMapping(value = "/nostream.json")
    public JsonResult nostream(@UserInfo BaseQuery baseQuery,
                               @ModelAttribute @Valid PageBaseForm form, @ModelAttribute @Valid ChatContentForm chatContent) throws Exception {
        return new JsonResult(chatService.chatWithGpt(baseQuery, chatContent.getContent(),chatContent.getId(),chatContent.getCharater()));
    }
    @RequestMapping(value = "/stream.json", method = {RequestMethod.POST,RequestMethod.GET})
    public JsonResult stream(@UserInfo BaseQuery baseQuery,
                              @ModelAttribute @Valid PageBaseForm form,@RequestParam(name="channel",required=false) String channel) {
        return new JsonResult(dataImgService.getAllImgChannel(baseQuery, form.toParam(),channel));
    }
}

