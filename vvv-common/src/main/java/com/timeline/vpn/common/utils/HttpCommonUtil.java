package com.timeline.vpn.common.utils;

import lombok.extern.slf4j.Slf4j;
import org.apache.commons.codec.binary.Base64;
import org.apache.hc.client5.http.HttpResponseException;
import org.apache.hc.client5.http.classic.HttpClient;
import org.apache.hc.client5.http.classic.methods.HttpGet;
import org.apache.hc.client5.http.classic.methods.HttpPost;
import org.apache.hc.client5.http.config.RequestConfig;
import org.apache.hc.client5.http.impl.classic.CloseableHttpClient;
import org.apache.hc.client5.http.impl.classic.CloseableHttpResponse;
import org.apache.hc.client5.http.impl.classic.HttpClientBuilder;
import org.apache.hc.client5.http.impl.io.PoolingHttpClientConnectionManager;
import org.apache.hc.client5.http.socket.ConnectionSocketFactory;
import org.apache.hc.client5.http.ssl.SSLConnectionSocketFactory;
import org.apache.hc.core5.http.HttpEntity;
import org.apache.hc.core5.http.HttpResponse;
import org.apache.hc.core5.http.config.Registry;
import org.apache.hc.core5.http.config.RegistryBuilder;
import org.apache.hc.core5.http.io.SocketConfig;
import org.apache.hc.core5.http.io.entity.EntityUtils;
import org.apache.hc.core5.http.ContentType;
import org.apache.hc.core5.http.NameValuePair;
import org.apache.hc.core5.http.io.entity.StringEntity;
import org.apache.hc.core5.http.message.BasicNameValuePair;
import org.apache.hc.core5.http.message.StatusLine;
import org.apache.hc.core5.ssl.SSLContexts;
import org.apache.hc.core5.ssl.TrustStrategy;
import org.apache.hc.core5.util.Timeout;
import org.apache.http.client.utils.URLEncodedUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.multipart.MultipartFile;

import javax.net.ssl.HostnameVerifier;
import javax.net.ssl.SSLSession;
import java.io.*;
import java.net.*;
import java.nio.charset.Charset;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;

@Slf4j
public class HttpCommonUtil {
    private static final Logger LOGGER = LoggerFactory.getLogger(HttpCommonUtil.class);
    private static CloseableHttpClient httpClient = null;
    private static CloseableHttpClient httpClientSsl = null;
    private static final String DEFAULT_CHARSET = "UTF-8";
    public static final String UTF8_CHARSET = DEFAULT_CHARSET;
    private static final String UA =
            "Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)";
    private static RequestConfig config = RequestConfig.custom()
            .setConnectTimeout(Timeout.ofSeconds(15))
            .setConnectionRequestTimeout(Timeout.ofSeconds(30))
            .setResponseTimeout(Timeout.ofSeconds(30)) // 添加套接字超时
            .build();
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

