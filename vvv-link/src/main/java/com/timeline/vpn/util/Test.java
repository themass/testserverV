package com.timeline.vpn.util;

import org.apache.commons.codec.binary.Base64;

import javax.crypto.*;
import javax.crypto.spec.SecretKeySpec;
import java.io.UnsupportedEncodingException;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.Arrays;
import java.util.List;


/**
 * @Description: TODO(添加描述)
 * @author gqli
 * @date 2017年4月25日 下午10:17:16
 * @version V1.0
 */
public class Test {
    private final static String encoding = "UTF-8";
    private final static String AES = "AES";
    private final static String KEY = "xxxxsfddsfdsfsdfds";

    /**
    * AES加密
    * **/
    public static String encryptAES(String content) {
        byte[] encryptResult = encrypt(content);
        String encryptResultStr = parseByte2HexStr(encryptResult);
        // BASE64位加密
        encryptResultStr = ebotongEncrypto(encryptResultStr);
        return encryptResultStr;
    }

    /**
    * AES解密
    * @param encryptResultStr
    * @return String
    * **/
    public static String decryptAES(String encryptResultStr) {

        // BASE64位解密
        String decrpt = ebotongDecrypto(encryptResultStr);
        byte[] decryptFrom = parseHexStr2Byte(decrpt);
        byte[] decryptResult = decrypt(decryptFrom);
        return new String(decryptResult);
    }


    /**
    * 加密字符串
    * */
    public static String ebotongEncrypto(String str) {

        String result = str;
        if (str != null && str.length() > 0) {
            try {

                byte[] encodeByte = str.getBytes(encoding);
                result = Base64.encodeBase64String(encodeByte);
            } catch (UnsupportedEncodingException e) {
                e.printStackTrace();
            }
        }

        // base64加密超过一定长度会自动换行 需要去除换行符
        return result.replaceAll("\r\n", "").replaceAll("\r", "").replaceAll("\n", "");
    }

    /**
    * 解密字符串
    * */
    public static String ebotongDecrypto(String str) {

        byte[] encodeByte = Base64.decodeBase64(str);
        return new String(encodeByte);
    }



    /**
    * 加密
    *
    * @param content 需要加密的内容
    * @param password  加密密码
    * @return
    */
    public static byte[] encrypt(String content) {

        try {
            KeyGenerator kgen = KeyGenerator.getInstance(AES);
            SecureRandom secureRandom = SecureRandom.getInstance("SHA1PRNG");
            secureRandom.setSeed(KEY.getBytes());
            kgen.init(128, secureRandom);
            SecretKey secretKey = kgen.generateKey();
            byte[] enCodeFormat = secretKey.getEncoded();
            SecretKeySpec key = new SecretKeySpec(enCodeFormat, AES);
            Cipher cipher = Cipher.getInstance(AES);// 创建密码器
            byte[] byteContent = content.getBytes();
            cipher.init(Cipher.ENCRYPT_MODE, key);// 初始化
            byte[] result = cipher.doFinal(byteContent);
            return result; // 加密
        } catch (NoSuchAlgorithmException e) {
            e.printStackTrace();
        } catch (NoSuchPaddingException e) {
            e.printStackTrace();
        } catch (InvalidKeyException e) {
            e.printStackTrace();
        } catch (IllegalBlockSizeException e) {
            e.printStackTrace();
        } catch (BadPaddingException e) {
            e.printStackTrace();
        }
        return null;
    }



