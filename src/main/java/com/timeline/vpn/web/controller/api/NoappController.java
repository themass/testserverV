package com.timeline.vpn.web.controller.api;

import java.util.ArrayList;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;

import com.timeline.vpn.Constant;
import com.timeline.vpn.exception.TokenException;
import com.timeline.vpn.model.form.WeiXinForm;
import com.timeline.vpn.model.form.YoumiOffadsForm;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.po.PingCheck;
import com.timeline.vpn.model.vo.JsonResult;
import com.timeline.vpn.service.ReportService;
import com.timeline.vpn.web.common.resolver.UserInfo;
import com.timeline.vpn.web.controller.BaseController;

/**
 * @author gqli
 * @date 2015年7月24日 下午3:16:25
 * @version V1.0
 */
@Controller
@RequestMapping("/api/noapp")
public class NoappController extends BaseController {
    @Autowired
    private ReportService reportService;
    @RequestMapping(value = "/collect.json", method = RequestMethod.POST)
    public JsonResult collect(@UserInfo BaseQuery baseQuery,@RequestParam Integer count,@RequestParam String localhost) {
        reportService.collect(baseQuery, count,localhost);
        return Constant.RESULT_SUCCESS;
    }
    @RequestMapping(value = "/ping.json", method = RequestMethod.POST)
    public JsonResult ping(@UserInfo BaseQuery baseQuery,@RequestParam String pingCheck) {
        List<PingCheck> list = parse(pingCheck);
        LOGGER.info(" ping check count="+list.size());
        for(PingCheck item:list)
            reportService.pingCheck(baseQuery, item.getType(),item.getIp());
        return Constant.RESULT_SUCCESS;
    }
    @RequestMapping(value = "/offerads/youmi.json", method = RequestMethod.GET)
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

