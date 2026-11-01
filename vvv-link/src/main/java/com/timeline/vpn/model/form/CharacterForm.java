package com.timeline.vpn.model.form;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;
import lombok.ToString;

/**
 * 用户创建/编辑自定义角色的表单。
 *
 * 官方角色不通过这个表单管理（目前仍是直接写库），这里只服务
 * "用户上传自定义角色"这一个场景。
 */
@Data
@ToString
public class CharacterForm {
    /** 编辑时必填；创建时忽略。 */
    private Integer id;

    @NotBlank
    private String title;

    /** 人设正文，组装 system prompt 用。 */
    @NotBlank
    private String content;

    /** 头像 url，可选。 */
    private String url;

    private String extra;
}
