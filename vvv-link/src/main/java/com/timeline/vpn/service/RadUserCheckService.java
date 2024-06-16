package vpn.service;

import com.timeline.vpn.model.po.RadCheck;
import com.timeline.vpn.model.po.RadUserGroup;

/**
 * @author gqli
 * @date 2016年12月14日 下午12:54:09
 * @version V1.0
 */
public interface RadUserCheckService {
    public RadCheck addRadUser(String name,String pass,String group);
    public RadCheck getRadUser(String name);
    public RadUserGroup updateRadUserGroup(String name,String group);
}

