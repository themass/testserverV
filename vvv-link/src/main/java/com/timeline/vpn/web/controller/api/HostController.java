package com.timeline.vpn.web.controller.api;

import com.timeline.vpn.Constant;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.JsonResult;
import com.timeline.vpn.web.common.resolver.UserInfo;
import com.timeline.vpn.web.controller.BaseController;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Arrays;
import java.util.List;

/**
 * @author gqli
 * @date 2015年7月24日 下午3:16:25
 * @version V1.0
 */
@RestController
@RequestMapping("/api/host")
public class HostController extends BaseController {
    
    //获取具体主机信息
    @RequestMapping(value = "/server/cache.json", method = {RequestMethod.POST,RequestMethod.GET})
    public JsonResult serverListCache(@UserInfo BaseQuery baseQuery,
            @RequestParam(defaultValue = "0",name = "id") int id) {
        return new JsonResult(hostService.getHostInfoById(baseQuery, id));
    }
    
    //获取具体的vpn链接线路
    @RequestMapping(value = "/server/list.json", method = {RequestMethod.POST,RequestMethod.GET})
    public JsonResult serverList(@UserInfo BaseQuery baseQuery,
            @RequestParam(defaultValue = "0",name = "location") int location) {
        return new JsonResult(hostService.getHostInfoV2(baseQuery, location));
    }
        //单个item页，下拉刷新
    @RequestMapping(value = "/server/location/cache.json", method = {RequestMethod.POST,RequestMethod.GET})
    public JsonResult locationListCache(@UserInfo BaseQuery baseQuery,@RequestParam(required=false,name="type")Integer type) {
        return new JsonResult(hostService.getAllLocationCacheV2(baseQuery,type));
    }
       // page页，全部缓存数据
    @RequestMapping(value = "/server/location/vip/cache.json", method = {RequestMethod.POST,RequestMethod.GET})
    public JsonResult locationListVipCache(@UserInfo BaseQuery baseQuery) {
        return new JsonResult(hostService.getAllLocationVipCacheV2(baseQuery));
    }

    @RequestMapping(value = "/server/dns.json", method = {RequestMethod.POST,RequestMethod.GET})
    public JsonResult dns(@UserInfo BaseQuery baseQuery,@RequestParam(name = "id") String d) {
        List<String> list = Arrays.asList(d.split(Constant.comma));
        return new JsonResult(hostService.getDnsResver(baseQuery, list));
    }
}

