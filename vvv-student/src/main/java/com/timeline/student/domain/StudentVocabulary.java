package com.timeline.student.domain;

import java.util.List;
import java.util.Set;
import java.util.regex.Pattern;

/**
 * The only place the student API states its closed vocabularies. Events carry no free text, so every
 * accepted value is listed here; anything else is rejected before it can reach a table.
 */
public final class StudentVocabulary {
    private StudentVocabulary() {}

    /** Order matters: it is the five-step order 读 到 见 回 诵. */
    public static final List<String> STEPS = List.of("read", "arrive", "meet", "return", "recite");
    public static final Set<String> LAYERS = Set.of("SCENE", "CITY", "WORLD", "PERSON");
    public static final Set<String> ASK_ACTIONS = Set.of("rephrase", "hint", "ask_why", "open_layer", "basis",
        "recite_prompt", "decline");
    public static final Set<String> DEGRADE_REASONS = Set.of("weak_net", "low_memory", "reduced_motion", "user_off",
        "asset_failed", "context_lost");
    public static final Set<String> FALLBACK_REASONS = Set.of("timeout", "unavailable", "rejected", "budget", "disabled");
    public static final Set<String> RETELL_LENGTHS = Set.of("len_0_20", "len_21_60", "len_61_plus");
    public static final Set<String> EVENT_KINDS = Set.of("step_enter", "step_leave", "step_skip", "layer_open",
        "line_tap", "ask", "retell_submit", "media_degraded", "agent_fallback");
    public static final Set<String> GAP_STATES = Set.of("COVERED", "MISSING");

    /** Same shape the catalog accepts for ids: no path characters, no whitespace, bounded length. */
    public static final Pattern ID = Pattern.compile("[A-Za-z0-9][A-Za-z0-9_-]{0,63}");
    /** A retell point id, e.g. "p-era", "p-scene". */
    public static final Pattern POINT_ID = Pattern.compile("[A-Za-z0-9][A-Za-z0-9_.-]{0,47}");
    /** A bundle hash is the full SHA-256 hex. A prefix is never accepted: the hash is also a file path part. */
    public static final Pattern BUNDLE_HASH = Pattern.compile("[a-f0-9]{64}");
    public static final Pattern SCRIPT_HASH = Pattern.compile("[a-f0-9]{12,64}");

    public static final int MAX_EVENTS_PER_BATCH = 50;
    public static final int MAX_POINTS_PER_LIST = 12;
    public static final int MAX_DWELL_MS = 3_600_000;
    public static final int MAX_LINE_SEQ = 64;
    /** Below this many distinct devices the gap board refuses to show a number (small-group disclosure). */
    public static final int MIN_BOARD_DEVICES = 5;
}
