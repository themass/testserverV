package com.timeline.vpn.metric;


import org.influxdb.dto.BatchPoints;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;


public class InfluxDBImpl extends org.influxdb.impl.InfluxDBImpl {

    private static final Logger LOGGER = LoggerFactory.getLogger(InfluxDBImpl.class);
    ThreadPoolExecutor executor = new ThreadPoolExecutor(1, 2, 1L, TimeUnit.MINUTES,
            new LinkedBlockingQueue<Runnable>(10), new ThreadPoolExecutor.DiscardPolicy());

    /**
     * Constructor which should only be used from the InfluxDBFactory.
     *
     * @param url      the url where the influxdb is accessible.
     * @param username the user to connect.
     * @param password
     */
    public InfluxDBImpl(String url, String username, String password) {
        super(url, username, password);
    }

    @Override
    public void write(final BatchPoints batchPoints) {

        executor.execute(new Runnable() {
            @Override
            public void run() {
                try {
                    int size = batchPoints.getPoints().size();
                    Long current = System.currentTimeMillis();
                    InfluxDBImpl.super.write(batchPoints);
                    LOGGER.info("write cost:{} size:{}", System.currentTimeMillis() - current, size);
                } catch (Exception e) {
                    e.printStackTrace();
                    LOGGER.warn("write error", e);
                }
            }
        });

    }
}
