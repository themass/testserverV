package com.timeline.vpn.util;

import java.util.ArrayList;
import java.util.List;

/**
 * @author gqli
 * @date 2015年8月26日 下午7:41:10
 * @version V1.0
 */
public class ArrayUtil<T> {
    public static <T> List<T> newZreoSizeArrayList(Class<T> t) {
        return new ArrayList<T>(0);
    }

    public static <T> List<T> newArrayList(Class<T> t) {
        return new ArrayList<T>();
    }

    public static <T> List<T> newArrayList(Class<T> t, int size) {
        return new ArrayList<T>(size);
    }
}

