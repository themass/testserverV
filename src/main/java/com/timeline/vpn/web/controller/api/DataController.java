package com.timeline.vpn.web.controller.api;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

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
@RequestMapping("/api/data")
public class DataController extends BaseController {
    @RequestMapping(value = "/recommend.json", method = RequestMethod.GET)
    public JsonResult recommendList(@UserInfo BaseQuery baseQuery) {
        return new JsonResult(dataService.getRecommendList());
    }
    @RequestMapping(value = "/version.json", method = RequestMethod.GET)
    public JsonResult version(@UserInfo BaseQuery baseQuery) {
        return new JsonResult(dataService.getVersion(baseQuery.getAppInfo().getPlatform()));
    }
}

