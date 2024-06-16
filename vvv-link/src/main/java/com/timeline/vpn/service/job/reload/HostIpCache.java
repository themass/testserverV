package vpn.service.job.reload;

import com.timeline.vpn.dao.db.LocationDao;
import com.timeline.vpn.model.po.LocationPo;
import com.timeline.vpn.service.job.ReloadJob;
import org.apache.commons.lang3.RandomUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import javax.annotation.PostConstruct;
import java.util.*;
import java.util.concurrent.locks.ReadWriteLock;
import java.util.concurrent.locks.ReentrantReadWriteLock;

/**
 * @author gqli
 * @Description: 预约原信息reload类，jvm内存存储
 * @date 2016年9月26日 下午2:47:21
 */
@Repository
public class HostIpCache extends ReloadJob {
    private static final Logger LOGGER = LoggerFactory.getLogger(HostIpCache.class);
    private static List<LocationPo> locationList = new ArrayList<>();
    private static HashMap<Integer,List<LocationPo>> locationMap = new HashMap<>();
    private static ReadWriteLock lock = new ReentrantReadWriteLock(false);
    @Autowired
    private LocationDao locationDao;
    
    public void init() {
        List<LocationPo> list = locationDao.getAllInfo();
        List<LocationPo> locationOk = new ArrayList<>();
        for(LocationPo po :list){
            if(HostCheck.isErrorIp(po.getGateway())){
                LOGGER.error("有问题的IP：hostId="+po.getHostId()+"; name="+po.getName()+"; IP="+po.getGateway());
            }else{
                locationOk.add(po);
            }
        }
        try {
//            LOGGER.info("locationOk = "+locationOk);
            lock.writeLock().lock();
            locationList = locationOk;
        } finally {
            lock.writeLock().unlock();
        }
    }
    @PostConstruct
    public void reload() {
        init();
        try {
            lock.writeLock().lock();
            locationMap.clear();
            for(LocationPo po:locationList){
                List<LocationPo> list = locationMap.get(po.getId());
                if(list==null){
                    list = new ArrayList<>();
                    locationMap.put(po.getId(), list);
                }
                if(po.getWeight()==null){
                    list.add(po);
                }else{
                    for(int i=0;i<po.getWeight();i++)
                        list.add(po);
                }
            }
        } finally {
            lock.writeLock().unlock();
        }
    }
  public static List<LocationPo> getLocationList(){
      List<LocationPo> ret = new ArrayList<>();
      try {
          lock.readLock().lock();
          for(Map.Entry<Integer, List<LocationPo>> entry:locationMap.entrySet()){
              if(entry.getValue().size()==1){
                  ret.addAll(entry.getValue());
              }else{
                  ret.add(entry.getValue().get(RandomUtils.nextInt(0, entry.getValue().size())));
              }
          }
          Collections.sort(ret);
          return ret;
      } finally {
          lock.readLock().unlock();
      }
  }
  
  
}
