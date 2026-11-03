package com.timeline.vpn.model.form;

import com.timeline.vpn.Constant;
import org.hibernate.validator.constraints.NotBlank;

/** 通过邮箱验证码重置密码。 */
public class UserResetPwdForm {
    @NotBlank(message = Constant.ResultMsg.RESULT_DATA_EMPETY_ERROR)
    private String email;
    @NotBlank(message = Constant.ResultMsg.RESULT_DATA_EMPETY_ERROR)
    private String code;
    @NotBlank(message = Constant.ResultMsg.RESULT_DATA_EMPETY_ERROR)
    private String pwd;
    @NotBlank(message = Constant.ResultMsg.RESULT_DATA_EMPETY_ERROR)
    private String rePwd;

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getCode() { return code; }
    public void setCode(String code) { this.code = code; }
    public String getPwd() { return pwd; }
    public void setPwd(String pwd) { this.pwd = pwd; }
    public String getRePwd() { return rePwd; }
    public void setRePwd(String rePwd) { this.rePwd = rePwd; }
}
