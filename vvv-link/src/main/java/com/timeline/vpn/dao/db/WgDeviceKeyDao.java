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

    /**
     * 插入或覆盖（devId 唯一）。
     * <p>
     * 用 upsert 而不是"先查后改"：两个并发请求同时注册同一设备时，
     * 先查后改会产生唯一键冲突；单条 INSERT ... ON DUPLICATE KEY UPDATE 是原子的。
     *
     * @return 受影响行数（1 = 新建，2 = 更新，0 = 数据未变化）
     */
    int upsert(@Param("devId") String devId, @Param("publicKey") String publicKey);

    WgDeviceKeyPo getByDevId(@Param("devId") String devId);

    int deleteByDevId(@Param("devId") String devId);
}
