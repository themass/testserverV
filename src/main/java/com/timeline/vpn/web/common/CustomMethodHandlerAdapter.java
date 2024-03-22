package com.timeline.vpn.web.common;

import java.util.List;

import javax.annotation.PostConstruct;
import javax.servlet.http.HttpServletRequest;

import com.timeline.vpn.web.common.resolver.BodyHandlerMethodArgumentResolver;
import com.timeline.vpn.web.common.response.FastJsonHttpMessageConverterEx;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.converter.json.MappingJackson2HttpMessageConverter;
import org.springframework.http.converter.support.AllEncompassingFormHttpMessageConverter;
import org.springframework.messaging.converter.MappingJackson2MessageConverter;
import org.springframework.web.bind.ServletRequestDataBinder;
import org.springframework.web.bind.support.WebBindingInitializer;
import org.springframework.web.context.request.NativeWebRequest;
import org.springframework.web.method.annotation.InitBinderDataBinderFactory;
import org.springframework.web.method.support.InvocableHandlerMethod;
import org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter;
import org.springframework.web.servlet.mvc.method.annotation.ServletRequestDataBinderFactory;

public class CustomMethodHandlerAdapter extends RequestMappingHandlerAdapter {

    @Autowired
    private FastJsonHttpMessageConverterEx fastJsonHttpMessageConverterEx;
    private static final Logger LOGGER =
            LoggerFactory.getLogger(CustomMethodHandlerAdapter.class);
    @Override
    protected InitBinderDataBinderFactory createDataBinderFactory(
            List<InvocableHandlerMethod> binderMethods) throws Exception {
        return new ServletRequestDataBinderFactory(binderMethods, getWebBindingInitializer());
    }
    @PostConstruct
    public void initConverters() {
        getMessageConverters().add(fastJsonHttpMessageConverterEx);
        getMessageConverters().add(new MappingJackson2HttpMessageConverter());
        LOGGER.info(getMessageConverters().toString());
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
