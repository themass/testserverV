package com.timeline.vpn.web.controller.api;

import com.timeline.vpn.Constant;
import com.timeline.vpn.exception.LoginException;
import com.timeline.vpn.model.form.CInfoForm;
import com.timeline.vpn.model.form.ConnLogForm;
import com.timeline.vpn.model.form.MtuLogForm;
import com.timeline.vpn.dao.db.MtuLogDao;
import com.timeline.vpn.model.po.MtuLogPo;
import com.timeline.vpn.util.JsonUtil;
import org.springframework.beans.factory.annotation.Autowired;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.JsonResult;
import com.timeline.vpn.util.AES2;
import com.timeline.vpn.web.common.resolver.UserInfo;
import com.timeline.vpn.web.controller.BaseController;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Map;

/**
 * @author gqli
 * @date 2015年7月24日 下午3:16:25
 * @version V1.0
 */
@RestController
@RequestMapping("/api/monitor")
public class MonitorController extends BaseController {
    @RequestMapping(value = "/leak.json", method = RequestMethod.POST)
    public JsonResult leak(@UserInfo BaseQuery baseQuery,@RequestParam List<MultipartFile> fileList) {
        return Constant.RESULT_SUCCESS;
    }

    @RequestMapping(value = "/bug.json", method = RequestMethod.POST)
    public JsonResult bug(@UserInfo BaseQuery baseQuery,@RequestParam List<MultipartFile> fileList) {
        return Constant.RESULT_SUCCESS;
    }
    @RequestMapping(value = "/connlog.json", method = RequestMethod.POST)
    public JsonResult connlog(@UserInfo BaseQuery baseQuery,@ModelAttribute @Valid ConnLogForm logs) {
//        reportService.connlog(baseQuery, logs);
        return Constant.RESULT_SUCCESS;
    }
    @Autowired
    private MtuLogDao mtuLogDao;

    /** 单次上报最多接收的条数，超出部分丢弃（客户端本地也有上限）。 */
    private static final int MTU_LOG_MAX = 100;

    /**
     * 隧道 MTU 探测结果上报（doc/MTU-DESIGN.md 3.7）。
     * 统计数据，写库失败（如迁移未执行）不影响客户端：只记日志，照常返回成功，避免客户端反复重发。
     */
    @RequestMapping(value = "/mtulog.json", method = RequestMethod.POST)
    public JsonResult mtulog(@UserInfo BaseQuery baseQuery, @ModelAttribute MtuLogForm form) {
        if (form == null || form.getLog() == null || form.getLog().isEmpty()) {
            return Constant.RESULT_SUCCESS;
        }
        try {
            List<Map<String, Object>> raw = JsonUtil.readValue(form.getLog(), JsonUtil.getListType(Map.class));
            if (raw == null || raw.isEmpty()) {
                return Constant.RESULT_SUCCESS;
            }
            String devId = baseQuery.getAppInfo() == null ? null : baseQuery.getAppInfo().getDevId();
            String userIp = baseQuery.getAppInfo() == null ? null : baseQuery.getAppInfo().getUserIp();
            Date now = new Date();
            List<MtuLogPo> list = new ArrayList<>();
            for (Map<String, Object> m : raw) {
                if (list.size() >= MTU_LOG_MAX) {
                    break;
                }
                MtuLogPo po = new MtuLogPo();
                po.setDevId(cut(devId, 64));
                po.setUserIp(cut(userIp, 64));
                po.setNode(cut(str(m.get("node")), 96));
                po.setProtocol(cut(str(m.get("protocol")), 16));
                po.setNetType(cut(str(m.get("netType")), 8));
                po.setCarrier(cut(str(m.get("carrier")), 16));
                po.setLinkMtu(intIn(m.get("linkMtu"), 0, 65535));
                po.setMtu(intIn(m.get("mtu"), 0, 65535));
                po.setProbe(cut(str(m.get("probe")), 16));
                po.setRetried(Boolean.TRUE.equals(m.get("retried")));
                po.setCreatedAt(now);
                list.add(po);
            }
            if (!list.isEmpty()) {
                mtuLogDao.insertAll(list);
            }
        } catch (Exception e) {
            LOGGER.error("mtulog 写入失败: " + e.getMessage());
        }
        return Constant.RESULT_SUCCESS;
    }

    private static String str(Object o) {
        return o == null ? null : String.valueOf(o);
    }

    private static String cut(String s, int max) {
        return s == null || s.length() <= max ? s : s.substring(0, max);
    }

    private static int intIn(Object o, int min, int max) {
        int v;
        if (o instanceof Number) {
            v = ((Number) o).intValue();
        } else {
            try {
                v = o == null ? 0 : Integer.parseInt(String.valueOf(o));
            } catch (NumberFormatException e) {
                v = 0;
            }
        }
        return Math.max(min, Math.min(max, v));
    }

    @RequestMapping(value = "/emulator.json", method = RequestMethod.POST)
    public JsonResult emulator(@UserInfo BaseQuery baseQuery,@RequestParam(name="dev") String dev) {
//        reportService.connlog(baseQuery, logs);
        LOGGER.error("这是一个模拟器："+dev);
        throw new LoginException(Constant.ResultMsg.RESULT_ERROR_DEV);
//        return Constant.RESULT_SUCCESS;
    }
    @RequestMapping(value = "/detail.json", method = RequestMethod.POST)
    public JsonResult detail(@UserInfo BaseQuery baseQuery,@ModelAttribute @Valid CInfoForm form) {
        String key = (baseQuery.getAppInfo().getDevId()+form.getName()+"eb0?01tta#$q20").substring(5,21);
        form.setInfo(AES2.decode(form.getInfo(), key));
//        reportService.connlog(baseQuery, logs);
        LOGGER.error(" info detail："+form);
        return Constant.RESULT_SUCCESS;
    }
}

