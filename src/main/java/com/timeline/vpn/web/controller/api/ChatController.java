package com.timeline.vpn.web.controller.api;

import com.timeline.vpn.model.form.ChannelItemsForm;
import com.timeline.vpn.model.form.PageBaseForm;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.JsonResult;
import com.timeline.vpn.service.ChatService;
import com.timeline.vpn.web.common.resolver.UserInfo;
import com.timeline.vpn.web.controller.BaseController;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;

import javax.validation.Valid;

/**
 * @author gqli
 * @date 2015年7月24日 下午3:16:25
 * @version V1.0
 */
@Controller
@RequestMapping("/api/chat")
public class ChatController extends BaseController {
    @Autowired
    private ChatService chatService;
    @RequestMapping(value = "/nostream.json", method = {RequestMethod.POST,RequestMethod.GET})
    public JsonResult nostream(@UserInfo BaseQuery baseQuery,
            @ModelAttribute @Valid PageBaseForm form,@RequestParam(required=false) String content) throws Exception {
        return new JsonResult(chatService.chatWithGpt(baseQuery, content));
    }
    @RequestMapping(value = "/stream.json", method = {RequestMethod.POST,RequestMethod.GET})
    public JsonResult stream(@UserInfo BaseQuery baseQuery,
                              @ModelAttribute @Valid PageBaseForm form,@RequestParam(required=false) String channel) {
        return new JsonResult(dataImgService.getAllImgChannel(baseQuery, form.toParam(),channel));
    }
}

