package com.timeline.poetry;

import com.timeline.poetry.domain.TimeSpan;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class TimeSpanTest {
    @Test void preservesUnknownAndUncertainRanges() {
        assertNull(new TimeSpan(null, null, "UNKNOWN").startYear());
        assertEquals(757, new TimeSpan(756, 758, "APPROXIMATE").startYear() + 1);
        assertDoesNotThrow(() -> new TimeSpan(-2, 2, "RANGE"));
    }
    @Test void rejectsYearZeroReversedAndFalseExactDates() {
        assertThrows(IllegalArgumentException.class, () -> new TimeSpan(0, 1, "RANGE"));
        assertThrows(IllegalArgumentException.class, () -> new TimeSpan(758, 757, "RANGE"));
        assertThrows(IllegalArgumentException.class, () -> new TimeSpan(756, 758, "EXACT"));
        assertThrows(IllegalArgumentException.class, () -> new TimeSpan(null, 757, "EXACT"));
        assertThrows(IllegalArgumentException.class, () -> new TimeSpan(757, 757, "UNKNOWN"));
    }
}
