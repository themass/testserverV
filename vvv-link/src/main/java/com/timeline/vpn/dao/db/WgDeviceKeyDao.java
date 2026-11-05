package com.timeline.vpn.dao.db;

import com.timeline.vpn.model.po.WgDeviceKeyPo;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

/**
 * WireGuard 设备公钥注册表 DAO。
 *
 * @author gqli
 * @date 2026年11月1日
 * @version V1.0
 */
@Mapper
public interface WgDeviceKeyDao {

    /** 更新已有设备的公钥，地址序号不变。 */
    int updateKey(@Param("devId") String devId, @Param("publicKey") String publicKey);

    /**
     * 插入新设备。devId 或 addrIndex 的唯一键冲突时抛 DuplicateKeyException，
     * 由 {@link com.timeline.vpn.util.WgAddressAllocator} 重新取下标再试。
     */
    int insert(@Param("devId") String devId, @Param("publicKey") String publicKey,
               @Param("addrIndex") int addrIndex);

    /** 当前最小的空闲序号（范围 min~max）；池满返回 null。 */
    Integer nextFreeIndex(@Param("min") int min, @Param("max") int max);

    /** 全部设备，按地址序号排序，供服务器同步。 */
    java.util.List<WgDeviceKeyPo> listAll();

    WgDeviceKeyPo getByDevId(@Param("devId") String devId);

    int deleteByDevId(@Param("devId") String devId);
}
