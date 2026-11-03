package com.timeline.vpn.model.form;

import com.timeline.vpn.Constant;
import org.hibernate.validator.constraints.NotBlank;

/** 已登录用户修改密码。 */
public class UserChangePwdForm {
    @NotBlank(message = Constant.ResultMsg.RESULT_DATA_EMPETY_ERROR)
    private String oldPwd;
    @NotBlank(message = Constant.ResultMsg.RESULT_DATA_EMPETY_ERROR)
    private String newPwd;
    @NotBlank(message = Constant.ResultMsg.RESULT_DATA_EMPETY_ERROR)
    private String rePwd;

    public String getOldPwd() { return oldPwd; }
    public void setOldPwd(String oldPwd) { this.oldPwd = oldPwd; }
    public String getNewPwd() { return newPwd; }
    public void setNewPwd(String newPwd) { this.newPwd = newPwd; }
    public String getRePwd() { return rePwd; }
    public void setRePwd(String rePwd) { this.rePwd = rePwd; }
}
