package com.timeline.vpn.util;

import java.beans.BeanInfo;
import java.beans.Introspector;
import java.beans.PropertyDescriptor;
import java.lang.reflect.Method;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.google.common.base.Preconditions;
import com.google.common.collect.Maps;

public class BeanToMapUtil {

    public static final String CLASS = "class";
    private static Logger logger = LoggerFactory.getLogger(BeanToMapUtil.class);

    public static Map<String, String> toMap(Object obj) {
        Map<String, String> result = Maps.newHashMap();
        try {
            Preconditions.checkNotNull(obj, "参数不能为空");
            logger.info("BeanToMapUtil.toMap params : {}", JsonUtil.writeValueAsString(obj));

            Class clazz = obj.getClass();
            BeanInfo beanInfo;
            beanInfo = Introspector.getBeanInfo(clazz);
            PropertyDescriptor[] propertyDescriptors = beanInfo.getPropertyDescriptors();
            for (PropertyDescriptor propertyDescriptor : propertyDescriptors) {
                String propertyName = propertyDescriptor.getName();
                if (CLASS.equalsIgnoreCase(propertyName)) {
                    continue;
                }
                Method readMethod = propertyDescriptor.getReadMethod();
                Object readValue = readMethod.invoke(obj, new Object[0]);
                if (readValue == null) {
                    continue;
                }
                result.put(propertyName, readValue.toString());
            }
        } catch (Exception e) {
            e.printStackTrace();
            logger.error("映射失败:{}", obj, e);
        }

        return result;
    }


}
