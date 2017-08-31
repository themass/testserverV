package com.timeline.vpn.service.impl;

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
    public static String getImageBaseUrl(String ip){
        if(HostCheck.isMyHost(ip)){
            return null;
        }
        if(ZhIpCache.isChinaIp(ip)){
            return FileIpCache.getHost(Constant.FileIpTYPE.IMG, Constant.FileIpExtra.ZH);
        }
        return FileIpCache.getHost(Constant.FileIpTYPE.IMG, Constant.FileIpExtra.OTHER);
    }
    public static String getFetchImageBaseUrl(String ip ,String url){
        if(HostCheck.isMyHost(ip)){
            return null;
        }
        return url;
    }
    public static String getBookBaseUrl(String ip){
        return FileIpCache.getHost(Constant.FileIpTYPE.BOOK, Constant.FileIpExtra.ALL);
    }
}

