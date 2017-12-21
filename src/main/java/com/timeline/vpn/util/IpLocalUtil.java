package com.timeline.vpn.util;

import org.springframework.util.StringUtils;

import com.timeline.vpn.model.po.IpLocalPo;

/**
 * @author gqli
 * @date 2017年4月14日 下午4:00:27
 * @version V1.0
 */
public class IpLocalUtil {
    public static final String IP_HOST="http://ip.taobao.com/service/getIpInfo.php?ip=%s";
    public static String getLocal(String ip){
        String url = String.format(IP_HOST, ip);
        String json = HttpCommonUtil.sendGet(url);
        if(!StringUtils.hasText(json)){
            return null;
        }
        IpLocalPo po = JsonUtil.readValue(json, IpLocalPo.class);
        if(po.getCode()==0){
            return po.getData().getCountry()+"-"+po.getData().getRegion();
        }
        return null;
    }
    
    
    public static void main(String[]args){
        System.out.println(getLocal("112.74.58.248"));
    }

}

