package com.timeline.vpn.model.chat;

/**
 * @Author： liguoqing
 * @Date： 2024/4/12 19:53
 * @Describe：
 */
public class ChatMsg {
    private String role;
    private String content;

    public ChatMsg() {
    }

    public ChatMsg(String role, String content) {
        this.role = role;
        this.content = content;
    }

    public String getRole() {
        return role;
    }

    public void setRole(String role) {
        this.role = role;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }
}
