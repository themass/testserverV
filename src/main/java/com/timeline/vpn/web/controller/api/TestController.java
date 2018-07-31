package com.timeline.vpn.web.controller.api;

import java.util.HashMap;
import java.util.Map;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

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
@RequestMapping("/api/test")
public class TestController extends BaseController {
    @RequestMapping(value = "/test.json", method = RequestMethod.GET)
    public JsonResult recommendList(@UserInfo BaseQuery baseQuery) {
        Map<String, String> map = new HashMap<>();
        map.put("key", "test");
        return new JsonResult(map);
    }
}

