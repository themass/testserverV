package com.timeline.vpn.web.common;

import java.util.Map;

import org.springframework.web.servlet.view.json.MappingJackson2JsonView;

import com.timeline.vpn.Constant;
import com.timeline.vpn.model.vo.JsonResult;
import com.timeline.vpn.util.JsonUtil;

public class MappingJacksonJsonViewWrapper extends MappingJackson2JsonView {
    private String modelKey;

    public MappingJacksonJsonViewWrapper() {
        super();
        setObjectMapper(JsonUtil.getMapper());
    }

    public String getModelKey() {
        return modelKey;
    }

    public void setModelKey(String modelKey) {
        this.modelKey = modelKey;
    }

    @Override
    protected Object filterModel(Map<String, Object> model) {
        Object obj = model.get(modelKey);
        if (obj == null) {
            obj = new JsonResult(Constant.ResultErrno.ERRNO_SYSTEM, "访问的URL不存在");
        }
        return obj;
    }
}
