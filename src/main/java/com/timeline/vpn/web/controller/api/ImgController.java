package com.timeline.vpn.web.controller.api;

import javax.validation.Valid;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;

import com.timeline.vpn.model.form.ChannelItemsForm;
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
@RequestMapping("/api/img")
public class ImgController extends BaseController {
    @RequestMapping(value = "/channle.json", method = RequestMethod.GET)
    public JsonResult channle(@UserInfo BaseQuery baseQuery,
            @ModelAttribute @Valid PageBaseForm form) {
        return new JsonResult(dataService.getAllImgChannel(baseQuery, form.toParam()));
    }
    @RequestMapping(value = "/items.json", method = RequestMethod.GET)
    public JsonResult items(@UserInfo BaseQuery baseQuery,
            @ModelAttribute @Valid ChannelItemsForm form) {
        return new JsonResult(dataService.getImgItems(baseQuery, form.toParam(),form.getChannel()));
    }
    @RequestMapping(value = "/item.json", method = RequestMethod.GET)
    public JsonResult items(@UserInfo BaseQuery baseQuery,@RequestParam String itemUrl) {
        return new JsonResult(dataService.getImgItem(baseQuery, itemUrl));
    }
    
}

