package com.timeline.vpn.util;

import java.util.regex.Pattern;

import org.apache.commons.lang3.RandomUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.util.StringUtils;

import com.timeline.vpn.Constant;
import com.timeline.vpn.exception.LoginException;
import com.timeline.vpn.exception.ParamException;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.param.DevApp;
import com.timeline.vpn.service.impl.HostServerImpl;

/**
 * @author gqli
 * @date 2015年12月15日 下午1:04:57
 * @version V1.0
 */
public class CommonUtil {
    private static final Logger LOGGER =
            LoggerFactory.getLogger(CommonUtil.class);
    private static final int CODE_START = 1000;
    private static final int CODE_END = 9999;
    private static final Pattern pattern = Pattern.compile("[0-9A-Za-z]*");
    public static String generateCode() {
        return String.valueOf(RandomUtils.nextInt(CODE_START, CODE_END));
    }
    public static boolean isNumAndEnglish(String str){
        return pattern.matcher(str).matches();
    }
    public static boolean isDog(BaseQuery baseQuery) {
        if((baseQuery.getUser()!=null && Constant.userNodog.contains(baseQuery.getUser().getName())) 
                || Constant.userNodogDiv.contains(baseQuery.getAppInfo().getDevId())) {
            if(Constant.VPN.equals(baseQuery.getAppInfo().getNetType()) || 
                    (Constant.VPNC.equals(baseQuery.getAppInfo().getNetType()) && Integer.valueOf(baseQuery.getAppInfo().getVersion())<1000008025)) {
                throw new LoginException(Constant.ResultMsg.RESULT_VERSION_ERROR);
            }else if(StringUtils.isEmpty(baseQuery.getAppInfo().getNetType())) {
                throw new ParamException(Constant.ResultMsg.RESULT_DENGTA_ERROR);
            }
        }
        return false;
    }
    public static boolean isWhite(BaseQuery baseQuery) {
        if(Constant.VPN.equals(baseQuery.getAppInfo().getNetType()) || 
                Constant.VPNC.equals(baseQuery.getAppInfo().getNetType())) {
            LOGGER.error("user--isWhite--"+baseQuery.getUser());

            if(baseQuery.getUser()!=null && baseQuery.getUser().getLevel()>1) {
                return true;
            }else {
                LOGGER.error("user--isWhite-- 抛异常了");
                throw new LoginException(Constant.ResultMsg.RESULT_PERM_ERROR);
            }
        }
        return true;
    }
    
    public static boolean isDog(DevApp appInfo,String name) {
        if(Constant.userNodog.contains(name) 
                || Constant.userNodogDiv.contains(appInfo.getDevId())) {
            return true;
        }
        return false;
    }
}

