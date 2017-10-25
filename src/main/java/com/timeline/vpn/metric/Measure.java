package com.timeline.vpn.metric;

/**
 * @author: yong.lin
 * @date: 2016-01-29  16:44
 */
public enum Measure {
    http,
    monitor,
    vpn_connect;
    public static Measure value(String value) {
        Measure[] measures = Measure.values();
        for (Measure measure : measures) {
            if (measure.name().equals(value)) {
                return measure;
            }
        }
        return null;
    }
}
