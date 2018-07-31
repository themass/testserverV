package com.timeline.vpn.web.controller.api;

import javax.validation.Valid;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;

import com.timeline.vpn.Constant;
import com.timeline.vpn.model.form.CustomeAddForm;
import com.timeline.vpn.model.form.LoginForm;
import com.timeline.vpn.model.form.UserEmailForm;
import com.timeline.vpn.model.form.UserRegForm;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.JsonResult;
import com.timeline.vpn.web.common.resolver.UserInfo;
import com.timeline.vpn.web.controller.BaseController;

import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;

/**
 * @author gqli
 * @date 2016年3月10日 上午10:28:07
 * @version V1.0
 */
@Controller
@RequestMapping("/api/user")
@Api(tags = "用户信息接口")
public class UserController extends BaseController {
    
    @ApiOperation(value = "注册用户")
    @RequestMapping(value = "/reg.json", method = RequestMethod.POST)
    public JsonResult reg(@UserInfo BaseQuery baseQuery, @Valid @ModelAttribute UserRegForm form) {
        userService.reg(form, baseQuery);
        return Constant.RESULT_SUCCESS;
    }
    @RequestMapping(value = "/findpass.json", method = RequestMethod.POST)
    public JsonResult findpass(@UserInfo BaseQuery baseQuery, @Valid @ModelAttribute UserEmailForm form) {
//        userService.reg(form, baseQuery.getAppInfo());
        //TODO 找回密码 发送邮件
        return Constant.RESULT_SUCCESS;
    }
    @RequestMapping(value = "/setemail.json", method = RequestMethod.POST)
    public JsonResult setemail(@UserInfo BaseQuery baseQuery, @Valid @ModelAttribute UserEmailForm form) {
        userService.updateEmail(form, baseQuery);
        return Constant.RESULT_SUCCESS;
    }
    @RequestMapping(value = "/info.json", method = RequestMethod.GET)
    public JsonResult info(@UserInfo(required = true) BaseQuery baseQuery) {
        return new JsonResult(userService.info(baseQuery));
    }

    @RequestMapping(value = "/login.json", method = RequestMethod.POST)
    public JsonResult login(@UserInfo BaseQuery baseQuery, @Valid @ModelAttribute LoginForm form) {
        return new JsonResult(userService.login(baseQuery, form.getName(), form.getPwd(),form.getScore()));
    }

    @RequestMapping(value = "/logout.json", method = RequestMethod.POST)
    public JsonResult logout(@UserInfo BaseQuery baseQuery) {
        userService.logout(baseQuery);
        return Constant.RESULT_SUCCESS;
    }
    @RequestMapping(value = "/custome/add.json", method = RequestMethod.POST)
    public JsonResult customeUpdate(@UserInfo(required = true) BaseQuery baseQuery,@Valid @ModelAttribute CustomeAddForm form) {
        userService.addOrUpdateCustome(baseQuery,form);
        return Constant.RESULT_SUCCESS;
    }
    @RequestMapping(value = "/custome/del.json", method = RequestMethod.POST)
    public JsonResult customeDel(@UserInfo(required = true) BaseQuery baseQuery,@RequestParam int id) {
        userService.delCustome(baseQuery,id);
        return Constant.RESULT_SUCCESS;
    }
    @RequestMapping(value = "/ads/score.json", method = RequestMethod.GET)
    public JsonResult adsFabCLick(@UserInfo(required = true) BaseQuery baseQuery,
            @RequestParam int score) {
        if (score == Constant.ADS_FAB_SCORE || score == Constant.ADS_CLICK_SCORE) {
            return new JsonResult(userService.score(baseQuery, score));
        }
        return Constant.RESULT_SUCCESS;
    }
}

