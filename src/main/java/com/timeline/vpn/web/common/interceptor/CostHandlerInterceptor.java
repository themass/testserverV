package com.timeline.vpn.web.common.interceptor;

import java.util.Map;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.NamedThreadLocal;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.handler.HandlerInterceptorAdapter;

import com.timeline.vpn.model.vo.JsonResult;
import com.timeline.vpn.util.HttpCommonUtil;

/**
 * 
 * @ClassName: CostHandlerInterceptor
 * @Description: 接口cost时间拦截器，在json结果中添加cost字段
 * @author gqli
 * @date 2015年8月12日 下午8:19:53
 *
 */
public class CostHandlerInterceptor extends HandlerInterceptorAdapter {
    private NamedThreadLocal<Long> startTimeThreadLocal =
            new NamedThreadLocal<Long>("costTimeThreadLocal");
    private static final Logger LOGGER = LoggerFactory.getLogger(CostHandlerInterceptor.class);

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response,
            Object handler) throws Exception {
        long startTime = System.currentTimeMillis();
        startTimeThreadLocal.set(startTime);
        LOGGER.info(request.getServletPath()+"--start");
        HttpCommonUtil.printHeader(request);
        return true;
    }

    @Override
    public void postHandle(HttpServletRequest request, HttpServletResponse response, Object handler,
            ModelAndView modelAndView) throws Exception {
        if (modelAndView != null && modelAndView.getModel() != null) {
            Map<String, Object> map = modelAndView.getModel();
            if (map.get(JsonResult.MODEL_KEY) != null) {
                long endTime = System.currentTimeMillis();
                long costTime = endTime - startTimeThreadLocal.get();
                JsonResult result = (JsonResult) map.get(JsonResult.MODEL_KEY);
                result.setCost(costTime);
                LOGGER.info(String.format(request.getServletPath() + ",cost:%s", costTime));
            }

        }
    }

}
