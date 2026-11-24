package com.timeline.vpn.sound;

import com.timeline.vpn.model.po.SoundItems;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

/**
 * 音频 URL 规范化（契约 §2 Phase 2 第 1 步）+ 指纹。纯函数，不连库。
 *
 * <p>口径以 2026-11-24 线上冒烟实测为准（items.json 真数据）：
 * <b>url 列是网页路径</b>（如 /yousheng/2474.html），mp3 在 file 列
 * （如 https://mmssxs1.com/有声连载/欲孽23.mp3）；myFile 只是国内镜像，
 * Deepgram 在美区拉流不喂镜像。所以规范化按「谁是可拉取的 http(s) 绝对地址就用谁」：
 * url 绝对 → url；否则 file 绝对 → file；否则 baseurl+file 拼接。
 * 拼不出可用地址返回 null——生成侧据此直接判 failed，不空转调 API。
 */
class SoundAudioUrlTest {

    @Test
    void prefersAbsoluteUrlColumn() {
        SoundItems po = new SoundItems();
        po.setUrl("https://cdn.example.com/a/b.mp3");
        po.setFile("https://other.example.com/a/b.mp3");
        po.setMyFile("https://mirror.cn/a/b.mp3");
        po.setBaseurl("https://ignored");
        assertEquals("https://cdn.example.com/a/b.mp3", SoundAudioUrl.resolve(po));
    }

    @Test
    void fallsToFileWhenUrlIsAWebPagePath() {
        // 线上真实形状：url=/yousheng/2474.html 不是音频，file 才是 mp3
        SoundItems po = new SoundItems();
        po.setUrl("/yousheng/2474.html");
        po.setFile("https://mmssxs1.com/有声连载/欲孽23.mp3");
        po.setBaseurl("https://www.259cf.com/");
        assertEquals("https://mmssxs1.com/有声连载/欲孽23.mp3", SoundAudioUrl.resolve(po));
    }

    @Test
    void joinsBaseurlPlusRelativeFile() {
        SoundItems po = new SoundItems();
        po.setUrl("/yousheng/2474.html");
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
    void neverPicksTheCnMirror() {
        // url/file 都不绝对、只有 myFile 是绝对地址：也不能喂镜像（Deepgram 拉的是境外源）
        SoundItems po = new SoundItems();
        po.setUrl("/yousheng/2474.html");
        po.setFile("media/a.mp3"); // 没有 baseurl，拼不出来
        po.setMyFile("https://mirror.cn/media/a.mp3");
        assertNull(SoundAudioUrl.resolve(po));
    }

    @Test
    void noUsableAddressReturnsNull() {
        SoundItems po = new SoundItems();
        po.setFile("media/a.mp3");
        assertNull(SoundAudioUrl.resolve(po));
    }

    @Test
    void nullPoIsNull() {
        assertNull(SoundAudioUrl.resolve(null));
    }

    @Test
    void httpsAndhttpBothAcceptedButNotOtherSchemes() {
        SoundItems po = new SoundItems();
        po.setUrl("ftp://nope/a.mp3");
        po.setFile("HTTPS://OK.example/a.mp3");
        assertEquals("HTTPS://OK.example/a.mp3", SoundAudioUrl.resolve(po));
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
