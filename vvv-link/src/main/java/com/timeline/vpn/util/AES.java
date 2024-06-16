package com.timeline.vpn.util;

import org.apache.commons.codec.binary.Base64;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;
import java.security.SecureRandom;

public class AES {
    private static final Logger LOGGER = LoggerFactory.getLogger(AES.class);
    /**
      * 加密
     * 
      * @param content 需要加密的内容
     * @param password  加密密码
     * @return
      */
    public static String encrypt(String content, String password) {
        try {
            long startTime = System.currentTimeMillis();
            KeyGenerator kgen = KeyGenerator.getInstance("AES");
            kgen.init(128, new SecureRandom(password.getBytes()));
            SecretKey secretKey = kgen.generateKey();
            byte[] enCodeFormat = secretKey.getEncoded();
            SecretKeySpec key = new SecretKeySpec(enCodeFormat, "AES");
            Cipher cipher = Cipher.getInstance("AES/ECB/PKCS7Padding", "BC"); // 创建密码器
            byte[] byteContent = content.getBytes("utf-8");
            cipher.init(Cipher.ENCRYPT_MODE, key);// 初始化
            byte[] result = cipher.doFinal(byteContent);
            long end = System.currentTimeMillis();
            LOGGER.info("aes encrypt cost:{}",end-startTime);
            return new String(Base64.encodeBase64(result), "utf-8");
        } catch (Exception e) {
            LOGGER.error("",e);
        } 
        return null;
    }

    /**解密
     * @param content  待解密内容
     * @param password 解密密钥
     * @return
      */
    public static String decrypt(String content, String password) {
        try {
            long startTime = System.currentTimeMillis();
            byte[] con = Base64.decodeBase64(content.getBytes());
            KeyGenerator kgen = KeyGenerator.getInstance("AES");
            kgen.init(128, new SecureRandom(password.getBytes()));
            SecretKey secretKey = kgen.generateKey();
            byte[] enCodeFormat = secretKey.getEncoded();
            SecretKeySpec key = new SecretKeySpec(enCodeFormat, "AES");
            Cipher cipher = Cipher.getInstance("AES/ECB/PKCS7Padding", "BC"); // 创建密码器
            cipher.init(Cipher.DECRYPT_MODE, key);// 初始化
            byte[] result = cipher.doFinal(con);
            long end = System.currentTimeMillis();
            LOGGER.info("aes decrypt cost:{}",end-startTime);
            return new String(result); // 加密
        } catch (Exception e) {
            LOGGER.error("",e);
        } 
        return null;
    }


    /**将二进制转换成16进制
     * @param buf
      * @return
      */
    public static String parseByte2HexStr(byte buf[]) {
        StringBuffer sb = new StringBuffer();
        for (int i = 0; i < buf.length; i++) {
            String hex = Integer.toHexString(buf[i] & 0xFF);
            if (hex.length() == 1) {
                hex = '0' + hex;
            }
            sb.append(hex.toUpperCase());
        }
        return sb.toString();
    }

    /**将16进制转换为二进制
     * @param hexStr
      * @return
      */
    public static byte[] parseHexStr2Byte(String hexStr) {
        if (hexStr.length() < 1)
            return null;
        byte[] result = new byte[hexStr.length() / 2];
        for (int i = 0; i < hexStr.length() / 2; i++) {
            int high = Integer.parseInt(hexStr.substring(i * 2, i * 2 + 1), 16);
            int low = Integer.parseInt(hexStr.substring(i * 2 + 1, i * 2 + 2), 16);
            result[i] = (byte) (high * 16 + low);
        }
        return result;
    }

    /**
       * 加密
      *
       * @param content 需要加密的内容
      * @param password  加密密码
      * @return
       */
    public static byte[] encrypt2(String content, String password) {
        try {
            SecretKeySpec key = new SecretKeySpec(password.getBytes(), "AES");
            Cipher cipher = Cipher.getInstance("AES/ECB/NoPadding");
            byte[] byteContent = content.getBytes("utf-8");
            cipher.init(Cipher.ENCRYPT_MODE, key);// 初始化
            byte[] result = cipher.doFinal(byteContent);
            return result; // 加密
        } catch (Exception e) {
            LOGGER.error("",e);
        } 
        return null;
    }

    public static void main(String[] args) {
        String content = "dGmpYiEai6J9F6n1OraBAzUDVaU4sG5DVRqPNDRLbv2VrYotEozKtXMQHdfkt+HRf/4gIsXWYw/LMIHodvuXi71kIQ/me5XgO6mH6Smbj1Prqao6F7iXWofrG8hHfVWpJ3tz1LOX1eBbNMj4opKQQ/Fy+wZSp0efeCJW2HobV44=";
        String password = "56382298";
        // 加密
        System.out.println("加密前：" + content);
        String encryptResult = encrypt(content, password);
        // String tt4 = new String(Base64.encodeBase64(encryptResult),"utf-8");
        System.out.println(encryptResult);

        // 解密
        String decryptResult = decrypt(encryptResult, password);
        System.out.println("解密后：" + decryptResult);
    }
}
