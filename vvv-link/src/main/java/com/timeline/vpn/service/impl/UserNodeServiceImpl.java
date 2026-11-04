package com.timeline.vpn.service.impl;

import com.timeline.vpn.Constant;
import com.timeline.vpn.dao.db.UserNodeDao;
import com.timeline.vpn.exception.DataException;
import com.timeline.vpn.model.form.UserNodeDelForm;
import com.timeline.vpn.model.form.UserNodeSaveForm;
import com.timeline.vpn.model.vo.UserNodeVo;
import com.timeline.vpn.service.UserNodeService;
import com.timeline.vpn.util.ShareLinkInfo;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
public class UserNodeServiceImpl implements UserNodeService {

    @Autowired
    private UserNodeDao userNodeDao;

    @Override
    public List<UserNodeVo> list(String userName) {
        return userNodeDao.listByUser(userName);
    }

    @Override
    public UserNodeVo save(String userName, UserNodeSaveForm form) {
        // 服务端重新解析链接：协议、地址、端口以这里为准，不信任客户端
        ShareLinkInfo info;
        try {
            info = ShareLinkInfo.parse(form.getLink());
        } catch (IllegalArgumentException e) {
            throw new DataException(Constant.ResultMsg.RESULT_DATA_ERROR);
        }

        UserNodeVo node = new UserNodeVo();
        node.name = form.getName() == null || form.getName().trim().isEmpty()
                ? info.name : form.getName().trim();
        node.protocol = info.protocol;
        node.server = info.server;
        node.port = info.port;
        node.link = form.getLink().trim();

        if (form.getLink() == null || form.getLink().trim().isEmpty()) {
            throw new DataException(Constant.ResultMsg.RESULT_DATA_EMPETY_ERROR);
        }
        if (form.getId() == null || form.getId().isEmpty()) {
            node.id = UUID.randomUUID().toString();
            userNodeDao.insert(userName, node);
        } else {
            node.id = form.getId();
            if (userNodeDao.update(userName, node) == 0) {
                // 节点不存在，或者属于别的用户：统一按不存在处理，不泄露他人数据
                throw new DataException(Constant.ResultMsg.RESULT_DATA_ERROR);
            }
        }
        node.updatedAt = System.currentTimeMillis();
        return node;
    }

    @Override
    public void delete(String userName, UserNodeDelForm form) {
        userNodeDao.delete(userName, form.getId());
    }
}
