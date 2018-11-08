package com.timeline.vpn.service.job.reload;

import java.util.Collections;
import java.util.List;
import java.util.Map;

import org.apache.commons.lang3.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Repository;

import com.google.common.collect.Lists;
import com.google.common.collect.Maps;
import com.timeline.vpn.service.job.ReloadJob;
import com.timeline.vpn.util.HttpCommonUtil;

/**
 * @author gqli
 * @Description: 预约原信息reload类，jvm内存存储
 * @date 2016年9月26日 下午2:47:21
 */
@Repository
public class ZhIpCache extends ReloadJob {
    private static Map<Integer, List<int[]>> chinaIps = Maps.newHashMap();
    private static final String url =
            "http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest";
    private static final Logger LOGGER = LoggerFactory.getLogger(ZhIpCache.class);

//    @PostConstruct
//    public void init() {
//        reload();
//    }

    @SuppressWarnings("unchecked")
    public void reload() {
        try {
            String content = HttpCommonUtil.sendGet(url);
            String[] lines = content.split("\n");
            Map<Integer, List<int[]>> map = Maps.newHashMap();
            for (String line : lines) {
                if (line.startsWith("apnic|CN|ipv4|")) {
                    // 只处理属于中国的ipv4地址
                    String[] strs = line.split("\\|");
                    String ip = strs[3];
                    String[] add = ip.split("\\.");
                    int count = Integer.valueOf(strs[4]);
                    if(ip.startsWith("112.74")){
                        LOGGER.info("my host："+line);
                    }
                    int startIp = Integer.parseInt(add[0]) * 256 + Integer.parseInt(add[1]);
                    while (count >0) {
                        if (count >= 65536) {
                            // add1,add2 整段都是中国ip
                            map.put(startIp, Collections.EMPTY_LIST);
                            count -= 65536;
                            startIp += 1;
                        } else {

                            int[] ipRange = new int[2];
                            ipRange[0] = Integer.parseInt(add[2]) * 256 + Integer.parseInt(add[3]);
                            ipRange[1] = ipRange[0] + count;
                            count -= count;

                            List<int[]> list = map.get(startIp);
                            if (list == null) {
                                list = Lists.newArrayList();
                                map.put(startIp, list);
                            }
                            list.add(ipRange);
                        }
                    }
                }
            }
            chinaIps = map;
            LOGGER.info("中国 ip 更新："+chinaIps.size());
        } catch (Exception e) {
            LOGGER.error("ERROR", e);
            e.printStackTrace();
        }
    }
    public static boolean isChinaIp(String ip) {
        if (StringUtils.isEmpty(ip)) {
            return false;
        }
        String[] strs = ip.split("\\.");
        if (strs.length != 4) {
            return false;
        }
        int key = Integer.valueOf(strs[0]) * 256 + Integer.valueOf(strs[1]);
        List<int[]> list = chinaIps.get(key);
        if (list == null) {
            return false;
        }
        if (list.size() == 0) {
            // 整段都是中国ip
            return true;
        }
        int ipValue = Integer.valueOf(strs[2]) * 256 + Integer.valueOf(strs[3]);
        for (int[] ipRange : list) {
            if (ipValue >= ipRange[0] && ipValue <= ipRange[1]) {
                return true;
            }
        }

        return false;
    }
}
