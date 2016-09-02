package com.timeline.vpn.model.vo;

import java.util.List;

import javax.servlet.http.HttpServletRequest;

import org.springframework.util.CollectionUtils;
import org.springframework.validation.FieldError;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;
import org.springframework.web.servlet.support.RequestContext;

import com.timeline.vpn.Constant;

public class JsonResult {
    public static final String MODEL_KEY = "jsonResult";
    private int errno = 0; // 是否成功
    private Object data;
    private String error;
    private long cost;

    /**
     * 根据结果和消息生成返回json
     * 
     * @param status 是否成功
     * @param msg 消息
     */
    public JsonResult(int status, String msg) {
        this(null, status, msg);
    }

    public JsonResult(Object data, int status, String msg) {
        this.data = data;
        this.errno = status;
        this.error = msg;
    }

    public JsonResult() {}

    public JsonResult(Object data) {
        this.data = data;
        this.errno = Constant.ResultErrno.ERRNO_SUCCESS;
    }

    /**
     * form校验错误时返回结果
     * 
     * @param errorList 错误列表
     */
    public JsonResult(List<FieldError> errorList) {
        HttpServletRequest request =
                ((ServletRequestAttributes) RequestContextHolder.getRequestAttributes())
                        .getRequest();
        RequestContext rc = new RequestContext(request);
        this.errno = Constant.ResultErrno.ERRNO_PARAM;
        if (!CollectionUtils.isEmpty(errorList)) {
            this.error = rc.getMessage(errorList.get(0));
        }
    }


    public Object getData() {
        return data;
    }

    public void setData(Object data) {
        this.data = data;
    }


    public int getErrno() {
        return errno;
    }

    public void setErrno(int errno) {
        this.errno = errno;
    }

    public String getError() {
        return error;
    }

    public void setError(String error) {
        this.error = error;
    }

    public long getCost() {
        return cost;
    }

    public void setCost(long cost) {
        this.cost = cost;
    }



}
