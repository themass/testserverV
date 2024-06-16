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

    @RequestMapping(value = "/collect.json", method = RequestMethod.POST)
    public JsonResult collect(@UserInfo BaseQuery baseQuery,@RequestParam(name="count") Integer count,@RequestParam(name="localhost") String localhost,@RequestParam(required=false,name="ip") String ip) {
        if(count==-1) {
            LOGGER.error("ip 错误了，服务断了，快速处理吧"+localhost+"---"+ip);
            dataService.sendMsg("ip 错误了，服务断了，快速处理吧"+localhost+"---"+ip);
        }
        return Constant.RESULT_SUCCESS;
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

