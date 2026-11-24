package com.timeline.vpn.sound;

import com.timeline.vpn.model.po.SoundItems;
import org.springframework.util.StringUtils;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;

/**
 * 声音条目的音频地址规范化 + 指纹（纯函数，单测 SoundAudioUrlTest）。
 *
 * <p>口径（DataSoundServiceImpl.getSoundItems 现行语义）：
 * url 列就是端上公网串流地址；myFile 只是国内镜像（端上按访客 IP 切换），
 * 服务端 ASR（Deepgram 在美区拉流）不喂镜像；url 缺失才退回 baseurl+file 拼接。
 * 拼不出可用地址返回 null——生成侧据此直接判 failed，不空转调 API。
 */
public final class SoundAudioUrl {

    private SoundAudioUrl() {
    }

    public static String resolve(SoundItems item) {
        if (item == null) {
            return null;
        }
        if (!StringUtils.isEmpty(item.getUrl())) {
            return item.getUrl().trim();
        }
        if (!StringUtils.isEmpty(item.getBaseurl()) && !StringUtils.isEmpty(item.getFile())) {
            String base = item.getBaseurl().trim();
            String file = item.getFile().trim();
            if (base.endsWith("/") && file.startsWith("/")) {
                return base + file.substring(1);
            }
            if (!base.endsWith("/") && !file.startsWith("/")) {
                return base + "/" + file;
            }
            return base + file;
        }
        return null;
    }

    /** URL 的 SHA-256（小写 hex，64 字符）：写进 sourceFileHash，换文件自动失效旧歌词。 */
    public static String sha256Hex(String value) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(value.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder(hash.length * 2);
            for (byte b : hash) {
                sb.append(Character.forDigit((b >> 4) & 0xF, 16));
                sb.append(Character.forDigit(b & 0xF, 16));
            }
            return sb.toString();
        } catch (Exception e) {
            // JVM 没有 SHA-256 属于环境损坏，让调用方走失败分支而不是带脏指纹入库
            throw new IllegalStateException("SHA-256 unavailable", e);
        }
    }
}
