package com.timeline.vpn.web.common.resolver;

import java.lang.annotation.Annotation;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.MethodParameter;
import org.springframework.core.annotation.AnnotationUtils;
import org.springframework.validation.BindException;
import org.springframework.validation.Errors;
import org.springframework.web.bind.WebDataBinder;
import org.springframework.web.bind.support.WebDataBinderFactory;
import org.springframework.web.context.request.NativeWebRequest;
import org.springframework.web.method.support.HandlerMethodArgumentResolver;
import org.springframework.web.method.support.ModelAndViewContainer;

import com.timeline.vpn.util.JsonUtil;

/**
 * 通用参数解析
 *
 * @author gqli
 */

public class RequestFormParamArgumentResolver implements HandlerMethodArgumentResolver {
    private static final Logger LOGGER =
            LoggerFactory.getLogger(RequestFormParamArgumentResolver.class);
    @Override
    public boolean supportsParameter(MethodParameter parameter) {

        return parameter.getParameterAnnotation(RequestFormParam.class) != null;
    }

    @Override
    public Object resolveArgument(MethodParameter parameter, ModelAndViewContainer mavContainer,
            NativeWebRequest webRequest, WebDataBinderFactory binderFactory) throws Exception {
        RequestFormParam ann = parameter.getParameterAnnotation(RequestFormParam.class);
        
        String data = webRequest.getParameter(ann.key());
        Object form = JsonUtil.readValue(data, parameter.getParameterType());
        if (form == null) {
            if(ann.canNull()){
//                return null;
            }else{
                LOGGER.error("请求类型转换出错,data:{}", data);
                throw new FormInvalidException("totype:"+parameter.getParameterType()+"--data:"+data);
            }
        }
        if(form!=null && ann.invalide()&& form instanceof InvalidForm){
            ((InvalidForm)form).invalide();
        }
//        BeanPropertyBindingResult result = new BeanPropertyBindingResult(form,ann.key());
//        mavContainer.removeAttributes(result.getModel());
//        mavContainer.addAllAttributes(result.getModel());
        
        WebDataBinder binder = binderFactory.createBinder(webRequest, form, ann.key());
        if (binder.getTarget() != null) {
            validateIfApplicable(binder,parameter);
            if (binder.getBindingResult().hasErrors()) {
                if (isBindExceptionRequired(binder, parameter)) {
                    throw new BindException(binder.getBindingResult());
                }
            }
        }
        
        Map<String, Object> bindingResultModel = binder.getBindingResult().getModel();
        mavContainer.removeAttributes(bindingResultModel);
        mavContainer.addAllAttributes(bindingResultModel);

        return binder.getTarget();
    }
    protected void validateIfApplicable(WebDataBinder binder, MethodParameter parameter) {
        Annotation[] annotations = parameter.getParameterAnnotations();
        for (Annotation annot : annotations) {
            if (annot.annotationType().getSimpleName().startsWith("Valid")) {
                Object hints = AnnotationUtils.getValue(annot);
                binder.validate(hints instanceof Object[] ? (Object[]) hints : new Object[] {hints});
                break;
            }
        }
    }

    protected boolean isBindExceptionRequired(WebDataBinder binder, MethodParameter parameter) {
        int i = parameter.getParameterIndex();
        Class<?>[] paramTypes = parameter.getMethod().getParameterTypes();
        boolean hasBindingResult = (paramTypes.length > (i + 1) && Errors.class.isAssignableFrom(paramTypes[i + 1]));

        return !hasBindingResult;
    }

}
