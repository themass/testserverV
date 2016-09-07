package com.timeline.vpn.service.impl;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.util.CollectionUtils;

import com.timeline.vpn.Constant;
import com.timeline.vpn.dao.db.HostDao;
import com.timeline.vpn.dao.db.LocationDao;
import com.timeline.vpn.dao.db.FreeUseinfoDao;
import com.timeline.vpn.dao.db.ServerDao;
import com.timeline.vpn.exception.DataException;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.po.HostPo;
import com.timeline.vpn.model.po.FreeUseinfoPo;
import com.timeline.vpn.model.po.ServerPo;
import com.timeline.vpn.model.vo.InfoListVo;
import com.timeline.vpn.model.vo.LocationVo;
import com.timeline.vpn.model.vo.ServerVo;
import com.timeline.vpn.model.vo.VoBuilder;
import com.timeline.vpn.service.HostService;

/**
 * @author gqli
 * @date 2016年3月7日 下午1:44:16
 * @version V1.0
 */
@Service
public class HostServerImpl implements HostService {
    @Autowired
    private ServerDao serverDao;
    @Autowired
    private HostDao hostDao;
    @Autowired
    private LocationDao cityDao;
    @Autowired
    private FreeUseinfoDao freeUseinfoDao;

    @Override
    public ServerVo getHostInfo(BaseQuery baseQuery, int location) {
        List<ServerPo> list = serverDao.get(Constant.SERVER_TYPE_FREE);
        if (CollectionUtils.isEmpty(list)) {
            throw new DataException(Constant.ResultMsg.RESULT_DATA_ERROR);
        }
        FreeUseinfoPo setting = freeUseinfoDao.get(baseQuery.getAppInfo().getDevId());
        long useTime = 0;
        if (setting != null) {
            useTime = setting.getUseTime();
        }
        long remainingTime = Constant.FREE_TIME - useTime;
        if (remainingTime <= 0) {
            throw new DataException(Constant.ResultMsg.RESULT_USE_TIME_ERROR);
        }
        List<HostPo> hostList = null;

        if (location == Constant.LOCATION_ALL) {
            hostList = hostDao.getAll();
        } else {
            hostList = hostDao.getByLocation(location);
        }
        if (CollectionUtils.isEmpty(hostList)) {
            throw new DataException(Constant.ResultMsg.RESULT_DATA_ERROR);
        }
        return VoBuilder.buildServerVo(list.get(0), hostList, remainingTime);
    }

    //
    // @Override
    // public RetInfoVo getCert(BaseQuery baseQuery, String ip) {
    // String ca = "-----BEGIN CERTIFICATE-----\n" +
    // "MIIDNDCCAhygAwIBAgIIYZKnlsSZupswDQYJKoZIhvcNAQEFBQAwODELMAkGA1UE\n" +
    // "BhMCQ04xETAPBgNVBAoTCHRpbWVsaW5lMRYwFAYDVQQDEw1zdHJvbmdTd2FuIENB\n" +
    // "MB4XDTE2MDMwNzE1MDI1MVoXDTE5MDMwNzE1MDI1MVowODELMAkGA1UEBhMCQ04x\n" +
    // "ETAPBgNVBAoTCHRpbWVsaW5lMRYwFAYDVQQDEw1zdHJvbmdTd2FuIENBMIIBIjAN\n" +
    // "BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAn7PC6woHV7MsUR6UQ3AGdVRhIVpz\n" +
    // "teQELSR4x8x2GmTwr+qc/pQM6a3ON+clXXWn1MWGlSoXtFIYYN58aKJoRVscwtvv\n" +
    // "kUGlZvrkfbd8xaJNOu8+7EESspee4vNsXiiPnDWgIFxGvgnZHOi0fkEMNkLeAbp8\n" +
    // "gGsU/2jMkMIMrCK2E+CewAEmUkLUBWf/7He2W7FbEU96Ti/qWS46Rg2YdWTVDERI\n" +
    // "ohYOCtFIb0REl8qe2Z87Ew8Piup+GxqAV2rPDiE7B8ZtBXKWwcu43CFtGD8gLkKQ\n" +
    // "Av2Z37DKyewE58TAQq4ia7G7glKHvGHamI5RBmkujS/jufiK/ENlD8c29QIDAQAB\n" +
    // "o0IwQDAPBgNVHRMBAf8EBTADAQH/MA4GA1UdDwEB/wQEAwIBBjAdBgNVHQ4EFgQU\n" +
    // "xBifVNA7HPUDlNZ4sWHed/dXrVQwDQYJKoZIhvcNAQEFBQADggEBAG61czb8yaFX\n" +
    // "djiXEbVQpDvdH0XkcdvHobSl8OghP1pO4IFfX27AoYYWrjBzwKg2nT1D/TzarJMl\n" +
    // "pSQZ0a/0nfNm7lqgammkMeC2wkXIeuFBOc0MC6TjmNKWWJjxzqn63XJhOQcPNlyZ\n" +
    // "klkzMb68vu2X9XvwkQmlpMIHUFgbyM93TzWU9BizG/K41n2nd4cbAdIqY7lcMHvL\n" +
    // "kfHrdtenGVSr74fe3DbTCsCcSXP2TC+DNi9wv0NYll9pUsjYt4NsqwV3MmubRXG3\n" +
    // "d3hFsH8Awh1MXQ6yr1ehZ+t/0jqMDgAyINK7ESq/5guVH23Zw1EMVEzqTiDkHqQ/\n" +
    // "FxyormgtRvU=\n" +
    // "-----END CERTIFICATE-----";
    // return new RetInfoVo(ca);
    // }
    @Override
    public InfoListVo<LocationVo> getAllLocation() {
        return VoBuilder.buildListInfoVo(cityDao.getAll(), LocationVo.class);
    }

}

