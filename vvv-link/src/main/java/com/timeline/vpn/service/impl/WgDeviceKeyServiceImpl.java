package com.timeline.vpn.service.impl;

import com.timeline.vpn.dao.db.WgDeviceKeyDao;
import com.timeline.vpn.exception.DataException;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.po.WgDeviceKeyPo;
import com.timeline.vpn.service.WgDeviceKeyService;
import org.apache.commons.lang3.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
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
    public void register(BaseQuery baseQuery, String devId, String publicKey) {
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
        int rows = wgDeviceKeyDao.upsert(finalDevId, key);
        LOGGER.info("wireguard register devId={} rows={}", finalDevId, rows);
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
