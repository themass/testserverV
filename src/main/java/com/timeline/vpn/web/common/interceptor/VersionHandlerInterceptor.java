package com.timeline.vpn.web.common.interceptor;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.servlet.handler.HandlerInterceptorAdapter;

import com.timeline.vpn.Constant;
import com.timeline.vpn.exception.ParamException;
import com.timeline.vpn.model.param.DevApp;
import com.timeline.vpn.model.vo.VersionInfoVo;
import com.timeline.vpn.service.DataService;
import com.timeline.vpn.util.DeviceUtil;

/**
 * 
 * @ClassName: CostHandlerInterceptor
 * @Description: 接口cost时间拦截器，在json结果中添加cost字段
 * @author gqli
 * @date 2015年8月12日 下午8:19:53
 *
 */
public class VersionHandlerInterceptor extends HandlerInterceptorAdapter {
    @Autowired
    private DataService dataService;

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response,
            Object handler) throws Exception {
        DevApp app = DeviceUtil.getAPPInfo(request);
        VersionInfoVo vo = dataService.getVersion(app.getPlatform());
        long version = Long.parseLong(app.getVersion());
        if (version < vo.getMinBuild()) {
            throw new ParamException(Constant.ResultMsg.RESULT_VERSION_ERROR);
        }
        return true;
    }


}
