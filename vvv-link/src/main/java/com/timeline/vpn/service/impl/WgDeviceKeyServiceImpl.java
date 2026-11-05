package com.timeline.vpn.service.impl;

import com.timeline.vpn.dao.db.WgDeviceKeyDao;
import com.timeline.vpn.exception.DataException;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.po.WgDeviceKeyPo;
import com.timeline.vpn.service.WgDeviceKeyService;
import com.timeline.vpn.util.WgAddress;
import com.timeline.vpn.util.WgAddressAllocator;
import org.apache.commons.lang3.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;

/**
 * @author gqli
 * @date 2026年11月1日
 * @version V1.0
 */
@Service
public class WgDeviceKeyServiceImpl implements WgDeviceKeyService {

    private static final Logger LOGGER =
            LoggerFactory.getLogger(WgDeviceKeyServiceImpl.class);

    /** WireGuard 公钥固定 32 字节，Base64 编码后恒为 44 个字符（含末尾 '='）。 */
    private static final int WG_PUBLIC_KEY_LENGTH = 44;

    @Autowired
    private WgDeviceKeyDao wgDeviceKeyDao;

    @Override
    public String register(BaseQuery baseQuery, String devId, String publicKey) {
        String finalDevId = resolveDevId(baseQuery, devId);
        if (StringUtils.isBlank(finalDevId)) {
            throw new DataException("缺少设备标识");
        }
        if (StringUtils.isBlank(publicKey)) {
            throw new DataException("缺少 publicKey");
        }
        String key = publicKey.trim();
        // 长度先卡一道：非法长度直接拒绝，避免脏数据进库后才在握手阶段暴露。
        // 真正的合法性（是否 32 字节的 Curve25519 点）由 wg-go 在握手时校验。
        if (key.length() != WG_PUBLIC_KEY_LENGTH) {
            throw new DataException("publicKey 长度非法，应为 44 字符的 Base64");
        }
        int index;
        try {
            index = new WgAddressAllocator(new DaoStore()).register(finalDevId, key);
        } catch (WgAddressAllocator.PoolExhaustedException e) {
            LOGGER.error("wireguard 地址池已用完，无法为新设备分配地址");
            throw new DataException("服务繁忙，请稍后再试");
        }
        LOGGER.info("wireguard register devId={} addrIndex={}", finalDevId, index);
        return WgAddress.toCidr(index);
    }

    @Override
    public String peersText() {
        return WgAddress.formatPeers(wgDeviceKeyDao.listAll());
    }

    /** 把分配器需要的存储操作接到 DAO；唯一键冲突转成 false 交给分配器重试。 */
    private final class DaoStore implements WgAddressAllocator.Store {
        @Override
        public Integer findIndex(String devId) {
            WgDeviceKeyPo po = wgDeviceKeyDao.getByDevId(devId);
            return po == null ? null : po.getAddrIndex();
        }

        @Override
        public void updateKey(String devId, String publicKey) {
            wgDeviceKeyDao.updateKey(devId, publicKey);
        }

        @Override
        public boolean tryInsert(String devId, String publicKey, int index) {
            try {
                wgDeviceKeyDao.insert(devId, publicKey, index);
                return true;
            } catch (DuplicateKeyException e) {
                return false;
            }
        }

        @Override
        public Integer nextFreeIndex() {
            return wgDeviceKeyDao.nextFreeIndex(WgAddress.INDEX_MIN, WgAddress.INDEX_MAX);
        }
    }

    @Override
    public void unregister(BaseQuery baseQuery, String devId) {
        String finalDevId = resolveDevId(baseQuery, devId);
        if (StringUtils.isBlank(finalDevId)) {
            return;
        }
        int rows = wgDeviceKeyDao.deleteByDevId(finalDevId);
        LOGGER.info("wireguard unregister devId={} rows={}", finalDevId, rows);
    }

    @Override
    public String getPublicKey(String devId) {
        if (StringUtils.isBlank(devId)) {
            return null;
        }
        WgDeviceKeyPo po = wgDeviceKeyDao.getByDevId(devId);
        return po == null ? null : po.getPublicKey();
    }

    /**
     * 设备号优先取请求体里的值；缺失时回退到请求头里的设备号，
     * 与 host 接口里 {@code baseQuery.getAppInfo().getDevId()} 的取法保持一致。
     */
    private String resolveDevId(BaseQuery baseQuery, String devId) {
        if (StringUtils.isNotBlank(devId)) {
            return devId.trim();
        }
        if (baseQuery != null && baseQuery.getAppInfo() != null) {
            return baseQuery.getAppInfo().getDevId();
        }
        return null;
    }
}
