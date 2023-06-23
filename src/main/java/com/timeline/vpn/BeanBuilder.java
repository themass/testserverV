package com.timeline.vpn;

import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

import org.springframework.util.CollectionUtils;

import com.google.common.base.Function;
import com.google.common.collect.ArrayListMultimap;
import com.google.common.collect.Maps;
import com.google.common.collect.Multimap;

/**
 * @author gqli
 * @date 2015年12月15日 下午7:19:23
 * @version V1.0
 */
public class BeanBuilder {
    public static <M, I> Map<M, I> buildSimpleMap(Collection<I> list, Function<I, M> function) {
        if (CollectionUtils.isEmpty(list)) {
            return Maps.newHashMap();
        }
        Map<M, I> retMap = Maps.newHashMap();
        for (I item : list) {
            retMap.put(function.apply(item), item);
        }
        return retMap;
    }
    public static <M,I> Map<M, Collection<I>> buildMultimap(
            Collection<I> list, Function<I, M> function) {
        if (CollectionUtils.isEmpty(list)) {
            return new TreeMap<>();
        }

        Multimap<M, I> multiMap = ArrayListMultimap.create();
        for (I item : list) {
            multiMap.put(function.apply(item), item);
        }
        return multiMap.asMap();
    }
}