            SSLConnectionSocketFactory sslsf = new SSLConnectionSocketFactory(
                    SSLContexts.custom().loadTrustMaterial(new TrustStrategy() {
                        @Override
                        public boolean isTrusted(X509Certificate[] x509Certificates, String s)
                                throws CertificateException {
                            // 安全配置：仅在开发环境中信任所有证书，生产环境中应配置为信任特定证书
                            return true;
                        }
                    }).build(), new HostnameVerifier() {
                @Override
                public boolean verify(String hostname, SSLSession session) {
                    // 安全配置：仅在开发环境中信任所有主机名，生产环境中应配置为信任特定主机名
                    return true;
                }
            });
            Registry<ConnectionSocketFactory> socketFactoryRegistry = RegistryBuilder
                    .<ConnectionSocketFactory>create().register("https", sslsf).build();
            PoolingHttpClientConnectionManager ccmSsl =
                    new PoolingHttpClientConnectionManager(socketFactoryRegistry);
            ccmSsl.setDefaultMaxPerRoute(MAX_PERROUTE); // 每个host最多100个连接
            ccmSsl.setMaxTotal(MAXTOTAL); // 一共800个连接
            httpClientBuilder.setConnectionManager(ccmSsl);
            httpClientSsl = httpClientBuilder.build();

        } catch (Exception e) {
            LOGGER.error("Failed to initialize HttpClient", e);
        }
    }

    /**
     * Constructor
     */
    private HttpCommonUtil() {}


    public static String sendPostWithEntity(String url, HttpEntity entity,
                                            Map<String, String> headerMap, boolean ssl) throws Exception {
        HttpPost httpPost = new HttpPost(url);
        if (entity != null) {
            httpPost.setEntity(entity);
        }
        if (headerMap != null && !headerMap.isEmpty()) {
            for (Entry<String, String> entry : headerMap.entrySet()) {
                httpPost.setHeader(entry.getKey(), entry.getValue());
            }
        }
        try (CloseableHttpResponse response = (CloseableHttpResponse)getHttpClient(ssl).execute(httpPost)) {
            return responseToString(response);
        }
    }

    public static String responseToString(CloseableHttpResponse response) throws Exception {
        return responseToString(response, DEFAULT_CHARSET);
    }

    private static String responseToString(CloseableHttpResponse response, String charset) throws Exception {
        HttpEntity entity = getHttpEntity(response);
        if (entity == null) {
            return null;
        }
        return EntityUtils.toString(entity, charset);
    }

    private static HttpEntity getHttpEntity(CloseableHttpResponse response) throws Exception {
        int code = response.getCode();
        if (code >= 300) {
            LOGGER.error("Response error: {}", response);
            String ret = EntityUtils.toString(response.getEntity(), DEFAULT_CHARSET);
            throw new HttpResponseException(code,
                    response.getReasonPhrase() + "--ret=" + ret);
        } else {
            if (LOGGER.isDebugEnabled()) {
                LOGGER.debug("Response: {}", response);
            }
            return response.getEntity();
        }
    }

    /**
     * Create an HttpClient with the ThreadSafeClientConnManager.
     *
     * @return
     */
    private static HttpClient getHttpClient(boolean ssl) {
        if (ssl) {
            return httpClientSsl;
        } else {
            return httpClient;
        }
    }

    public static String sendGet(String url) {
        return sendGet(url, DEFAULT_CHARSET);
    }

    /**
     * Send get to URL.
     *
     * @param url url
     * @param charset charset
     * @return result content
     */
    public static String sendGet(String url, String charset) {
        return sendGetWithHeaders(url, charset, null);
    }

    /**
     * 发送带有对应Header的get请求
     *
     * @param url url
     * @param headers headers
     * @return HttpResponse
     */
    public static String sendGetWithHeaders(String url, String charset,
                                            Map<String, String> headers) {
        HttpGet httpGet = new HttpGet(url);
        if (headers != null) {
            for (Entry<String, String> entry : headers.entrySet()) {
                httpGet.setHeader(entry.getKey(), entry.getValue());
            }
        }

        try (CloseableHttpResponse response = (CloseableHttpResponse)getHttpClient(url.contains("https")).execute(httpGet)) {
            return responseToString(response, charset);
        } catch (Exception e) {
            LOGGER.error("Failed to execute GET request for URL: {}", url, e);
        }
        return null;
    }

    public static String sendGet(String url, String charset, Map<String, String> params,
                                 Map<String, String> headers) {
        if (params != null && !params.isEmpty()) {
            StringBuilder sb = new StringBuilder();
            sb.append(url).append("?");
            for (Entry<String, String> entry : params.entrySet()) {
                sb.append(entry.getKey()).append("=").append(encoderParam(entry.getValue()))
                        .append("&");
            }
            url = sb.toString();
        }
        return sendGetWithHeaders(url, charset, headers);
    }

    private static String encoderParam(String param) {
        try {
            return URLEncoder.encode(param, DEFAULT_CHARSET);
        } catch (Exception e) {
            LOGGER.error("Failed to encode parameter: {}", param, e);
            throw new RuntimeException("Failed to encode parameter", e);
        }
    }

    public static boolean ping(String ip) {
        String result = null;
        Process p = null;
        try {
            p = Runtime.getRuntime().exec("ping -c 2 -w 5 " + ip);
            InputStream input = p.getInputStream();
            BufferedReader in = new BufferedReader(new InputStreamReader(input));
            StringBuilder stringBuffer = new StringBuilder("test");
            String content;
            while ((content = in.readLine()) != null) {
                stringBuffer.append(content);
            }
            int status = p.waitFor();
            if (status == 0 && !stringBuffer.toString().trim().contains("100%packetloss")) {
                result = "successful~";
                return true;
            } else {
                result = "failed~ cannot reach the IP address";
            }
        } catch (IOException e) {
            result = "failed~ IOException";
            LOGGER.error("IOException during ping for IP: {}", ip, e);
        } catch (InterruptedException e) {
            result = "failed~ InterruptedException";
            LOGGER.error("InterruptedException during ping for IP: {}", ip, e);
        } finally {
            if (p != null) {
                p.destroy();
            }
        }
        LOGGER.error("Ping failed for IP: {} - result = {}", ip, result);
        return false;
    }

    public static String getHostName() {
        try {
            return (InetAddress.getLocalHost()).getHostName();
        } catch (UnknownHostException uhe) {
            String host = uhe.getMessage(); // host = "hostname: hostname"
            if (host != null) {
                int colon = host.indexOf(':');
                if (colon > 0) {
                    return host.substring(0, colon);
                }
            }
            return "UnknownHost";
        }
    }

    public static String getUA(String ua) {
        if (ua.startsWith("google:")) {
            ua = ua.replace("google:", "");
            return new String(Base64.decodeBase64(ua.getBytes()));
        } else {
            return ua;
        }
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
        return (CloseableHttpResponse)getHttpClient(false).execute(httpPost); // 默认使用非SSL客户端
    }

    public static CloseableHttpResponse sendPostWithMultipartFile(String url, String filePath, Map<String, String> headerMap) throws Exception {
        org.apache.hc.client5.http.entity.mime.MultipartEntityBuilder builder = org.apache.hc.client5.http.entity.mime.MultipartEntityBuilder.create();
        builder.addBinaryBody("file", new File(filePath), ContentType.APPLICATION_OCTET_STREAM, new File(filePath).getName());
        HttpEntity multipart = builder.build();

        return sendPostWithEntity(url, multipart, headerMap);
    }

    public static CloseableHttpResponse sendPostWithMultipartFile(String url, MultipartFile file, Map<String, String> headerMap) throws Exception {
        org.apache.hc.client5.http.entity.mime.MultipartEntityBuilder builder = org.apache.hc.client5.http.entity.mime.MultipartEntityBuilder.create();
        builder.addBinaryBody("file", file.getInputStream(), ContentType.APPLICATION_OCTET_STREAM, file.getOriginalFilename());
        HttpEntity multipart = builder.build();

        return sendPostWithEntity(url, multipart, headerMap);
    }
}
