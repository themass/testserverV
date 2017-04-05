package com.timeline.vpn.service.job.reload;

import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import com.timeline.vpn.dao.db.HostDao;
import com.timeline.vpn.model.po.HostPo;
import com.timeline.vpn.service.impl.MailRegAuthServiceImpl;
import com.timeline.vpn.service.job.AbstractJob;
import com.timeline.vpn.util.HttpCommonUtil;
import com.timeline.vpn.util.MailUtil;

/**
 * @author gqli
 * @Description: 预约原信息reload类，jvm内存存储
 * @date 2016年9月26日 下午2:47:21
 */
@Repository
public class HostCheck extends AbstractJob {
    private static final Logger LOGGER = LoggerFactory.getLogger(HostCheck.class);
    @Autowired
    private HostDao hostDao;
    @Override
    public void executeInternal() throws Exception {
        List<HostPo> list = hostDao.getAll();
        for(HostPo po :list){
            int count = 0;
            while(count<3){
                boolean ret = HttpCommonUtil.ping(po.getGateway());
                if(!ret){
                    if(count==2){
                        String title = "服务器 ping 失败："+po.getGateway();
                        MailUtil.sendMail(title, title);
                    }
                }else{
                    break;
                }
            }
            LOGGER.info("check {} finish",po.getGateway());
        }
        
    }
  
  
}
