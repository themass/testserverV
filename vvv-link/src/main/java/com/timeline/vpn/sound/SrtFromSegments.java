package com.timeline.vpn.sound;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

/**
 * Deepgram segments → SRT 正文（纯函数，无 IO，单测 SrtFromSegmentsTest 钉格式）。
 *
 * <p>契约 sound-lyrics-contract §2 Phase 2 第 3 步：秒（浮点）→ HH:MM:SS,mmm；
 * 时长 &lt;0.6s 的碎段并入前一条（防闪字），文本逐行追加、结束时间取较晚者。
 * 空文本段直接丢弃（Deepgram 静音窗会产生 transcript="" 的段）。
 * 输出是标准 SRT：客户端 LocalSubtitleTrack（≤1MiB/10000 cues）直接解析。
 */
public final class SrtFromSegments {

    /** 碎段阈值（毫秒）：短于这个时长的段并进前条。 */
    static final long MERGE_BELOW_MS = 600;

    private SrtFromSegments() {
    }

    /** Deepgram 的一个识别段：起止为相对音频起点的秒（浮点）。 */
    public record Segment(double start, double end, String text) {
    }

    public static String build(List<Segment> segments) {
        if (segments == null || segments.isEmpty()) {
            return "";
        }
        List<Segment> sorted = new ArrayList<>(segments.size());
        for (Segment s : segments) {
            if (s == null || s.text() == null || s.text().trim().isEmpty()) {
                continue;
            }
            sorted.add(s);
        }
        sorted.sort(Comparator.comparingDouble(Segment::start));

        // 先折成 cue（毫秒边界），再统一格式化——比较走整数毫秒，避开浮点毛刺
        List<Cue> cues = new ArrayList<>();
        for (Segment s : sorted) {
            long startMs = toMs(s.start());
            long endMs = toMs(s.end());
            long durationMs = endMs - startMs;
            if (!cues.isEmpty() && durationMs < MERGE_BELOW_MS) {
                Cue prev = cues.get(cues.size() - 1);
                prev.text = prev.text + "\n" + s.text().trim();
                prev.endMs = Math.max(prev.endMs, endMs);
            } else {
                cues.add(new Cue(startMs, endMs, s.text().trim()));
            }
        }

        StringBuilder sb = new StringBuilder();
        int index = 1;
        for (Cue c : cues) {
            sb.append(index++).append('\n')
              .append(format(c.startMs)).append(" --> ").append(format(c.endMs)).append('\n')
              .append(c.text).append("\n\n");
        }
        return sb.toString();
    }

    private static long toMs(double seconds) {
        return Math.round(seconds * 1000.0);
    }

    /** 毫秒 → HH:MM:SS,mmm（SRT 时间戳）。 */
    static String format(long ms) {
        long h = ms / 3_600_000L;
        long m = (ms % 3_600_000L) / 60_000L;
        long s = (ms % 60_000L) / 1_000L;
        long frac = ms % 1_000L;
        return String.format("%02d:%02d:%02d,%03d", h, m, s, frac);
    }

    private static final class Cue {
        long startMs;
        long endMs;
        String text;

        Cue(long startMs, long endMs, String text) {
            this.startMs = startMs;
            this.endMs = endMs;
            this.text = text;
        }
    }
}
