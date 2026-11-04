package com.timeline.vpn.web.controller.api;

import com.timeline.vpn.model.vo.JsonResult;
import com.timeline.vpn.model.vo.MyIpVo;
import com.timeline.vpn.util.UrlUtil;
import com.timeline.vpn.web.controller.BaseController;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;

/** 网络体检：返回服务端看到的请求 IP。App 的请求经过 VPN 时，这就是节点出口。 */
@RestController
@RequestMapping("/api/net")
public class NetController extends BaseController {

    @RequestMapping(value = "/ip.json", method = {RequestMethod.GET, RequestMethod.POST})
    public JsonResult ip(HttpServletRequest request) {
        return new JsonResult(new MyIpVo(UrlUtil.getIpAddr(request)));
    }
}
