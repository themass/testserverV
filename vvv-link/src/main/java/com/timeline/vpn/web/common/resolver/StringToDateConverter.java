package com.timeline.vpn.web.common.resolver;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.convert.converter.Converter;
import org.springframework.util.StringUtils;

import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;

public class StringToDateConverter implements Converter<String, Date> {

    private static final Logger LOGGER = LoggerFactory.getLogger(StringToDateConverter.class);
    private List<String> dateFormatPatterns;

    @Override
    public Date convert(String source) {
        if (!StringUtils.hasLength(source)) {
            return null;
        }
        for (String pattern : dateFormatPatterns) {
            try {
                DateFormat df = new SimpleDateFormat(pattern);
                // ②转换成功
                return df.parse(source);
            } catch (ParseException e) {
                // ③转化失败
                continue;
            }
        }
        LOGGER.error(String.format("类型转换失败，格式是[%s]", source));
        throw new IllegalArgumentException(String.format("类型转换失败，格式是[%s]", source));
    }

    public List<String> getDateFormatPatterns() {
        return dateFormatPatterns;
    }

    public void setDateFormatPatterns(List<String> dateFormatPatterns) {
        this.dateFormatPatterns = dateFormatPatterns;
    }

}
