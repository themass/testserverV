package com.timeline.vpn.metric;

import com.google.common.collect.Lists;

import org.influxdb.dto.Point;

import java.util.List;

/**
 * @author: yong.lin
 * @date: 2016-01-28  19:30
 */
public class Metrics {


    private static final MetricContext metrics = new MetricContext();

    /**
     *
     *计数
     * @param name
     */
    public static void count(String name,Integer count,String hostName) {
        metrics.count( name, count,hostName);
    }
    /**
     *
     *计数
     * @param name
     */
    public static void count(String name,String hostName) {
        count(name,1,hostName);
    }
    /**
     * 执行时间
     *
     * @param name
     * @param time
     */
    public static void time(String name, Long time) {
        metrics.time(name,time);
    }

    /**
     * 执行时间
     *
     * @param name
     * @param time
     */
    public static void time(String name, Long time, Integer status) {
        metrics.time(name, time, status);
    }

    public static void main(String[] args) {
        List<Point> list= Lists.newArrayList();
        long total = Runtime.getRuntime().totalMemory(); // byte
        long m1 = Runtime.getRuntime().freeMemory();
        System.out.println("before:" + (total - m1));

        for (int i = 0; i < 10000; i++) {
            Point point = Point
                    .measurement("http")
                    .tag("host", "1111111111111")
                    .tag("monitor_name", "123456789012345678901234567890")
                    .field("count", 1)
                    .build();
            list.add(point);
        }
        long total1 = Runtime.getRuntime().totalMemory();
        long m2 = Runtime.getRuntime().freeMemory();
        System.out.println("after:" + (total1 - m2));
        System.out.println(list.size());
        System.out.println(Runtime.getRuntime().freeMemory());


    }
}
