package com.timeline.vpn.web.common.interceptor;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.commons.lang.StringUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.handler.HandlerInterceptorAdapter;

import com.timeline.vpn.Constant;
import com.timeline.vpn.model.po.UserPo;
import com.timeline.vpn.model.vo.JsonResult;
import com.timeline.vpn.service.CacheService;

/**
 * 
 * @ClassName: CostHandlerInterceptor
 * @Description: 接口cost时间拦截器，在json结果中添加cost字段
 * @author gqli
 * @date 2015年8月12日 下午8:19:53
 *
 */
public class UserCheckHandlerInterceptor extends HandlerInterceptorAdapter {
    @Autowired
    private CacheService cacheService;
    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response,
            Object handler) throws Exception {
        String token = request.getHeader(Constant.HTTP_TOKEN_KEY);
        if(StringUtils.isEmpty(token)){
            return true;
        }
        UserPo po = cacheService.getUser(token); 
        if(po!=null){
            request.setAttribute(Constant.HTTP_ATTR_TOKEN, po);
        }else{
            request.setAttribute(Constant.HTTP_ATTR_RET, Constant.ResultErrno.ERRNO_CLEAR_LOGIN);
        }
        return true;
    }

    @Override
    public void postHandle(HttpServletRequest request, HttpServletResponse response, Object handler,
            ModelAndView modelAndView) throws Exception {
        super.postHandle(request, response, handler, modelAndView);
        Integer ret = (Integer)request.getAttribute(Constant.HTTP_ATTR_RET);
        if(ret!=null){
            JsonResult result = (JsonResult)modelAndView.getModel().get(JsonResult.MODEL_KEY);
            result.setErrno(ret);
        }
    }
    


}
