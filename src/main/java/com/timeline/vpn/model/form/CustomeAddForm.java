package com.timeline.vpn.model.form;

import org.hibernate.validator.constraints.NotBlank;

import com.timeline.vpn.Constant;

/**
 * Created by themass on 2017/2/14.
 */

public class CustomeAddForm {
    private Integer id;
    @NotBlank(message = Constant.ResultMsg.RESULT_DATA_EMPETY_ERROR)
    private String title;
    @NotBlank(message = Constant.ResultMsg.RESULT_DATA_EMPETY_ERROR)
    private String url;
    public String getTitle() {
        return title;
    }
    public void setTitle(String title) {
        this.title = title;
    }
    public String getUrl() {
        return url;
    }
    public void setUrl(String url) {
        this.url = url;
    }
    public Integer getId() {
        return id;
    }
    public void setId(Integer id) {
        this.id = id;
    }
    

}
