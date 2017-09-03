package com.timeline.vpn.model.form;
/**
 * @author gqli
 * @date 2017年8月17日 下午8:01:14
 * @version V1.0
 */
public class ChannelItemsForm extends PageBaseForm{
    private String channel;
    private String keyword;
    public String getChannel() {
        return channel;
    }

    public void setChannel(String channel) {
        this.channel = channel;
    }

    public String getKeyword() {
        return keyword;
    }

    public void setKeyword(String keyword) {
        this.keyword = keyword;
    }
    
}

