package com.timeline.vpn.service.job.reload;

import java.util.ArrayList;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;
import org.springframework.util.StringUtils;

import com.timeline.vpn.dao.db.RadacctDao;
import com.timeline.vpn.model.po.Radacct;
import com.timeline.vpn.service.job.AbstractJob;
import com.timeline.vpn.util.IpLocalUtilSina;

/**
 * @author gqli
 * @Description: 预约原信息reload类，jvm内存存储
 * @date 2016年9月26日 下午2:47:21
 */
@Repository
public class IpLocalUpdater extends AbstractJob {
    private static final Logger LOGGER = LoggerFactory.getLogger(IpLocalUpdater.class);
    @Autowired
    private RadacctDao radacctDao;
    @Override
    public void executeInternal() throws Exception {
        try{
            int count =0;
            while(count<2){
                List<Radacct>list = radacctDao.selectIpLocal();
                List<Radacct>forUp = new ArrayList<>();
                for(Radacct item:list){
                    String to = IpLocalUtilSina.getLocal(item.getNasipaddress());
                    String from = null;
                    if(StringUtils.hasText(item.getCallingstationid())){
                        String ip = item.getCallingstationid().split("=")[0];
                        from = IpLocalUtilSina.getLocal(ip);
                    }
                    item.setFrom(from);
                    item.setTo(to);
                    item.setStatus(1);
                    forUp.add(item);
                }
                if(forUp.size()>0)
                    radacctDao.updateIpLocal(forUp);
                LOGGER.info("IpLocalUpdater ok size = "+forUp.size());
                if(list.size()==100){
                    count++;
                }else{
                    break;
                }
            }
        }catch(Throwable e){
            LOGGER.error("");
        }
    }
       
  
  
}
