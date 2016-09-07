package com.timeline.vpn.web.controller.api;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;

import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.JsonResult;
import com.timeline.vpn.web.common.annotation.UserInfo;
import com.timeline.vpn.web.controller.BaseController;

/**
 * @author gqli
 * @date 2015年7月24日 下午3:16:25
 * @version V1.0
 */
@Controller
@RequestMapping("/api/host")
public class HostController extends BaseController {
    @RequestMapping(value = "/server/list.json", method = RequestMethod.GET)
    public JsonResult serverList(@UserInfo BaseQuery baseQuery,
            @RequestParam(defaultValue = "0") int location) {
        return new JsonResult(hostService.getHostInfo(baseQuery, location));
    }

    @RequestMapping(value = "/server/location.json", method = RequestMethod.GET)
    public JsonResult locationList(@UserInfo BaseQuery baseQuery) {
        return new JsonResult(hostService.getAllLocation());
    }
}

