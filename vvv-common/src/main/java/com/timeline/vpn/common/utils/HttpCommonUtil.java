package com.timeline.vpn.common.utils;


import lombok.extern.slf4j.Slf4j;
import org.apache.hc.client5.http.classic.methods.HttpGet;
import org.apache.hc.client5.http.classic.methods.HttpPost;
import org.apache.hc.client5.http.config.RequestConfig;
import org.apache.hc.client5.http.impl.classic.CloseableHttpClient;
import org.apache.hc.client5.http.impl.classic.CloseableHttpResponse;
import org.apache.hc.client5.http.impl.classic.HttpClientBuilder;
import org.apache.hc.client5.http.impl.io.PoolingHttpClientConnectionManager;
import org.apache.hc.core5.http.HttpEntity;
import org.apache.hc.core5.http.io.SocketConfig;
import org.apache.hc.core5.http.io.entity.EntityUtils;
import org.apache.hc.core5.util.Timeout;

import java.io.IOException;
import java.util.Map;

/**
 * gqli
 */
@Slf4j
public class HttpCommonUtil {
    private static CloseableHttpClient httpClient = null;
    private static final String DEFAULT_CHARSET = "UTF-8";
    public static final String UTF8_CHARSET = DEFAULT_CHARSET;
    private static final String UA =
            "Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)";
    private static RequestConfig config = RequestConfig.custom().setConnectTimeout(Timeout.ofSeconds(10)).setConnectionRequestTimeout(Timeout.ofSeconds(10)).build();
    private static HttpClientBuilder httpClientBuilder = null;
    private static final int MAX_PERROUTE = 800;
    private static final int MAXTOTAL = 2500;

    static {
        try {
            PoolingHttpClientConnectionManager connectionManager =
                    new PoolingHttpClientConnectionManager();
            connectionManager.setDefaultMaxPerRoute(MAX_PERROUTE); // 每个host最多100个连接
            connectionManager.setMaxTotal(MAXTOTAL); // 一共800个连接
            // 配置 Socket 参数
            SocketConfig socketConfig = SocketConfig.custom()
                    .setTcpNoDelay(true) // 禁用 Nagle 算法
                    .setSoKeepAlive(true) // 设置 TCP Keep-Alive
                    .build();
            connectionManager.setDefaultSocketConfig(socketConfig);

            httpClientBuilder = HttpClientBuilder.create()
                    .setDefaultRequestConfig(config).setUserAgent(UA)
                    .setConnectionManager(connectionManager);
            httpClient = httpClientBuilder.build();
        } catch (Exception e) {
            log.error("错误", e);
        }
    }

    /**
     * Constructor
     */
    private HttpCommonUtil() {
    }

    public static CloseableHttpResponse sendPostWithEntity(String url, HttpEntity entity,
                                                           Map<String, String> headerMap) throws Exception {
        HttpPost httpPost = new HttpPost(url);
        if (entity != null) {
            httpPost.setEntity(entity);
        }
        if (headerMap != null && !headerMap.isEmpty()) {
            for (Map.Entry<String, String> entry : headerMap.entrySet()) {
                httpPost.setHeader(entry.getKey(), entry.getValue());
            }
        }
        return httpClient.execute(httpPost);
    }


    public static CloseableHttpResponse sendGet(String url,
                                            Map<String, String> headers) {
        HttpGet httpGet = new HttpGet(url);
        if (headers != null) {
            for (Map.Entry<String, String> entry : headers.entrySet()) {
                httpGet.setHeader(entry.getKey(), entry.getValue());
            }
        }

        try {
            return httpClient.execute(httpGet);
        } catch (Exception e) {
            log.error(url, e);
        }
        return null;
    }

    public static void main(String[] args) throws IOException {
        CloseableHttpResponse httpResponse = HttpCommonUtil.sendGet("https://cdn-hs.yuaiweiwu.com/athena/voice/11/11_1d91be18-f267-4e61-846b-fc375a5dbe78.wav", null);
        byte[] audioData = EntityUtils.toByteArray(httpResponse.getEntity());
        System.out.println(audioData.length);
    }

}
