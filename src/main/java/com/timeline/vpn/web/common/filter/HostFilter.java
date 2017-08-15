package com.timeline.vpn.web.common.filter;

import java.io.IOException;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;

import com.timeline.vpn.model.param.DevApp;
import com.timeline.vpn.util.DeviceUtil;
import com.timeline.vpn.util.UrlUtil;
import com.timeline.vpn.web.common.DevAppContext;

/**
 * @author gqli
 * @date 2016年12月12日 下午7:04:16
 * @version V1.0
 */
public class HostFilter implements Filter{

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
    }

    @Override
    public void doFilter(ServletRequest servletRequest, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest request = (HttpServletRequest) servletRequest;
        String uri = request.getRequestURI();
        if(uri.contains("test") || uri.contains("noapp")){
            DevApp app = new DevApp();
            app.setTest(true);
            app.setAuthKey("ssssssdddeee4eee");
            app.setHost(request.getHeader("Host"));
            app.setTokenHeader("1111");
            app.setUserIp(UrlUtil.getIpAddr(request));
            DevAppContext.set(app);
        }else{
            DevApp app = DeviceUtil.getAPPInfo(request);
            //TODO 暂时注释;
            DevAppContext.set(app);
        }
        
        chain.doFilter(request, response);
    }

    @Override
    public void destroy() {
    }

}

