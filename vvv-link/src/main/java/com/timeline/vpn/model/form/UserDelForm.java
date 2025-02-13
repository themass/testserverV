package com.timeline.vpn.model.form;

import com.timeline.vpn.Constant;
import lombok.Data;
import org.hibernate.validator.constraints.NotBlank;

/**
 * @author gqli
 * @date 2016年8月9日 上午10:56:12
 * @version V1.0
 */
@Data
public class UserDelForm {
    private String name;
    private String pwd;

}

