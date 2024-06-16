package com.timeline.vpn.web.common.interceptor;

import com.timeline.vpn.model.vo.JsonResult;
import com.timeline.vpn.util.HttpCommonUtil;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.NamedThreadLocal;
import org.springframework.lang.Nullable;
import org.springframework.stereotype.Service;
import org.springframework.web.servlet.HandlerInterceptor;
import org.springframework.web.servlet.ModelAndView;

import java.util.Map;

/**
 * 
 * @ClassName: CostHandlerInterceptor
 * @Description: 接口cost时间拦截器，在json结果中添加cost字段
 * @author gqli
 * @date 2015年8月12日 下午8:19:53
 *
 */
@Service
public class CostHandlerInterceptor implements HandlerInterceptor {
    private NamedThreadLocal<Long> startTimeThreadLocal =
            new NamedThreadLocal<Long>("costTimeThreadLocal");
    private static final Logger LOGGER = LoggerFactory.getLogger(CostHandlerInterceptor.class);

    @Override
    public boolean preHandle(jakarta.servlet.http.HttpServletRequest request, jakarta.servlet.http.HttpServletResponse response, Object handler)
            throws Exception {
        long startTime = System.currentTimeMillis();
        startTimeThreadLocal.set(startTime);
//        LOGGER.info(request.getServletPath() + "--start; "+HttpCommonUtil.getHeaderStr(request));
        return true;
    }

    @Override
    public  void postHandle(HttpServletRequest request, HttpServletResponse response, Object handler,
                            @Nullable ModelAndView modelAndView) throws Exception {
//        Metrics.count(Measure.http.name(),);
        LOGGER.info(request.getServletPath()+"?"+request.getQueryString() + " -ua=-"+HttpCommonUtil.getHeaderStr(request));
        if (modelAndView != null && modelAndView.getModel() != null) {
            Map<String, Object> map = modelAndView.getModel();
            if (map.get(JsonResult.MODEL_KEY) != null) {
                long endTime = System.currentTimeMillis();
                long costTime = endTime - startTimeThreadLocal.get();
                JsonResult result = (JsonResult) map.get(JsonResult.MODEL_KEY);
                result.setCost(costTime);
//                LOGGER.info(String.format(request.getServletPath()+"[%s],[ua=%s]cost:%s", request.getQueryString(),HttpCommonUtil.getHeaderStr(request),costTime));
//                String uri=request.getRequestURI();
//                Metrics.time(MetricsName.http(uri),
//                        costTime);
//                Metrics.time(MetricsName.http("ALL"),
//                        0l);
            }

        }
    }

}
