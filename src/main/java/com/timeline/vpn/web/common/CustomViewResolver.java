package com.timeline.vpn.web.common;

import java.util.Locale;

import org.springframework.web.servlet.View;
import org.springframework.web.servlet.ViewResolver;


public class CustomViewResolver implements ViewResolver {
    private View jsonView;

    @Override
    public View resolveViewName(String viewName, Locale locale) throws Exception {
        return jsonView;
    }

    public void setJsonView(View jsonView) {
        this.jsonView = jsonView;
    }
}
