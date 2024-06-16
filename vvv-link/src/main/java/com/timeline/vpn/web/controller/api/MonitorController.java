package vpn.web.controller.api;

import com.timeline.vpn.Constant;
import com.timeline.vpn.exception.LoginException;
import com.timeline.vpn.model.form.CInfoForm;
import com.timeline.vpn.model.form.ConnLogForm;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.JsonResult;
import com.timeline.vpn.util.AES2;
import com.timeline.vpn.web.common.resolver.UserInfo;
import com.timeline.vpn.web.controller.BaseController;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.multipart.MultipartFile;

import javax.validation.Valid;
import java.util.List;

/**
 * @author gqli
 * @date 2015年7月24日 下午3:16:25
 * @version V1.0
 */
@Controller
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
    @RequestMapping(value = "/emulator.json", method = RequestMethod.POST)
    public JsonResult emulator(@UserInfo BaseQuery baseQuery,@RequestParam String dev) {
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

