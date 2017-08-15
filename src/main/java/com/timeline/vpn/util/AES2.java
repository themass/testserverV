package com.timeline.vpn.util;

import java.util.Random;

import javax.crypto.Cipher;
import javax.crypto.spec.SecretKeySpec;

public class AES2 {

    static final String algorithmStr = "AES/ECB/PKCS5Padding";
    private static byte[] encrypt(String content, String password) {
        try {
            byte[] keyStr = getKey(password);
            SecretKeySpec key = new SecretKeySpec(keyStr, "AES");
            Cipher cipher = Cipher.getInstance(algorithmStr);// algorithmStr
            byte[] byteContent = content.getBytes("utf-8");
            cipher.init(Cipher.ENCRYPT_MODE, key);// ʼ
            byte[] result = cipher.doFinal(byteContent);
            return result; //
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    private static byte[] decrypt(byte[] content, String password) {
        try {
            byte[] keyStr = getKey(password);
            SecretKeySpec key = new SecretKeySpec(keyStr, "AES");
            byte[] i = key.getEncoded();
            Cipher cipher = Cipher.getInstance(algorithmStr);// algorithmStr
            cipher.init(Cipher.DECRYPT_MODE, key);// ʼ
            byte[] result = cipher.doFinal(content);
            return result; //
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    private static byte[] getKey(String password) {
        byte[] rByte = null;
        if (password != null) {
            rByte = password.getBytes();
        } else {
            rByte = new byte[24];
        }
        return rByte;
    }

    /**
     * 将二进制转换成16进制
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

    /**
     * 将16进制转换为二进制
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
    *加密
    */
    public static String encode(String content,String key) {
        // 加密之后的字节数组,转成16进制的字符串形式输出
        return parseByte2HexStr(encrypt(content, key));
    }

    /**
    *解密
    */
    public static String decode(String content,String key) {
        // 解密之前,先将输入的字符串按照16进制转成二进制的字节数组,作为待解密的内容输入
        byte[] b = decrypt(parseHexStr2Byte(content), key);
        return new String(b);
    }
    public static String getRandom(){
        Random r = new Random();
        return (r.nextInt(999999)+100000)+"";
    }
    
    
    
    // 测试用例
    public static void test1() {
        String content = "111";
        String key = "abcdefg123456!@#";
        String pStr = encode(content,key);
        System.out.println("加密前：" + content);
        System.out.println("加密后:" + pStr);

        String postStr = decode(pStr,key);
        System.out.println("解密后：" + postStr);
    }

    public static void main(String[] args) {
        test1();
       
    }

}

