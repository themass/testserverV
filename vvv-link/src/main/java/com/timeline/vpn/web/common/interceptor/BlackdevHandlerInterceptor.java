package com.timeline.vpn.web.common.interceptor;

import com.timeline.vpn.dao.db.BlackDevDao;
import com.timeline.vpn.exception.MonitorException;
import com.timeline.vpn.model.param.DevApp;
import com.timeline.vpn.model.po.BlackDevPo;
import com.timeline.vpn.web.common.DevAppContext;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.servlet.HandlerInterceptor;


/**
 * 设备黑名单拦截器：命中黑名单的 devId 直接抛异常中断请求。
 *
 * 原先的 javadoc 是从另一个类（CostHandlerInterceptor）复制过来的，写的是"统计接口耗时、
 * 在 json 结果里加 cost 字段"——和这个类实际做的事完全相反，误导性很强，已修正。
 *
 * @author gqli
 */
@Service
public class BlackdevHandlerInterceptor implements HandlerInterceptor {
    private static final Logger LOGGER = LoggerFactory.getLogger(BlackdevHandlerInterceptor.class);

    @Autowired
    private BlackDevDao blackDevDao;
    @Override
    public boolean preHandle(jakarta.servlet.http.HttpServletRequest request, jakarta.servlet.http.HttpServletResponse response, Object handler)
            throws Exception {
        DevApp app = DevAppContext.get();
        BlackDevPo po = blackDevDao.get(app.getDevId());
        if(po!=null){
            LOGGER.error("这是一个黑名单用户，{}",app);
            throw new MonitorException("服务器异常,请稍后再试"); 
        }
        return true;
    }
}
