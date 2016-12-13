/**
 * 
 */
package com.timeline.vpn.util;

import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.security.Security;

import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;

import org.bouncycastle.jce.provider.BouncyCastleProvider;
import org.bouncycastle.util.encoders.Base64;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * AES加密解密单元. 参考一下两篇文章. http://www.cnblogs.com/arix04/archive/2009/10/15/1511839.html
 * http://aub.iteye.com/blog/1133494
 * 
 * @author bjqinkan
 */
public class AESUtil {
    private static final Logger LOGGER = LoggerFactory.getLogger(AESUtil.class);
    private static AESUtil instance = new AESUtil();

    private AESUtil() {
        try {
            Security.addProvider(new BouncyCastleProvider());
        } catch (Exception e) {
            LOGGER.error("", e);
        }
    }

    public static AESUtil getInstance() {
        return instance;
    }

    /**
     * 加密.
     * 
     * @param content
     * @param key
     * @return
     * @throws Exception
     */
    public String encrypt(String content, String key) {
        byte[] raw = key.getBytes();
        SecretKeySpec skeySpec = new SecretKeySpec(raw, "AES");
        try {
            Cipher cipher = Cipher.getInstance("AES/ECB/PKCS7Padding", "BC"); // "算法/模式/补码方式"
            cipher.init(Cipher.ENCRYPT_MODE, skeySpec);
            byte[] encrypted = cipher.doFinal(content.getBytes("utf-8"));
            return new String(Base64.encode(encrypted), "UTF-8");// 此处使用BASE64做转码功能，同时能起到2次加密的作用。
        } catch (Exception e) {
            e.printStackTrace();
            LOGGER.error("", e);
        }
        return null;

    }

    /**
     * 解密.
     * 
     * @param content
     * @param key
     * @return
     */
    public String decrypt(String content, String key) {
        try {
            byte[] raw = key.getBytes();
            SecretKeySpec skeySpec = new SecretKeySpec(raw, "AES");
            Cipher cipher = Cipher.getInstance("AES/ECB/PKCS7Padding", "BC");
            cipher.init(Cipher.DECRYPT_MODE, skeySpec);
            byte[] encrypted = Base64.decode(content);
            byte[] original = cipher.doFinal(encrypted);
            return new String(original, "utf-8");
        } catch (Exception ex) {
            ex.printStackTrace();
            LOGGER.error("", ex);
        }
        return null;
    }
    public static void main(String[]args) throws NoSuchAlgorithmException{
        KeyGenerator kgen = KeyGenerator.getInstance("AES");
        kgen.init(128, new SecureRandom("12345678".getBytes()));
        SecretKey secretKey = kgen.generateKey();
        String str = AESUtil.getInstance().encrypt("11112e3dsadsads", new String(secretKey.getEncoded()));
        System.out.print(str);
    }
}
