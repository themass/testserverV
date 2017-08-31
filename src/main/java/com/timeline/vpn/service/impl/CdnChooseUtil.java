package com.timeline.vpn.service.impl;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.timeline.vpn.Constant;
import com.timeline.vpn.service.job.reload.FileIpCache;
import com.timeline.vpn.service.job.reload.HostCheck;
import com.timeline.vpn.service.job.reload.ZhIpCache;

/**
 * @author gqli
 * @date 2017年8月31日 下午2:24:11
 * @version V1.0
 */
public class CdnChooseUtil {
    private static final Logger LOGGER = LoggerFactory.getLogger(CdnChooseUtil.class);
    public static String getImageBaseUrl(String ip){
        if(HostCheck.isMyHost(ip)){
            LOGGER.info("cdn : ip={},vpn已连接",ip);
            return null;
        }
        if(ZhIpCache.isChinaIp(ip)){
            LOGGER.info("cdn : ip={},中国ip",ip);
            return FileIpCache.getHost(Constant.FileIpTYPE.IMG, Constant.FileIpExtra.ZH);
        }
        LOGGER.info("cdn : ip={},国外ip",ip);
        return FileIpCache.getHost(Constant.FileIpTYPE.IMG, Constant.FileIpExtra.OTHER);
    }
    public static String getFetchImageBaseUrl(String ip ,String url){
        if(HostCheck.isMyHost(ip)){
            LOGGER.info("cdn : ip={},vpn已连接",ip);
            return null;
        }
        LOGGER.info("cdn : ip={},没有连接vpn",ip);
        return url;
    }
    public static String getBookBaseUrl(String ip){
        return FileIpCache.getHost(Constant.FileIpTYPE.BOOK, Constant.FileIpExtra.ALL);
    }
}

