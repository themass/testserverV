package com.timeline.vpn.web.common.interceptor;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.servlet.handler.HandlerInterceptorAdapter;

import com.timeline.vpn.dao.db.BlackDevDao;
import com.timeline.vpn.exception.MonitorException;
import com.timeline.vpn.model.param.DevApp;
import com.timeline.vpn.model.po.BlackDevPo;
import com.timeline.vpn.web.common.DevAppContext;

/**
 * 
 * @ClassName: CostHandlerInterceptor
 * @Description: 接口cost时间拦截器，在json结果中添加cost字段
 * @author gqli
 * @date 2015年8月12日 下午8:19:53
 *
 */
public class BlackdevHandlerInterceptor extends HandlerInterceptorAdapter {
    private static final Logger LOGGER = LoggerFactory.getLogger(BlackdevHandlerInterceptor.class);

    @Autowired
    private BlackDevDao blackDevDao;
    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response,
            Object handler) throws Exception {
        DevApp app = DevAppContext.get();
        BlackDevPo po = blackDevDao.get(app.getDevId());
        if(po!=null){
            LOGGER.error("这是一个黑名单用户，{}",app);
            throw new MonitorException("服务器异常,请稍后再试"); 
        }
        return true;
    }
}
