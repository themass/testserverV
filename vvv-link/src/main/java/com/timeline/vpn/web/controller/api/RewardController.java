package com.timeline.vpn.web.controller.api;

import com.timeline.vpn.Constant;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.RewardStatusVo;
import com.timeline.vpn.service.RewardService;
import com.timeline.vpn.model.vo.JsonResult;
import com.timeline.vpn.web.common.resolver.UserInfo;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;

/**
 * 激励视频观看券。
 * <p>
 * /admob/ssv 由 AdMob 服务器调用，不以 .json 结尾，因此不会经过 App 校验拦截器；
 * 它只信任带 Google 签名的回调。其余接口需要登录。
 */
@RestController
@RequestMapping("/api/reward")
public class RewardController {

    @Autowired
    private RewardService rewardService;

    @RequestMapping(value = "/admob/ssv", method = RequestMethod.GET)
    public ResponseEntity<String> ssv(HttpServletRequest request) {
        if (!rewardService.onAdmobCallback(request.getQueryString())) {
            return ResponseEntity.status(403).body("INVALID");
        }
        return ResponseEntity.ok("OK");
    }

    @RequestMapping(value = "/status.json", method = {RequestMethod.GET, RequestMethod.POST})
    public JsonResult status(@UserInfo(required = true) BaseQuery baseQuery) {
        return new JsonResult(rewardService.status(baseQuery.getUser().getName()));
    }

    @RequestMapping(value = "/redeem.json", method = RequestMethod.POST)
    public JsonResult redeem(@UserInfo(required = true) BaseQuery baseQuery) {
        RewardStatusVo vo = rewardService.redeem(baseQuery.getUser().getName());
        return new JsonResult(vo);
    }
}
