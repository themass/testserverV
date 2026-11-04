package com.timeline.vpn.model.vo;

/** 用户自定义节点。字段与客户端 UserNodeStore.UserNode 对应。 */
public class UserNodeVo {
    public String id;
    public String name;
    public String protocol;
    public String server;
    public int port;
    public String link;
    /** 更新时间（毫秒），客户端以服务端为准覆盖本地。 */
    public long updatedAt;
}
