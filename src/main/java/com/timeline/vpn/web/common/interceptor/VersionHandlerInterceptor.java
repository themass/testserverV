package com.timeline.vpn.web.common.interceptor;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.servlet.handler.HandlerInterceptorAdapter;

import com.timeline.vpn.Constant;
import com.timeline.vpn.exception.MonitorException;
import com.timeline.vpn.exception.ParamException;
import com.timeline.vpn.model.param.DevApp;
import com.timeline.vpn.model.vo.VersionInfoVo;
import com.timeline.vpn.service.DataService;
import com.timeline.vpn.web.common.DevAppContext;

/**
 * 
 * @ClassName: CostHandlerInterceptor
 * @Description: 接口cost时间拦截器，在json结果中添加cost字段
 * @author gqli
 * @date 2015年8月12日 下午8:19:53
 *
 */
public class VersionHandlerInterceptor extends HandlerInterceptorAdapter {
    private static final Logger LOGGER = LoggerFactory.getLogger(VersionHandlerInterceptor.class);
    @Autowired
    private DataService dataService;

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response,
            Object handler) throws Exception {
        DevApp app = DevAppContext.get();
        if(app.isTest()){
            return true;
        }
        if (app == null || !app.check()) {
            LOGGER.error("恶意攻击--devapp={}",app);
            throw new MonitorException("服务异常，请稍后再试");
        }
        VersionInfoVo vo = dataService.getMaxVersion(app,app.getChannel());
        long version = Long.parseLong(app.getVersion());
        if (version < vo.getMinBuild()) {
            throw new ParamException(Constant.ResultMsg.RESULT_VERSION_ERROR);
        }
        return true;
    }


}
