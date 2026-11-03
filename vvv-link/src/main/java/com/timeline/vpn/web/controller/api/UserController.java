package com.timeline.vpn.web.controller.api;

import com.timeline.vpn.Constant;
import com.timeline.vpn.model.form.*;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.InviteVo;
import com.timeline.vpn.model.vo.JsonResult;
import com.timeline.vpn.service.InviteService;
import com.timeline.vpn.web.common.resolver.UserInfo;
import com.timeline.vpn.web.controller.BaseController;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.apache.commons.lang3.StringUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;



/**
 * @author gqli
 * @date 2016年3月10日 上午10:28:07
 * @version V1.0
 */
@RestController
@RequestMapping("/api/user")
public class UserController extends BaseController {

    @Autowired
    private InviteService inviteService;

    /** 当前用户的邀请码（没有则生成）。 */
    @RequestMapping(value = "/invite.json", method = {RequestMethod.GET, RequestMethod.POST})
    public JsonResult invite(@UserInfo(required = true) BaseQuery baseQuery) {
        return new JsonResult(new InviteVo(inviteService.getOrCreateCode(baseQuery.getUser().getName())));
    }
    
    @RequestMapping(value = "/reg.json", method = RequestMethod.POST)
    public JsonResult reg(@UserInfo BaseQuery baseQuery, @Valid @ModelAttribute UserRegForm form) {
        userService.reg(form, baseQuery);
        return Constant.RESULT_SUCCESS; 
    }
    @RequestMapping(value = "/findpass.json", method = RequestMethod.POST)
    public JsonResult findpass(@UserInfo BaseQuery baseQuery, @Valid @ModelAttribute UserEmailForm form) {
        userService.requestPasswordReset(form.getEmail());
        return Constant.RESULT_SUCCESS;
    }

    @RequestMapping(value = "/changepass.json", method = RequestMethod.POST)
    public JsonResult changepass(@UserInfo(required = true) BaseQuery baseQuery, @Valid @ModelAttribute UserChangePwdForm form) {
        userService.changePassword(baseQuery, form);
        return Constant.RESULT_SUCCESS;
    }

    @RequestMapping(value = "/resetpass.json", method = RequestMethod.POST)
    public JsonResult resetpass(@UserInfo BaseQuery baseQuery, @Valid @ModelAttribute UserResetPwdForm form) {
        userService.resetPassword(form);
        return Constant.RESULT_SUCCESS;
    }
    @RequestMapping(value = "/del.json", method = RequestMethod.POST)
    public JsonResult del(@UserInfo BaseQuery baseQuery, @Valid @ModelAttribute UserDelForm form) {
//        userService.reg(form, baseQuery.getAppInfo());
        userService.del(baseQuery, form.getName(), form.getPwd());
        return Constant.RESULT_SUCCESS;
    }
    @RequestMapping(value = "/setemail.json", method = RequestMethod.POST)
    public JsonResult setemail(@UserInfo BaseQuery baseQuery, @Valid @ModelAttribute UserEmailForm form) {
        userService.updateEmail(form, baseQuery);
        return Constant.RESULT_SUCCESS;
    }
    @RequestMapping(value = "/info.json", method = {RequestMethod.POST,RequestMethod.GET})
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
    public JsonResult customeDel(@UserInfo(required = true) BaseQuery baseQuery,@RequestParam(name="id") int id) {
        userService.delCustome(baseQuery,id);
        return Constant.RESULT_SUCCESS;
    }
    @RequestMapping(value = "/ads/score.json", method = {RequestMethod.POST,RequestMethod.GET})
    public JsonResult adsFabClick(@UserInfo(required = true) BaseQuery baseQuery,
            @RequestParam(name="score") int score) {
//          return new JsonResult(userService.score(baseQuery, score));
        // 已停用：积分由客户端上报、没有服务端验证，任何人都能伪造。
        // 激励视频奖励改由 /api/reward/admob/ssv（AdMob 服务端回调）发放。
        return Constant.RESULT_SUCCESS;
    }
    @RequestMapping(value = "/ads/check.json", method = RequestMethod.POST)
    public JsonResult adsFabcheck(ServletRequest servletRequest, @UserInfo(required = true) BaseQuery baseQuery) {
        HttpServletRequest request = (HttpServletRequest) servletRequest;
        String key = request.getHeader("CookieCache");
        int score = 0;
        if(!StringUtils.isEmpty(key)) {
            score = Integer.parseInt(key.replace("sdsktesstkey", ""));
        }
        LOGGER.info("scoreadd->"+baseQuery.getUser().getName()+"------"+score);
        if(score<60) {
            return Constant.RESULT_SUCCESS;
        }
        return new JsonResult(userService.score(baseQuery, score));
    }
    @RequestMapping(value = "/setting/character.json", method = RequestMethod.GET)
    public JsonResult character(@UserInfo BaseQuery baseQuery) {
        return new JsonResult(chatService.getCharacter(baseQuery));
    }

    /**
     * 创建自定义角色。
     *
     * 多角色支持的一部分：官方角色由后端管理，这个接口让用户上传自己的人设——
     * 新建的角色 ownerUserId 归属当前用户，只有自己能在列表里看到、能编辑/删除。
     */
    @RequestMapping(value = "/setting/character/create.json", method = RequestMethod.POST)
    public JsonResult createCharacter(@UserInfo(required = true) BaseQuery baseQuery,
            @Valid @ModelAttribute CharacterForm form) {
        return new JsonResult(chatService.createCharacter(baseQuery, form));
    }

    @RequestMapping(value = "/setting/character/update.json", method = RequestMethod.POST)
    public JsonResult updateCharacter(@UserInfo(required = true) BaseQuery baseQuery,
            @Valid @ModelAttribute CharacterForm form) {
        return new JsonResult(chatService.updateCharacter(baseQuery, form));
    }

    @RequestMapping(value = "/setting/character/delete.json", method = RequestMethod.POST)
    public JsonResult deleteCharacter(@UserInfo(required = true) BaseQuery baseQuery,
            @RequestParam("id") int characterId) {
        chatService.deleteCharacter(baseQuery, characterId);
        return Constant.RESULT_SUCCESS;
    }
}

