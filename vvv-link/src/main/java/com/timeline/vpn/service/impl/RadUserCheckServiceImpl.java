package com.timeline.vpn.service.impl;

import com.timeline.vpn.Constant;
import com.timeline.vpn.dao.db.RadUserCheckDao;
import com.timeline.vpn.model.po.RadCheck;
import com.timeline.vpn.model.po.RadUserGroup;
import com.timeline.vpn.service.RadUserCheckService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * @author gqli
 * @date 2016年12月14日 下午12:55:41
 * @version V1.0
 */
@Service
public class RadUserCheckServiceImpl implements RadUserCheckService{
    @Autowired
    private RadUserCheckDao radUserCheck;
    @Override
    @Transactional
    public RadCheck addRadUser(String name, String pass, String groupName) {
        RadCheck check = new RadCheck();
        check.setUserName(name);
        check.setAttribute(Constant.RAD_PASS);
        check.setOp(Constant.RAD_EQ);
        check.setValue(pass);
        radUserCheck.replaceUserPass(check);
        RadUserGroup group = new RadUserGroup();
        group.setGroupName(groupName);
        group.setPriority(Constant.RAD_PRIORITY_DEF);
        group.setUserName(name);
        radUserCheck.replaceUserGroup(group);
        return check;
    }
    @Override
    public RadCheck getRadUser(String name) {
        return radUserCheck.getUserPass(name);
    }
    @Override
    public RadUserGroup updateRadUserGroup(String name, String group) {
        RadUserGroup g = new RadUserGroup();
        g.setGroupName(group);
        g.setPriority(Constant.RAD_PRIORITY_DEF);
        g.setUserName(name);
        radUserCheck.replaceUserGroup(g);
        return g;
    }

}

