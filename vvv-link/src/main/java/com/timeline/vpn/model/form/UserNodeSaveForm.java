package com.timeline.vpn.model.form;

import lombok.Data;

/** 保存用户节点：id 为空表示新增。链接由服务端重新解析，不信任客户端提交的协议和地址。 */
@Data
public class UserNodeSaveForm {
    private String id;
    private String name;
    private String link;
}
