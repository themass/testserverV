package com.timeline.vpn.web.common;

import org.springframework.core.convert.TypeDescriptor;
import org.springframework.format.support.DefaultFormattingConversionService;
import org.springframework.util.StringValueResolver;

/**
 * @author gqli
 * @date 2016年11月3日 下午9:10:46
 * @version V1.0
 */
public class MyFormattingConversionService extends DefaultFormattingConversionService {
    private static final String nullStr = "null";

    public MyFormattingConversionService() {
        this(null, true);
    }

    public MyFormattingConversionService(boolean registerDefaultFormatters) {
        this(null, registerDefaultFormatters);
    }

    public MyFormattingConversionService(StringValueResolver embeddedValueResolver,
            boolean registerDefaultFormatters) {
        super(embeddedValueResolver, registerDefaultFormatters);
    }

    @Override
    public <T> T convert(Object source, Class<T> targetType) {
        if (nullStr.equals(source))
            source = null;
        return super.convert(source, targetType);
    }

    @Override
    public Object convert(Object source, TypeDescriptor sourceType, TypeDescriptor targetType) {
        if (nullStr.equals(source))
            source = null;
        return super.convert(source, sourceType, targetType);
    }

    @Override
    public Object convert(Object source, TypeDescriptor targetType) {
        if (nullStr.equals(source))
            source = null;
        return super.convert(source, targetType);
    }

}

