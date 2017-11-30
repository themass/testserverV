package com.timeline.vpn.web.controller.api;

import javax.validation.Valid;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;

import com.timeline.vpn.model.form.PageBaseForm;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.JsonResult;
import com.timeline.vpn.web.common.resolver.UserInfo;
import com.timeline.vpn.web.controller.BaseController;

/**
 * @author gqli
 * @date 2015年7月24日 下午3:16:25
 * @version V1.0
 */
@Controller
@RequestMapping("/api/video")
public class VideoController extends BaseController {
    @RequestMapping(value = "/items.json", method = RequestMethod.GET)
    public JsonResult items(@UserInfo BaseQuery baseQuery,
            @ModelAttribute @Valid PageBaseForm form) {
        return new JsonResult(dataService.getVideoPage(baseQuery, form.toParam()));
    }
    @RequestMapping(value = "/channel.json", method = RequestMethod.GET)
    public JsonResult channel(@UserInfo BaseQuery baseQuery) {
        return new JsonResult(dataService.getVideoChannel(baseQuery));
    }
    @RequestMapping(value = "/channel/items.json", method = RequestMethod.GET)
    public JsonResult channelItems(@UserInfo BaseQuery baseQuery,
            @ModelAttribute @Valid PageBaseForm form,@RequestParam String channel) {
        return new JsonResult(dataService.getVideoChannelItemsPage(baseQuery, form.toParam(),channel));
    } @RequestMapping(value = "/user.json", method = RequestMethod.GET)
    public JsonResult user(@UserInfo BaseQuery baseQuery,
            @ModelAttribute @Valid PageBaseForm form) {
        return new JsonResult(dataService.getVideoUserPage(baseQuery, form.toParam()));
    } @RequestMapping(value = "/user/items.json", method = RequestMethod.GET)
    public JsonResult userItems(@UserInfo BaseQuery baseQuery,
            @ModelAttribute @Valid PageBaseForm form,@RequestParam String userId) {
        return new JsonResult(dataService.getVideoUserItemsPage(baseQuery, form.toParam(),userId));
    }
}

