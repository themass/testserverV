package com.timeline.vpn.web.common.resolver;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.MethodParameter;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.support.WebDataBinderFactory;
import org.springframework.web.context.request.NativeWebRequest;
import org.springframework.web.method.support.HandlerMethodArgumentResolver;
import org.springframework.web.method.support.ModelAndViewContainer;
import org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter;
import org.springframework.web.servlet.mvc.method.annotation.RequestResponseBodyMethodProcessor;
import org.springframework.web.servlet.mvc.method.annotation.ServletModelAttributeMethodProcessor;

import javax.annotation.PostConstruct;
import javax.servlet.http.HttpServletRequest;
import java.util.List;

/**
 * 自定义参数解析器
 *
 * 注: 自定义参数解析器, 实现对RequestResponseBodyMethodProcessor的扩展
 *
 * 提示: 此解析器要实现的功能是: 若controller方法的参数前, 使用了@RequestBody注解, 那么解析此参数时，
 *                           1、若Content-Type为application/x-www-form-urlencoded，
 *                              那么走ServletModelAttributeMethodProcessor解析器
 *                           2、若Content-Type不为application/x-www-form-urlencoded，
 *                              那么走本应该走的RequestResponseBodyMethodProcessor解析器
 *
 * @author JustryDeng
 * @date 2019/8/19 19:47
 */
public class BodyHandlerMethodArgumentResolver implements HandlerMethodArgumentResolver {

    private static final Logger LOGGER =
            LoggerFactory.getLogger(BodyHandlerMethodArgumentResolver.class);
    /**
     * 解析Content-Type为application/json的默认解析器是RequestResponseBodyMethodProcessor
     */
    private RequestResponseBodyMethodProcessor requestResponseBodyMethodProcessor;
 
    /**
     * 解析Content-Type为application/x-www-form-urlencoded的默认解析器是ServletModelAttributeMethodProcessor
     */
    private ServletModelAttributeMethodProcessor servletModelAttributeMethodProcessor;
    @Autowired
    private RequestMappingHandlerAdapter requestMappingHandlerAdapter;

    /**
     * 全参构造
     */
    public BodyHandlerMethodArgumentResolver(){
    }
    @PostConstruct
    private void addArgumentResolvers() {
        // 获取到的是不可变的集合
        List<HandlerMethodArgumentResolver> argumentResolvers =
                requestMappingHandlerAdapter.getArgumentResolvers();
        LOGGER.info(argumentResolvers.toString());
        for (HandlerMethodArgumentResolver argumentResolver : argumentResolvers) {
            if (requestResponseBodyMethodProcessor != null && servletModelAttributeMethodProcessor != null) {
                break;
            }
            if (argumentResolver instanceof RequestResponseBodyMethodProcessor) {
                requestResponseBodyMethodProcessor = (RequestResponseBodyMethodProcessor) argumentResolver;

                continue;
            }
            if (argumentResolver instanceof ServletModelAttributeMethodProcessor) {
                servletModelAttributeMethodProcessor = (ServletModelAttributeMethodProcessor) argumentResolver;
            }

        }
    }
    /**
     * 当参数前有@RequestBody注解时， 解析该参数 会使用此 解析器
     *
     * 注:此方法的返回值将决定:是否使用此解析器解析该参数
     */
    @Override
    public boolean supportsParameter(MethodParameter methodParameter) {
        return methodParameter.hasParameterAnnotation(RequestBody.class);
    }
 
    /**
     * 解析参数
     */
    @Override
    public Object resolveArgument(MethodParameter methodParameter, ModelAndViewContainer modelAndViewContainer,
                                  NativeWebRequest nativeWebRequest, WebDataBinderFactory webDataBinderFactory)
                                  throws Exception {
        final String applicationXwwwFormUrlencoded = "application/x-www-form-urlencoded";
        HttpServletRequest request = nativeWebRequest.getNativeRequest(HttpServletRequest.class);
 
        if (request == null) {
            throw  new RuntimeException(" request must not be null!");
        }
        String contentType = request.getContentType();
        /*
         * 如果ContentType是application/x-www-form-urlencoded，那么使用ServletModelAttributeMethodProcessor解析器
         *
         * 注:其实默认的，当系统识别到参数前有@RequestBody注解时，就会走RequestResponseBodyMethodProcessor解析器;这里就
         *    相当于在走默认的解析器前走了个判断而已。
         */
        if (applicationXwwwFormUrlencoded.equals(contentType)) {
            return servletModelAttributeMethodProcessor.resolveArgument(methodParameter,
                    modelAndViewContainer, nativeWebRequest, webDataBinderFactory);
        }
        return requestResponseBodyMethodProcessor.resolveArgument(methodParameter,
                    modelAndViewContainer, nativeWebRequest, webDataBinderFactory);
    }
}