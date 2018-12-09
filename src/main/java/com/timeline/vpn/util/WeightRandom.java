package com.timeline.vpn.util;
import java.util.List;
import java.util.SortedMap;
import java.util.TreeMap;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.google.common.base.Preconditions;
import com.timeline.vpn.model.po.HostPo;
 
 
public class WeightRandom {
    private TreeMap<Double, HostPo> weightMap = new TreeMap<Double, HostPo>();
    private static final Logger logger = LoggerFactory.getLogger(WeightRandom.class);
 
    public WeightRandom(List<HostPo> list) {
        Preconditions.checkNotNull(list, "list can NOT be null!");
        for (HostPo po : list) {
            double lastWeight = this.weightMap.size() == 0 ? 0 : this.weightMap.lastKey().doubleValue();//统一转为double
            this.weightMap.put(po.getWeight() + lastWeight, po);//权重累加
        }
    }
 
    public HostPo random() {
        double randomWeight = this.weightMap.lastKey() * Math.random();
        SortedMap<Double, HostPo> tailMap = this.weightMap.tailMap(randomWeight, false);
        return this.weightMap.get(tailMap.firstKey());
    }
 
}