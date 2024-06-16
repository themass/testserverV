package vpn.util;

import com.timeline.vpn.Constant;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.param.DevApp;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

import javax.servlet.http.HttpServletRequest;
import java.text.DecimalFormat;
import java.util.Date;
import java.util.Locale;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

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
    private static final String VPNVERSION = "(VVV|LIFE|SEX|SEX_TEMP|NETHELP)/(([0-9]+)\\.([0-9]+)\\.([0-9]+)\\.([0-9]+))";
    private static final String VPNVERSION_VPN_POOL = ",channel=(MYPOOL),";
    private static final String VPNVERSION_NETTYPE= ",NETTYPE=(NETTYPEA|VVVB|VVVC|VVVD|SEXPLAY),";
    private static final String DEVID = "devid";
    private static final int VERSION_COUNT = 4;
    private static final String HTTP_HOST= "Host";
    private static final Pattern pattern = Pattern.compile(VPNVERSION);
    private static final Pattern pattern_pool = Pattern.compile(VPNVERSION_VPN_POOL);
    private static final Pattern pattern_netType = Pattern.compile(VPNVERSION_NETTYPE);
    private static final String VERSION = "([0-9]+)\\.([0-9]+)\\.([0-9]+)\\.([0-9]+)";
    private static final Pattern versionPattern = Pattern.compile(VERSION);
    private static final String LOC = "loc";
    public static String getPlatForm(HttpServletRequest webRequest) {
        String ua = HttpCommonUtil.getUA(webRequest.getHeader(Constant.HTTP_UA));
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
        String ua = HttpCommonUtil.getUA(webRequest.getHeader(Constant.HTTP_UA));
        String devId = webRequest.getHeader(DEVID);
        String language = webRequest.getHeader(Constant.LANG);
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
                app.setLang(language);
                app.setAuthKey(auth);
              //TODO 暂时注释;
                app.setSign(timeSign.substring(len, timeSign.length()));
                app.setTime(Long.parseLong(timeSign.substring(0, len)));
                app.setHost(webRequest.getHeader(HTTP_HOST));
                app.setUserIp(UrlUtil.getIpAddr(webRequest));
                if(app.getUserIp()==null) {
                    app.setUserIp("");
                }
                if(Constant.VPN.equals((matcher.group(1)))){
                    app.setTokenHeader(Constant.HTTP_TOKEN_KEY);
                    app.setChannel(Constant.VPN);
                }else if(Constant.LIFE.equals(matcher.group(1))){
                    app.setTokenHeader(Constant.HTTP_TOKEN_LIFE_KEY);
                    app.setChannel(Constant.LIFE);
                }else if(Constant.SEX.equals(matcher.group(1))){
                    app.setTokenHeader(Constant.HTTP_TOKEN_SEX_KEY);
                    app.setChannel(Constant.SEX);
                }else if(Constant.SEX_TEMP.equals(matcher.group(1))){
                    app.setTokenHeader(Constant.HTTP_TOKEN_SEX_KEY);
                    app.setChannel(Constant.SEX_TEMP);
                }else{
                    return null;
                }
                Matcher matcherPool = pattern_pool.matcher(ua);
                if (matcherPool.find()) {
                    app.setPool(matcherPool.group(1));
                }
                Matcher matcherNetType = pattern_netType.matcher(ua);
                if (matcherNetType.find()) {
                  app.setNetType(matcherNetType.group(1));
                }else {
                  app.setNetType("");

                }
                parsLoc(webRequest,app);
                app.setUa(ua);
                return app;
            }

        }
        LOGGER.error("ua或者版本不对，有可能抓取数据:{}", HttpCommonUtil.getHeaderStr(webRequest));
        return null;
    }
    public static void parsLoc(HttpServletRequest webRequest,DevApp app){
        String loc = webRequest.getHeader(LOC);
        if(StringUtils.hasLength(loc)){
            String[]locas = loc.split(Constant.fen);
            if(locas.length==2){
                String[]lon = locas[0].split(Constant.mao);
                String[]lat = locas[1].split(Constant.mao);
                app.setLat(lat[1]);
                app.setLon(lon[1]);
            }
        }
    }

    public static Locale getLocale(HttpServletRequest webRequest) {
      String language = webRequest.getHeader(Constant.LANG);
        if(StringUtils.isEmpty(language)) {
          return Locale.getDefault();
        }
        try {
          return new Locale(language);
        }catch (Exception e) {
          return Locale.getDefault();
        }
    }
    public static Locale getLocale(String language) {
      if(StringUtils.isEmpty(language)) {
        return Locale.getDefault();
      }
      try {
        return new Locale(language);
      }catch (Exception e) {
        return Locale.getDefault();
      }
  }
    public static boolean isAdmin(BaseQuery baseQuery) {
      return baseQuery.getUser()!=null&&Constant.ADMIN_NAME.equals(baseQuery.getUser().getName());
    }
}
