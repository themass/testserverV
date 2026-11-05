package com.timeline.vpn.util;

import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;

class WgSyncAuthTest {

    private static final String TOKEN = "0123456789abcdef0123456789abcdef";

    @Test
    void matchingTokenIsAccepted() {
        Assertions.assertTrue(WgSyncAuth.matches(TOKEN, TOKEN));
    }

    @Test
    void wrongOrMissingTokenIsRejected() {
        Assertions.assertFalse(WgSyncAuth.matches("0123456789abcdef0123456789abcdee", TOKEN));
        Assertions.assertFalse(WgSyncAuth.matches(TOKEN.substring(0, 30), TOKEN));
        Assertions.assertFalse(WgSyncAuth.matches(null, TOKEN));
        Assertions.assertFalse(WgSyncAuth.matches("", TOKEN));
    }

    @Test
    void unconfiguredServerRejectsEverythingIncludingEmptyToken() {
        Assertions.assertFalse(WgSyncAuth.matches("", ""));
        Assertions.assertFalse(WgSyncAuth.matches(null, null));
        Assertions.assertFalse(WgSyncAuth.matches("anything", ""));
        Assertions.assertFalse(WgSyncAuth.matches("anything", null));
    }

    @Test
    void weakConfiguredTokenIsRejectedEvenWhenItMatches() {
        Assertions.assertFalse(WgSyncAuth.matches("123456", "123456"));
    }
}
