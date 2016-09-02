package com.timeline.vpn.util;

import org.apache.commons.codec.binary.Base64;
import org.apache.commons.lang.math.RandomUtils;

/**
 * @author gqli
 * @date 2015年7月24日 上午9:57:34
 * @version V1.0
 */
public class AuthUtil {
    private static final long MIN1 = 10000000000000000L;
    private static final long MAX1 = 99999999999999999L;
    private static final long MIN2 = 100000L;
    private static final long MAX2 = 999999L;
    private static final String ACCESS_KEY = "vpn@@server";

    public static byte[] xorEncode(byte[] data, byte[] key) {
        byte[] encode = new byte[data.length];
        for (int i = 0; i < data.length; i++) {
            encode[i] = (byte) (data[i] ^ key[i % key.length]);
        }
        return encode;
    }

    public static byte[] xorEncodeKDK(byte[] data, byte[] key) {
        byte[] encode = new byte[data.length * 2];
        int index = 0;
        for (int i = 0; i < data.length; i++) {
            encode[index++] = key[i % key.length];
            encode[index++] = (byte) (data[i] ^ key[i % key.length]);
        }
        return encode;
    }

    public static byte[] xorDecodeKDK(byte[] data) {
        byte[] decode = new byte[data.length / 2];
        int index = 0;
        for (int i = 0; i < decode.length; i++) {
            byte md5 = data[index++];
            decode[i] = (byte) (data[index++] ^ md5);
        }
        return decode;
    }

    public static String nameToToken(String name) {
        long md5Pre = RandomUtils.nextLong() % (MAX1 - MIN1 + 1) + MIN1;
        long md5end = RandomUtils.nextLong() % (MAX2 - MIN2 + 1) + MIN2;
        String md5Str = (Long.parseLong(DateTimeUtils.getCurrentTime()) + md5Pre) + "" + md5end;
        String oneStepkey = Md5.encode(md5Str);
        byte[] oneStep = xorEncodeKDK(name.getBytes(), oneStepkey.getBytes());
        String twoStepKey = Md5.encode(ACCESS_KEY);
        return Base64.encodeBase64String(
                new String(xorEncode(oneStep, twoStepKey.getBytes())).getBytes());
    }

    public static String tokenToName(String token) {
        try {
            if (token != null) {
                String key = Md5.encode(ACCESS_KEY);
                byte[] oneStep = xorEncode(Base64.decodeBase64(token), key.getBytes());
                return new String(xorDecodeKDK(oneStep));
            }
        } catch (NumberFormatException e) {
            return null;
        }
        return null;
    }
}

