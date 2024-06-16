package com.timeline.vpn.web.common.resolver;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.format.support.FormattingConversionService;

import java.util.Arrays;
import java.util.List;

@Configuration
public class ConversionServiceConfiguration {

    @Bean
    public FormattingConversionService conversionServiceFactoryBean() {
        MyFormattingConversionService factoryBean = new MyFormattingConversionService();
        factoryBean.addConverter(stringToDateConverter());
        return factoryBean;
    }

    @Bean
    public StringToDateConverter stringToDateConverter() {
        StringToDateConverter converter = new StringToDateConverter();
        List<String> dateFormatPatterns = Arrays.asList(
            "yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd HH:mm", "yyyy-MM-dd HH",
            "yyyy-MM-dd", "yyyyMMdd", "yyyy/MM/dd HH:mm:ss", "yyyy/MM/dd HH:mm", "yyyy/MM/dd", "yyyy/MM/dd"
        );
        converter.setDateFormatPatterns(dateFormatPatterns);
        return converter;
    }

    // 如果需要，可以添加额外的配置方法来注册其他formatters和converters
}