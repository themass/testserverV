package com.timeline.vpn.util;

import org.springframework.util.StringUtils;

/**
 * @author gqli
 * @date 2017年4月14日 下午4:00:27
 * @version V1.0
 */
public class IpLocalUtilSina {
    public static final String IP_HOST="http://int.dpool.sina.com.cn/iplookup/iplookup.php?format=json&ip=%s";
    public static String getLocal(String ip){
        String url = String.format(IP_HOST, ip);
        String json = HttpCommonUtil.sendGet(url);
        if(!StringUtils.hasText(json)){
            return null;
        }
        IpLocalPo po = JsonUtil.readValue(json, IpLocalPo.class);
        if(po.getRet()==1){
            StringBuilder sb = new StringBuilder();
            sb.append(po.getCountry());
            if(StringUtils.hasText(po.getProvince()))
                sb.append("-").append(po.getProvince());
            if(StringUtils.hasText(po.getCity()))
                sb.append("-").append(po.getCity());
            return sb.toString();
        }
        return null;
    }
    public static class IpLocalPo {
        private int ret;
        private String country;
        private String province;
        private String city;
        private String district;
        private String isp;
        private String desc;
        public int getRet() {
            return ret;
        }
        public void setRet(int ret) {
            this.ret = ret;
        }
        public String getCountry() {
            return country;
        }
        public void setCountry(String country) {
            this.country = country;
        }
        public String getProvince() {
            return province;
        }
        public void setProvince(String province) {
            this.province = province;
        }
        public String getCity() {
            return city;
        }
        public void setCity(String city) {
            this.city = city;
        }
        public String getDistrict() {
            return district;
        }
        public void setDistrict(String district) {
            this.district = district;
        }
        public String getIsp() {
            return isp;
        }
        public void setIsp(String isp) {
            this.isp = isp;
        }
        public String getDesc() {
            return desc;
        }
        public void setDesc(String desc) {
            this.desc = desc;
        }
    }
    public static void main(String[]args){
        System.out.println(getLocal("45.77.35.56"));
    }
}

