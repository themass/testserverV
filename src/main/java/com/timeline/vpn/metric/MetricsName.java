package com.timeline.vpn.metric;

/**
 * @author: yong.lin
 * @date: 2016-01-29  16:38
 */
public class MetricsName {


    public static final String HTTP_MEASURE_FORMAT = "http#%s";
    public static final String HTTP_MEASURE_ERROR_FORMAT = "http#%s_error";

    public static final String SERVICE_MEASURE_FORMAT = "service#%s";
    public static final String SERVICE_MEASURE_ERROR_FORMAT = "service#%s_error";


    public static String http(String name) {
       return String.format(HTTP_MEASURE_FORMAT, name);
    }

    public static String httpError(String name) {
        return String.format(HTTP_MEASURE_ERROR_FORMAT, name);
    }

    public static String service(String name) {
        return String.format(SERVICE_MEASURE_FORMAT, name);
    }

    public static String serviceError(String name) {
        return String.format(SERVICE_MEASURE_ERROR_FORMAT, name);
    }

}
