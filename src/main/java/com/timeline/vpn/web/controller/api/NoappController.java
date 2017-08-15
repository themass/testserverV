package com.timeline.vpn.web.controller.api;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;

import com.timeline.vpn.Constant;
import com.timeline.vpn.model.param.BaseQuery;
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
    public JsonResult collect(@UserInfo BaseQuery baseQuery,@RequestParam Integer count) {
        reportService.collect(baseQuery, count);
        return Constant.RESULT_SUCCESS;
    }
}

