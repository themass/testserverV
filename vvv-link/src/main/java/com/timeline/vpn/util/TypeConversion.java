package com.timeline.vpn.util;

import org.springframework.web.util.HtmlUtils;

/** 
 * @Package: 
 * @ClassName:TypeConversion 
 * @Description:字节流、字符串、16进制字符串转换 
 * @author:xk 
 * @date:Jan 8, 2013 5:00:08 PM 
 */
public class TypeConversion {

    /** 
     * @Title:bytes2HexString 
     * @Description:字节数组转16进制字符串 
     * @param b 
     *            字节数组 
     * @return 16进制字符串 
     * @throws 
     */

    public static String str2HexStr(byte[] bs) {
        char[] chars = "0123456789abcdef".toCharArray();
        StringBuilder sb = new StringBuilder("");
        int bit;
        for (int i = 0; i < bs.length; i++) {
            bit = (bs[i] & 0x0f0) >> 4;
            sb.append(chars[bit]);
            bit = bs[i] & 0x0f;
            sb.append(chars[bit]);
        }
        return sb.toString();
    }

    /** 
     * @Title:hexString2Bytes 
     * @Description:16进制字符串转字节数组 
     * @param src 
     *            16进制字符串 
     * @return 字节数组 
     * @throws 
     */
    public static byte[] hexString2Bytes(String src) {
        int l = src.length() / 2;
        byte[] ret = new byte[l];
        for (int i = 0; i < l; i++) {
            ret[i] = Integer.valueOf(src.substring(i * 2, i * 2 + 2), 16).byteValue();
        }
        return ret;
    }

    /** 
     * @Title:string2HexString 
     * @Description:字符串转16进制字符串 
     * @param strPart 
     *            字符串 
     * @return 16进制字符串 
     * @throws 
     */
    public static String string2HexString(String strPart) {
        StringBuilder hexString = new StringBuilder();
        for (int i = 0; i < strPart.length(); i++) {
            int ch = (int) strPart.charAt(i);
            String strHex = Integer.toHexString(ch);
            hexString.append(strHex);
        }
        return hexString.toString();
    }

    /** 
     * @Title:hexString2String 
     * @Description:16进制字符串转字符串 
     * @param src 
     *            16进制字符串 
     * @return 字节数组 
     * @throws 
     */
    public static String hexString2String(String src) {
        String temp = "";
        for (int i = 0; i < src.length() / 2; i++) {
            temp = temp + (char) Integer.valueOf(src.substring(i * 2, i * 2 + 2), 16).byteValue();
        }
        return temp;
    }

    /** 
     * @Title:char2Byte 
     * @Description:字符转成字节数据char-->integer-->byte 
     * @param src 
     * @return 
     * @throws 
     */
    public static Byte char2Byte(Integer src) {
        return src.byteValue();
    }

    /** 
    * @Title:intToHexString 
    * @Description:10进制数字转成16进制 
    * @param a 转化数据 
    * @param len 占用字节数 
    * @return 
    * @throws 
    */
    @SuppressWarnings("unused")
    private static String intToHexString(int a, int len) {
        len <<= 1;
        String hexString = Integer.toHexString(a);
        int b = len - hexString.length();
        if (b > 0) {
            for (int i = 0; i < b; i++) {
                hexString = "0" + hexString;
            }
        }
        return hexString;
    }

    public static Boolean integerToBoolean(Integer i) {
        return i == null ? null : (i != 0);
    }

    public static Boolean strToBoolean(String i) {
        return i == null ? null : (!"0".equals(i));
    }
    public static String htmlToStr(String str){
       return  HtmlUtils.htmlUnescape(str);
    }
}
