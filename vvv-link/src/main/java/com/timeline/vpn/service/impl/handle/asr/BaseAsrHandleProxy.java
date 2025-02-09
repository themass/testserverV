package com.timeline.vpn.service.impl.handle.asr;

import com.timeline.vpn.model.chat.LlmRecord;
import com.timeline.vpn.model.chat.UserRole;
import com.timeline.vpn.model.form.AsrContentForm;
import com.timeline.vpn.model.form.ChatContentForm;
import com.timeline.vpn.model.form.SimpleMessage;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.AsrResponseVo;
import com.timeline.vpn.model.vo.Choice;
import com.timeline.vpn.service.CacheRedisUtil;
import com.timeline.vpn.util.JsonUtil;
import org.apache.commons.lang3.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * @author gqli
 * @version V1.0
 * @date 2017年11月28日 下午6:32:52
 */
public abstract class BaseAsrHandleProxy extends BaseAsrHandle {
    protected static final Logger LOGGER =
            LoggerFactory.getLogger(BaseAsrHandleProxy.class);

    @Override
    public AsrResponseVo asrHandlerBase(BaseQuery baseQuery, AsrContentForm chatContentForm) throws Exception{
        AsrResponseVo asrResponseVo = asrHandler(baseQuery, chatContentForm);
        asrResponseVo.setId(chatContentForm.getId());
        asrResponseVo.setLang(baseQuery.getAppInfo().getLang());
        return asrResponseVo;
    }
    public abstract AsrResponseVo asrHandler(BaseQuery baseQuery, AsrContentForm chatContentForm) throws Exception;
    @Override
    public boolean isDefault() {
        return false;
    }

}

