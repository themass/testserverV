package com.timeline.vpn.util;

import java.io.UnsupportedEncodingException;
import java.net.URLDecoder;
import java.util.Enumeration;

import javax.servlet.http.HttpServletRequest;

import org.springframework.util.StringUtils;
import org.springframework.web.util.UrlPathHelper;
import org.springframework.web.util.WebUtils;

import com.timeline.vpn.Constant;

/**
 * @author gqli
 * @date 2016年6月27日 上午11:40:26
 * @version V1.0
 */
public class UrlUtil {
    private static final UrlPathHelper urlPathHelper = new UrlPathHelper();
    private static final String LOG_URL = "%s?%s ,cost:%s ,ua:%s";
    private static final String HEADER_URL = "%s?%s , header:[%s]";

    /**
     * 
     * @Description: 获取uri，不带参数
     * @param request
     * @return
     */
    public static String getRequestUri(HttpServletRequest request) {
        return urlPathHelper.getRequestUri(request);
    }

    /**
     * 
     * @Description: 获取uri？param
     * @param request
     * @return
     */
    public static String getFullRequestUri(HttpServletRequest request) {
        return urlPathHelper.getRequestUri(request) + "?" + getQueryString(request);
    }

    /**
     * 
     * @Description: url + "%s?%s ,city:%s ,code:%s ,ua:%s ,devId:%s ,cost:%s ";
     * @param request
     * @return
     */

    public static String getFullRequestUriForLog(HttpServletRequest request, Long costTime) {
        return String.format(LOG_URL, request.getRequestURI(), getQueryString(request), costTime,
                request.getHeader(Constant.HTTP_UA));
    }

    public static String getQueryString(HttpServletRequest request) {
        String param = null;
        try {
            param = StringUtils.hasText(request.getQueryString())
                    ? URLDecoder.decode(request.getQueryString(), "utf-8") : null;
        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
        }
        return param;
    }

    /**
     * 
     * @Description: 获取url？param，全路径，
     * @param request
     * @return
     */
    public static String getFullRequestUrl(HttpServletRequest request) {
        return request.getRequestURL() + "?" + getQueryString(request);
    }

    /**
     * 
     * @Description: 获取url，全路径，
     * @param request
     * @return
     */
    public static String getRequestUrl(HttpServletRequest request) {
        return request.getRequestURL().toString();
    }

    public static String getFullRequestUriWithHeader(HttpServletRequest request) {
        Enumeration<String> e = request.getHeaderNames();
        StringBuilder header = new StringBuilder(" header:");
        while (e.hasMoreElements()) {
            String name = e.nextElement();
            header.append(",").append(name).append("=").append(request.getHeader(name));
        }
        return String.format(HEADER_URL, urlPathHelper.getRequestUri(request),
                getQueryString(request), header.toString());
    }

    public static String getUa(HttpServletRequest request) {
        return request.getHeader(Constant.HTTP_UA);
    }

    @SuppressWarnings("deprecation")
    public static boolean isJsonRequest(HttpServletRequest request) {
        String filename = WebUtils.extractFullFilenameFromUrlPath(getRequestUri(request));
        String extension = StringUtils.getFilenameExtension(filename);
        // 后缀为json或为空时，表示是ajax请求
        return "json".equals(extension) || org.apache.commons.lang.StringUtils.isBlank(extension);
    }

    public static String getIpAddr(HttpServletRequest request) {
        String ip = request.getHeader("x-forwarded-for");
        if (!StringUtils.isEmpty(ip) && !"unknown".equalsIgnoreCase(ip)) {
            // 多次反向代理后会有多个IP值，第一个为真实IP。
            int index = ip.indexOf(',');
            if (index != -1) {
                return ip.substring(0, index);
            } else {
                return ip;
            }
        } else {
            return request.getRemoteAddr();
        }
    }
}

