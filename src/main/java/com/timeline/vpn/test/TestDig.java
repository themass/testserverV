package com.timeline.vpn.test;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

import org.mortbay.util.UrlEncoded;

import com.sun.tools.classfile.StackMap_attribute.stack_map_frame;
import com.timeline.vpn.util.HttpCommonUtil;
import com.timeline.vpn.util.JsonUtil;

/**
 * @Title: TestDig.java
 * @Package com.timeline.vpn.test
 * @Description: TODO(添加描述)
 * @author gqli
 * @date 2018年5月29日 上午10:44:07
 * @version V1.0
 */
public class TestDig {
    public static void digv() throws InterruptedException {
        for(int i=0;i<100;i++) {
            String ts = System.currentTimeMillis()+"";
            Digv digv = new Digv();
            digv.setSsid("041F376F-9332C3-4F59-A057-CC00C0B25"+i);
            digv.setTs(ts);
            digv.setUdid("7BEE8F9B-7733B5-466E-A0AC-67DA8FC5F4"+i);
            digv.setUuid(UUID.randomUUID().toString().replace("-", ""));
            digv.setPid("lianjiaapp");;
            DigVDetail digVDetail = new DigVDetail();
            digVDetail.setAdId(100000072);
            digVDetail.setFlow("commerce");
            digv.setEvt("10327");
            int index = i%10;
            digVDetail.setsId("100000003"+index);
            digVDetail.setV("V1");
            digVDetail.setUni("999888777");
            digVDetail.setrId(ts);
            Action action = new Action();
            action.setAgent_id("1000000020136887");
            action.setE_plan(JsonUtil.writeValueAsString(digVDetail));
            digv.setAction(action);
            System.out.println(JsonUtil.writeValueAsString(digv));
            String dString = UrlEncoded.encodeString(JsonUtil.writeValueAsString(digv));
            String url = String.format("https://dig.lianjia.com/t.gif?r=%s&d=%s",  ts,dString);
            Map<String, String> headers = new HashMap<>();
            headers.put("user-agent", "Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/63.0.3239.132 Mobile Safari/537.36");
            String string =HttpCommonUtil.sendGetWithHeaders(url, "utf-8", headers);
            System.out.println(string);
            Thread.currentThread().sleep(10);
         }
        for(int i=0;i<50;i++) {
            String ts = System.currentTimeMillis()+"";
            Digv digv = new Digv();
            digv.setSsid("0411176F-92C3-4F59-A057-CC00C0B25"+i);
            digv.setTs(ts);
            digv.setUdid("7BE11F9B-77B5-466E-A0AC-67DA8FC5F4"+i);
            digv.setUuid(UUID.randomUUID().toString().replace("-", ""));
            digv.setPid("lianjiaapp");;
            DigVDetail digVDetail = new DigVDetail();
            digVDetail.setAdId(100000072);
            digVDetail.setFlow("commerce");
            digv.setEvt("10328");
            int index = i%10;
            digVDetail.setsId("100000003"+index);
            digVDetail.setV("V1");
            digVDetail.setUni("999888777");
            digVDetail.setrId(ts);
            Action action = new Action();
            action.setAgent_id("1000000020136887");
            action.setE_plan(JsonUtil.writeValueAsString(digVDetail));
            digv.setAction(action);
            System.out.println(JsonUtil.writeValueAsString(digv));
            String dString = UrlEncoded.encodeString(JsonUtil.writeValueAsString(digv));
            String url = String.format("https://dig.lianjia.com/t.gif?r=%s&d=%s",ts,dString);
            Map<String, String> headers = new HashMap<>();
            headers.put("user-agent", "Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/63.0.3239.132 Mobile Safari/537.36");
            String string =HttpCommonUtil.sendGetWithHeaders(url, "utf-8", headers);
            System.out.println(string);
            Thread.currentThread().sleep(10);
         }
        for(int i=200;i<300;i++) {
            String ts = System.currentTimeMillis()+"";
            Digv digv = new Digv();
            digv.setSsid("0412276F-92C3-4F59-A057-CC00C1B25"+i);
            digv.setTs(ts);
            digv.setUdid("7BEE22F9B-77B5-466E-A0AC-67DA8FB5F4"+i);
            digv.setUuid(UUID.randomUUID().toString().replace("-", ""));
            digv.setEvt("10327");
            digv.setPid("lianjiaapp");;
            DigVDetail digVDetail = new DigVDetail();
            digVDetail.setAdId(100000072);
            digVDetail.setFlow("natural");
            int index = i%10;
            digVDetail.setsId("1000000020136887_"+"111102737593"+index);
            digVDetail.setV("V1");
            digVDetail.setrId(ts);
            digVDetail.setUni("999888777");
            Action action = new Action();
            action.setAgent_id("1000000020136887");
            action.setE_plan(JsonUtil.writeValueAsString(digVDetail));
            digv.setAction(action);
            System.out.println(JsonUtil.writeValueAsString(digv));
            String dString = UrlEncoded.encodeString(JsonUtil.writeValueAsString(digv));
            String url = String.format("https://dig.lianjia.com/t.gif?r=%s&d=%s",ts,dString);
            Map<String, String> headers = new HashMap<>();
            headers.put("user-agent", "Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/63.0.3239.132 Mobile Safari/537.36");
            String string =HttpCommonUtil.sendGetWithHeaders(url, "utf-8", headers);
            System.out.println(string);
            Thread.currentThread().sleep(10);
         }
    }
    public static void insert() {
        String string = "INSERT INTO `commerce_brand`.`perbid_order_info` (`order_id`, `period_id`, `group_id`, `product_uid_relation_id`, `biz_product_no`, `biz_product_name`, `uid`, `pred_pv`, `pred_call`, `top_num`, `display_times`, `q`, `q_rank`, `ecpm`, `ecpm_rank`, `bid`, `status`, `mtime`, `ctime`, `bid_time`) VALUES (%s, '1', '100', '%s', '%s', '%s', '%s', '100', '100', '2', '5', '100.00', '100', '100.00', '100', '10', '5', '2018-05-23 17:51:22', '1970-01-02 00:00:00', '2018-05-02 00:00:00');";
        for(int i =1;i<300;i++) {
            String sql = String.format(string, i,i,"13110419583"+i,"万达华府一期-"+i,"10000000201368"+i);
            System.out.println(sql);
        }
    }
    public static void main(String[] args) throws InterruptedException {
//       TestDig.insert();
       digv();
    }
}

