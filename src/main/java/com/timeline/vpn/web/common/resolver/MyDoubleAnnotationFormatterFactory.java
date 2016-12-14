package com.timeline.vpn.web.common.resolver;

import java.text.NumberFormat;
import java.text.ParseException;
import java.util.Collections;
import java.util.HashSet;
import java.util.Locale;
import java.util.Set;

import org.springframework.context.EmbeddedValueResolverAware;
import org.springframework.format.AnnotationFormatterFactory;
import org.springframework.format.Formatter;
import org.springframework.format.Parser;
import org.springframework.format.Printer;
import org.springframework.format.number.NumberFormatter;
import org.springframework.util.StringUtils;
import org.springframework.util.StringValueResolver;

/**
 * @Description: MyDoubleFormat 解析类
 * @author gqli
 * @date 2016年10月12日 下午12:55:08
 * @version V1.0
 */
public class MyDoubleAnnotationFormatterFactory implements AnnotationFormatterFactory<MyDoubleFormat>, EmbeddedValueResolverAware {

    private final Set<Class<?>> fieldTypes;

    private StringValueResolver embeddedValueResolver;


    public MyDoubleAnnotationFormatterFactory() {
        Set<Class<?>> rawFieldTypes = new HashSet<Class<?>>(7);
        rawFieldTypes.add(Double.class);
        this.fieldTypes = Collections.unmodifiableSet(rawFieldTypes);
    }

    @Override
    public final Set<Class<?>> getFieldTypes() {
        return this.fieldTypes;
    }


    @Override
    public void setEmbeddedValueResolver(StringValueResolver resolver) {
        this.embeddedValueResolver = resolver;
    }

    protected String resolveEmbeddedValue(String value) {
        return (this.embeddedValueResolver != null ? this.embeddedValueResolver.resolveStringValue(value) : value);
    }


    @Override
    public Printer<Number> getPrinter(MyDoubleFormat annotation, Class<?> fieldType) {
        return configureFormatterFrom(annotation);
    }

    @Override
    public Parser<Number> getParser(MyDoubleFormat annotation, Class<?> fieldType) {
        return configureFormatterFrom(annotation);
    }


    private Formatter<Number> configureFormatterFrom(MyDoubleFormat annotation) {
        if (StringUtils.hasLength(annotation.pattern())) {
            return new MyNumberFormatter(resolveEmbeddedValue(annotation.pattern()));
        }
        return new MyNumberFormatter();
    }
    class MyNumberFormatter extends NumberFormatter{
        public MyNumberFormatter(String pattern){
            super(pattern);
        }
        public MyNumberFormatter(){}
        @Override
        public Number parse(String text, Locale locale) throws ParseException {
            NumberFormat format = getNumberFormat(locale);
            double d = Double.parseDouble(text);
            String s = format.format(d);
            return Double.parseDouble(s);
        }
        
    }

}
