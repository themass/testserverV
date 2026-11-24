package com.timeline.vpn.sound;

import com.timeline.vpn.model.po.SoundItems;
import org.springframework.util.StringUtils;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Locale;

/**
 * 声音条目的音频地址规范化 + 指纹（纯函数，单测 SoundAudioUrlTest）。
 *
 * <p>口径以 2026-11-24 线上冒烟实测为准：items.json 真实行里
 * <b>url 是网页路径</b>（/yousheng/2474.html），mp3 在 file 列
 * （https://mmssxs1.com/有声连载/欲孽23.mp3）。所以规则是
 * 「谁是不可否认的 http(s) 绝对地址就用谁」：url 绝对 → url；file 绝对 → file；
 * 否则 baseurl+file 拼接。myFile 只是国内镜像（端上按访客 IP 切换），
 * Deepgram 在美区拉流不喂镜像。拼不出可用地址返回 null——生成侧据此直接判
 * failed，不空转调 API。
 */
public final class SoundAudioUrl {

    private SoundAudioUrl() {
    }

    public static String resolve(SoundItems item) {
        if (item == null) {
            return null;
        }
        if (isHttpUrl(item.getUrl())) {
            return item.getUrl().trim();
        }
        if (isHttpUrl(item.getFile())) {
            return item.getFile().trim();
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

    /** 大小写不敏感的 http(s):// 前缀判定；页面路径/裸文件名一律不算可拉取音频。 */
    private static boolean isHttpUrl(String value) {
        if (StringUtils.isEmpty(value)) {
            return false;
        }
        String v = value.trim().toLowerCase(Locale.ROOT);
        return v.startsWith("http://") || v.startsWith("https://");
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
