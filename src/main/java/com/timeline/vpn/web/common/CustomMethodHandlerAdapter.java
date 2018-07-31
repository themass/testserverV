package com.timeline.vpn.web.common;

import java.util.List;

import javax.servlet.http.HttpServletRequest;

import org.springframework.web.bind.ServletRequestDataBinder;
import org.springframework.web.bind.support.WebBindingInitializer;
import org.springframework.web.context.request.NativeWebRequest;
import org.springframework.web.method.annotation.InitBinderDataBinderFactory;
import org.springframework.web.method.support.InvocableHandlerMethod;
import org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter;
import org.springframework.web.servlet.mvc.method.annotation.ServletRequestDataBinderFactory;

public class CustomMethodHandlerAdapter extends RequestMappingHandlerAdapter {


    @Override
    protected InitBinderDataBinderFactory createDataBinderFactory(
            List<InvocableHandlerMethod> binderMethods) throws Exception {
        return new ServletRequestDataBinderFactory(binderMethods, getWebBindingInitializer());
    }

    class MyServletRequestDataBinderFactory extends ServletRequestDataBinderFactory {

        public MyServletRequestDataBinderFactory(List<InvocableHandlerMethod> binderMethods,
                WebBindingInitializer initializer) {
            super(binderMethods, initializer);
        }

        @Override
        protected ServletRequestDataBinder createBinderInstance(Object target, String objectName,
                NativeWebRequest request) {
            ServletRequestDataBinder binder = new CustomServletRequestDataBinder(target, objectName,
                    (HttpServletRequest) request.getNativeRequest());
            // binder.setBindingErrorProcessor(new CustomBindingErrorProcessor((HttpServletRequest)
            // request.getNativeRequest()));
            return binder;
        }



    }

}
