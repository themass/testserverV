package com.timeline.vpn.metric;


public enum Measure {
    http,
    monitor,
    ping_check,
    vpn_connect,
    vpn_connect_live_all;
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
