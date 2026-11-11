package com.timeline.vpn.web.controller.api;

import com.timeline.vpn.Constant;
import com.timeline.vpn.exception.LoginException;
import com.timeline.vpn.model.form.CInfoForm;
import com.timeline.vpn.model.form.ConnLogForm;
import com.timeline.vpn.model.form.MtuLogForm;
import com.timeline.vpn.dao.db.BugReportDao;
import com.timeline.vpn.dao.db.MtuLogDao;
import com.timeline.vpn.model.param.DevApp;
import com.timeline.vpn.model.po.BugReportPo;
import com.timeline.vpn.model.po.UserPo;
import com.timeline.vpn.model.po.MtuLogPo;
import com.timeline.vpn.util.JsonUtil;
import org.springframework.beans.factory.annotation.Autowired;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.JsonResult;
import com.timeline.vpn.model.vo.RetInfoVo;
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

    /**
     * 客户端「上报问题」：用户在设置页读完成本清单、点同意之后才会走到这里。
     * <p>
     * 早先这里直接 return SUCCESS，文件读完就丢——用户看到"已发送"，实际什么都没存。
     * mtulog 也踩过同一个坑（无条件成功导致数据静默丢失），这里必须如实反映写库结果：
     * 客户端只在收到成功后才删本地日志，失败就保留，用户下次还能再报。
     */
    @RequestMapping(value = "/bug.json", method = RequestMethod.POST)
    public JsonResult bug(@UserInfo BaseQuery baseQuery,
                          @RequestParam(required = false) List<MultipartFile> fileList,
                          @RequestParam(required = false) String label) {
        if (fileList == null || fileList.isEmpty()) {
            return Constant.RESULT_SUCCESS;   // 没有附件时不算失败
        }
        try {
            DevApp app = baseQuery.getAppInfo();
            UserPo user = baseQuery.getUser();
            for (MultipartFile file : fileList) {
                if (file == null || file.isEmpty()) {
                    continue;
                }
                BugReportPo po = new BugReportPo();
                po.setUserId(user == null ? null : user.getId());
                po.setDevId(cut(app == null ? null : app.getDevId(), 64));
                po.setUserIp(cut(app == null ? null : app.getUserIp(), 64));
                po.setVersion(cut(app == null ? null : app.getVersionName(), 32));
                po.setLabel(cut(label, 128));
                po.setFileName(cut(file.getOriginalFilename(), 128));
                po.setFileBytes((int) Math.min(Integer.MAX_VALUE, file.getSize()));
                String text = readText(file);
                po.setTruncated(text.length() > BUG_CONTENT_MAX);
                if (po.isTruncated()) {
                    // 截断保留尾部：最接近崩溃时刻的记录比开头的启动信息更有用
                    text = text.substring(text.length() - BUG_CONTENT_MAX);
                }
                po.setContent(text);
                po.setCreatedAt(new Date());
                bugReportDao.insert(po);
            }
        } catch (Exception e) {
            // 带上完整堆栈：只看 getMessage() 时，"表不存在"和"字段超长"这类错误分不出来，
            // 排查时得靠这句话本身说清楚是哪种失败。
            LOGGER.error("bug.json 写入失败: " + e, e);
            return new JsonResult(new RetInfoVo(false), Constant.ResultErrno.ERRNO_SYSTEM, null);
        }
        return Constant.RESULT_SUCCESS;
    }

    /** 单条上报最多保存的字符数。MEDIUMTEXT 很大，但没必要为了日志把行撑爆。 */
    private static final int BUG_CONTENT_MAX = 200_000;

    /**
     * 按文本读入日志。字符集按 UTF-8 解码，遇到非法字节用替换字符而不是抛异常：
     * charon 日志里混着 native 层的字节，直接 new String(bytes, UTF_8) 不会抛，但这里仍单独包一层，
     * 免得将来改成严格解码时把整条上报弄失败。
     */
    private static String readText(MultipartFile file) {
        try {
            return new String(file.getBytes(), java.nio.charset.StandardCharsets.UTF_8);
        } catch (Exception e) {
            LOGGER.error("读取上报文件失败: " + e.getMessage());
            return "";
        }
    }
    @RequestMapping(value = "/connlog.json", method = RequestMethod.POST)
    public JsonResult connlog(@UserInfo BaseQuery baseQuery,@ModelAttribute @Valid ConnLogForm logs) {
//        reportService.connlog(baseQuery, logs);
        return Constant.RESULT_SUCCESS;
    }
    @Autowired
    private MtuLogDao mtuLogDao;
    @Autowired
    private BugReportDao bugReportDao;

    /** 单次上报最多接收的条数，超出部分丢弃（客户端本地也有上限）。 */
    private static final int MTU_LOG_MAX = 100;

    /**
     * 隧道 MTU 探测结果上报（doc/MTU-DESIGN.md 3.7）。
     * <p>
     * 客户端只在收到成功响应后才清本地队列，所以这里必须如实反映写库结果：
     * 写库失败返回非 0 errno，客户端保留数据下次重发。早先无条件返回成功，
     * 迁移没执行时数据会静默丢失，而这份数据正是用来决定"要不要下调默认 MTU"的。
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
            return new JsonResult(new RetInfoVo(false), Constant.ResultErrno.ERRNO_SYSTEM, null);
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

