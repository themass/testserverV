package vpn.service.job.reload;

import com.google.common.collect.HashMultimap;
import com.google.common.collect.Multimap;
import com.timeline.vpn.dao.db.DnsResverDao;
import com.timeline.vpn.model.po.DnsResverPo;
import com.timeline.vpn.service.job.ReloadJob;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import javax.annotation.PostConstruct;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.concurrent.locks.ReadWriteLock;
import java.util.concurrent.locks.ReentrantReadWriteLock;

/**
 * @author gqli
 * @Description: 预约原信息reload类，jvm内存存储
 * @date 2016年9月26日 下午2:47:21
 */
@Repository
public class DnsCache extends ReloadJob {
    private static ReadWriteLock lock = new ReentrantReadWriteLock(false);
    private static Map<String, String> configMap = new HashMap<>();
    @Autowired
    private DnsResverDao dnsResverDao;

    @PostConstruct
    public void init() {
        reload();
    }

    public void reload() {
        List<DnsResverPo> list = dnsResverDao.getAll();
        Multimap<String, DnsResverPo> map = HashMultimap.create();
        for (DnsResverPo p : list) {
            map.put(p.getDomain(), p);
        }
        Map<String, Collection<DnsResverPo>> mapList = map.asMap();
        Map<String, String> mapC = new HashMap<>();
        for(Entry<String,Collection<DnsResverPo>> c:mapList.entrySet()){
            StringBuilder sb = new StringBuilder();
            for(DnsResverPo po:c.getValue()){
                sb.append(po.getIp()).append(":").append(po.getTtl()).append(";");
            }
            mapC.put(c.getKey(), sb.toString());
        }
        try {
            lock.writeLock().lock();
            configMap = mapC;
            LOGGER.info("DnsCache metaMap size = {}", configMap.size());
        } finally {
            lock.writeLock().unlock();
        }
    }
    public String  getByDomain(String domain){
        return configMap.get(domain);
    }
}
