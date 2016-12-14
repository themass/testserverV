package com.timeline.vpn.web.common;

import java.util.Map;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.springframework.web.servlet.view.json.MappingJackson2JsonView;

import com.timeline.vpn.Constant;
import com.timeline.vpn.model.param.DevApp;
import com.timeline.vpn.model.vo.JsonResult;
import com.timeline.vpn.util.AES2;
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
    @Override
    protected Object filterAndWrapModel(Map<String, Object> model, HttpServletRequest request) {
        // TODO Auto-generated method stub
        return super.filterAndWrapModel(model, request);
    }

    @Override
    protected void renderMergedOutputModel(Map<String, Object> model, HttpServletRequest request,
            HttpServletResponse response) throws Exception {
        if(model!=null && model.get(modelKey)!=null){
            JsonResult result = (JsonResult)model.get(modelKey);
            DevApp app = DevAppContext.get();
            if(result.getData()!=null){
                String json = JsonUtil.writeValueAsString(result.getData());
                String encry = AES2.encode(json, app.getAuthKey());
                result.setData(encry);
                model.put(modelKey, result);
            }
        }
        super.renderMergedOutputModel(model, request, response);
    }
    
}
