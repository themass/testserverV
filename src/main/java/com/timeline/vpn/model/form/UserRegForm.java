package com.timeline.vpn.model.form;

import org.hibernate.validator.constraints.NotBlank;

import com.timeline.vpn.Constant;

/**
 * @author gqli
 * @date 2016年8月9日 上午10:56:12
 * @version V1.0
 */
public class UserRegForm {
    @NotBlank(message=Constant.ResultMsg.RESULT_DATA_EMPETY_ERROR)
    private String name;
    @NotBlank(message=Constant.ResultMsg.RESULT_DATA_EMPETY_ERROR)
    private String pwd;
    @NotBlank(message=Constant.ResultMsg.RESULT_DATA_EMPETY_ERROR)
    private String rePwd;
    @NotBlank(message=Constant.ResultMsg.RESULT_DATA_EMPETY_ERROR)
    private String sex;
    public String getName() {
        return name;
    }
    public void setName(String name) {
        this.name = name;
    }
    public String getPwd() {
        return pwd;
    }
    public void setPwd(String pwd) {
        this.pwd = pwd;
    }
    public String getRePwd() {
        return rePwd;
    }
    public void setRePwd(String rePwd) {
        this.rePwd = rePwd;
    }
    public String getSex() {
        return sex;
    }
    public void setSex(String sex) {
        this.sex = sex;
    }
    
}