    /**解密
    * @param content  待解密内容
    * @param password 解密密钥
    * @return
    */
    public static byte[] decrypt(byte[] content) {

        try {
            KeyGenerator kgen = KeyGenerator.getInstance(AES);
            // kgen.init(128, new SecureRandom(AESUtilsPassWordKey.PASSWORD_KEY.getBytes()));
            SecureRandom secureRandom = SecureRandom.getInstance("SHA1PRNG");
            secureRandom.setSeed(KEY.getBytes());
            kgen.init(128, secureRandom);
            SecretKey secretKey = kgen.generateKey();
            byte[] enCodeFormat = secretKey.getEncoded();
            SecretKeySpec key = new SecretKeySpec(enCodeFormat, AES);
            Cipher cipher = Cipher.getInstance(AES);// 创建密码器
            cipher.init(Cipher.DECRYPT_MODE, key);// 初始化
            byte[] result = cipher.doFinal(content);
            return result; // 加密
        } catch (NoSuchAlgorithmException e) {
            e.printStackTrace();
        } catch (NoSuchPaddingException e) {
            e.printStackTrace();
        } catch (InvalidKeyException e) {
            e.printStackTrace();
        } catch (IllegalBlockSizeException e) {
            e.printStackTrace();
        } catch (BadPaddingException e) {
            e.printStackTrace();
        }
        return null;
    }


