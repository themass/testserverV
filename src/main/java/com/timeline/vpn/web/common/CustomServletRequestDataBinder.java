package com.timeline.vpn.web.common;

import javax.servlet.http.HttpServletRequest;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.ServletRequestDataBinder;
import org.springframework.web.servlet.support.RequestContext;

import com.timeline.vpn.Constant;
import com.timeline.vpn.exception.NormalException;
import com.timeline.vpn.util.UrlUtil;


/**
 * 执行绑定时，能够通过注解自定义绑定到ModelAttribute对象的字段
 */

public class CustomServletRequestDataBinder extends ServletRequestDataBinder {
    protected static final Logger LOGGER =
            LoggerFactory.getLogger(CustomServletRequestDataBinder.class);
    private HttpServletRequest request;

    public CustomServletRequestDataBinder(Object target, HttpServletRequest request) {
        super(target);
        this.request = request;
    }

    public CustomServletRequestDataBinder(Object target, String objectName,
            HttpServletRequest request) {
        super(target, objectName);
        this.request = request;
    }


    @Override
    public void validate(Object... validationHints) {
        super.validate(validationHints);
        if (getBindingResult().hasErrors()) {
            RequestContext rc = new RequestContext(request);
            LOGGER.error(String.format("%s, error=%s", UrlUtil.getFullRequestUri(request),
                    getBindingResult().getFieldErrors().toString()));
            throw new NormalException(Constant.ResultErrno.ERRNO_PARAM,
                    rc.getMessage(getBindingResult().getFieldErrors().get(0)));
        }
    }


}
