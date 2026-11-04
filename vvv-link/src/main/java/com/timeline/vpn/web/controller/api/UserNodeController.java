package com.timeline.vpn.web.controller.api;

import com.timeline.vpn.model.form.UserNodeDelForm;
import com.timeline.vpn.model.form.UserNodeSaveForm;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.JsonResult;
import com.timeline.vpn.service.UserNodeService;
import com.timeline.vpn.web.common.resolver.UserInfo;
import com.timeline.vpn.web.controller.BaseController;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;

/** 用户自定义节点接口。都需要登录，且只操作本人的数据。 */
@RestController
@RequestMapping("/api/node")
public class UserNodeController extends BaseController {

    @Autowired
    private UserNodeService userNodeService;

    @RequestMapping(value = "/list.json", method = {RequestMethod.GET, RequestMethod.POST})
    public JsonResult list(@UserInfo(required = true) BaseQuery baseQuery) {
        return new JsonResult(userNodeService.list(baseQuery.getUser().getName()));
    }

    @RequestMapping(value = "/save.json", method = RequestMethod.POST)
    public JsonResult save(@UserInfo(required = true) BaseQuery baseQuery,
                           @Valid @ModelAttribute UserNodeSaveForm form) {
        return new JsonResult(userNodeService.save(baseQuery.getUser().getName(), form));
    }

    @RequestMapping(value = "/del.json", method = RequestMethod.POST)
    public JsonResult delete(@UserInfo(required = true) BaseQuery baseQuery,
                             @Valid @ModelAttribute UserNodeDelForm form) {
        userNodeService.delete(baseQuery.getUser().getName(), form);
        return com.timeline.vpn.Constant.RESULT_SUCCESS;
    }
}
