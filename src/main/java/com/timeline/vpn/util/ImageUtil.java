package com.timeline.vpn.util;

/**
 * @author gqli
 * @date 2015年10月15日 下午3:17:05
 * @version V1.0
 */
public class ImageUtil {
    private static final String DEFAULT_SIZE = ".160x160.jpg";
    private static final String IMAGE_REG = "\\.[0-9]+x[0-9]+\\.jpg";

    public static String getImageUrl(String imageUrl) {
        if (imageUrl == null) {
            return imageUrl;
        }
        return imageUrl.replaceAll(IMAGE_REG, DEFAULT_SIZE);
    }
}

