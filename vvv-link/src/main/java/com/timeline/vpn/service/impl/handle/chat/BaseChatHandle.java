package com.timeline.vpn.service.impl.handle.chat;

import com.timeline.vpn.model.form.ChatContentForm;
import com.timeline.vpn.model.form.SimpleMessage;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.Choice;
import com.timeline.vpn.service.strategy.BaseSupportHandle;
import com.timeline.vpn.util.JsonUtil;
import okhttp3.OkHttpClient;
import org.apache.commons.lang3.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;
import java.util.Optional;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;

/**
 * @author gqli
 * @version V1.0
 * @date 2017年11月28日 下午6:32:52
 */
public abstract class BaseChatHandle implements BaseSupportHandle<Integer> {
    protected static final Logger LOGGER =
            LoggerFactory.getLogger(BaseChatHandle.class);
    public static OkHttpClient.Builder builder = new OkHttpClient.Builder();
    public static okhttp3.OkHttpClient httpClient;
    static {
        // 设置超时时间
        builder.connectTimeout(10, TimeUnit.SECONDS);  // 连接超时
        builder.readTimeout(10, TimeUnit.SECONDS);     // 读取超时
        builder.writeTimeout(10, TimeUnit.SECONDS);    // 写入超时
        // 设置长连接保持
        int maxIdleConnections = 15; // 最大空闲连接数
        long keepAliveDuration = 30; // 最大空闲时间（秒）
        builder.connectionPool(new okhttp3.ConnectionPool(maxIdleConnections, keepAliveDuration, TimeUnit.SECONDS));
        httpClient = builder.build();
    }

    public abstract Choice chatWithGptBase(BaseQuery baseQuery, ChatContentForm chatContentForm) throws Exception;
    @Override
    public boolean isDefault() {
        return false;
    }
}

