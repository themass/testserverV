package com.timeline.vpn.web.controller.api;

import javax.validation.Valid;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;

import com.timeline.vpn.Constant;
import com.timeline.vpn.model.form.PageBaseForm;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.JsonResult;
import com.timeline.vpn.web.common.resolver.UserInfo;
import com.timeline.vpn.web.controller.BaseController;

/**
 * @author gqli
 * @date 2015年7月24日 下午3:16:25
 * @version V1.0
 */
@Controller
@RequestMapping("/api/data")
public class DataController extends BaseController {
    @RequestMapping(value = "/recommend.json", method = RequestMethod.GET)
    public JsonResult recommendList(@UserInfo BaseQuery baseQuery,
            @ModelAttribute @Valid PageBaseForm form) {
        return new JsonResult(dataService.getRecommendPage(baseQuery,form.toParam()));
    }
    
    
    
    @RequestMapping(value = "/recommend/movie.json", method = RequestMethod.GET)
    public JsonResult movie(@UserInfo BaseQuery baseQuery) {
        return new JsonResult(dataService.getRecommendMoviePage(baseQuery));
    }
    @RequestMapping(value = "/recommend/night.json", method = RequestMethod.GET)
    public JsonResult night(@UserInfo BaseQuery baseQuery,
            @ModelAttribute @Valid PageBaseForm form) {
        return new JsonResult(dataService.getRecommendNightPage(baseQuery,form.toParam()));
    }
    @RequestMapping(value = "/recommend/area.json", method = RequestMethod.GET)
    public JsonResult area(@UserInfo BaseQuery baseQuery,
            @ModelAttribute @Valid PageBaseForm form) {
        return new JsonResult(dataService.getRecommendAreaPage(baseQuery,form.toParam()));
    }
    @RequestMapping(value = "/recommend/custome.json", method = RequestMethod.GET)
    public JsonResult customeList(@UserInfo(required=true) BaseQuery baseQuery,
            @ModelAttribute @Valid PageBaseForm form) {
        return new JsonResult(userService.getRecommendCustomePage(baseQuery,form.toParam()));
    }
    
    
    
    
    @RequestMapping(value = "/recommend/vip.json", method = RequestMethod.GET)
    public JsonResult vipList(@UserInfo BaseQuery baseQuery,
            @ModelAttribute @Valid PageBaseForm form) {
        return new JsonResult(dataService.getRecommendVipPage(baseQuery,form.toParam()));
    }
    
    @RequestMapping(value = "/version.json", method = RequestMethod.GET)
    public JsonResult version(@UserInfo BaseQuery baseQuery) {
        return new JsonResult(dataService.getVersion(baseQuery,baseQuery.getAppInfo().getPlatform(),baseQuery.getAppInfo().getChannel()));
    }
    @RequestMapping(value = "/appinfo.json", method = RequestMethod.GET)
    public JsonResult appinfo(@UserInfo BaseQuery baseQuery) {
        return new JsonResult(dataService.getAllApp(baseQuery));
    }
    @RequestMapping(value = "/donation.json", method = RequestMethod.GET)
    public JsonResult donation(@UserInfo BaseQuery baseQuery) {
        return new JsonResult(dataService.getAllDon(baseQuery));
    }
    @RequestMapping(value = "/feed/wanna.json", method = RequestMethod.GET)
    public JsonResult wanna(@UserInfo BaseQuery baseQuery,
            @ModelAttribute @Valid PageBaseForm form) {
        return new JsonResult(dataService.getIwannaPage(baseQuery, form.toParam()));
    }

    @RequestMapping(value = "/feed/wanna.json", method = RequestMethod.POST)
    public JsonResult wanna(@UserInfo(required=true) BaseQuery baseQuery, @RequestParam String content) {
       return new JsonResult(dataService.addIwanna(baseQuery, content));
    }
    @RequestMapping(value = "/feed/wanna/{id}.json", method = RequestMethod.POST)
    public JsonResult wannaLike(@UserInfo BaseQuery baseQuery, @PathVariable long id) {
        dataService.addIwannaLike(baseQuery, id);
        return Constant.RESULT_SUCCESS;
    }
    
    @RequestMapping(value = "/feed/score.json", method = RequestMethod.GET)
    public JsonResult wannaScore(@UserInfo BaseQuery baseQuery,
            @ModelAttribute @Valid PageBaseForm form) {
        return new JsonResult(dataService.getIwannaPage(baseQuery, form.toParam()));
    }
    @RequestMapping(value = "/feed/score.json", method = RequestMethod.POST)
    public JsonResult wannaScore(@UserInfo(required=true) BaseQuery baseQuery, @RequestParam String content) {
       return new JsonResult(dataService.addIwanna(baseQuery, content));
    }
    @RequestMapping(value = "/feed/score/{id}.json", method = RequestMethod.POST)
    public JsonResult wannaScoreLike(@UserInfo BaseQuery baseQuery, @PathVariable long id) {
        dataService.addIwannaLike(baseQuery, id);
        return Constant.RESULT_SUCCESS;
    }
}

