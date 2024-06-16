package com.timeline.vpn.model.form;

import com.timeline.vpn.Constant;
import com.timeline.vpn.model.param.PageBaseParam;
import jakarta.validation.constraints.Min;
import org.springframework.beans.BeanUtils;


/**
 * @author gqli
 * @version V1.0
 * @Title: PageBaseForm.java
 * @Package com.homelink.folio.api.form
 * @date 2015年7月24日 下午8:00:00
 */
public class PageBaseForm {
    @Min(value = 0)
    private int start;
    @Min(value = 1)
    private int limit = Constant.MIN_PAGESIZE;


    public int getStart() {
        return start;
    }

    public void setStart(int start) {
        this.start = start;
    }

    public int getLimit() {
        return limit;
    }

    public void setLimit(int limit) {
        limit = limit<Constant.MIN_PAGESIZE?Constant.MIN_PAGESIZE:limit;
        this.limit = limit;
    }

    public PageBaseParam toParam() {
        PageBaseParam param = new PageBaseParam();
        BeanUtils.copyProperties(this, param);
        return param;
    }
}
