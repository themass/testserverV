package com.timeline.vpn.util;

import org.springframework.util.StringUtils;

import com.timeline.vpn.model.po.IpLocalPo;

/**
 * @author gqli
 * @date 2017年4月14日 下午4:00:27
 * @version V1.0
 */
public class IpLocalUtilTaobao {
    public static final String IP_HOST="http://ip.taobao.com/service/getIpInfo.php?ip=%s";
    public static String getLocal(String ip){
        String url = String.format(IP_HOST, ip);
        String json = HttpCommonUtil.sendGet(url);
        if(!StringUtils.hasText(json)){
            return null;
        }
        IpLocalPo po = JsonUtil.readValue(json, IpLocalPo.class);
        if(po.getCode()==0&&po.getData()!=null){
            StringBuilder sb = new StringBuilder();
            sb.append(po.getData().getCountry());
            if(StringUtils.hasText(po.getData().getCity()))
                sb.append("-").append(po.getData().getCity());
            if(StringUtils.hasText(po.getData().getIsp()))
                sb.append("-").append(po.getData().getIsp());
            return sb.toString();
        }
        return null;
    }
}

