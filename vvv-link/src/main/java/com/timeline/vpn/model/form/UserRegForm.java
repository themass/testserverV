package com.timeline.vpn.model.form;

import com.timeline.vpn.Constant;
import lombok.Data;
import lombok.ToString;
import org.hibernate.validator.constraints.NotBlank;

/**
 * @author gqli
 * @date 2016年8月9日 上午10:56:12
 * @version V1.0
 */
@ToString
@Data
public class UserRegForm {
    @NotBlank(message = Constant.ResultMsg.RESULT_DATA_EMPETY_ERROR)
    private String name;
    @NotBlank(message = Constant.ResultMsg.RESULT_DATA_EMPETY_ERROR)
    private String pwd;
    @NotBlank(message = Constant.ResultMsg.RESULT_DATA_EMPETY_ERROR)
    private String rePwd;
    @NotBlank(message = Constant.ResultMsg.RESULT_DATA_EMPETY_ERROR)
    private String sex;
    private String code;
    private String channel;
    private String email;
    private String ref;

}

