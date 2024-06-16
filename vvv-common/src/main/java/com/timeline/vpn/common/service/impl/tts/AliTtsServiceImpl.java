package com.timeline.vpn.common.service.impl.tts;

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONObject;
import com.aliyuncs.CommonRequest;
import com.aliyuncs.CommonResponse;
import com.aliyuncs.DefaultAcsClient;
import com.aliyuncs.IAcsClient;
import com.aliyuncs.exceptions.ClientException;
import com.aliyuncs.http.MethodType;
import com.aliyuncs.http.ProtocolType;
import com.aliyuncs.profile.DefaultProfile;
import com.timeline.vpn.common.annotation.MethodTimed;
import com.timeline.vpn.common.config.TtsSupplierConfig;
import com.timeline.vpn.common.config.TtsVolcengineConfig;
import com.timeline.vpn.common.constant.GlobalConstant;
import com.timeline.vpn.common.exception.BusinessException;
import com.timeline.vpn.common.service.TtsService;
import com.timeline.vpn.common.service.impl.tts.dto.AliTtsRequest;
import com.timeline.vpn.common.service.impl.tts.dto.TtsConfig;
import com.timeline.vpn.common.service.impl.tts.dto.TtsVolcResponse;
import com.timeline.vpn.common.utils.Base64Util;
import com.timeline.vpn.common.utils.JacksonJsonUtil;
import lombok.extern.slf4j.Slf4j;
import okhttp3.*;
import org.apache.commons.lang3.StringUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.util.concurrent.TimeUnit;

@Service("aliTtsService")
@Slf4j
@MethodTimed
public class AliTtsServiceImpl implements TtsService {
    // 您的地域ID
    private static final String REGIONID = "cn-shanghai";
    // 获取Token服务域名
    private static final String DOMAIN = "nls-meta.cn-shanghai.aliyuncs.com";
    // API 版本
    private static final String API_VERSION = "2019-02-28";
    // API名称
    private static final String REQUEST_ACTION = "CreateToken";
    // 响应参数
    private static final String KEY_TOKEN = "Token";
    private static final String KEY_ID = "Id";
    private static final String KEY_EXPIRETIME = "ExpireTime";
    @Autowired
    private TtsSupplierConfig ttSsupplierConfig;
    private static String AI_LSESSION_ALI_TTS_TOKEN = "AI_LSESSION:ALI_TTS_TOKEN";

    @Autowired
    private StringRedisTemplate stringRedisTemplate;

    /**
     * HTTPS POST 请求
     */
    @Override
    public TtsVolcResponse textToVideo(String name, String text) {
        TtsVolcengineConfig ttsVolcengineConfig = ttSsupplierConfig.getActiveConfig();
        TtsConfig ttsConfig = ttsVolcengineConfig.getActiveConfig();
        if (GlobalConstant.SSML.equals(ttsConfig.getTextType())) { //ssml协议
            text = textToSSML(text);
        }
        AliTtsRequest aliTtsRequest = new AliTtsRequest();
        aliTtsRequest.setText(text);
        aliTtsRequest.setVoice(ttsConfig.getUid());
        aliTtsRequest.setFormat(ttsConfig.getEncoding());
        aliTtsRequest.setAppkey(ttsConfig.getAppid());
        aliTtsRequest.setToken(getToken(ttsConfig.getaKey(), ttsConfig.getaKeySecret()));
        aliTtsRequest.setSampleRate(ttsConfig.getSampleRate());
        aliTtsRequest.setVoice(ttsConfig.getUid());
        log.info("tts 厂商：{}; 声音:{}; name:{}; 请求：{}", ttSsupplierConfig.getActive(), ttsVolcengineConfig.getActive(), name, JacksonJsonUtil.toJsonStr(aliTtsRequest));
        RequestBody reqBody = RequestBody.create(MediaType.parse("application/json"), JacksonJsonUtil.toJsonStr(aliTtsRequest));
        Request request = new Request.Builder()
                .url(ttsConfig.getUrl())
                .header("Content-Type", "application/json")
                .post(reqBody)
                .build();
        Response response = null;
        try {
            OkHttpClient client = new OkHttpClient();
            response = client.newCall(request).execute();
            String contentType = response.header("Content-Type");
            if ("audio/mpeg".equals(contentType)) {
                TtsVolcResponse ttsVolcResponse = new TtsVolcResponse();
                ttsVolcResponse.setData(Base64Util.encodeBase64(response.body().bytes()));
                log.info("tts 厂商：{}; 声音:{}; name:{}; 返回值：{}", ttSsupplierConfig.getActive(), ttsVolcengineConfig.getActive(), name, contentType);
                return ttsVolcResponse;
            } else {
                // ContentType 为 null 或者为 "application/json"
                String errorMessage = response.body().string();
                log.error("阿里语音合成失败: " + errorMessage);
                throw new BusinessException("阿里语音合成失败");
            }
        } catch (Exception e) {
            log.error("阿里语音合成失败", e);
            throw new BusinessException("阿里语音合成失败");
        } finally {
            if (response != null) {
                response.close();
            }
        }
    }

    @Override
    public String textToSSML(String text) {
        String ssmltemp = "<speak>#{mytext}</speak>";
        return ssmltemp.replace("#{mytext}", text);
    }

    private String getToken(String accessKey, String accessKeySecret) {
        String token = stringRedisTemplate.opsForValue().get(AI_LSESSION_ALI_TTS_TOKEN);
        if (!StringUtils.isEmpty(token)) {
            return token;
        }
        DefaultProfile profile = DefaultProfile.getProfile(
                REGIONID,
                accessKey,
                accessKeySecret);
        IAcsClient client = new DefaultAcsClient(profile);
        CommonRequest request = new CommonRequest();
        request.setDomain(DOMAIN);
        request.setVersion(API_VERSION);
        request.setAction(REQUEST_ACTION);
        request.setMethod(MethodType.POST);
        request.setProtocol(ProtocolType.HTTPS);
        CommonResponse response = null;
        try {
            response = client.getCommonResponse(request);
        } catch (ClientException e) {
            log.error("获取Token失败！", e);
            throw new BusinessException("获取 ali tts-token 失败");
        }
        log.info("获取Token 完成！" + response.getHttpStatus());
        JSONObject result = JSON.parseObject(response.getData());
        if (response.getHttpStatus() == 200) {
            token = result.getJSONObject(KEY_TOKEN).getString(KEY_ID);
            long expireTime = result.getJSONObject(KEY_TOKEN).getLongValue(KEY_EXPIRETIME);
            // 缓存5额小时
            long max = Math.min(5 * 60 * 60, expireTime - System.currentTimeMillis() / 1000);
            stringRedisTemplate.opsForValue().set(AI_LSESSION_ALI_TTS_TOKEN, token, max, TimeUnit.SECONDS);
            log.info("获取到的Token： " + token + "，有效期时间戳(单位：秒): " + max);
            // 将10位数的时间戳转换为北京时间
            return token;
        } else {
            log.error("获取Token失败！" + response.getData());
            throw new BusinessException("获取 ali tts-token 失败");
        }
    }

}