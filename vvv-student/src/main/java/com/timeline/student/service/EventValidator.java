package com.timeline.student.service;

import com.timeline.student.api.StudentModels.EventIn;
import com.timeline.student.api.StudentModels.GapIn;
import com.timeline.student.api.StudentModels.SessionWrite;
import com.timeline.student.domain.StudentErrors.BadRequest;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import static com.timeline.student.domain.StudentVocabulary.*;

/**
 * Pure validation, no I/O. The privacy contract is enforced here: an event has no free-text field,
 * `ref` is an enumerated value or a small integer, and anything else is rejected, not trimmed.
 */
public final class EventValidator {
    private EventValidator() {}

    private static final DateTimeFormatter SQL_TS = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    private static final Duration CLIENT_CLOCK_WINDOW = Duration.ofHours(24);

    /** A validated event, ready to insert. */
    public record Clean(String workId, String step, String kind, String ref, Integer ms, String clientAt) {}

    public static List<Clean> events(List<EventIn> batch, Instant now) {
        if (batch == null || batch.isEmpty()) throw new BadRequest("events must not be empty");
        if (batch.size() > MAX_EVENTS_PER_BATCH) throw new BadRequest("at most " + MAX_EVENTS_PER_BATCH + " events per request");
        List<Clean> out = new ArrayList<>(batch.size());
        for (int i = 0; i < batch.size(); i++) {
            try {
                out.add(event(batch.get(i), now));
            } catch (BadRequest ex) {
                // Name the position, never echo the offending value back.
                throw new BadRequest("event #" + i + " rejected: " + ex.getMessage());
            }
        }
        return out;
    }

    static Clean event(EventIn e, Instant now) {
        if (e == null) throw new BadRequest("empty event");
        if (e.workId() == null || !ID.matcher(e.workId()).matches()) throw new BadRequest("workId");
        if (e.step() == null || !STEPS.contains(e.step())) throw new BadRequest("step");
        if (e.kind() == null || !EVENT_KINDS.contains(e.kind())) throw new BadRequest("kind");

        String ref = e.ref();
        Integer ms = e.ms();
        switch (e.kind()) {
            case "step_enter", "step_skip" -> { require(ref == null, "ref not allowed"); require(ms == null, "ms not allowed"); }
            case "step_leave" -> {
                require(ref == null, "ref not allowed");
                require(ms != null && ms >= 0 && ms <= MAX_DWELL_MS, "ms out of range");
            }
            case "layer_open" -> {
                require("arrive".equals(e.step()), "layer_open only in arrive");
                require(ref != null && LAYERS.contains(ref), "ref");
                require(ms == null, "ms not allowed");
            }
            case "line_tap" -> {
                require("read".equals(e.step()) || "return".equals(e.step()), "line_tap only in read/return");
                require(isLineSeq(ref), "ref");
                require(ms == null, "ms not allowed");
            }
            case "ask" -> { require(ref != null && ASK_ACTIONS.contains(ref), "ref"); require(ms == null, "ms not allowed"); }
            case "retell_submit" -> {
                require("recite".equals(e.step()), "retell_submit only in recite");
                require(ref != null && RETELL_LENGTHS.contains(ref), "ref");
                require(ms == null, "ms not allowed");
            }
            case "media_degraded" -> { require(ref != null && DEGRADE_REASONS.contains(ref), "ref"); require(ms == null, "ms not allowed"); }
            case "agent_fallback" -> { require(ref != null && FALLBACK_REASONS.contains(ref), "ref"); require(ms == null, "ms not allowed"); }
            default -> throw new BadRequest("kind");
        }
        return new Clean(e.workId(), e.step(), e.kind(), ref, ms, clientTime(e.at(), now));
    }

    static boolean isLineSeq(String ref) {
        if (ref == null || ref.isEmpty() || ref.length() > 2) return false;
        for (int i = 0; i < ref.length(); i++) if (ref.charAt(i) < '0' || ref.charAt(i) > '9') return false;
        int n = Integer.parseInt(ref);
        return n >= 1 && n <= MAX_LINE_SEQ;
    }

    /**
     * The client clock is kept only when it is within a day of the server clock; a wild value is dropped (null),
     * not rejected, because a wrong phone clock is not the learner's mistake.
     */
    static String clientTime(String at, Instant now) {
        if (at == null || at.isBlank()) return null;
        try {
            Instant t = Instant.parse(at);
            if (Duration.between(t, now).abs().compareTo(CLIENT_CLOCK_WINDOW) > 0) return null;
            return LocalDateTime.ofInstant(t, ZoneOffset.UTC).format(SQL_TS);
        } catch (DateTimeParseException ex) {
            return null;
        }
    }

    public static SessionWrite session(SessionWrite in) {
        if (in == null) throw new BadRequest("empty session");
        if (in.lastStep() == null || !STEPS.contains(in.lastStep())) throw new BadRequest("lastStep");
        List<String> visited = in.visited() == null ? List.of() : in.visited();
        if (visited.size() > STEPS.size()) throw new BadRequest("visited");
        Set<String> seen = new HashSet<>();
        for (String s : visited) {
            if (s == null || !STEPS.contains(s) || !seen.add(s)) throw new BadRequest("visited");
        }
        return new SessionWrite(in.lastStep(), List.copyOf(visited));
    }

    public static GapIn gaps(GapIn in) {
        if (in == null) throw new BadRequest("empty gap report");
        if (in.workId() == null || !ID.matcher(in.workId()).matches()) throw new BadRequest("workId");
        if (in.scriptHash() == null || !SCRIPT_HASH.matcher(in.scriptHash()).matches()) throw new BadRequest("scriptHash");
        List<String> covered = points(in.covered());
        List<String> missing = points(in.missing());
        Set<String> overlap = new HashSet<>(covered);
        overlap.retainAll(missing);
        if (!overlap.isEmpty()) throw new BadRequest("a point cannot be both covered and missing");
        if (covered.isEmpty() && missing.isEmpty()) throw new BadRequest("no points");
        return new GapIn(in.workId(), in.scriptHash(), covered, missing);
    }

    private static List<String> points(List<String> in) {
        if (in == null) return List.of();
        if (in.size() > MAX_POINTS_PER_LIST) throw new BadRequest("too many points");
        Set<String> seen = new HashSet<>();
        for (String p : in) {
            if (p == null || !POINT_ID.matcher(p).matches() || !seen.add(p)) throw new BadRequest("point id");
        }
        return List.copyOf(in);
    }

    private static void require(boolean ok, String why) {
        if (!ok) throw new BadRequest(why);
    }
}
