package com.timeline.vpn.service.job.reload;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.locks.ReadWriteLock;
import java.util.concurrent.locks.ReentrantReadWriteLock;

import javax.annotation.PostConstruct;

import org.apache.commons.lang3.RandomUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import com.google.common.collect.HashMultimap;
import com.google.common.collect.Multimap;
import com.sun.tools.classfile.StackMap_attribute.stack_map_frame;
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
    private static Map<String, List<String>> configMap = new HashMap<>();
    @Autowired
    private FileIpDao fileIpDao;

    @PostConstruct
    public void init() {
        reload();
    }

    public void reload() {
        List<FileIpPo> list = fileIpDao.getAll();
        Multimap<String, String> map = HashMultimap.create();
        for (FileIpPo p : list) {
            map.put(p.getType(), p.getIp());
        }
        try {
            lock.writeLock().lock();
            for(String key:map.keys()){
                configMap.put(key, new ArrayList<>(map.get(key)));
            }
            LOGGER.info("FileIp metaMap size = {}", configMap.size());
        } finally {
            lock.writeLock().unlock();
        }
    }
    public static String  getIp(String type){
        List<String> list = configMap.get(type);
        int size = list.size();
        return list.get(RandomUtils.nextInt(0, size));
    }
}
