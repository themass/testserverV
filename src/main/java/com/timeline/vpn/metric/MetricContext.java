package com.timeline.vpn.metric;

import java.io.InputStream;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.Properties;
import java.util.concurrent.TimeUnit;

import org.apache.commons.lang.StringUtils;
import org.influxdb.InfluxDB;
import org.influxdb.dto.BatchPoints;
import org.influxdb.dto.Point;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * @author: yong.lin
 * @date: 2016-02-03  11:04
 */
public class MetricContext {
    private static final Logger LOGGER = LoggerFactory.getLogger(MetricContext.class);
    private static String database;
    //刷新间隔改动次数
    private static final Integer DEFAULT_ACTIONS = 20000;
    //刷新间隔秒数
    private static final Integer DEFAULT_DURATION = 30;

    public static final String MONITOR = "monitor";
    public static final String WELL = "#";

    private static InfluxDB influxDB;

    static {
        Properties properties = new Properties();
        InputStream inputStream = null;
        try {
            inputStream = Metrics.class.getResourceAsStream("/conf/metrics.properties");
            if (inputStream != null) {
                properties.load(inputStream);
            }
            String metricUrl = properties.getProperty("metrics.url");
            String username = properties.getProperty("metrics.name");
            String password = properties.getProperty("metrics.passwd");
            database = properties.getProperty("metrics.database");
            influxDB = InfluxDBFactory.connect(metricUrl, username, password);
            influxDB.ping();
            influxDB.enableBatch(DEFAULT_ACTIONS, DEFAULT_DURATION, TimeUnit.SECONDS);
            LOGGER.info("Metrics init success");
        } catch (Exception e) {
            e.printStackTrace();
            influxDB=null;
            LOGGER.warn("Metrics init fail", e);
        } finally {
            try {
                if (inputStream != null) {
                    inputStream.close();
                }
            } catch (Exception e) {

            }
        }
    }


    public void count(String name, Integer count) {
        try {
            if (influxDB != null) {
                Point point = Point
                        .measurement(measurementName(name))
                        .tag("host", getHostName())
                        .tag("monitor_name", name)
                        .field("count", count)
                        .build();
                influxDB.write(database, null, point);
            }
        } catch (Exception e) {
            LOGGER.error("MetricContext count error name :{} count:{}", name, count, e);
            e.printStackTrace();
        }
    }

    public void time(String name, Long time) {
        try {
            if (influxDB != null) {
                Point point = Point
                        .measurement(measurementName(name))
                        .tag("host", getHostName())
                        .tag("monitor_name", name)
                        .field("used_time", time)
                        .field("count", 1)
                        .build();
                influxDB.write(database, null, point);
            }
        } catch (Exception e) {
            LOGGER.error("MetricContext count error name :{} count:{}", name, time, e);
            e.printStackTrace();
        }
    }

    public void time(String name, Long time, Integer status) {
        try {
            if (influxDB != null) {
                Point point = Point
                    .measurement(measurementName(name))
                    .tag("host", getHostName())
                    .tag("monitor_name", name)
                    .field("used_time", time)
                    .field("status", status)
                    .field("count", 1)
                    .build();
                influxDB.write(database, null, point);
            }
        } catch (Exception e) {
            LOGGER.error("MetricContext error name :{} time:{},status:{}", name, time,status, e);
            e.printStackTrace();
        }
    }


    public String measurementName(String name) {

        if (name.indexOf(WELL) != -1) {
            String measure = StringUtils.substringBefore(name, WELL);
            if (Measure.value(measure) != null) {
                return measure;
            }
        }
        return MONITOR;

    }
    public String getHostName(){
        try {  
            return (InetAddress.getLocalHost()).getHostName();  
        } catch (UnknownHostException uhe) {  
            String host = uhe.getMessage(); // host = "hostname: hostname"  
            if (host != null) {  
                int colon = host.indexOf(':');  
                if (colon > 0) {  
                    return host.substring(0, colon);  
                }  
            }  
            return "UnknownHost";  
        }  
    }
//    public String getHostAddress() throws SocketException {
//        if (StringUtils.isNotBlank(ip)) {
//            return ip;
//        }
//        Enumeration allNetInterfaces = NetworkInterface.getNetworkInterfaces();
//        InetAddress inetAddress;
//        while (allNetInterfaces.hasMoreElements()) {
//            NetworkInterface netInterface = (NetworkInterface) allNetInterfaces.nextElement();
//            Enumeration addresses = netInterface.getInetAddresses();
//            while (addresses.hasMoreElements()) {
//                inetAddress = (InetAddress) addresses.nextElement();
//                if (inetAddress != null && inetAddress instanceof Inet4Address) {
//                    ip = inetAddress.getHostAddress();
//                    return ip;
//                }
//            }
//        }
//        return null;
//    }

    public static void main(String[] args) {
        InfluxDB influxDB = org.influxdb.InfluxDBFactory.connect("http://172.30.19.94:8086", "folio", "qazxsw");

        BatchPoints batchPoints = BatchPoints.database("folio").build();

        for (int i = 20000; i < 30000; i++) {
            Point point = Point
                    .measurement("test")
                    .tag("type", "timer")
                    .time(System.currentTimeMillis(), TimeUnit.MILLISECONDS)
                    .tag("host", "1111")
                    .tag("monitor_name", "test112")
                    .field("used_time", "111")
                    .tag("i", i + "")
                    .build();
            batchPoints.point(point);
        }
        Long current = System.currentTimeMillis();
        influxDB.ping();
        influxDB.write(batchPoints);
        System.out.println(System.currentTimeMillis() - current);


    }

}
