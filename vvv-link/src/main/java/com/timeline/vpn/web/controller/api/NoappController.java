package com.timeline.vpn.web.controller.api;

import com.timeline.vpn.Constant;
import com.timeline.vpn.exception.TokenException;
import com.timeline.vpn.model.form.WeiXinForm;
import com.timeline.vpn.model.form.YoumiOffadsForm;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.po.PingCheck;
import com.timeline.vpn.model.vo.JsonResult;
import com.timeline.vpn.service.DataService;
import com.timeline.vpn.service.UserService;
import com.timeline.vpn.web.common.resolver.UserInfo;
import com.timeline.vpn.web.controller.BaseController;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.ArrayList;
import java.util.List;

/**
 * @author gqli
 * @date 2015年7月24日 下午3:16:25
 * @version V1.0
 */
@RestController
@RequestMapping("/api/noapp")
public class NoappController extends BaseController {
    @Autowired
    private DataService dataService;
    @Autowired
    private UserService userService;

    @RequestMapping(value = "/repass.json", method = {RequestMethod.POST,RequestMethod.GET})
    public JsonResult delUser(@UserInfo BaseQuery baseQuery,@RequestParam(name="name") String name, @RequestParam(name="pass") String pass) {
        userService.del(baseQuery, name,pass);
        return Constant.RESULT_SUCCESS;
    }

    /**
     * 网页版账号注销（Play 要求提供"不安装 App 也能申请删除"的入口）。
     * <p>
     * 与 {@code /repass.json} 的区别：
     * <ul>
     *   <li>只接受 POST —— 旧接口同时接受 GET，密码会出现在 URL、浏览器历史和服务器访问日志里；</li>
     *   <li>参数名用 name/pwd，与 App 内接口一致，避免两套叫法。</li>
     * </ul>
     * 走 noapp 前缀是刻意的：{@code HostFilter} 对含 "noapp" 的 URI 跳过 App 头校验，
     * 网页端没有 devId / 签名 / 版本号，走普通用户接口会被拦掉。
     */
    @RequestMapping(value = "/delete.json", method = RequestMethod.POST)
    public JsonResult deleteFromWeb(@UserInfo BaseQuery baseQuery,
                                    @RequestParam(name = "name") String name,
                                    @RequestParam(name = "pwd") String pwd) {
        userService.del(baseQuery, name, pwd);
        return Constant.RESULT_SUCCESS;
    }

    @RequestMapping(value = "/collect.json", method = RequestMethod.POST)
    public JsonResult collect(@UserInfo BaseQuery baseQuery,@RequestParam(name="count") Integer count,@RequestParam(name="localhost") String localhost,@RequestParam(required=false,name="ip") String ip) {
        if(count==-1) {
            LOGGER.error("ip 错误了，服务断了，快速处理吧"+localhost+"---"+ip);
            dataService.sendMsg("ip 错误了，服务断了，快速处理吧"+localhost+"---"+ip);
        }
        return Constant.RESULT_SUCCESS;
    }
    /**
     * WireGuard 服务器同步 peer 列表（服务器主动拉取，见 modules/wireguard.sh 的 sync）。
     * <p>
     * 必须带 level（这台服务器所属线路的等级）：只返回所属用户等级够用的设备，免费线路（0/4）返回全部。
     * 故意用 .txt 而不是 .json：.json 才会进用户校验、版本校验、AES 加密这套面向 App 的拦截链，
     * 服务器脚本既没有这些头也解不了 AES。鉴权只靠令牌（请求头 X-Sync-Token）。
     * 令牌未配置或不匹配一律 403，且不区分原因，不暴露配置状态。
     */
    @RequestMapping(value = "/wg/peers.txt", method = RequestMethod.GET, produces = "text/plain;charset=UTF-8")
    public org.springframework.http.ResponseEntity<String> wgPeers(
            @org.springframework.web.bind.annotation.RequestHeader(name = "X-Sync-Token", required = false) String token,
            @RequestParam(name = "level", required = false) String level) {
        if (!com.timeline.vpn.util.WgSyncAuth.matches(token, com.timeline.vpn.util.Secrets.get("wg.syncToken"))) {
            return org.springframework.http.ResponseEntity.status(403).body("forbidden\n");
        }
        if (level == null || !level.matches("\\d{1,2}")) {
            return org.springframework.http.ResponseEntity.badRequest().body("level required\n");
        }
        return org.springframework.http.ResponseEntity.ok(wgDeviceKeyService.peersText(Integer.parseInt(level)));
    }

    @RequestMapping(value = "/ping.json", method = RequestMethod.POST)
    public JsonResult ping(@UserInfo BaseQuery baseQuery,@RequestParam(name="pingCheck") String pingCheck) {
        List<PingCheck> list = parse(pingCheck);
        LOGGER.info(" ping check count="+list.size());
        return Constant.RESULT_SUCCESS;
    }
    @RequestMapping(value = "/offerads/youmi.json", method = {RequestMethod.POST,RequestMethod.GET})
    public JsonResult youmiOfferads(@UserInfo BaseQuery baseQuery,@RequestParam YoumiOffadsForm form) {
        LOGGER.info(form.toString()+"; check"+form.isRightReq());
        return Constant.RESULT_SUCCESS;
    }
    private List<PingCheck> parse(String str){
        String []ips = str.split(Constant.fen);
        List<PingCheck> list = new ArrayList<>();
        for(int i=0;i<ips.length;i++){
            String []types = ips[i].split(Constant.mao);
            PingCheck item = new PingCheck(types[0],Integer.parseInt(types[1]));
            list.add(item);
        }
        return list;
    }
    @RequestMapping(value = "/feed/wanna.json")
    public JsonResult wanna(WeiXinForm form) {
        LOGGER.info("weinxin form = "+form.toString());
        return new JsonResult(dataService.getIwannaWeiXin());
    }
    @RequestMapping(value = "/feed/token.json")
    public JsonResult token(WeiXinForm form) {
        LOGGER.info("weinxin form = "+form.toString());
        throw new TokenException(form.getEchostr());
    }
}

