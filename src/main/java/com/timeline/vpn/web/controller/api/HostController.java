package com.timeline.vpn.web.controller.api;

import java.util.Arrays;
import java.util.List;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;

import com.timeline.vpn.Constant;
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
@RequestMapping("/api/host")
public class HostController extends BaseController {
    @RequestMapping(value = "/server/list.json", method = RequestMethod.GET)
    public JsonResult serverList(@UserInfo BaseQuery baseQuery,
            @RequestParam(defaultValue = "0") int location) {
        return new JsonResult(hostService.getHostInfo(baseQuery, location));
    }
    @RequestMapping(value = "/server/cache.json", method = RequestMethod.GET)
    public JsonResult serverListCache(@UserInfo BaseQuery baseQuery,
            @RequestParam(defaultValue = "0") int id) {
        return new JsonResult(hostService.getHostInfoById(baseQuery, id));
    }
    @RequestMapping(value = "/server/location.json", method = RequestMethod.GET)
    public JsonResult locationList(@UserInfo BaseQuery baseQuery) {
        return new JsonResult(hostService.getAllLocation());
    }
    @RequestMapping(value = "/server/location/cache.json", method = RequestMethod.GET)
    public JsonResult locationListCache(@UserInfo BaseQuery baseQuery,@RequestParam(required=false)Integer type) {
        return new JsonResult(hostService.getAllLocationCache(type));
    }
    @RequestMapping(value = "/server/location/vip/cache.json", method = RequestMethod.GET)
    public JsonResult locationListVipCache(@UserInfo BaseQuery baseQuery) {
        return new JsonResult(hostService.getAllLocationVipCache(baseQuery));
    }
    @RequestMapping(value = "/server/dns.json", method = RequestMethod.GET)
    public JsonResult dns(@UserInfo BaseQuery baseQuery,@RequestParam String d) {
        List<String> list = Arrays.asList(d.split(Constant.comma));
        return new JsonResult(hostService.getDnsResver(baseQuery, list));
    }
}

