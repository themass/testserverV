package com.timeline.vpn.model.form;

import org.hibernate.validator.constraints.NotBlank;

import com.timeline.vpn.Constant;

/**
 * @author gqli
 * @date 2016年3月7日 下午1:11:54
 * @version V1.0
 */
public class LoginForm {
    @NotBlank(message = Constant.ResultMsg.RESULT_DATA_EMPETY_ERROR)
    private String name;
    @NotBlank(message = Constant.ResultMsg.RESULT_DATA_EMPETY_ERROR)
    private String pwd;
    private Integer score;
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

    public Integer getScore() {
        return score;
    }

    public void setScore(Integer score) {
        this.score = score;
    }

}

