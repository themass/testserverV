package com.timeline.vpn.web.controller.api;

import java.util.List;

import javax.validation.Valid;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.multipart.MultipartFile;

import com.timeline.vpn.Constant;
import com.timeline.vpn.exception.DataException;
import com.timeline.vpn.model.form.ConnLogForm;
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
@RequestMapping("/api/monitor")
public class MonitorController extends BaseController {
    @Autowired
    private ReportService reportService;
    @RequestMapping(value = "/leak.json", method = RequestMethod.POST)
    public JsonResult leak(@UserInfo BaseQuery baseQuery,@RequestParam List<MultipartFile> fileList) {
        return Constant.RESULT_SUCCESS;
    }

    @RequestMapping(value = "/bug.json", method = RequestMethod.POST)
    public JsonResult bug(@UserInfo BaseQuery baseQuery,@RequestParam List<MultipartFile> fileList) {
        reportService.reportBug(baseQuery, fileList);
        return Constant.RESULT_SUCCESS;
    }
    @RequestMapping(value = "/connlog.json", method = RequestMethod.POST)
    public JsonResult connlog(@UserInfo BaseQuery baseQuery,@ModelAttribute @Valid ConnLogForm logs) {
//        reportService.connlog(baseQuery, logs);
        return Constant.RESULT_SUCCESS;
    }
    @RequestMapping(value = "/emulator.json", method = RequestMethod.POST)
    public JsonResult emulator(@UserInfo BaseQuery baseQuery,@RequestParam String dev) {
//        reportService.connlog(baseQuery, logs);
        LOGGER.error("这是一个模拟器："+dev);
        throw new DataException(Constant.ResultMsg.RESULT_ERROR_DEV);
//        return Constant.RESULT_SUCCESS;
    }
}

