package com.timeline.vpn.web.controller.api;

import com.timeline.vpn.Constant;
import com.timeline.vpn.model.form.WgRegisterForm;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.JsonResult;
import com.timeline.vpn.web.common.resolver.UserInfo;
import com.timeline.vpn.web.controller.BaseController;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.ModelAttribute;
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

    /**
     * WireGuard 设备公钥注册。
     * <p>
     * WireGuard 没有账号密码，服务端必须事先认识客户端公钥才能接受握手。
     * 客户端在建隧道前调用本接口把公钥交上来；重复提交覆盖旧公钥，
     * 以支持重装 App / 重置身份的场景（见 WgDeviceKeyMapper.xml）。
     * <p>
     * 契约详见客户端仓库的 docs/WIREGUARD-BACKEND.md。
     */
    @RequestMapping(value = "/wg/register.json", method = RequestMethod.POST)
    public JsonResult wgRegister(@UserInfo(required = true) BaseQuery baseQuery,
            @Valid @ModelAttribute WgRegisterForm form) {
        // 必须登录：注册一次就会占用一个隧道内地址，并被同步到 WireGuard 服务器，
        // 匿名开放的话任何人都能耗尽地址池，或者给自己开一个能进内网的 peer。
        String clientAddress = wgDeviceKeyService.register(baseQuery, form.getDeviceId(), form.getPublicKey());
        return new JsonResult(new com.timeline.vpn.model.vo.WgRegisterVo(clientAddress));
    }

    /** 注销设备公钥。旧公钥在服务端成为死配置，不影响功能，仅避免垃圾数据累积。 */
    @RequestMapping(value = "/wg/unregister.json", method = RequestMethod.POST)
    public JsonResult wgUnregister(@UserInfo BaseQuery baseQuery,
            @RequestParam(required = false, name = "deviceId") String deviceId) {
        wgDeviceKeyService.unregister(baseQuery, deviceId);
        return Constant.RESULT_SUCCESS;
    }
}

