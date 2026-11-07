package com.timeline.student;

import com.timeline.student.api.StudentModels.EventIn;
import com.timeline.student.api.StudentModels.GapIn;
import com.timeline.student.api.StudentModels.SessionWrite;
import com.timeline.student.domain.StudentErrors.BadRequest;
import com.timeline.student.service.EventValidator;
import org.junit.jupiter.api.Test;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import static org.junit.jupiter.api.Assertions.*;

/** The privacy contract as executable rules: no free text can enter, only enumerated values and small integers. */
class EventValidatorTest {
    private static final Instant NOW = Instant.parse("2026-11-06T12:00:00Z");

    private static EventIn ev(String step, String kind, String ref, Integer ms) {
        return new EventIn("work-chun-wang", step, kind, ref, ms, null);
    }

    private static List<EventValidator.Clean> ok(EventIn... in) { return EventValidator.events(List.of(in), NOW); }

    private static void rejected(EventIn in) {
        assertThrows(BadRequest.class, () -> EventValidator.events(List.of(in), NOW));
    }

    @Test void acceptsEachWhitelistedKind() {
        assertEquals(9, ok(
            ev("arrive", "step_enter", null, null),
            ev("arrive", "step_leave", null, 42_000),
            ev("arrive", "step_skip", null, null),
            ev("arrive", "layer_open", "WORLD", null),
            ev("return", "line_tap", "3", null),
            ev("meet", "ask", "basis", null),
            ev("recite", "retell_submit", "len_21_60", null),
            ev("arrive", "media_degraded", "weak_net", null),
            ev("meet", "agent_fallback", "timeout", null)).size());
    }

    @Test void freeTextInRefIsRejectedNotTrimmed() {
        rejected(ev("meet", "ask", "我家住在北京市海淀区", null));
        rejected(ev("recite", "retell_submit", "杜甫被困在长安", null));
        rejected(ev("arrive", "layer_open", "SCENE; DROP TABLE student_event", null));
        rejected(ev("arrive", "media_degraded", "iPad Air 5 / iOS 17.4", null));
    }

    @Test void refAndMsAreOnlyAllowedWhereTheKindDefinesThem() {
        rejected(ev("arrive", "step_enter", "WORLD", null));
        rejected(ev("arrive", "step_enter", null, 10));
        rejected(ev("arrive", "step_leave", null, null));          // dwell time is required
        rejected(ev("arrive", "step_leave", null, -1));
        rejected(ev("arrive", "step_leave", null, 3_600_001));
        rejected(ev("meet", "layer_open", "WORLD", null));          // layer_open only exists in arrive
        rejected(ev("meet", "line_tap", "3", null));                // line_tap only in read/return
        rejected(ev("read", "retell_submit", "len_0_20", null));    // retell only in recite
    }

    @Test void lineSeqIsASmallPositiveInteger() {
        assertEquals(1, ok(ev("read", "line_tap", "1", null)).size());
        assertEquals(1, ok(ev("read", "line_tap", "64", null)).size());
        rejected(ev("read", "line_tap", "0", null));
        rejected(ev("read", "line_tap", "65", null));
        rejected(ev("read", "line_tap", "007", null));
        rejected(ev("read", "line_tap", "3a", null));
        rejected(ev("read", "line_tap", "-1", null));
        rejected(ev("read", "line_tap", "", null));
    }

    @Test void unknownStepKindAndBadWorkIdAreRejected() {
        rejected(ev("quiz", "step_enter", null, null));
        rejected(ev("arrive", "score", null, null));
        rejected(new EventIn("../etc/passwd", "arrive", "step_enter", null, null, null));
        rejected(new EventIn("", "arrive", "step_enter", null, null, null));
        rejected(new EventIn(null, "arrive", "step_enter", null, null, null));
    }

    @Test void batchSizeIsBoundedAndEmptyIsRejected() {
        assertThrows(BadRequest.class, () -> EventValidator.events(List.of(), NOW));
        assertThrows(BadRequest.class, () -> EventValidator.events(null, NOW));
        List<EventIn> fifty = new ArrayList<>();
        for (int i = 0; i < 50; i++) fifty.add(ev("arrive", "step_enter", null, null));
        assertEquals(50, EventValidator.events(fifty, NOW).size());
        fifty.add(ev("arrive", "step_enter", null, null));
        assertThrows(BadRequest.class, () -> EventValidator.events(fifty, NOW));
    }

    @Test void errorMessageNamesThePositionButNeverEchoesTheValue() {
        BadRequest ex = assertThrows(BadRequest.class,
            () -> EventValidator.events(List.of(ev("arrive", "step_enter", null, null),
                ev("meet", "ask", "my phone is 13800000000", null)), NOW));
        assertTrue(ex.getMessage().contains("#1"));
        assertFalse(ex.getMessage().contains("13800000000"));
    }

    @Test void clientClockIsKeptOnlyWhenPlausible() {
        EventIn near = new EventIn("work-chun-wang", "arrive", "step_enter", null, null, "2026-11-06T11:59:00Z");
        EventIn wild = new EventIn("work-chun-wang", "arrive", "step_enter", null, null, "2031-01-01T00:00:00Z");
        EventIn junk = new EventIn("work-chun-wang", "arrive", "step_enter", null, null, "yesterday-ish");
        assertEquals("2026-11-06 11:59:00", EventValidator.events(List.of(near), NOW).get(0).clientAt());
        assertNull(EventValidator.events(List.of(wild), NOW).get(0).clientAt());   // dropped, not rejected
        assertNull(EventValidator.events(List.of(junk), NOW).get(0).clientAt());
    }

    @Test void sessionAcceptsOnlyKnownStepsWithoutDuplicates() {
        SessionWrite good = EventValidator.session(new SessionWrite("arrive", List.of("read", "arrive"), "PRIMARY"));
        assertEquals("arrive", good.lastStep());
        assertThrows(BadRequest.class, () -> EventValidator.session(new SessionWrite("quiz", List.of(), "PRIMARY")));
        assertThrows(BadRequest.class, () -> EventValidator.session(new SessionWrite("arrive", List.of("read", "read"), "PRIMARY")));
        assertThrows(BadRequest.class, () -> EventValidator.session(new SessionWrite("arrive", List.of("x"), "PRIMARY")));
        assertThrows(BadRequest.class, () -> EventValidator.session(new SessionWrite("arrive", List.of(), "SENIOR")));
        assertThrows(BadRequest.class, () -> EventValidator.session(null));
    }

    @Test void gapsCarryPointIdsOnlyAndNeverOverlap() {
        GapIn good = EventValidator.gaps(new GapIn("work-chun-wang", "60279d333bec", List.of("p-era"), List.of("p-home")));
        assertEquals(List.of("p-era"), good.covered());
        assertThrows(BadRequest.class, () -> EventValidator.gaps(new GapIn("work-chun-wang", "60279d333bec", List.of("p-era"), List.of("p-era"))));
        assertThrows(BadRequest.class, () -> EventValidator.gaps(new GapIn("work-chun-wang", "60279d333bec", List.of(), List.of())));
        assertThrows(BadRequest.class, () -> EventValidator.gaps(new GapIn("work-chun-wang", "60279d333bec",
            List.of("他说因为想家所以才写了这首诗"), List.of())));                 // sentences are not point ids
        assertThrows(BadRequest.class, () -> EventValidator.gaps(new GapIn("work-chun-wang", "nothex!", List.of("p-era"), List.of())));
    }
}
