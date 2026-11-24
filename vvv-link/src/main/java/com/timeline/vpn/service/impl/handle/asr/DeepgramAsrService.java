package com.timeline.vpn.service.impl.handle.asr;

import com.timeline.vpn.util.Secrets;

import com.timeline.vpn.common.utils.Base64Util;
import com.timeline.vpn.model.chat.DeepgramListenResponse;
import com.timeline.vpn.model.chat.SpeechRecognitionResponse;
import com.timeline.vpn.model.form.AsrContentForm;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.AsrResponseVo;
import com.timeline.vpn.util.JsonUtil;
import okhttp3.HttpUrl;
import okhttp3.OkHttpClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.concurrent.TimeUnit;

@Service
public class DeepgramAsrService extends BaseAsrHandleProxy {
    private static final Logger logger = LoggerFactory.getLogger(DeepgramAsrService.class);
    String token = Secrets.get("deepgram.token");
    String url = "https://api.deepgram.com/v1/listen?model=nova-2-general&smart_format=true";// 项目的 token

    /**
     * 离线文件识别专用客户端。共享 httpClient 读超时 10s 是给端上实时短句识别定的——
     * url 模式是 Deepgram 自己拉整条音频再识别，一首几分钟的音频远超 10s，必须单独放宽。
     */
    private static final OkHttpClient fileHttpClient = new OkHttpClient.Builder()
            .connectTimeout(10, TimeUnit.SECONDS)
            .readTimeout(600, TimeUnit.SECONDS)
            .writeTimeout(60, TimeUnit.SECONDS)
            .build();

    /**
     * 离线 url 模式（契约 sound-lyrics-contract §2 Phase 2 第 2 步）：把公网可达的音频 URL
     * 交给 Deepgram 自己拉流，segments=true 返回逐段 {start,end,transcript}（秒级浮点）。
     *
     * <p>与流式 asrHandler 是两条不同 API 用法，刻意不共用解析 bean：那条只要 transcript，
     * 歌词要的是分段时间轴。非 2xx 抛带状态码的异常——调用方据此置 genStatus=failed，
     * 这里绝不吞异常返回 null 之外还分不清是配置错还是音频不可达。
     */
    public DeepgramListenResponse recognizeUrl(String audioUrl) throws Exception {
        HttpUrl listenUrl = HttpUrl.parse(url).newBuilder()
                .addQueryParameter("segments", "true")
                .addQueryParameter("url", audioUrl)
                .build();
        okhttp3.Request httpRequest = new okhttp3.Request.Builder()
                .url(listenUrl)
                .addHeader("Authorization", token)
                .post(okhttp3.RequestBody.create(okhttp3.MediaType.parse("application/octet-stream"),
                        new byte[0]))
                .build();
        try (okhttp3.Response response = fileHttpClient.newCall(httpRequest).execute()) {
            String res = response.body() == null ? "" : response.body().string();
            if (!response.isSuccessful()) {
                // 截断即可：Deepgram 错误体是 {"err_url":...,"description":...}，前 300 字符够用
                throw new IllegalStateException("deepgram url mode HTTP " + response.code()
                        + ": " + (res.length() > 300 ? res.substring(0, 300) : res));
            }
            DeepgramListenResponse parsed = JsonUtil.readValue(res, DeepgramListenResponse.class);
            if (parsed == null || parsed.getResults() == null) {
                throw new IllegalStateException("deepgram url mode 响应无法解析: "
                        + (res.length() > 300 ? res.substring(0, 300) : res));
            }
            LOGGER.info("deepgram url mode 识别完成 url={} transcriptChars={}", audioUrl,
                    transcriptLength(parsed));
            return parsed;
        }
    }

    private static int transcriptLength(DeepgramListenResponse parsed) {
        if (parsed.getResults().getChannels() == null || parsed.getResults().getChannels().isEmpty()
                || parsed.getResults().getChannels().get(0).getAlternatives() == null
                || parsed.getResults().getChannels().get(0).getAlternatives().isEmpty()) {
            return 0;
        }
        String t = parsed.getResults().getChannels().get(0).getAlternatives().get(0).getTranscript();
        return t == null ? 0 : t.length();
    }

    @Override
    public AsrResponseVo asrHandler(BaseQuery baseQuery, AsrContentForm asrContentForm) throws Exception {
        try {
            okhttp3.MediaType mediaType = okhttp3.MediaType.parse("audio/wav");
            okhttp3.RequestBody body = okhttp3.RequestBody.create(mediaType,Base64Util.decodeBase64(asrContentForm.getContent()));
            okhttp3.Request httpRequest = new okhttp3.Request.Builder()
                    .url(url)
                    .addHeader("Authorization", token)
                    .addHeader("Content-Type", "audio/wav")
                    .post(body)
                    .build();
            okhttp3.Response response = httpClient.newCall(httpRequest).execute();
            String res = response.body().string();
            SpeechRecognitionResponse response1 = JsonUtil.readValue(res, SpeechRecognitionResponse.class);
            AsrResponseVo asrResponseVo = new AsrResponseVo();
            LOGGER.info("deepgram asr 识别："+res);
            asrResponseVo.setProd("deepgram_asr");
            if (response1 != null && response1.getResults() != null && response1.getResults().getChannels() != null && response1.getResults().getChannels().size() > 0 && response1.getResults().getChannels().get(0).getAlternatives() != null && response1.getResults().getChannels().get(0).getAlternatives().size() > 0) {
                asrResponseVo.setText(response1.getResults().getChannels().get(0).getAlternatives().get(0).getTranscript());
            }
            return asrResponseVo;
        }catch (Exception e){
            LOGGER.error("", e);
        }
        return  new AsrResponseVo();
    }

    @Override
    public boolean support(Integer t) {
        return false;
    }

}
