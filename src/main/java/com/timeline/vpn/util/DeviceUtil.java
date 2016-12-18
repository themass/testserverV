package com.timeline.vpn.util;

import java.text.DecimalFormat;
import java.util.Date;
import java.util.Locale;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import javax.servlet.http.HttpServletRequest;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import com.timeline.vpn.Constant;
import com.timeline.vpn.model.param.DevApp;

/**
 *
 * @author gqli
 * @date 2015年8月19日 上午10:10:14
 * @version V1.0
 */
@Component
public class DeviceUtil {
    private static final Logger LOGGER =
            LoggerFactory.getLogger(DeviceUtil.class);
    public static final String ANDROID = "android";
    public static final String IOS = "ios";
    private static final String FORMAT = "000";
    private static final String VPNVERSION = "(VPN/)(([0-9]+)\\.([0-9]+)\\.([0-9]+)\\.([0-9]+))";
    private static final String DEVID = "devid";
    private static final int VERSION_COUNT = 4;
    private static final String HTTP_UA = "user-agent";
    private static final String HTTP_HOST= "Host";
    private static final Pattern pattern = Pattern.compile(VPNVERSION);
    private static final String VERSION = "([0-9]+)\\.([0-9]+)\\.([0-9]+)\\.([0-9]+)";
    private static final Pattern versionPattern = Pattern.compile(VERSION);
    public static String getPlatForm(HttpServletRequest webRequest) {
        String ua = webRequest.getHeader(HTTP_UA);
        if (ua != null) {
            if (ua.toLowerCase().contains(ANDROID)) {
                return ANDROID;
            } else if (ua.toLowerCase().contains(IOS)) {
                return IOS;
            }
        }
        return null;
    }

    /**
     * 
     * @Description: 从ua中获取版本号
     * @param
     * @return
     */
    public static String getAppVersion(String version) {
        Matcher matcher = versionPattern.matcher(version);
        if (matcher.find()) {
            StringBuilder sb = new StringBuilder();
            DecimalFormat df = new DecimalFormat(FORMAT);
            for (int i = 1; i <= VERSION_COUNT; i++) {
                sb.append(df.format(Integer.parseInt(matcher.group(i))));
            }
            return sb.toString();
        }
        return null;
    }

    public static DevApp getAPPInfo(HttpServletRequest webRequest) {
        String ua = webRequest.getHeader(HTTP_UA);
        String devId = webRequest.getHeader(DEVID);
        if (ua != null) {
            Matcher matcher = pattern.matcher(ua);
            if (matcher.find()) {
                String versionName = matcher.group(2);
                DevApp app = new DevApp(devId, webRequest.getRemoteAddr(), versionName,
                        getAppVersion(versionName), getPlatForm(webRequest));
                String timeSign = ua.substring(ua.lastIndexOf(",IE") + 3, ua.length());
                long now = new Date().getTime();
                int len = String.valueOf(now).length();
                String auth = ua.substring(ua.length()-16,ua.length());
                app.setAuthKey(auth);
              //TODO 暂时注释;
                app.setSign(timeSign.substring(len, timeSign.length()));
                app.setTime(Long.parseLong(timeSign.substring(0, len)));
                app.setHost(webRequest.getHeader(HTTP_HOST));
                return app;
            }

        }
        LOGGER.error("ua或者版本不多，有可能抓取数据:{}", ua);
        return null;
    }

    public static Locale getLocale(HttpServletRequest webRequest) {
        String language = webRequest.getHeader(Constant.LANG);
        return new Locale(language);
    }
}
