package com.timeline.vpn.model.vo;

/**
 * @Author： liguoqing
 * @Date： 2024/4/14 10:34
 * @Describe：
 */
public class CharacterVo {
    private int id;
    private String title;
    private String content;
    private String url;
    private String extra;
    /** 是否我自己上传的角色；官方角色为 false。客户端用这个字段决定"编辑/删除"按钮是否显示。 */
    private boolean mine;

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public String getUrl() {
        return url;
    }

    public void setUrl(String url) {
        this.url = url;
    }

    public String getExtra() {
        return extra;
    }

    public void setExtra(String extra) {
        this.extra = extra;
    }

    public boolean isMine() {
        return mine;
    }

    public void setMine(boolean mine) {
        this.mine = mine;
    }
}
