package com.timeline.vpn.sound;

import com.timeline.vpn.model.po.SoundItems;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

/**
 * 音频 URL 规范化（契约 §2 Phase 2 第 1 步）+ 指纹。纯函数，不连库。
 *
 * <p>口径：url 列就是端上公网串流地址（DataSoundServiceImpl.getSoundItems 原样 copyProperties 下发）；
 * myFile 只是国内镜像（端上按访客 IP 切换），服务端 ASR（Deepgram 在美国拉流）不该喂镜像；
 * url 缺失才退回 baseurl+file 拼接。
 */
class SoundAudioUrlTest {

    @Test
    void prefersUrlColumn() {
        SoundItems po = new SoundItems();
        po.setUrl("https://cdn.example.com/a/b.mp3");
        po.setMyFile("https://mirror.cn/a/b.mp3");
        po.setBaseurl("https://ignored");
        assertEquals("https://cdn.example.com/a/b.mp3", SoundAudioUrl.resolve(po));
    }

    @Test
    void fallsBackToBaseurlPlusFileWhenUrlMissing() {
        SoundItems po = new SoundItems();
        po.setBaseurl("https://host.example/");
        po.setFile("media/a.mp3");
        assertEquals("https://host.example/media/a.mp3", SoundAudioUrl.resolve(po));
    }

    @Test
    void joinsBaseurlAndFileWithExactlyOneSlash() {
        SoundItems po = new SoundItems();
        po.setBaseurl("https://host.example");
        po.setFile("/media/a.mp3");
        assertEquals("https://host.example/media/a.mp3", SoundAudioUrl.resolve(po));
    }

    @Test
    void noUsableAddressReturnsNull() {
        SoundItems po = new SoundItems();
        po.setFile("media/a.mp3"); // 没有 baseurl 也拼不出可拉取的地址
        assertNull(SoundAudioUrl.resolve(po));
    }

    @Test
    void nullPoIsNull() {
        assertNull(SoundAudioUrl.resolve(null));
    }

    @Test
    void sha256HexIsLowercaseSixtyFourChars() {
        // 空串的 SHA-256 是公开值，拿它钉实现
        assertEquals("e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
                SoundAudioUrl.sha256Hex(""));
    }

    @Test
    void sha256StableForSameUrl() {
        String a = SoundAudioUrl.sha256Hex("https://cdn.example.com/a.mp3");
        String b = SoundAudioUrl.sha256Hex("https://cdn.example.com/a.mp3");
        assertEquals(64, a.length());
        assertEquals(a, b);
    }
}