    /**将16进制转换为二进制 解密
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
    * 将二进制转换成16进制 加密
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

    public static void main(String[] args) {

//        String content = "hello abcdefggsdfasdfasdfaf asdf asdf asdg fdsg sfdg sdf hgdfgh fgh f{contractId:100000350072,houseNo:101100041102,customerNo:501100042035,contractBaseDto:{parentId:-1,contractType:1,orderId:374253,inputType:1,bizType:1,cityCode:120000,districtCode:120101,contractNo:100008179789,contractStatus:2,changeStatus:0,createdUserId:1000000020043722,createdOrgId:B0001201,signUserId:1000000020043722,signOrgId:B0001201,firstSignOrgId:B0001201,contractCompleteStatus:1,contractPageCount:0,createdTime:1472024652000,updatedTime:1472024653000,pdfNoSealId:null,pdfSealId:null,sealTime:1472024652000,isEvaluated:0,tradeStatus:0,accessoryStatus:null,accessoryMsg:null,processInstanceId:null,branchCompany:B00001,tradeProduct:18,sectionType:-1,printCount:1,signTime:1472024653000,invalidReason:null,isNeedAssign:0,assignLog:null,deedAddress:xts address,realPrice:343434686.00,perfAuditUserId:null,perfAuditTime:null},contractDetailMap:{pingguYfzffydx:{columnCode:pingguYfzffydx,columnName:评估-乙方支付费用大写,columnDataType:text,textValue:壹仟元整,intValue:null,decimalValue:null,dataDictKey:-1,isArray:0},dishangLc:{columnCode:dishangLc,columnName:地上楼层,columnDataType:text,textValue:454,intValue:null,decimalValue:null,dataDictKey:-1,isArray:0},pingguYfzffyxx:{columnCode:pingguYfzffyxx,columnName:评估-乙方支付费用小写,columnDataType:decimal,textValue:null,intValue:null,decimalValue:1000.00,dataDictKey:-1,isArray:0},quankuanQdfcmmxyrq:{columnCode:quankuanQdfcmmxyrq,columnName:全款-签订房产买卖协议日期,columnDataType:text,textValue:null,intValue:null,decimalValue:null,dataDictKey:-1,isArray:0},fangwuCjjdx:{columnCode:fangwuCjjdx,columnName:房屋成交价大写,columnDataType:text,textValue:叁亿肆仟叁佰肆拾叁万肆仟陆佰捌拾陆元整,intValue:null,decimalValue:null,dataDictKey:-1,isArray:0},tengfangYjjedx:{columnCode:tengfangYjjedx,columnName:腾房押金金额大写,columnDataType:text,textValue:叁拾叁元整,intValue:null,decimalValue:null,dataDictKey:-1,isArray:0},daikuanYedx:{columnCode:daikuanYedx,columnName:贷款余额大写,columnDataType:text,textValue:肆仟伍佰肆拾伍元整,intValue:null,decimalValue:null,dataDictKey:-1,isArray:0},shifouQsfwdkwtht:{columnCode:shifouQsfwdkwtht,columnName:是否签署房屋贷款委托合同,columnDataType:int,textValue:null,intValue:1,decimalValue:null,dataDictKey:74,isArray:0},fangwuSfcf:{columnCode:fangwuSfcf,columnName:房屋是否查封,columnDataType:int,textValue:null,intValue:2,decimalValue:null,dataDictKey:73,isArray:0},daikuanQdfcmmxyrq:{columnCode:daikuanQdfcmmxyrq,columnName:贷款-签订房产买卖协议日期,columnDataType:text,textValue:2016-02-04,intValue:null,decimalValue:null,dataDictKey:-1,isArray:0},jianzhuMj:{columnCode:jianzhuMj,columnName:建筑面积,columnDataType:decimal,textValue:null,intValue:null,decimalValue:54.00,dataDictKey:-1,isArray:0},fangwuCjjxx:{columnCode:fangwuCjjxx,columnName:房屋成交价小写,columnDataType:decimal,textValue:null,intValue:null,decimalValue:343434686.00,dataDictKey:-1,isArray:0},suozaiLc:{columnCode:suozaiLc,columnName:所在楼层,columnDataType:text,textValue:454,intValue:null,decimalValue:null,dataDictKey:-1,isArray:0},fangwuCqr:{columnCode:fangwuCqr,columnName:房屋产权人,columnDataType:text,textValue:454,intValue:null,decimalValue:null,dataDictKey:-1,isArray:0},yezhuZfjjdlfdx:{columnCode:yezhuZfjjdlfdx,columnName:业主支付居间代理费大写,columnDataType:text,textValue:叁佰元整,intValue:null,decimalValue:null,dataDictKey:-1,isArray:0},jiafangJffwgyftj:{columnCode:jiafangJffwgyftj,columnName:甲方交付房屋给乙方条件,columnDataType:text,textValue:33,intValue:null,decimalValue:null,dataDictKey:-1,isArray:0},yifangCdsf:{columnCode:yifangCdsf,columnName:乙方承担税费,columnDataType:text,textValue:null,intValue:null,decimalValue:null,dataDictKey:21,isArray:1},fangwuSfyfzcsw:{columnCode:fangwuSfyfzcsw,columnName:房屋是否有非正常死亡,columnDataType:int,textValue:null,intValue:2,decimalValue:null,dataDictKey:62,isArray:0},pingguFycdf:{columnCode:pingguFycdf,columnName:评估费用承担方,columnDataType:int,textValue:null,intValue:2,decimalValue:null,dataDictKey:76,isArray:0},wuyedizhi:{columnCode:wuyedizhi,columnName:物业地址,columnDataType:text,textValue:xts address,intValue:null,decimalValue:null,dataDictKey:-1,isArray:0},pingguYztgdqtzlyd:{columnCode:pingguYztgdqtzlyd,columnName:评估-业主提供的其他资料约定,columnDataType:text,textValue:产权人身份证复印件,intValue:null,decimalValue:null,dataDictKey:-1,isArray:0},jiafangCdqtsf:{columnCode:jiafangCdqtsf,columnName:甲方承担其他税费,columnDataType:text,textValue:null,intValue:null,decimalValue:null,dataDictKey:-1,isArray:0},jiafangCdsf:{columnCode:jiafangCdsf,columnName:甲方承担税费,columnDataType:text,textValue:1,intValue:null,decimalValue:null,dataDictKey:21,isArray:1},dingjinJexx:{columnCode:dingjinJexx,columnName:定金金额小写,columnDataType:decimal,textValue:null,intValue:null,decimalValue:343434343.00,dataDictKey:-1,isArray:0},pingguJfzffyxx:{columnCode:pingguJfzffyxx,columnName:评估-甲方支付费用小写,columnDataType:decimal,textValue:null,intValue:null,decimalValue:null,dataDictKey:-1,isArray:0},fangkuanZffs:{columnCode:fangkuanZffs,columnName:房款支付方式,columnDataType:int,textValue:null,intValue:2,decimalValue:null,dataDictKey:51,isArray:0},fangwuZljsrq:{columnCode:fangwuZljsrq,columnName:房屋租赁结束日期,columnDataType:text,textValue:2015-12-08,intValue:null,decimalValue:null,dataDictKey:-1,isArray:0},yifangCdqtsf:{columnCode:yifangCdqtsf,columnName:乙方承担其他税费,columnDataType:text,textValue:null,intValue:null,decimalValue:null,dataDictKey:-1,isArray:0},kehuZfjjdlfdx:{columnCode:kehuZfjjdlfdx,columnName:客户支付居间代理费大写,columnDataType:text,textValue:贰佰元整,intValue:null,decimalValue:null,dataDictKey:-1,isArray:0},yezhuZfjjdlfxx:{columnCode:yezhuZfjjdlfxx,columnName:业主支付居间代理费小写,columnDataType:decimal,textValue:null,intValue:null,decimalValue:10.00,dataDictKey:-1,isArray:0},chudingJwsyfkzjdx:{columnCode:chudingJwsyfkzjdx,columnName:除定金外剩余房款总计大写,columnDataType:text,textValue:叁佰肆拾叁元整,intValue:null,decimalValue:null,dataDictKey:-1,isArray:0},maimaiHtbz:{columnCode:maimaiHtbz,columnName:买卖合同备注,columnDataType:text,textValue:3434,intValue:null,decimalValue:null,dataDictKey:-1,isArray:0},shifouCzls:{columnCode:shifouCzls,columnName:是否存在漏水,columnDataType:int,textValue:null,intValue:2,decimalValue:null,dataDictKey:62,isArray:0},daikuanYzzfdkfwfdx:{columnCode:daikuanYzzfdkfwfdx,columnName:贷款合同-业主支付贷款服务费大写,columnDataType:text,textValue:陆佰元整,intValue:null,decimalValue:null,dataDictKey:-1,isArray:0},pingguJfssfcxz:{columnCode:pingguJfssfcxz,columnName:评估-甲方所售房产性质,columnDataType:int,textValue:null,intValue:1,decimalValue:null,dataDictKey:18,isArray:0},tengfangYjjexx:{columnCode:tengfangYjjexx,columnName:腾房押金金额小写,columnDataType:decimal,textValue:null,intValue:null,decimalValue:33.00,dataDictKey:-1,isArray:0},fangwuYt:{columnCode:fangwuYt,columnName:房屋用途,columnDataType:int,textValue:null,intValue:1,decimalValue:null,dataDictKey:72,isArray:0},xiangzhongCwsqzcf:{columnCode:xiangzhongCwsqzcf,columnName:向仲裁委申请仲裁方,columnDataType:text,textValue:343,intValue:null,decimalValue:null,dataDictKey:-1,isArray:0},dixiaLc:{columnCode:dixiaLc,columnName:地下楼层,columnDataType:text,textValue:454,intValue:null,decimalValue:null,dataDictKey:-1,isArray:0},zongLc:{columnCode:zongLc,columnName:总楼层,columnDataType:text,textValue:908,intValue:null,decimalValue:null,dataDictKey:-1,isArray:0},daikuanYexx:{columnCode:daikuanYexx,columnName:贷款余额小写,columnDataType:decimal,textValue:null,intValue:null,decimalValue:4545.00,dataDictKey:-1,isArray:0},dingjinJedx:{columnCode:dingjinJedx,columnName:定金金额大写,columnDataType:text,textValue:叁亿肆仟叁佰肆拾叁万肆仟叁佰肆拾叁元整,intValue:null,decimalValue:null,dataDictKey:-1,isArray:0},chudingJwsyfkzjxx:{columnCode:chudingJwsyfkzjxx,columnName:除定金外剩余房款总计小写,columnDataType:decimal,textValue:null,intValue:null,decimalValue:343.00,dataDictKey:-1,isArray:0},jiafangHqdkyerq:{columnCode:jiafangHqdkyerq,columnName:甲方还请贷款余额日期,columnDataType:text,textValue:2015-12-02,intValue:null,decimalValue:null,dataDictKey:-1,isArray:0},dingjinZfrq:{columnCode:dingjinZfrq,columnName:定金支付日期,columnDataType:text,textValue:2015-12-02,intValue:null,decimalValue:null,dataDictKey:-1,isArray:0},fangwuSyqbh:{columnCode:fangwuSyqbh,columnName:房屋所有权证编号,columnDataType:text,textValue:454,intValue:null,decimalValue:null,dataDictKey:-1,isArray:0},banliGhjdydjsxrq:{columnCode:banliGhjdydjsxrq,columnName:办理过户及抵押登记手续日期,columnDataType:text,textValue:2015-12-01,intValue:null,decimalValue:null,dataDictKey:-1,isArray:0},daikuanYzzfdkfwfxx:{columnCode:daikuanYzzfdkfwfxx,columnName:贷款合同-业主支付贷款服务费小写,columnDataType:decimal,textValue:null,intValue:null,decimalValue:600.00,dataDictKey:-1,isArray:0},fangwuCqxz:{columnCode:fangwuCqxz,columnName:房屋产权性质,columnDataType:text,textValue:343,intValue:null,decimalValue:null,dataDictKey:-1,isArray:0},shifouQswtpgxy:{columnCode:shifouQswtpgxy,columnName:是否签署委托评估协议,columnDataType:int,textValue:null,intValue:1,decimalValue:null,dataDictKey:74,isArray:0},kehuZfjjdlfxx:{columnCode:kehuZfjjdlfxx,columnName:客户支付居间代理费小写,columnDataType:decimal,textValue:null,intValue:null,decimalValue:2.00,dataDictKey:-1,isArray:0},diyaQk:{columnCode:diyaQk,columnName:抵押情况,columnDataType:int,textValue:null,intValue:1,decimalValue:null,dataDictKey:62,isArray:0},fangwuZlksrq:{columnCode:fangwuZlksrq,columnName:房屋租赁开始日期,columnDataType:text,textValue:2015-12-02,intValue:null,decimalValue:null,dataDictKey:-1,isArray:0},daikuanFS:{columnCode:daikuanFS,columnName:贷款合同-贷款方式,columnDataType:int,textValue:null,intValue:1,decimalValue:null,dataDictKey:20,isArray:0},pingguJfzffydx:{columnCode:pingguJfzffydx,columnName:评估-甲方支付费用大写,columnDataType:text,textValue:null,intValue:null,decimalValue:null,dataDictKey:-1,isArray:0},hetongZydjjbfssf:{columnCode:hetongZydjjbfssf,columnName:合同争议的解决办法申诉方,columnDataType:int,textValue:null,intValue:2,decimalValue:null,dataDictKey:75,isArray:0}},seller:{id:558088,contractId:100000350072,partyType:1,personCompany:1,partyName:史晓强,agentName:null,partySex:1,partyEmail:shixiaoqiang@lianjia.com,partyNationality:中国,partyCardType:1,partyCardNo:110101198001010520,partyIdentity:null,partyMarriage:null,phone1:13289000009,phone2:null,phone3:null,address:西二旗领秀新硅谷链家网,isOwners:null,isAgents:null,partyOwners:[],partyAgents:[]},buyer:{id:558087,contractId:100000350072,partyType:2,personCompany:null,partyName:李毅,agentName:null,partySex:2,partyEmail:liyi@lianjia.com,partyNationality:女儿国,partyCardType:1,partyCardNo:110101198001010547,partyIdentity:null,partyMarriage:null,phone1:13645454545,phone2:null,phone3:null,address:上地十街百度大厦,isOwners:null,isAgents:null,partyOwners:[],partyAgents:[]},sellerAgent:[],sellerOwner:[],buyerAgent:[],buyerOwner:[]}";
//        String encryptResultStr = encryptAES(content);
//        System.out.println("加密前: " + content);
//        System.out.println("加密后: " + encryptResultStr);
//        System.out.println("解密后: " + decryptAES(encryptResultStr));
        String str = "(?!a11).*";  //^(a11).*
        List<String>arg = Arrays.asList("a1","a11","a11111","a11sssss","a1q1sssss","aa11sssss","da11sssss",
                    "da11sssss","fa11sssss","fa1s","ssa11","sssa11sssss"); 
        for(String item:arg)
        {
            System.out.println(item.matches(str)+"----"+item);
        }
    }
}

