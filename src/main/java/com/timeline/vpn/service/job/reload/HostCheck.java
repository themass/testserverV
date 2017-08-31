package com.timeline.vpn.service.job.reload;

import java.util.ArrayList;
import java.util.List;

import javax.annotation.PostConstruct;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import com.timeline.vpn.dao.db.HostDao;
import com.timeline.vpn.model.po.HostPo;
import com.timeline.vpn.service.job.ReloadJob;
import com.timeline.vpn.util.HttpCommonUtil;
import com.timeline.vpn.util.MailUtil;

/**
 * @author gqli
 * @Description: 预约原信息reload类，jvm内存存储
 * @date 2016年9月26日 下午2:47:21
 */
@Repository
public class HostCheck extends ReloadJob {
    private static final Logger LOGGER = LoggerFactory.getLogger(HostCheck.class);
    private static List<String> myIpList = new ArrayList<>();
    @Autowired
    private HostDao hostDao;
    @PostConstruct
    public void init() {
        List<HostPo> list = hostDao.getAll();
        List<String> ips = new ArrayList<>(); 
        for(HostPo po :list){
            ips.add(po.getGateway());
        }
        myIpList = ips;
    }

    public void reload() {
        init();
        for(String ip :myIpList){
            int count = 0;
            while(count<3){
                boolean ret = HttpCommonUtil.ping(ip);
                if(!ret){
                    if(count==2){
                        String title = "服务器 ping 失败："+ip;
                        LOGGER.error(title);
                        MailUtil.sendMail(title, title);
                    }
                }else{
                    break;
                }
            }
            LOGGER.info("check {} finish",ip);
        }
        
    }
  public static boolean isMyHost(String ip){
      return myIpList.contains(ip);
  }
  
}
