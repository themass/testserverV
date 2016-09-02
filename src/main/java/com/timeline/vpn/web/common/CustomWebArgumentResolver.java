package com.timeline.vpn.web.common;

import javax.servlet.ServletRequest;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.MethodParameter;
import org.springframework.web.bind.support.WebDataBinderFactory;
import org.springframework.web.context.request.NativeWebRequest;
import org.springframework.web.method.support.HandlerMethodArgumentResolver;
import org.springframework.web.method.support.ModelAndViewContainer;

import com.timeline.vpn.exception.ParamException;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.web.common.annotation.UserInfo;
import com.timeline.vpn.web.common.annotation.UserInfoResolver;

/**
 * 通用参数解析
 * 
 * @author gqli
 */

public class CustomWebArgumentResolver implements HandlerMethodArgumentResolver {
    @Autowired
    private UserInfoResolver userInfoResolver;
    @Override
    public boolean supportsParameter(MethodParameter parameter) {
        return true;
    }

    @Override
    public Object resolveArgument(MethodParameter parameter, ModelAndViewContainer mavContainer,
            NativeWebRequest webRequest, WebDataBinderFactory binderFactory) throws Exception {
        if (parameter.getParameterAnnotation(UserInfo.class) != null) {
            BaseQuery baseQuery =
                    userInfoResolver.resolve((ServletRequest) webRequest.getNativeRequest(),
                            parameter.getParameterAnnotation(UserInfo.class).required()); // resolve
            if (parameter.getParameterAnnotation(UserInfo.class).appinfo() && baseQuery.getAppInfo()==null) {
                throw new ParamException();
            }
            return baseQuery;
        }
        return null;
    }
}
