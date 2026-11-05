package com.timeline.poetry;

import com.timeline.poetry.domain.PublicationGate;
import org.junit.jupiter.api.Test;
import java.util.List;
import static org.junit.jupiter.api.Assertions.*;

class PublicationGateTest {
    @Test void humanReviewAndEvidenceAreBothRequired() {
        assertFalse(PublicationGate.problems("", "FACT", List.of("source-1"), true).isEmpty());
        assertFalse(PublicationGate.problems("reviewer", "FACT", List.of(), true).isEmpty());
        assertTrue(PublicationGate.problems("reviewer", "FACT", List.of("source-1"), true).isEmpty());
    }
    @Test void dramatizationMustBeLabeledAndNeverMasqueradesAsFact() {
        assertFalse(PublicationGate.problems("reviewer", "DRAMATIZATION", List.of(), false).isEmpty());
        assertTrue(PublicationGate.problems("reviewer", "DRAMATIZATION", List.of(), true).isEmpty());
        assertFalse(PublicationGate.problems("reviewer", "INVENTED", List.of("s"), true).isEmpty());
    }
}
