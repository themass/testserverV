package com.timeline.vpn.util;

import java.io.IOException;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;
import java.nio.charset.Charset;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;
import java.util.ArrayList;
import java.util.Enumeration;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.zip.GZIPInputStream;

import javax.net.ssl.HostnameVerifier;
import javax.net.ssl.SSLSession;
import javax.servlet.http.HttpServletRequest;

import org.apache.http.Header;
import org.apache.http.HeaderElement;
import org.apache.http.HttpEntity;
import org.apache.http.HttpException;
import org.apache.http.HttpRequest;
import org.apache.http.HttpRequestInterceptor;
import org.apache.http.HttpResponse;
import org.apache.http.HttpResponseInterceptor;
import org.apache.http.NameValuePair;
import org.apache.http.StatusLine;
import org.apache.http.client.HttpClient;
import org.apache.http.client.HttpResponseException;
import org.apache.http.client.config.RequestConfig;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.client.utils.URLEncodedUtils;
import org.apache.http.config.Registry;
import org.apache.http.config.RegistryBuilder;
import org.apache.http.conn.socket.ConnectionSocketFactory;
import org.apache.http.conn.ssl.SSLConnectionSocketFactory;
import org.apache.http.conn.ssl.TrustStrategy;
import org.apache.http.entity.ContentType;
import org.apache.http.entity.HttpEntityWrapper;
import org.apache.http.entity.StringEntity;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClientBuilder;
import org.apache.http.impl.conn.PoolingHttpClientConnectionManager;
import org.apache.http.message.BasicNameValuePair;
import org.apache.http.protocol.HttpContext;
import org.apache.http.ssl.SSLContexts;
import org.apache.http.util.EntityUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class HttpCommonUtil {
    private static final Logger LOGGER = LoggerFactory.getLogger(HttpCommonUtil.class);
    private static CloseableHttpClient httpClient = null;
    private static CloseableHttpClient httpClientSsl = null;
    private static final String DEFAULT_CHARSET = "UTF-8";
    public static final String UTF8_CHARSET = DEFAULT_CHARSET;
    private static final String UA =
            "Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)";
    private static RequestConfig config = RequestConfig.custom().setConnectTimeout(15000)
            .setSocketTimeout(30000).setConnectionRequestTimeout(20000).build();
    private static HttpClientBuilder httpClientBuilder = null;
    private static final int MAX_PERROUTE = 800;
    private static final int MAXTOTAL = 2500;
    static {
        try {
            PoolingHttpClientConnectionManager connectionManager =
                    new PoolingHttpClientConnectionManager();
            connectionManager.setDefaultMaxPerRoute(MAX_PERROUTE); // 每个host最多100个连接
            connectionManager.setMaxTotal(MAXTOTAL); // 一共800个连接
            httpClientBuilder = HttpClientBuilder.create()
                    // .addInterceptorFirst(new AcceptEncodingRequestInterceptor())
                    // .addInterceptorLast(new ContentEncodingResponseInterceptor())
                    .setDefaultRequestConfig(config).setUserAgent(UA)
                    .setConnectionManager(connectionManager);
            httpClient = httpClientBuilder.build();

            SSLConnectionSocketFactory sslsf = new SSLConnectionSocketFactory(
                    SSLContexts.custom().loadTrustMaterial(new TrustStrategy() {
                        @Override
                        public boolean isTrusted(X509Certificate[] x509Certificates, String s)
                                throws CertificateException {
                            return true;
                        }
                    }).build(), new HostnameVerifier() {
                        @Override
                        public boolean verify(String hostname, SSLSession session) {
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
            LOGGER.error("错误", e);
        }
    }

    /**
     * Constructor
     */
    private HttpCommonUtil() {}

    public static void printHeader(HttpServletRequest request) {
        Enumeration<String> e = request.getHeaderNames();
        while (e.hasMoreElements()) {
            String name = e.nextElement();
            LOGGER.info("head = " + name + "--" + request.getHeader(name));
        }
    }


    /**
     * Send post to URL with parameters by given encoding.
     * 
     * @param url url
     * @param parameterMap parameterMap
     * @return result content
     * @throws Exception
     */
    public static String sendPost(String url, Map<String, String> parameterMap) throws Exception {
        boolean ssl = false;
        if (url.startsWith("https")) {
            ssl = true;
        }
        return sendPost(url, parameterMap, null, DEFAULT_CHARSET, ssl);
    }

    public static String sendPost(String url, Map<String, String> parameterMap,
            Map<String, String> header) throws Exception {
        boolean ssl = false;
        if (url.startsWith("https")) {
            ssl = true;
        }
        return sendPost(url, parameterMap, header, DEFAULT_CHARSET, ssl);
    }

    /**
     * Send post to URL with parameters by given encoding.
     * 
     * @param url url
     * @param parameterMap parameterMap
     * @return result content
     * @throws Exception Exception
     */
    public static String sendPost(String url, Map<String, String> parameterMap, boolean ssl)
            throws Exception {
        return sendPost(url, parameterMap, null, DEFAULT_CHARSET, ssl);
    }

    /**
     * Send post to URL with parameters by given encoding.
     * 
     * @param url url
     * @param parameterMap parameterMap
     * @param encoding encoding
     * @return result content
     * @throws Exception
     */
    public static String sendPost(String url, Map<String, String> parameterMap, String encoding,
            boolean ssl) throws Exception {
        return sendPost(url, parameterMap, null, encoding, ssl);
    }

    /**
     * Send post to URL with parameters by given encoding.
     * 
     * @param url url
     * @param parameterMap parameterMap
     * @param headerMap headerMap
     * @param encoding encoding
     * @return result content
     * @throws Exception 
     */
    public static String sendPost(String url, Map<String, String> parameterMap,
            Map<String, String> headerMap, String encoding, boolean ssl) throws Exception {
        StringEntity entity = null;

        if (parameterMap != null && !parameterMap.isEmpty()) {
            List<NameValuePair> params = new ArrayList<NameValuePair>();
            for (Entry<String, String> entry : parameterMap.entrySet()) {
                params.add(new BasicNameValuePair(entry.getKey(), entry.getValue()));
            }

            try {
                entity = new StringEntity(URLEncodedUtils.format(params, encoding));
                entity.setContentType(URLEncodedUtils.CONTENT_TYPE);
            } catch (UnsupportedEncodingException e) {
                LOGGER.error(url, e);
            }
        }

        return sendPostWithEntity(url, entity, headerMap, ssl);
    }

    public static String sendPost(String url, String param, Map<String, String> headerMap,
            boolean ssl) throws Exception {
        StringEntity entity = null;
        entity = new StringEntity(param, DEFAULT_CHARSET);
        entity.setContentType(URLEncodedUtils.CONTENT_TYPE);
        return sendPostWithEntity(url, entity, headerMap, ssl);
    }

    public static String sendPost(String url, String param, Map<String, String> headerMap,
            boolean ssl, String encoding) throws Exception {
        StringEntity entity = null;
        entity = new StringEntity(param, ContentType.APPLICATION_JSON);
        entity.setContentType(encoding);
        return sendPostWithEntity(url, entity, headerMap, ssl);
    }

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
        HttpResponse response;
        response = getHttpClient(ssl).execute(httpPost);
        return responseToString(response);
    }

    private static String responseToString(HttpResponse response) throws Exception {
        return responseToString(response, DEFAULT_CHARSET);
    }

    private static String responseToString(HttpResponse response, String charset) throws Exception {
        HttpEntity entity = getHttpEntity(response);
        if (entity == null) {
            return null;
        }
        return EntityUtils.toString(entity, charset);
    }

    private static HttpEntity getHttpEntity(HttpResponse response) throws Exception {
        StatusLine statusLine = response.getStatusLine();
        if (statusLine.getStatusCode() >= 300) {
            LOGGER.error("response:{}", response);
            String ret = EntityUtils.toString(response.getEntity(), DEFAULT_CHARSET);
            throw new HttpResponseException(statusLine.getStatusCode(),
                    statusLine.getReasonPhrase() + "--ret=" + ret);
        } else {
            if (LOGGER.isDebugEnabled()) {
                LOGGER.debug("response:{}", response);
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

    private static class AcceptEncodingRequestInterceptor implements HttpRequestInterceptor {
        @Override
        public void process(HttpRequest request, HttpContext context)
                throws HttpException, IOException {
            if (!request.containsHeader("Accept-Encoding")) {
                request.addHeader("Accept-Encoding", "gzip");
            }
        }
    }

    private static class ContentEncodingResponseInterceptor implements HttpResponseInterceptor {
        public void process(final HttpResponse response, final HttpContext context)
                throws HttpException {
            HttpEntity entity = response.getEntity();
            if (entity != null) {
                Header ceheader = entity.getContentEncoding();
                if (ceheader != null) {
                    HeaderElement[] codecs = ceheader.getElements();
                    for (int i = 0; i < codecs.length; i++) {
                        if ("gzip".equalsIgnoreCase(codecs[i].getName())) {
                            response.setEntity(new GzipDecompressingEntity(response.getEntity()));
                            return;
                        }
                    }
                }
            }
        }
    }

    private static class GzipDecompressingEntity extends HttpEntityWrapper {
        public GzipDecompressingEntity(final HttpEntity entity) {
            super(entity);
        }

        @Override
        public InputStream getContent() throws IOException {
            InputStream wrappedin = wrappedEntity.getContent();
            return new GZIPInputStream(wrappedin);
        }

        @Override
        public long getContentLength() {
            return -1;
        }
    }


    /**
     * 返回请求响应的状态码
     * 
     * @param url url
     * @return status code
     */
    public static int getResponseStatusCode(String url) {
        HttpURLConnection connection = null;
        try {
            connection = (HttpURLConnection) new URL(url).openConnection();
            connection.setInstanceFollowRedirects(false);
            connection.connect();
            return connection.getResponseCode();
        } catch (Exception e) {
            LOGGER.error("错误", e);
        } finally {
            if (connection != null) {
                connection.disconnect();
            }
        }
        return -1;
    }


    public static String getURLEncodeUtf8(Object args) {
        try {
            if (args == null) {
                return null;
            }
            return URLEncoder.encode(String.valueOf(args),
                    Charset.forName(DEFAULT_CHARSET).toString());
        } catch (UnsupportedEncodingException e) {
            LOGGER.error("错误", e);
        }

        return null;
    }

    /**
     * Send get to URL.
     * 
     * @param url url
     * @return result content
     */
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

        try {
            HttpResponse response = null;
            boolean ssl = url.contains("https") ? true : false;
            if (ssl) {
                response = httpClientSsl.execute(httpGet);
            } else {
                response = httpClient.execute(httpGet);
            }
            return responseToString(response, charset);
        } catch (Exception e) {
            LOGGER.error(url, e);
        } finally {
            httpGet.abort();
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
            LOGGER.error("UrlEncoder:" + param, e);
        }
        return null;
    }

    public static void main(String[] args) {
        sendGet("https://collection.lianjia.com/homelink/inner/sleep");
    }

}
