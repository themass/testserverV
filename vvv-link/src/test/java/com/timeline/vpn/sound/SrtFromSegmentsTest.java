package com.timeline.vpn.sound;

import com.timeline.vpn.sound.SrtFromSegments.Segment;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * segments → SRT 纯函数（契约 sound-lyrics-contract §2 Phase 2 第 3 步）。
 *
 * <p>钉死三件事：秒 → HH:MM:SS,mmm 的换法；&lt;0.6s 碎段并入前条（防闪字）；
 * 空文本段直接丢弃。客户端 LocalSubtitleTrack 按标准 SRT 解析，格式错一处整轨废。
 */
class SrtFromSegmentsTest {

    @Test
    void formatsSecondsAsSrtTimestamps() {
        String srt = SrtFromSegments.build(List.of(
                new Segment(0, 2.5, "你好"),
                new Segment(61.234, 63.0, "世界")));
        assertEquals("""
                1
                00:00:00,000 --> 00:00:02,500
                你好

                2
                00:01:01,234 --> 00:01:03,000
                世界

                """, srt);
    }

    @Test
    void shortFragmentMergesIntoPreviousCue() {
        // 0.4s 的碎段单独成行会闪字，并进前条；前条结束时间取两者较晚
        String srt = SrtFromSegments.build(List.of(
                new Segment(1.0, 3.0, "第一句"),
                new Segment(3.2, 3.6, "嗯"),
                new Segment(4.0, 6.0, "第二句")));
        assertEquals("""
                1
                00:00:01,000 --> 00:00:03,600
                第一句
                嗯

                2
                00:00:04,000 --> 00:00:06,000
                第二句

                """, srt);
    }

    @Test
    void consecutiveShortFragmentsAllFoldIntoOneCue() {
        String srt = SrtFromSegments.build(List.of(
                new Segment(1.0, 2.0, "长句"),
                new Segment(2.1, 2.3, "a"),
                new Segment(2.4, 2.6, "b")));
        // 合并后前条被拉长约 0.6s——仍按原始边界判碎段的是当前段本身
        assertTrue(srt.contains("长句\na\nb"));
        assertTrue(srt.contains("00:00:01,000 --> 00:00:02,600"));
    }

    @Test
    void firstShortSegmentStandsAloneSinceThereIsNoPrevious() {
        String srt = SrtFromSegments.build(List.of(new Segment(0.1, 0.4, "开头")));
        assertTrue(srt.startsWith("1\n00:00:00,100 --> 00:00:00,400\n开头"));
    }

    @Test
    void exactlyThresholdKeepsItsOwnCue() {
        // 规则是「<0.6s」并入，等于 0.6 的独立成条
        String srt = SrtFromSegments.build(List.of(
                new Segment(0, 1, "A"),
                new Segment(1.5, 2.1, "B")));
        assertTrue(srt.contains("2\n00:00:01,500 --> 00:00:02,100\nB"));
    }

    @Test
    void blankAndNullSegmentsAreDropped() {
        String srt = SrtFromSegments.build(List.of(
                new Segment(0, 2, "  "),
                new Segment(2, 5, null),
                new Segment(5, 7, "有效")));
        assertEquals("""
                1
                00:00:05,000 --> 00:00:07,000
                有效

                """, srt);
    }

    @Test
    void emptyInputGivesEmptySrt() {
        assertEquals("", SrtFromSegments.build(List.of()));
        assertEquals("", SrtFromSegments.build(null));
    }

    @Test
    void inputOrderIsNotAssumed() {
        // 时间乱序进来也要按时间轴排好再编号（Deepgram 正常有序，防御性钉住）
        String srt = SrtFromSegments.build(List.of(
                new Segment(10, 12, "后"),
                new Segment(1, 3, "前")));
        assertTrue(srt.indexOf("前") < srt.indexOf("后"));
    }

    @Test
    void roundsHalfUpToNearestMillisecond() {
        String srt = SrtFromSegments.build(List.of(new Segment(0.0004, 1.9996, "x")));
        assertTrue(srt.contains("00:00:00,000 --> 00:00:02,000"));
    }
}
