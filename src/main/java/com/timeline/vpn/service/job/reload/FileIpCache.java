package com.timeline.vpn.service.job.reload;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.locks.ReadWriteLock;
import java.util.concurrent.locks.ReentrantReadWriteLock;

import javax.annotation.PostConstruct;

import org.apache.commons.lang3.RandomUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import com.google.common.collect.HashMultimap;
import com.timeline.vpn.dao.db.FileIpDao;
import com.timeline.vpn.model.po.FileIpPo;
import com.timeline.vpn.service.job.ReloadJob;

/**
 * @author gqli
 * @Description: 预约原信息reload类，jvm内存存储
 * @date 2016年9月26日 下午2:47:21
 */
@Repository
public class FileIpCache extends ReloadJob {
    private static ReadWriteLock lock = new ReentrantReadWriteLock(false);
    private static Map<String, HashMultimap<String, String>> configMap = new HashMap<>();
    @Autowired
    private FileIpDao fileIpDao;

    @PostConstruct
    public void init() {
        reload();
    }

    public void reload() {
        List<FileIpPo> list = fileIpDao.getAll();
        Map<String, HashMultimap<String, String>> map = new HashMap<>();
        for (FileIpPo p : list) {
            HashMultimap<String, String> item = map.get(p.getType());
            if(item==null){
                item = HashMultimap.create();
                map.put(p.getType(), item);
            }
            item.put(p.getExtra(), p.getIp());
        }
        try {
            lock.writeLock().lock();
            configMap = map;
            LOGGER.info("FileIp metaMap size = {}", configMap.size());
        } finally {
            lock.writeLock().unlock();
        }
    }
    public static String  getHost(String type,String extra){
        HashMultimap<String, String> map = configMap.get(type);
        if(map==null){
               return null;
        }
        Set<String> set = map.get(extra);
        return (String)set.toArray()[(RandomUtils.nextInt(0, set.size()))];
    }

}
