package com.timeline.vpn.model.param;

import com.timeline.vpn.model.po.UserPo;

/**
 *
 * @author gqli
 * @date 2015年7月28日 下午8:35:33
 * @version V1.0
 */
public class BaseQuery {
    private DevApp appInfo;
    private String token;
    private UserPo user;

    public DevApp getAppInfo() {
        return appInfo;
    }

    public void setAppInfo(DevApp appInfo) {
        this.appInfo = appInfo;
    }

    public String getToken() {
        return token;
    }

    public void setToken(String token) {
        this.token = token;
    }

    public UserPo getUser() {
        return user;
    }

    public void setUser(UserPo user) {
        this.user = user;
    }

    @Override
    public String toString() {
        return "BaseQuery{" +
                "appInfo=" + appInfo +
                ", token='" + token + '\'' +
                ", user=" + user +
                '}';
    }
}
