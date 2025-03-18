package com.timeline.vpn.model.form;

import lombok.Data;
import lombok.ToString;

@Data
@ToString
public class ChatContentForm {
    private String content;
    private String text;
    private String id;
    private String charater;
    private String settingName;
    private long sessionId;
}
