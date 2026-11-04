package com.timeline.vpn.service;

import com.timeline.vpn.model.form.UserNodeDelForm;
import com.timeline.vpn.model.form.UserNodeSaveForm;
import com.timeline.vpn.model.vo.UserNodeVo;

import java.util.List;

/** 用户自定义节点。所有方法都只作用于调用者本人的节点。 */
public interface UserNodeService {

    List<UserNodeVo> list(String userName);

    /** 新增或修改。链接由服务端解析；链接无效时抛出 IllegalArgumentException。 */
    UserNodeVo save(String userName, UserNodeSaveForm form);

    void delete(String userName, UserNodeDelForm form);
}
