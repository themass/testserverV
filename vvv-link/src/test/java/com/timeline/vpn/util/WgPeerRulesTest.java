package com.timeline.vpn.util;

import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;

class WgPeerRulesTest {

    @Test
    void freeLinesAcceptEveryDeviceIncludingUnknownOwners() {
        Assertions.assertTrue(WgPeerRules.allowed(0, 0));
        Assertions.assertTrue(WgPeerRules.allowed(4, null));
    }

    @Test
    void paidLineNeedsAUserAtOrAboveTheLineLevel() {
        Assertions.assertTrue(WgPeerRules.allowed(1, 1));
        Assertions.assertTrue(WgPeerRules.allowed(1, 2));
        Assertions.assertFalse(WgPeerRules.allowed(1, 0));
        Assertions.assertFalse(WgPeerRules.allowed(2, 1));
    }

    @Test
    void unknownOwnerNeverGetsAPaidLine() {
        Assertions.assertFalse(WgPeerRules.allowed(1, null));
    }
}
