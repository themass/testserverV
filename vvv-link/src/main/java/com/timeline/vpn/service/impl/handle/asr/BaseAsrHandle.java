package com.timeline.vpn.service.impl.handle.asr;

import com.timeline.vpn.model.form.AsrContentForm;
import com.timeline.vpn.model.form.ChatContentForm;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.AsrResponseVo;
import com.timeline.vpn.model.vo.Choice;
import com.timeline.vpn.service.strategy.BaseSupportHandle;
import okhttp3.OkHttpClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.TimeUnit;

/**
 * @author gqli
 * @version V1.0
 * @date 2017年11月28日 下午6:32:52
 */
public abstract class BaseAsrHandle implements BaseSupportHandle<Integer> {
    protected static final Logger LOGGER =
            LoggerFactory.getLogger(BaseAsrHandle.class);
    public static OkHttpClient.Builder builder = new OkHttpClient.Builder();
    public static OkHttpClient httpClient;
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

    public abstract AsrResponseVo asrHandlerBase(BaseQuery baseQuery, AsrContentForm chatContentForm) throws Exception;
    @Override
    public boolean isDefault() {
        return false;
    }
}

